<?php

namespace App\Console\Commands;

use App\Models\FidelidadOutboxEvent;
use App\Models\SoftwareInstance;
use App\Services\FidelidadEntitlementSyncService;
use Illuminate\Console\Command;
use Illuminate\Validation\ValidationException;

class SyncFidelidadEntitlements extends Command
{
    protected $signature = 'fidelidad:sync {--limit=100}';

    protected $description = 'Reconcile and deliver ADN Fidelidad subscription entitlements';

    public function handle(FidelidadEntitlementSyncService $sync): int
    {
        $baseUrl = (string) config('services.fidelidad.api_url');
        $secret = (string) config('services.fidelidad.webhook_secret');
        if ($baseUrl === '' || $secret === '') {
            $this->error('Configure FIDELIDAD_API_URL y FIDELIDAD_WEBHOOK_SECRET antes de sincronizar.');

            return self::FAILURE;
        }

        $limit = filter_var($this->option('limit'), FILTER_VALIDATE_INT);
        if ($limit === false || $limit < 1 || $limit > 500) {
            $this->error('--limit debe ser un entero entre 1 y 500.');

            return self::FAILURE;
        }

        $invalidInstances = 0;
        SoftwareInstance::query()
            ->whereHas('product', fn ($query) => $query->where('code', config('services.fidelidad.product_code')))
            ->orderBy('id')
            ->chunkById(100, function ($instances) use ($sync, &$invalidInstances): void {
                foreach ($instances as $instance) {
                    try {
                        $sync->reconcile($instance);
                    } catch (ValidationException $exception) {
                        $invalidInstances++;
                        $message = collect($exception->errors())->flatten()->first();
                        $this->error("Instancia {$instance->public_id}: {$message}");
                    }
                }
            });

        $failedDeliveries = 0;
        FidelidadOutboxEvent::query()
            ->where('status', 'pending')
            ->where(fn ($query) => $query
                ->whereNull('next_attempt_at')
                ->orWhere('next_attempt_at', '<=', now()))
            ->orderBy('id')
            ->limit($limit)
            ->get()
            ->each(function (FidelidadOutboxEvent $event) use ($sync, &$failedDeliveries): void {
                if (! $sync->deliver($event)) {
                    $failedDeliveries++;
                    $this->error("No se pudo entregar el evento {$event->event_id}; se reintentará.");
                }
            });

        if ($invalidInstances > 0 || $failedDeliveries > 0) {
            return self::FAILURE;
        }

        $this->info('Sincronización con ADN Fidelidad completada.');

        return self::SUCCESS;
    }
}
