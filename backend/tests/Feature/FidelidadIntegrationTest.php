<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\FidelidadOutboxEvent;
use App\Models\ProductPlan;
use App\Models\SoftwareInstance;
use App\Models\SoftwareProduct;
use App\Models\Subscription;
use App\Services\FidelidadEntitlementSyncService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request as ClientRequest;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Tests\TestCase;

class FidelidadIntegrationTest extends TestCase
{
    use RefreshDatabase;

    private const API_KEY = 'fidelidad-test-key';

    private const API_SECRET = 'fidelidad-test-api-secret';

    private const WEBHOOK_SECRET = 'fidelidad-test-webhook-secret';

    public function test_signed_pull_returns_a_versioned_entitlement_and_retries_are_safe(): void
    {
        $instance = $this->makeInstance();
        $this->configurePullCredentials();

        $first = $this->signedPull($instance->public_id)
            ->assertOk()
            ->assertJsonPath('product_code', 'adn-fidelidad')
            ->assertJsonPath('business.master_business_id', $instance->public_id)
            ->assertJsonPath('subscription.plan', 'pro')
            ->assertJsonPath('subscription.status', 'active')
            ->assertJsonPath('subscription.features', ['reports'])
            ->assertJsonPath('subscription.limits.max_programs', 3)
            ->assertJsonMissingPath('subscription.internal_id');

        $eventId = $first->json('event_id');
        $this->signedPull($instance->public_id)
            ->assertOk()
            ->assertJsonPath('event_id', $eventId)
            ->assertJsonPath('event_version', 1);
        $this->assertDatabaseCount('fidelidad_integration_outbox', 1);
    }

    public function test_pull_requires_a_valid_signature_and_bearer_key(): void
    {
        $instance = $this->makeInstance();
        $this->configurePullCredentials();

        $this->getJson($this->pullPath($instance->public_id))
            ->assertUnauthorized();

        $this->signedPull($instance->public_id, secret: 'wrong-secret')
            ->assertUnauthorized();

        $this->signedPull($instance->public_id, bearer: 'wrong-key')
            ->assertUnauthorized();

        $this->signedPull($instance->public_id, timestamp: now()->subHour()->timestamp)
            ->assertUnauthorized();
    }

    public function test_reconciliation_is_idempotent_and_versions_entitlement_changes(): void
    {
        $instance = $this->makeInstance();
        $sync = app(FidelidadEntitlementSyncService::class);

        $first = $sync->reconcile($instance);
        $first->update(['payload' => array_reverse($first->payload, true)]);
        $same = $sync->reconcile($instance);
        $this->assertSame($first->id, $same->id);

        $instance->subscriptions()->firstOrFail()->update(['status' => 'suspended']);
        $changed = $sync->reconcile($instance);

        $this->assertNotSame($first->id, $changed->id);
        $this->assertSame(2, $changed->event_version);
        $this->assertSame('suspended', $changed->payload['subscription']['status']);
        $this->assertSame(2, $instance->fresh()->entitlement_version);
    }

    public function test_draft_subscription_is_not_sent_to_fidelidad(): void
    {
        $instance = $this->makeInstance();
        $instance->subscriptions()->firstOrFail()->update(['status' => 'draft']);
        config([
            'services.fidelidad.api_url' => 'https://fidelidad.test',
            'services.fidelidad.webhook_secret' => self::WEBHOOK_SECRET,
        ]);
        Http::fake();

        $this->artisan('fidelidad:sync')->assertExitCode(0);
        $this->assertDatabaseCount('fidelidad_integration_outbox', 0);
        Http::assertNothingSent();
    }

    public function test_sync_command_signs_exact_json_body_and_marks_acknowledged_event_delivered(): void
    {
        $this->makeInstance();
        config([
            'services.fidelidad.api_url' => 'https://fidelidad.test',
            'services.fidelidad.webhook_secret' => self::WEBHOOK_SECRET,
        ]);

        Http::fake(['*' => Http::response(['status' => 'applied'], 200)]);

        $this->artisan('fidelidad:sync')
            ->assertExitCode(0);

        $event = FidelidadOutboxEvent::query()->firstOrFail();
        $this->assertSame('delivered', $event->status);
        $this->assertSame(1, $event->attempts);
        $this->assertNotNull($event->delivered_at);
        Http::assertSent(function (ClientRequest $request): bool {
            $timestamp = $request->header('X-ADN-Timestamp')[0] ?? '';
            $idempotencyKey = $request->header('X-ADN-Idempotency-Key')[0] ?? '';
            $signature = $request->header('X-ADN-Signature')[0] ?? '';
            $expected = hash_hmac(
                'sha256',
                $timestamp."\n".$idempotencyKey."\n".$request->body(),
                self::WEBHOOK_SECRET,
            );

            return $request->url() === 'https://fidelidad.test/api/v1/master/entitlements'
                && hash_equals($expected, $signature);
        });
    }

    public function test_failed_delivery_stays_pending_with_a_retry_time(): void
    {
        $this->makeInstance();
        config([
            'services.fidelidad.api_url' => 'https://fidelidad.test',
            'services.fidelidad.webhook_secret' => self::WEBHOOK_SECRET,
        ]);
        Http::fake(['*' => Http::response(['message' => 'No vinculado.'], 404)]);

        $this->artisan('fidelidad:sync')
            ->assertExitCode(1);

        $event = FidelidadOutboxEvent::query()->firstOrFail();
        $this->assertSame('pending', $event->status);
        $this->assertSame(1, $event->attempts);
        $this->assertSame(404, $event->last_http_status);
        $this->assertNotNull($event->next_attempt_at);
    }

    private function configurePullCredentials(): void
    {
        config([
            'services.fidelidad.api_key' => self::API_KEY,
            'services.fidelidad.api_secret' => self::API_SECRET,
            'services.fidelidad.product_code' => 'adn-fidelidad',
            'services.fidelidad.max_clock_skew' => 300,
        ]);
    }

    private function signedPull(
        string $instancePublicId,
        string $secret = self::API_SECRET,
        string $bearer = self::API_KEY,
        ?int $timestamp = null,
    ) {
        $timestamp = (string) ($timestamp ?? now()->timestamp);
        $key = (string) Str::uuid();
        $signature = hash_hmac('sha256', $timestamp."\n".$key."\n", $secret);

        return $this->call('GET', $this->pullPath($instancePublicId), [], [], [], [
            'HTTP_ACCEPT' => 'application/json',
            'HTTP_AUTHORIZATION' => 'Bearer '.$bearer,
            'HTTP_X_ADN_TIMESTAMP' => $timestamp,
            'HTTP_X_ADN_IDEMPOTENCY_KEY' => $key,
            'HTTP_X_ADN_SIGNATURE' => $signature,
        ]);
    }

    private function pullPath(string $instancePublicId): string
    {
        return '/api/v1/integrations/adn-fidelidad/subscriptions/'.$instancePublicId;
    }

    private function makeInstance(): SoftwareInstance
    {
        $product = SoftwareProduct::query()->create([
            'public_id' => (string) Str::uuid(),
            'code' => 'adn-fidelidad',
            'name' => 'ADN Fidelidad',
            'status' => 'active',
        ]);
        $plan = ProductPlan::query()->create([
            'public_id' => (string) Str::uuid(),
            'product_id' => $product->id,
            'code' => 'pro',
            'name' => 'Pro',
            'price_cents' => 10000,
            'currency' => 'HNL',
            'billing_period' => 'monthly',
            'status' => 'active',
        ]);
        $plan->features()->create([
            'feature_code' => 'reports',
            'enabled' => true,
        ]);
        $plan->features()->create([
            'feature_code' => 'max_programs',
            'enabled' => true,
            'limit_value' => 3,
        ]);
        $customer = Customer::query()->create([
            'public_id' => (string) Str::uuid(),
            'legal_name' => 'Cliente de prueba',
        ]);
        $instance = SoftwareInstance::query()->create([
            'public_id' => (string) Str::uuid(),
            'customer_id' => $customer->id,
            'product_id' => $product->id,
            'plan_id' => $plan->id,
            'name' => 'Instancia de prueba',
        ]);
        Subscription::query()->create([
            'public_id' => (string) Str::uuid(),
            'instance_id' => $instance->id,
            'status' => 'active',
            'starts_on' => today(),
            'ends_on' => today()->addMonth(),
            'currency' => 'HNL',
        ]);

        return $instance;
    }
}
