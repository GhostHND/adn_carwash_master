<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AuditEvent;
use App\Models\Charge;
use App\Models\Customer;
use App\Models\Payment;
use App\Models\SoftwareInstance;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class BillingController extends Controller
{
    private const AMOUNT_MAX = 1000000000000;

    public function subscriptions(Request $request)
    {
        $data = $request->validate(['per_page' => ['integer', 'min:1', 'max:100']]);

        return Subscription::query()->orderByDesc('id')->paginate($data['per_page'] ?? 25)
            ->through(fn ($subscription) => $this->subscriptionData($subscription));
    }

    public function storeSubscription(Request $request)
    {
        $data = $request->validate([
            'instance_id' => ['required', 'uuid', 'exists:software_instances,public_id'],
            'currency' => ['required', 'string', 'regex:/\A[A-Z]{3}\z/'],
            'starts_on' => ['nullable', 'date_format:Y-m-d'],
            'ends_on' => ['nullable', 'date_format:Y-m-d'],
            'grace_days' => ['sometimes', 'integer', 'min:0', 'max:65535'],
            'status' => ['prohibited'],
        ]);
        if (($data['starts_on'] ?? null) && ($data['ends_on'] ?? null) && $data['ends_on'] < $data['starts_on']) {
            throw ValidationException::withMessages(['ends_on' => 'The end date must not precede the start date.']);
        }
        $instance = SoftwareInstance::query()->where('public_id', $data['instance_id'])->firstOrFail();
        $subscription = DB::transaction(fn () => Subscription::query()->create([
            'public_id' => (string) Str::uuid(),
            'instance_id' => $instance->id,
            'currency' => $data['currency'],
            'starts_on' => $data['starts_on'] ?? null,
            'ends_on' => $data['ends_on'] ?? null,
            'grace_days' => $data['grace_days'] ?? 0,
            'status' => 'draft',
        ]));

        return response()->json(['data' => $this->subscriptionData($subscription)], 201);
    }

    public function showSubscription(Subscription $subscription)
    {
        return response()->json(['data' => $this->subscriptionData($subscription)]);
    }

    public function updateSubscription(Request $request, Subscription $subscription)
    {
        $data = $request->validate([
            'currency' => ['sometimes', 'string', 'regex:/\A[A-Z]{3}\z/'],
            'starts_on' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'ends_on' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'grace_days' => ['sometimes', 'integer', 'min:0', 'max:65535'],
            'status' => ['prohibited'],
            'instance_id' => ['prohibited'],
        ]);
        $subscription = DB::transaction(function () use ($subscription, $data) {
            $subscription = Subscription::query()->lockForUpdate()->findOrFail($subscription->id);
            $this->requireState($subscription->status === 'draft', 'Only draft subscriptions can be changed.');
            $this->requireState(
                ! $subscription->charges()->where('status', '!=', 'void')->exists(),
                'Subscription details cannot be changed after a charge has been created.',
            );
            $start = array_key_exists('starts_on', $data) ? $data['starts_on'] : $subscription->starts_on?->format('Y-m-d');
            $end = array_key_exists('ends_on', $data) ? $data['ends_on'] : $subscription->ends_on?->format('Y-m-d');
            if ($start && $end && $end < $start) {
                throw ValidationException::withMessages(['ends_on' => 'The end date must not precede the start date.']);
            }
            if (isset($data['currency']) && $data['currency'] !== $subscription->currency && $subscription->charges()->where('status', '!=', 'void')->exists()) {
                throw ValidationException::withMessages(['currency' => 'Currency cannot be changed after a charge is created.']);
            }
            $subscription->fill($data)->save();

            return $subscription;
        });

        return response()->json(['data' => $this->subscriptionData($subscription)]);
    }

    public function activateSubscription(Request $request, Subscription $subscription)
    {
        $this->authorizeBillingOwner($request);

        $subscription = DB::transaction(function () use ($subscription): Subscription {
            $subscription = Subscription::query()->lockForUpdate()->findOrFail($subscription->id);
            $this->requireState($subscription->status === 'draft', 'Only draft subscriptions can be activated.');
            $today = now()->toDateString();
            $this->requireState(
                $subscription->starts_on !== null && $subscription->starts_on->format('Y-m-d') <= $today,
                'A subscription can only be activated on or after its start date.',
            );
            $this->requireState(
                $subscription->ends_on === null || $subscription->ends_on->format('Y-m-d') >= $today,
                'An expired subscription cannot be activated.',
            );

            SoftwareInstance::query()->lockForUpdate()->findOrFail($subscription->instance_id);
            $anotherActiveSubscription = Subscription::query()
                ->where('instance_id', $subscription->instance_id)
                ->where('status', 'active')
                ->where('id', '!=', $subscription->id)
                ->exists();
            $this->requireState(! $anotherActiveSubscription, 'The instance already has an active subscription.');

            $hasPaidIssuedCharge = $subscription->charges()
                ->whereIn('status', ['issued', 'paid'])
                ->get()
                ->contains(function (Charge $charge): bool {
                    $confirmedAllocations = $charge->allocations()
                        ->whereHas('payment', fn ($query) => $query->where('confirmation_status', 'confirmed'))
                        ->sum('amount_cents');

                    return (int) $confirmedAllocations >= $charge->amount_cents;
                });
            $this->requireState(
                $hasPaidIssuedCharge,
                'At least one issued charge must be fully covered by confirmed payments before activation.',
            );

            $subscription->update([
                'status' => 'active',
                'activated_at' => now(),
            ]);

            return $subscription;
        });

        return response()->json(['data' => $this->subscriptionData($subscription)]);
    }

    public function cancelSubscription(Request $request, Subscription $subscription)
    {
        $this->authorizeBillingOwner($request);

        $subscription = DB::transaction(function () use ($subscription): Subscription {
            $subscription = Subscription::query()->lockForUpdate()->findOrFail($subscription->id);
            $this->requireState(
                in_array($subscription->status, ['draft', 'active'], true),
                'Only draft or active subscriptions can be cancelled.',
            );
            $subscription->update([
                'status' => 'cancelled',
                'cancelled_at' => now(),
            ]);

            return $subscription;
        });

        return response()->json(['data' => $this->subscriptionData($subscription)]);
    }

    public function replaceItems(Request $request, Subscription $subscription)
    {
        $data = $request->validate([
            'starts_on' => ['sometimes', 'required', 'date_format:Y-m-d'],
            'items' => ['present', 'array', 'max:100'],
            'items.*' => ['array:concept,amount_cents,billing_frequency,effective_from,effective_until'],
            'items.*.concept' => ['required', 'string', 'max:255'],
            'items.*.amount_cents' => ['required', 'integer', 'min:0', 'max:'.self::AMOUNT_MAX],
            'items.*.billing_frequency' => ['required', 'in:monthly,quarterly,yearly,one_time'],
            'items.*.effective_from' => ['required', 'date_format:Y-m-d'],
            'items.*.effective_until' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:items.*.effective_from'],
        ]);
        $subscription = DB::transaction(function () use ($subscription, $data) {
            $subscription = Subscription::query()->lockForUpdate()->findOrFail($subscription->id);
            $this->requireState($subscription->status === 'draft', 'Only draft subscriptions can be changed.');
            $this->requireState(
                ! $subscription->charges()->where('status', '!=', 'void')->exists(),
                'Subscription items cannot be changed after a charge has been created.',
            );
            if (isset($data['starts_on'])) {
                if ($subscription->ends_on && $data['starts_on'] > $subscription->ends_on->format('Y-m-d')) {
                    throw ValidationException::withMessages(['starts_on' => 'The start date must not follow the end date.']);
                }
                $subscription->update(['starts_on' => $data['starts_on']]);
            }
            $subscription->items()->delete();
            $subscription->items()->createMany($data['items']);

            return $subscription;
        });

        return response()->json(['data' => $this->subscriptionData($subscription)]);
    }

    public function createInitialCharge(Request $request, Subscription $subscription)
    {
        $data = $request->validate([
            'expected_due_date' => ['required', 'date_format:Y-m-d'],
            'expected_amount_cents' => ['required', 'integer', 'min:1', 'max:'.self::AMOUNT_MAX],
        ]);
        $charge = DB::transaction(function () use ($subscription, $data): Charge {
            $subscription = Subscription::query()->lockForUpdate()->findOrFail($subscription->id);
            $this->requireState($subscription->status === 'draft', 'Only draft subscriptions can receive an initial charge.');
            $this->requireState(! $subscription->charges()->where('status', '!=', 'void')->exists(), 'An initial charge already exists.');
            $items = $subscription->items()->orderBy('effective_from')->get();
            $this->requireState($items->isNotEmpty(), 'The subscription has no items.');
            $dueDate = $items->first()->effective_from->format('Y-m-d');
            $amount = $items->filter(fn ($item) => $item->effective_from->format('Y-m-d') === $dueDate)->sum('amount_cents');
            $this->requireState($amount > 0 && $amount <= self::AMOUNT_MAX, 'The initial charge amount is invalid.');
            $this->requireState($dueDate === $data['expected_due_date'] && $amount === (int) $data['expected_amount_cents'], 'The subscription changed; review the amount and date again.');

            return $subscription->charges()->create([
                'public_id' => (string) Str::uuid(),
                'concept' => 'Cargo inicial de suscripción',
                'due_date' => $dueDate,
                'amount_cents' => $amount,
                'currency' => $subscription->currency,
                'status' => 'issued',
                'issued_at' => now(),
                'idempotency_key' => (string) Str::uuid(),
            ]);
        });

        return response()->json(['data' => $this->chargeData($charge)], 201);
    }

    public function charges(Request $request)
    {
        $data = $request->validate(['per_page' => ['integer', 'min:1', 'max:100']]);

        return Charge::query()->orderByDesc('id')->paginate($data['per_page'] ?? 25)
            ->through(fn ($charge) => $this->chargeData($charge));
    }

    public function storeCharge(Request $request)
    {
        $data = $request->validate([
            'subscription_id' => ['required', 'uuid', 'exists:subscriptions,public_id'],
            'concept' => ['required', 'string', 'max:255'],
            'due_date' => ['required', 'date_format:Y-m-d'],
            'amount_cents' => ['required', 'integer', 'min:1', 'max:'.self::AMOUNT_MAX],
            'currency' => ['required', 'string', 'regex:/\A[A-Z]{3}\z/'],
            'idempotency_key' => ['nullable', 'uuid', 'unique:charges,idempotency_key'],
            'status' => ['prohibited'],
            'issued_at' => ['prohibited'],
        ]);
        $charge = $this->uniqueKeyTransaction('charges', $data['idempotency_key'] ?? null, function () use ($data) {
            $subscription = Subscription::query()->where('public_id', $data['subscription_id'])->lockForUpdate()->firstOrFail();
            $this->requireState(in_array($subscription->status, ['draft', 'active'], true), 'Cannot create charges for this subscription.');
            if ($data['currency'] !== $subscription->currency) {
                throw ValidationException::withMessages(['currency' => 'Currency must match the subscription.']);
            }

            return Charge::query()->create([
                'public_id' => (string) Str::uuid(),
                'subscription_id' => $subscription->id,
                'concept' => $data['concept'],
                'due_date' => $data['due_date'],
                'amount_cents' => $data['amount_cents'],
                'currency' => $data['currency'],
                'idempotency_key' => $data['idempotency_key'] ?? null,
                'status' => 'draft',
            ]);
        });

        return response()->json(['data' => $this->chargeData($charge)], 201);
    }

    public function showCharge(Charge $charge)
    {
        return response()->json(['data' => $this->chargeData($charge)]);
    }

    public function issueCharge(Charge $charge)
    {
        $charge = DB::transaction(function () use ($charge) {
            $charge = Charge::query()->lockForUpdate()->findOrFail($charge->id);
            $this->requireState($charge->status === 'draft', 'Only draft charges can be issued.');
            $charge->update(['status' => 'issued', 'issued_at' => now()]);

            return $charge;
        });

        return response()->json(['data' => $this->chargeData($charge)]);
    }

    public function voidCharge(Request $request, Charge $charge)
    {
        $this->authorizeBillingOwner($request);
        $data = $request->validate(['reason' => ['required', 'string', 'min:5', 'max:500']]);
        $charge = DB::transaction(function () use ($charge, $request, $data): Charge {
            Subscription::query()->lockForUpdate()->findOrFail($charge->subscription_id);
            $charge = Charge::query()->lockForUpdate()->findOrFail($charge->id);
            $this->requireState(in_array($charge->status, ['draft', 'issued'], true) && $charge->paid_at === null, 'Only unpaid charges can be voided.');
            $this->requireState(! $charge->allocations()->exists(), 'A charge with payment allocations cannot be voided.');
            $charge->update(['status' => 'void']);
            AuditEvent::query()->create([
                'actor_id' => $request->user()->id,
                'actor_type' => 'user',
                'action' => 'charge.void',
                'resource_type' => 'charge',
                'resource_id' => $charge->public_id,
                'occurred_at' => now(),
                'outcome' => 'success',
                'request_reference' => (string) Str::uuid(),
                'metadata' => ['reason' => $data['reason']],
            ]);

            return $charge;
        });

        return response()->json(['data' => $this->chargeData($charge)]);
    }

    public function payments(Request $request)
    {
        $data = $request->validate(['per_page' => ['integer', 'min:1', 'max:100']]);

        return Payment::query()->orderByDesc('id')->paginate($data['per_page'] ?? 25)
            ->through(fn ($payment) => $this->paymentData($payment));
    }

    public function storePayment(Request $request)
    {
        $data = $request->validate([
            'customer_id' => ['required', 'uuid', 'exists:customers,public_id'],
            'amount_cents' => ['required', 'integer', 'min:1', 'max:'.self::AMOUNT_MAX],
            'currency' => ['required', 'string', 'regex:/\A[A-Z]{3}\z/'],
            'payment_method' => ['required', 'string', 'max:40'],
            'external_reference' => ['nullable', 'string', 'max:255'],
            'idempotency_key' => ['nullable', 'uuid', 'unique:payments,idempotency_key'],
            'confirmation_status' => ['prohibited'],
            'confirmed_at' => ['prohibited'],
            'created_by' => ['prohibited'],
        ]);
        $customer = Customer::query()->where('public_id', $data['customer_id'])->firstOrFail();
        $payment = $this->uniqueKeyTransaction('payments', $data['idempotency_key'] ?? null, fn () => Payment::query()->create([
            'public_id' => (string) Str::uuid(),
            'customer_id' => $customer->id,
            'amount_cents' => $data['amount_cents'],
            'currency' => $data['currency'],
            'payment_method' => $data['payment_method'],
            'external_reference' => $data['external_reference'] ?? null,
            'idempotency_key' => $data['idempotency_key'] ?? null,
            'confirmation_status' => 'pending',
            'created_by' => $request->user()->id,
        ]));

        return response()->json(['data' => $this->paymentData($payment)], 201);
    }

    public function showPayment(Payment $payment)
    {
        return response()->json(['data' => $this->paymentData($payment)]);
    }

    public function confirmPayment(Request $request, Payment $payment)
    {
        $this->authorizeBillingOwner($request);

        $payment = DB::transaction(function () use ($payment) {
            $payment = Payment::query()->lockForUpdate()->findOrFail($payment->id);
            $this->requireState($payment->confirmation_status === 'pending', 'Only pending payments can be confirmed.');
            $payment->update(['confirmation_status' => 'confirmed', 'confirmed_at' => now()]);

            return $payment;
        });

        return response()->json(['data' => $this->paymentData($payment)]);
    }

    public function allocatePayment(Request $request, Payment $payment)
    {
        $data = $request->validate([
            'charge_id' => ['required', 'uuid', 'exists:charges,public_id'],
            'amount_cents' => ['required', 'integer', 'min:1', 'max:'.self::AMOUNT_MAX],
        ]);
        $payment = DB::transaction(function () use ($payment, $data) {
            $payment = Payment::query()->lockForUpdate()->findOrFail($payment->id);
            $charge = Charge::query()->where('public_id', $data['charge_id'])->lockForUpdate()->firstOrFail();
            $this->requireState($payment->confirmation_status === 'confirmed', 'Only confirmed payments can be allocated.');
            $this->requireState($charge->status === 'issued', 'Only issued charges can receive allocations.');
            $subscription = $charge->subscription;
            $customerId = SoftwareInstance::withTrashed()->whereKey($subscription->instance_id)->value('customer_id');
            if ($customerId === null || (int) $payment->customer_id !== (int) $customerId) {
                throw ValidationException::withMessages(['charge_id' => 'Payment and charge must belong to the same customer.']);
            }
            if ($payment->currency !== $charge->currency || $charge->currency !== $subscription->currency) {
                throw ValidationException::withMessages(['charge_id' => 'Payment, charge and subscription currencies must match.']);
            }
            if ($payment->allocations()->where('charge_id', $charge->id)->exists()) {
                throw ValidationException::withMessages(['charge_id' => 'This payment is already allocated to that charge.']);
            }
            $paymentAllocated = (int) $payment->allocations()->sum('amount_cents');
            $chargeAllocated = (int) $charge->allocations()->sum('amount_cents');
            if ($data['amount_cents'] > $payment->amount_cents - $paymentAllocated || $data['amount_cents'] > $charge->amount_cents - $chargeAllocated) {
                throw ValidationException::withMessages(['amount_cents' => 'Allocation exceeds the remaining payment or charge balance.']);
            }
            $payment->allocations()->create(['charge_id' => $charge->id, 'amount_cents' => $data['amount_cents']]);
            if ($chargeAllocated + $data['amount_cents'] === $charge->amount_cents) {
                $charge->update(['status' => 'paid', 'paid_at' => now()]);
            }

            return $payment;
        });

        return response()->json(['data' => $this->paymentData($payment)], 201);
    }

    private function subscriptionData(Subscription $subscription): array
    {
        return [
            'id' => $subscription->public_id,
            'instance_id' => SoftwareInstance::withTrashed()->whereKey($subscription->instance_id)->value('public_id'),
            'status' => $subscription->status,
            'currency' => $subscription->currency,
            'starts_on' => $subscription->starts_on?->format('Y-m-d'),
            'ends_on' => $subscription->ends_on?->format('Y-m-d'),
            'activated_at' => $subscription->activated_at,
            'cancelled_at' => $subscription->cancelled_at,
            'grace_days' => $subscription->grace_days,
            'items' => $subscription->items()->orderBy('id')->get()->map(fn ($item) => [
                'concept' => $item->concept,
                'amount_cents' => $item->amount_cents,
                'billing_frequency' => $item->billing_frequency,
                'effective_from' => $item->effective_from->format('Y-m-d'),
                'effective_until' => $item->effective_until?->format('Y-m-d'),
            ]),
        ];
    }

    private function chargeData(Charge $charge): array
    {
        return [
            'id' => $charge->public_id,
            'subscription_id' => $charge->subscription->public_id,
            'concept' => $charge->concept,
            'due_date' => $charge->due_date->format('Y-m-d'),
            'amount_cents' => $charge->amount_cents,
            'currency' => $charge->currency,
            'status' => $charge->status,
            'issued_at' => $charge->issued_at,
            'paid_at' => $charge->paid_at,
            'idempotency_key' => $charge->idempotency_key,
            'allocated_cents' => (int) $charge->allocations()->sum('amount_cents'),
        ];
    }

    private function paymentData(Payment $payment): array
    {
        return [
            'id' => $payment->public_id,
            'customer_id' => Customer::withTrashed()->whereKey($payment->customer_id)->value('public_id'),
            'amount_cents' => $payment->amount_cents,
            'currency' => $payment->currency,
            'payment_method' => $payment->payment_method,
            'external_reference' => $payment->external_reference,
            'idempotency_key' => $payment->idempotency_key,
            'confirmation_status' => $payment->confirmation_status,
            'confirmed_at' => $payment->confirmed_at,
            'allocations' => $payment->allocations()->with('charge')->orderBy('id')->get()->map(fn ($allocation) => [
                'charge_id' => $allocation->charge->public_id,
                'amount_cents' => $allocation->amount_cents,
            ]),
        ];
    }

    private function requireState(bool $condition, string $message): void
    {
        if (! $condition) {
            throw ValidationException::withMessages(['status' => $message]);
        }
    }

    private function authorizeBillingOwner(Request $request): void
    {
        $user = $request->user();
        abort_unless(
            $user instanceof User && $user->is_active
                && $user->roles()->where('code', 'owner')->where('is_active', true)->exists(),
            403,
        );
    }

    private function uniqueKeyTransaction(string $table, ?string $key, callable $callback)
    {
        try {
            return DB::transaction($callback);
        } catch (QueryException $exception) {
            if ($key !== null && DB::table($table)->where('idempotency_key', $key)->exists()) {
                throw ValidationException::withMessages(['idempotency_key' => 'This idempotency key has already been used.']);
            }
            throw $exception;
        }
    }
}
