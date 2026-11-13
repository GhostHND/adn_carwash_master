<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\SoftwareInstance;
use App\Models\SoftwareProduct;
use App\Models\Subscription;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class GenerateRecurringChargesTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_recurring_charges_use_calendar_cycles_and_are_idempotent(): void
    {
        Carbon::setTestNow('2026-03-31 12:00:00');

        $customer = Customer::query()->create([
            'public_id' => (string) Str::uuid(),
            'legal_name' => 'Customer',
            'status' => 'active',
        ]);
        $product = SoftwareProduct::query()->create([
            'public_id' => (string) Str::uuid(),
            'code' => (string) Str::uuid(),
            'name' => 'Product',
        ]);
        $instance = SoftwareInstance::query()->create([
            'public_id' => (string) Str::uuid(),
            'customer_id' => $customer->id,
            'product_id' => $product->id,
            'name' => 'Instance',
            'administrative_status' => 'pending',
        ]);
        $subscription = Subscription::query()->create([
            'public_id' => (string) Str::uuid(),
            'instance_id' => $instance->id,
            'currency' => 'HNL',
            'status' => 'active',
            'starts_on' => '2026-01-31',
            'activated_at' => '2026-01-31 12:00:00',
        ]);
        $subscription->items()->createMany([
            [
                'concept' => 'Monthly',
                'amount_cents' => 1000,
                'billing_frequency' => 'monthly',
                'effective_from' => '2026-01-31',
            ],
            [
                'concept' => 'One time',
                'amount_cents' => 500,
                'billing_frequency' => 'one_time',
                'effective_from' => '2026-02-01',
            ],
        ]);

        $this->artisan('billing:charges:generate')->assertSuccessful();
        $this->artisan('billing:charges:generate')->assertSuccessful();

        $this->assertDatabaseCount('charges', 3);
        $this->assertSame(
            ['2026-02-01', '2026-02-28', '2026-03-31'],
            $subscription->charges()->orderBy('due_date')->pluck('due_date')->map(
                fn ($date) => Carbon::parse($date)->toDateString(),
            )->all(),
        );
        $this->assertSame(
            ['issued'],
            $subscription->charges()->pluck('status')->unique()->all(),
        );
    }
}
