<?php

namespace App\Console\Commands;

use App\Models\AuditEvent;
use App\Models\Subscription;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ExpireSubscriptions extends Command
{
    protected $signature = 'billing:subscriptions:expire';

    protected $description = 'Expire active subscriptions after their contract end date';

    public function handle(): int
    {
        $today = now()->toDateString();
        $expired = 0;

        Subscription::query()
            ->where('status', 'active')
            ->whereNotNull('ends_on')
            ->whereDate('ends_on', '<', $today)
            ->orderBy('id')
            ->chunkById(100, function ($subscriptions) use (&$expired): void {
                foreach ($subscriptions as $subscription) {
                    $didExpire = DB::transaction(function () use ($subscription): bool {
                        $subscription = Subscription::query()->lockForUpdate()->findOrFail($subscription->id);
                        if ($subscription->status !== 'active'
                            || $subscription->ends_on === null
                            || ! $subscription->ends_on->isBefore(today())) {
                            return false;
                        }

                        $subscription->update(['status' => 'expired']);
                        AuditEvent::query()->create([
                            'actor_id' => null,
                            'actor_type' => 'system',
                            'action' => 'subscription.expire',
                            'resource_type' => 'subscriptions',
                            'resource_id' => $subscription->public_id,
                            'occurred_at' => now(),
                            'outcome' => 'success',
                            'request_reference' => (string) Str::uuid(),
                            'metadata' => ['reason' => 'contract_end_date'],
                        ]);

                        return true;
                    });

                    $expired += $didExpire ? 1 : 0;
                }
            });

        $this->info("Se vencieron {$expired} suscripciones.");

        return self::SUCCESS;
    }
}
