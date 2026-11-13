<?php

namespace App\Services;

use App\Models\FidelidadOutboxEvent;
use App\Models\PlanFeature;
use App\Models\SoftwareInstance;
use App\Models\Subscription;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class FidelidadEntitlementSyncService
{
    private const FEATURE_CODES = [
        'wallet_apple',
        'wallet_google',
        'reports',
        'export',
        'multiple_programs',
        'staff',
    ];

    private const LIMIT_CODES = [
        'max_programs',
        'max_branches',
        'max_staff',
        'max_customers',
    ];

    private const SUBSCRIPTION_STATUSES = [
        'active',
        'trial',
        'past_due',
        'suspended',
        'expired',
        'cancelled',
    ];

    private const ACCEPTED_RESPONSES = ['applied', 'duplicate', 'ignored'];

    public function reconcile(SoftwareInstance $source): ?FidelidadOutboxEvent
    {
        return DB::transaction(function () use ($source): ?FidelidadOutboxEvent {
            $instance = SoftwareInstance::query()
                ->lockForUpdate()
                ->findOrFail($source->getKey());
            $instance->load(['product', 'plan.features']);

            if ($instance->product->code !== config('services.fidelidad.product_code')) {
                return null;
            }

            $subscription = $instance->subscriptions()->orderByDesc('id')->first();
            if (! $subscription || $subscription->status === 'draft') {
                return null;
            }

            if (! $instance->plan) {
                throw ValidationException::withMessages([
                    'subscription.plan' => 'La instancia no tiene un plan asignado.',
                ]);
            }

            $state = $this->entitlementState($instance, $subscription);
            $latest = FidelidadOutboxEvent::query()
                ->where('instance_id', $instance->id)
                ->orderByDesc('event_version')
                ->first();

            if ($latest && $this->sameState($latest->payload, $state)) {
                return $latest;
            }

            $version = $instance->entitlement_version + 1;
            $eventId = (string) Str::uuid();
            $eventType = $latest ? 'subscription.updated' : 'subscription.created';
            $payload = [
                'event_id' => $eventId,
                'event_type' => $eventType,
                'event_version' => $version,
                ...$state,
            ];

            $instance->entitlement_version = $version;
            $instance->save();

            return FidelidadOutboxEvent::query()->create([
                'instance_id' => $instance->id,
                'event_id' => $eventId,
                'event_version' => $version,
                'event_type' => $eventType,
                'payload' => $payload,
                'status' => 'pending',
            ]);
        });
    }

    public function deliver(FidelidadOutboxEvent $event): bool
    {
        $baseUrl = rtrim((string) config('services.fidelidad.api_url'), '/');
        $secret = (string) config('services.fidelidad.webhook_secret');
        if ($baseUrl === '' || $secret === '') {
            throw new \LogicException('Configure FIDELIDAD_API_URL y FIDELIDAD_WEBHOOK_SECRET antes de sincronizar.');
        }

        $body = json_encode(
            $event->payload,
            JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE,
        );
        $timestamp = (string) now()->timestamp;
        $idempotencyKey = (string) Str::uuid();
        $signature = hash_hmac(
            'sha256',
            $timestamp."\n".$idempotencyKey."\n".$body,
            $secret,
        );

        try {
            $response = Http::acceptJson()
                ->timeout(15)
                ->withHeaders([
                    'X-ADN-Timestamp' => $timestamp,
                    'X-ADN-Idempotency-Key' => $idempotencyKey,
                    'X-ADN-Signature' => $signature,
                ])
                ->withBody($body, 'application/json')
                ->post($baseUrl.'/api/v1/master/entitlements');
        } catch (ConnectionException $exception) {
            $this->scheduleRetry($event, null, $exception->getMessage());

            return false;
        }

        $remoteStatus = $response->json('status');
        if ($response->successful() && in_array($remoteStatus, self::ACCEPTED_RESPONSES, true)) {
            $event->forceFill([
                'status' => 'delivered',
                'attempts' => $event->attempts + 1,
                'next_attempt_at' => null,
                'delivered_at' => now(),
                'last_http_status' => $response->status(),
                'last_error' => null,
            ])->save();

            return true;
        }

        $message = $response->json('message');
        $error = is_string($message) && $message !== ''
            ? $message
            : 'Respuesta de integración no reconocida.';
        $this->scheduleRetry($event, $response->status(), $error);

        return false;
    }

    private function entitlementState(SoftwareInstance $instance, Subscription $subscription): array
    {
        if (! in_array($subscription->status, self::SUBSCRIPTION_STATUSES, true)) {
            throw ValidationException::withMessages([
                'subscription.status' => 'El estado de suscripción no es compatible con ADN Fidelidad.',
            ]);
        }

        $features = [];
        $limits = [];

        foreach ($instance->plan->features->sortBy('feature_code') as $planFeature) {
            if (in_array($planFeature->feature_code, self::LIMIT_CODES, true)) {
                $limits[$planFeature->feature_code] = $this->limitValue($planFeature);

                continue;
            }

            if (! in_array($planFeature->feature_code, self::FEATURE_CODES, true)) {
                throw ValidationException::withMessages([
                    'plan.features' => "La funcionalidad {$planFeature->feature_code} no está soportada por ADN Fidelidad.",
                ]);
            }

            if ($planFeature->enabled) {
                $features[] = $planFeature->feature_code;
            }
        }

        return [
            'product_code' => config('services.fidelidad.product_code'),
            'business' => ['master_business_id' => $instance->public_id],
            'subscription' => [
                'id' => $subscription->public_id,
                'plan' => $instance->plan->code,
                'status' => $subscription->status,
                'starts_at' => $subscription->starts_on?->copy()->startOfDay()->toIso8601String(),
                'ends_at' => $subscription->ends_on?->copy()->endOfDay()->toIso8601String(),
                'features' => array_values(array_unique($features)),
                'limits' => $limits,
            ],
        ];
    }

    private function limitValue(PlanFeature $feature): ?int
    {
        if (! $feature->enabled) {
            return 0;
        }

        $value = $feature->limit_value;
        if ($value === null) {
            return null;
        }
        if (is_int($value) && $value >= 0) {
            return $value;
        }
        if (is_string($value) && ctype_digit($value)) {
            return (int) $value;
        }

        throw ValidationException::withMessages([
            'plan.features' => "El límite {$feature->feature_code} debe ser un entero no negativo o null.",
        ]);
    }

    private function sameState(array $payload, array $state): bool
    {
        unset($payload['event_id'], $payload['event_type'], $payload['event_version']);

        return hash_equals($this->canonicalJson($payload), $this->canonicalJson($state));
    }

    private function canonicalJson(array $value): string
    {
        return json_encode(
            $this->canonicalize($value),
            JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE,
        );
    }

    private function canonicalize(array $value): array
    {
        if (array_is_list($value)) {
            return array_map(
                fn ($item) => is_array($item) ? $this->canonicalize($item) : $item,
                $value,
            );
        }

        ksort($value);
        foreach ($value as $key => $item) {
            if (is_array($item)) {
                $value[$key] = $this->canonicalize($item);
            }
        }

        return $value;
    }

    private function scheduleRetry(FidelidadOutboxEvent $event, ?int $httpStatus, string $error): void
    {
        $attempts = min(65535, $event->attempts + 1);
        $delay = min(21600, 30 * (2 ** min($attempts - 1, 10)));
        $message = mb_substr($error, 0, 1000);

        $event->forceFill([
            'attempts' => $attempts,
            'next_attempt_at' => now()->addSeconds($delay),
            'last_http_status' => $httpStatus,
            'last_error' => $message,
        ])->save();

        Log::warning('Falló la sincronización de una suscripción con ADN Fidelidad.', [
            'event_id' => $event->event_id,
            'http_status' => $httpStatus,
            'attempts' => $attempts,
            'error' => $message,
        ]);
    }
}
