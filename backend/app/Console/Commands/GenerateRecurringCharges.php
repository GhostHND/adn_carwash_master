<?php

namespace App\Console\Commands;

use App\Models\Charge;
use App\Models\Subscription;
use Carbon\CarbonImmutable;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use LogicException;
use Ramsey\Uuid\Uuid;

class GenerateRecurringCharges extends Command
{
    protected $signature = 'billing:charges:generate';

    protected $description = 'Generate and issue due subscription charges';

    public function handle(): int
    {
        $today = CarbonImmutable::today();
        $created = 0;

        Subscription::query()
            ->where('status', 'active')
            ->whereNotNull('activated_at')
            ->where(fn ($query) => $query->whereNull('ends_on')->orWhereDate('ends_on', '>=', $today))
            ->orderBy('id')
            ->chunkById(100, function ($subscriptions) use ($today, &$created): void {
                foreach ($subscriptions as $subscription) {
                    $created += DB::transaction(function () use ($subscription, $today): int {
                        $subscription = Subscription::query()
                            ->with('items')
                            ->lockForUpdate()
                            ->findOrFail($subscription->id);

                        if ($subscription->status !== 'active' || $subscription->activated_at === null) {
                            return 0;
                        }

                        $generated = 0;
                        $activationDate = CarbonImmutable::parse($subscription->activated_at->toDateString());

                        foreach ($subscription->items as $item) {
                            if ($item->amount_cents < 1) {
                                continue;
                            }

                            $anchor = CarbonImmutable::parse($item->effective_from->toDateString());
                            $limit = $today;
                            if ($item->effective_until !== null && $item->effective_until->lessThan($limit)) {
                                $limit = CarbonImmutable::parse($item->effective_until->toDateString());
                            }
                            if ($subscription->ends_on !== null && $subscription->ends_on->lessThan($limit)) {
                                $limit = CarbonImmutable::parse($subscription->ends_on->toDateString());
                            }

                            $months = $this->intervalMonths($item->billing_frequency);
                            if ($months === null) {
                                if ($anchor->greaterThan($activationDate) && ! $anchor->greaterThan($limit)) {
                                    $generated += $this->createCharge($subscription, $item->id, $item->concept, $item->amount_cents, $anchor);
                                }

                                continue;
                            }

                            $cycle = 0;
                            $dueDate = $this->cycleDate($anchor, $months, $cycle);
                            while (! $dueDate->greaterThan($activationDate)) {
                                $cycle++;
                                $dueDate = $this->cycleDate($anchor, $months, $cycle);
                            }

                            while (! $dueDate->greaterThan($limit)) {
                                $generated += $this->createCharge(
                                    $subscription,
                                    $item->id,
                                    $item->concept,
                                    $item->amount_cents,
                                    $dueDate,
                                );
                                $cycle++;
                                $dueDate = $this->cycleDate($anchor, $months, $cycle);
                            }
                        }

                        return $generated;
                    });
                }
            });

        $this->info("Se generaron {$created} cargos recurrentes.");

        return self::SUCCESS;
    }

    private function intervalMonths(string $frequency): ?int
    {
        return match ($frequency) {
            'monthly' => 1,
            'quarterly' => 3,
            'yearly' => 12,
            'one_time' => null,
            default => throw new LogicException("Unsupported billing frequency: {$frequency}"),
        };
    }

    private function cycleDate(CarbonImmutable $anchor, int $months, int $cycle): CarbonImmutable
    {
        $month = $anchor->startOfMonth()->addMonthsNoOverflow($months * $cycle);

        return $month->setDay(min($anchor->day, $month->daysInMonth));
    }

    private function createCharge(
        Subscription $subscription,
        int $itemId,
        string $concept,
        int $amountCents,
        CarbonImmutable $dueDate,
    ): int {
        $idempotencyKey = Uuid::uuid5(
            Uuid::NAMESPACE_URL,
            "adn-master:billing:{$subscription->public_id}:{$itemId}:{$dueDate->toDateString()}",
        )->toString();

        $charge = Charge::query()->firstOrCreate(
            ['idempotency_key' => $idempotencyKey],
            [
                'public_id' => (string) Str::uuid(),
                'subscription_id' => $subscription->id,
                'concept' => $concept,
                'due_date' => $dueDate->toDateString(),
                'amount_cents' => $amountCents,
                'currency' => $subscription->currency,
                'status' => 'issued',
                'issued_at' => now(),
            ],
        );

        return $charge->wasRecentlyCreated ? 1 : 0;
    }
}
