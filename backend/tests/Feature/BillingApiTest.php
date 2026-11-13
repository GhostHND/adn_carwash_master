<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Payment;
use App\Models\Permission;
use App\Models\Role;
use App\Models\SoftwareInstance;
use App\Models\SoftwareProduct;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class BillingApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_draft_subscription_and_items_are_persisted_without_activation(): void
    {
        $this->owner();
        [$customer, $instance] = $this->directory();
        $id = $this->postJson('/api/v1/subscriptions', [
            'instance_id' => $instance->public_id,
            'currency' => 'HNL',
            'starts_on' => '2026-01-01',
        ])->assertCreated()->assertJsonPath('data.status', 'draft')->json('data.id');

        $this->putJson("/api/v1/subscriptions/$id/items", ['items' => [[
            'concept' => 'Software',
            'amount_cents' => 1500,
            'billing_frequency' => 'monthly',
            'effective_from' => '2026-01-01',
            'effective_until' => '2026-12-31',
        ]]])->assertOk()->assertJsonPath('data.items.0.amount_cents', 1500);
        $this->putJson("/api/v1/subscriptions/$id/items", ['items' => [[
            'concept' => 'Invalid',
            'amount_cents' => 1500,
            'billing_frequency' => 'monthly',
            'effective_from' => '2026-02-01',
            'effective_until' => '2026-01-01',
        ]]])->assertUnprocessable();
        $this->getJson("/api/v1/subscriptions/$id")->assertOk()->assertJsonPath('data.items.0.concept', 'Software');
        $this->patchJson("/api/v1/subscriptions/$id", ['ends_on' => '2025-01-01'])->assertUnprocessable();
        $this->patchJson("/api/v1/subscriptions/$id", ['status' => 'active'])->assertUnprocessable();
        $this->getJson("/api/v1/subscriptions/$id")->assertOk()->assertJsonPath('data.status', 'draft');
        $this->putJson("/api/v1/subscriptions/$id/items", ['items' => []])->assertOk()->assertJsonCount(0, 'data.items');
        $this->assertDatabaseHas('software_instances', ['id' => $instance->id, 'administrative_status' => 'pending']);
        $this->assertDatabaseHas('customers', ['id' => $customer->id]);
    }

    public function test_charge_and_payment_require_explicit_authorized_transitions(): void
    {
        $this->owner();
        [$customer, $instance] = $this->directory();
        $subscription = $this->subscription($instance);
        $chargeKey = (string) Str::uuid();
        $chargePayload = $this->chargePayload($subscription, $chargeKey);
        $this->postJson('/api/v1/charges', $chargePayload + ['status' => 'issued'])->assertUnprocessable();
        $chargeId = $this->postJson('/api/v1/charges', $chargePayload)
            ->assertCreated()->assertJsonPath('data.status', 'draft')->json('data.id');
        $this->postJson('/api/v1/charges', $chargePayload)->assertUnprocessable()->assertJsonValidationErrors('idempotency_key');
        $this->patchJson("/api/v1/subscriptions/{$subscription->public_id}", ['currency' => 'USD'])->assertUnprocessable();
        $this->putJson("/api/v1/subscriptions/{$subscription->public_id}/items", ['items' => []])->assertUnprocessable();

        $paymentPayload = $this->paymentPayload($customer, (string) Str::uuid());
        $this->postJson('/api/v1/payments', $paymentPayload + ['confirmation_status' => 'confirmed'])->assertUnprocessable();
        $paymentId = $this->postJson('/api/v1/payments', $paymentPayload)
            ->assertCreated()->assertJsonPath('data.confirmation_status', 'pending')->json('data.id');
        $this->postJson('/api/v1/payments', $paymentPayload)->assertUnprocessable()->assertJsonValidationErrors('idempotency_key');
        $allocation = ['charge_id' => $chargeId, 'amount_cents' => 1000];
        $this->postJson("/api/v1/payments/$paymentId/allocations", $allocation)->assertUnprocessable();
        $this->postJson("/api/v1/payments/$paymentId/confirm")->assertOk()->assertJsonPath('data.confirmation_status', 'confirmed');
        $this->postJson("/api/v1/payments/$paymentId/confirm")->assertUnprocessable();
        $this->postJson("/api/v1/payments/$paymentId/allocations", $allocation)->assertUnprocessable();
        $this->postJson("/api/v1/charges/$chargeId/issue")->assertOk()->assertJsonPath('data.status', 'issued');
        $this->postJson("/api/v1/charges/$chargeId/issue")->assertUnprocessable();
        $this->postJson("/api/v1/payments/$paymentId/allocations", $allocation)->assertCreated()
            ->assertJsonPath('data.allocations.0.charge_id', $chargeId);
        $this->postJson("/api/v1/payments/$paymentId/allocations", $allocation)->assertUnprocessable();
        $this->getJson("/api/v1/charges/$chargeId")->assertOk()
            ->assertJsonPath('data.allocated_cents', 1000)
            ->assertJsonPath('data.status', 'paid');
        $this->assertDatabaseHas('subscriptions', ['public_id' => $subscription->public_id, 'status' => 'draft']);
    }

    public function test_voided_unpaid_charges_preserve_audit_and_allow_correcting_dates(): void
    {
        $this->owner();
        [, $instance] = $this->directory();
        $subscription = $this->subscription($instance);
        $first = $this->issuedCharge($subscription);
        $second = $this->issuedCharge($subscription);
        $reason = 'Fecha incorrecta y cargo duplicado';

        $this->postJson("/api/v1/charges/$first/void", ['reason' => $reason])
            ->assertOk()->assertJsonPath('data.status', 'void');
        $this->putJson("/api/v1/subscriptions/{$subscription->public_id}/items", [
            'starts_on' => '2026-11-12', 'items' => [],
        ])->assertUnprocessable();
        $this->postJson("/api/v1/charges/$second/void", ['reason' => $reason])->assertOk();
        $this->postJson("/api/v1/charges/$second/void", ['reason' => $reason])->assertUnprocessable();
        $this->putJson("/api/v1/subscriptions/{$subscription->public_id}/items", [
            'starts_on' => '2026-11-12',
            'items' => [[
                'concept' => 'Plan', 'amount_cents' => 60000,
                'billing_frequency' => 'monthly', 'effective_from' => '2026-11-12',
            ]],
        ])->assertOk()->assertJsonPath('data.starts_on', '2026-11-12')
            ->assertJsonPath('data.items.0.effective_from', '2026-11-12');
        $this->assertDatabaseHas('audit_events', [
            'action' => 'charge.void', 'resource_id' => $first,
        ]);
        $this->assertDatabaseCount('charges', 2);

        $payload = ['expected_due_date' => '2026-11-12', 'expected_amount_cents' => 60000];
        $this->postJson("/api/v1/subscriptions/{$subscription->public_id}/initial-charge", [
            'expected_due_date' => '2026-11-04', 'expected_amount_cents' => 60000,
        ])->assertUnprocessable();
        $this->postJson("/api/v1/subscriptions/{$subscription->public_id}/initial-charge", $payload)
            ->assertCreated()->assertJsonPath('data.amount_cents', 60000)
            ->assertJsonPath('data.due_date', '2026-11-12')->assertJsonPath('data.status', 'issued');
        $this->postJson("/api/v1/subscriptions/{$subscription->public_id}/initial-charge", $payload)
            ->assertUnprocessable();
        $this->assertDatabaseCount('charges', 3);
    }

    public function test_allocated_charge_cannot_be_voided(): void
    {
        $this->owner();
        [$customer, $instance] = $this->directory();
        $chargeId = $this->issuedCharge($this->subscription($instance));
        $paymentId = $this->confirmedPayment($customer);
        $this->postJson("/api/v1/payments/$paymentId/allocations", [
            'charge_id' => $chargeId, 'amount_cents' => 500,
        ])->assertCreated();
        $this->postJson("/api/v1/charges/$chargeId/void", ['reason' => 'Cargo incorrecto'])
            ->assertUnprocessable();
        $this->getJson("/api/v1/charges/$chargeId")->assertOk()
            ->assertJsonPath('data.status', 'issued')->assertJsonPath('data.allocated_cents', 500);
    }

    public function test_subscription_activation_requires_paid_issued_charge_and_cancellation_is_immediate(): void
    {
        $this->owner();
        [$customer, $instance] = $this->directory();
        $subscriptionId = $this->postJson('/api/v1/subscriptions', [
            'instance_id' => $instance->public_id,
            'currency' => 'HNL',
            'starts_on' => now()->toDateString(),
        ])->assertCreated()->json('data.id');

        $this->postJson("/api/v1/subscriptions/$subscriptionId/activate")
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');

        $chargeId = $this->postJson('/api/v1/charges', [
            'subscription_id' => $subscriptionId,
            'concept' => 'Initial service',
            'due_date' => now()->toDateString(),
            'amount_cents' => 1000,
            'currency' => 'HNL',
        ])->assertCreated()->json('data.id');
        $this->postJson("/api/v1/charges/$chargeId/issue")->assertOk();

        $firstPayment = $this->paymentPayload($customer, (string) Str::uuid());
        $firstPayment['amount_cents'] = 500;
        $firstPaymentId = $this->postJson('/api/v1/payments', $firstPayment)->assertCreated()->json('data.id');
        $this->postJson("/api/v1/payments/$firstPaymentId/confirm")->assertOk();
        $this->postJson("/api/v1/payments/$firstPaymentId/allocations", [
            'charge_id' => $chargeId,
            'amount_cents' => 500,
        ])->assertCreated();
        $this->postJson("/api/v1/subscriptions/$subscriptionId/activate")
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');

        $secondPayment = $this->paymentPayload($customer, (string) Str::uuid());
        $secondPayment['amount_cents'] = 500;
        $secondPaymentId = $this->postJson('/api/v1/payments', $secondPayment)->assertCreated()->json('data.id');
        $this->postJson("/api/v1/payments/$secondPaymentId/confirm")->assertOk();
        $this->postJson("/api/v1/payments/$secondPaymentId/allocations", [
            'charge_id' => $chargeId,
            'amount_cents' => 500,
        ])->assertCreated();
        $this->getJson("/api/v1/charges/$chargeId")->assertOk()->assertJsonPath('data.status', 'paid');

        $activated = $this->postJson("/api/v1/subscriptions/$subscriptionId/activate")
            ->assertOk()
            ->assertJsonPath('data.status', 'active');
        $this->assertIsString($activated->json('data.activated_at'));
        $cancelled = $this->postJson("/api/v1/subscriptions/$subscriptionId/cancel")
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled');
        $this->assertIsString($cancelled->json('data.cancelled_at'));
        $this->postJson("/api/v1/subscriptions/$subscriptionId/cancel")->assertUnprocessable();
    }

    public function test_contract_end_expires_subscription_and_writes_system_audit_event(): void
    {
        [, $instance] = $this->directory();
        $subscription = Subscription::query()->create([
            'public_id' => (string) Str::uuid(),
            'instance_id' => $instance->id,
            'currency' => 'HNL',
            'status' => 'active',
            'starts_on' => now()->subDays(10)->toDateString(),
            'ends_on' => now()->subDay()->toDateString(),
            'activated_at' => now()->subDays(10),
        ]);

        $this->artisan('billing:subscriptions:expire')->assertSuccessful();

        $this->assertSame('expired', $subscription->fresh()->status);
        $this->assertDatabaseHas('audit_events', [
            'actor_id' => null,
            'actor_type' => 'system',
            'action' => 'subscription.expire',
            'resource_id' => $subscription->public_id,
        ]);
    }

    public function test_allocation_rejects_mismatched_customer_currency_and_overallocation_on_both_sides(): void
    {
        $this->owner();
        [$customer, $instance] = $this->directory();
        [$otherCustomer, $otherInstance] = $this->directory();
        $subscription = $this->subscription($instance);
        $otherSubscription = $this->subscription($otherInstance);
        $badCharge = $this->chargePayload($subscription, (string) Str::uuid());
        $badCharge['currency'] = 'USD';
        $this->postJson('/api/v1/charges', $badCharge)->assertUnprocessable()->assertJsonValidationErrors('currency');
        $chargeId = $this->issuedCharge($subscription);
        $otherChargeId = $this->issuedCharge($otherSubscription);
        $paymentId = $this->confirmedPayment($customer);
        $otherPaymentId = $this->confirmedPayment($otherCustomer);
        $usd = $this->paymentPayload($customer, (string) Str::uuid());
        $usd['currency'] = 'USD';
        $usdId = $this->postJson('/api/v1/payments', $usd)->assertCreated()->json('data.id');
        $this->postJson("/api/v1/payments/$usdId/confirm")->assertOk();
        $this->postJson("/api/v1/payments/$usdId/allocations", ['charge_id' => $chargeId, 'amount_cents' => 1])->assertUnprocessable();
        $this->postJson("/api/v1/payments/$otherPaymentId/allocations", ['charge_id' => $chargeId, 'amount_cents' => 1])->assertUnprocessable();
        $this->postJson("/api/v1/payments/$paymentId/allocations", ['charge_id' => $otherChargeId, 'amount_cents' => 1])->assertUnprocessable();
        $this->postJson("/api/v1/payments/$paymentId/allocations", ['charge_id' => $chargeId, 'amount_cents' => 1001])->assertUnprocessable();
        $this->postJson("/api/v1/payments/$paymentId/allocations", ['charge_id' => $chargeId, 'amount_cents' => 800])->assertCreated();
        $secondChargeId = $this->issuedCharge($subscription);
        $this->postJson("/api/v1/payments/$paymentId/allocations", ['charge_id' => $secondChargeId, 'amount_cents' => 201])->assertUnprocessable();
        $secondPaymentId = $this->confirmedPayment($customer);
        $this->postJson("/api/v1/payments/$secondPaymentId/allocations", ['charge_id' => $chargeId, 'amount_cents' => 201])->assertUnprocessable();
        $this->assertDatabaseCount('payment_allocations', 1);
    }

    public function test_routes_require_active_authenticated_user_and_billing_permissions(): void
    {
        $this->getJson('/api/v1/subscriptions')->assertUnauthorized();
        [$customer] = $this->directory();
        $payment = Payment::query()->create([
            'public_id' => (string) Str::uuid(), 'customer_id' => $customer->id, 'amount_cents' => 100,
            'currency' => 'HNL', 'payment_method' => 'manual', 'confirmation_status' => 'pending',
        ]);
        $user = User::factory()->create(['is_active' => true]);
        $this->actingAs($user, 'sanctum');
        $this->getJson('/api/v1/subscriptions')->assertForbidden();
        $this->postJson('/api/v1/payments', [])->assertForbidden();
        $role = Role::query()->create(['code' => 'billing-reader', 'name' => 'Billing', 'is_active' => true]);
        $permission = Permission::query()->create(['code' => 'subscriptions.manage']);
        $role->permissions()->attach($permission);
        $user->roles()->attach($role);
        $this->getJson('/api/v1/subscriptions')->assertOk();
        $this->getJson('/api/v1/payments')->assertForbidden();
        $this->postJson("/api/v1/payments/{$payment->public_id}/confirm")->assertForbidden();
        $paymentPermission = Permission::query()->create(['code' => 'payments.manage']);
        $role->permissions()->attach($paymentPermission);
        $this->getJson('/api/v1/payments')->assertOk();
        $this->postJson("/api/v1/payments/{$payment->public_id}/confirm")->assertForbidden();
        $this->assertDatabaseHas('payments', ['id' => $payment->id, 'confirmation_status' => 'pending']);
        $user->update(['is_active' => false]);
        $this->getJson('/api/v1/subscriptions')->assertForbidden();
    }

    public function test_non_draft_subscriptions_cannot_be_edited_and_closed_subscriptions_cannot_be_charged(): void
    {
        $this->owner();
        [, $instance] = $this->directory();
        $subscription = $this->subscription($instance);
        $subscription->update(['status' => 'active']);
        $this->patchJson("/api/v1/subscriptions/{$subscription->public_id}", ['grace_days' => 4])->assertUnprocessable();
        $this->putJson("/api/v1/subscriptions/{$subscription->public_id}/items", ['items' => []])->assertUnprocessable();
        $subscription->update(['status' => 'cancelled']);
        $this->postJson('/api/v1/charges', $this->chargePayload($subscription, (string) Str::uuid()))->assertUnprocessable();
        $this->assertDatabaseCount('charges', 0);
    }

    private function owner(): void
    {
        $user = User::factory()->create(['is_active' => true]);
        $role = Role::query()->create(['code' => 'owner', 'name' => 'Owner', 'is_active' => true]);
        $user->roles()->attach($role);
        $this->actingAs($user, 'sanctum');
    }

    private function directory(): array
    {
        $customer = Customer::query()->create(['public_id' => (string) Str::uuid(), 'legal_name' => 'Customer', 'status' => 'active']);
        $product = SoftwareProduct::query()->create(['public_id' => (string) Str::uuid(), 'code' => (string) Str::uuid(), 'name' => 'Product']);
        $instance = SoftwareInstance::query()->create([
            'public_id' => (string) Str::uuid(), 'customer_id' => $customer->id, 'product_id' => $product->id,
            'name' => 'Instance', 'administrative_status' => 'pending',
        ]);

        return [$customer, $instance];
    }

    private function subscription(SoftwareInstance $instance): Subscription
    {
        return Subscription::query()->create([
            'public_id' => (string) Str::uuid(), 'instance_id' => $instance->id, 'currency' => 'HNL', 'status' => 'draft',
        ]);
    }

    private function chargePayload(Subscription $subscription, string $key): array
    {
        return [
            'subscription_id' => $subscription->public_id, 'concept' => 'Service', 'due_date' => '2026-12-01',
            'amount_cents' => 1000, 'currency' => 'HNL', 'idempotency_key' => $key,
        ];
    }

    private function paymentPayload(Customer $customer, string $key): array
    {
        return [
            'customer_id' => $customer->public_id, 'amount_cents' => 1000, 'currency' => 'HNL',
            'payment_method' => 'manual', 'idempotency_key' => $key,
        ];
    }

    private function issuedCharge(Subscription $subscription): string
    {
        $id = $this->postJson('/api/v1/charges', $this->chargePayload($subscription, (string) Str::uuid()))->assertCreated()->json('data.id');
        $this->postJson("/api/v1/charges/$id/issue")->assertOk();

        return $id;
    }

    private function confirmedPayment(Customer $customer): string
    {
        $id = $this->postJson('/api/v1/payments', $this->paymentPayload($customer, (string) Str::uuid()))->assertCreated()->json('data.id');
        $this->postJson("/api/v1/payments/$id/confirm")->assertOk();

        return $id;
    }
}
