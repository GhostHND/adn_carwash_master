<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'public_id',
    'subscription_id',
    'concept',
    'due_date',
    'amount_cents',
    'currency',
    'status',
    'issued_at',
    'paid_at',
    'idempotency_key',
])]
class Charge extends Model
{
    protected function casts(): array
    {
        return [
            'due_date' => 'date',
            'amount_cents' => 'integer',
            'issued_at' => 'datetime',
            'paid_at' => 'datetime',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'public_id';
    }

    public function subscription(): BelongsTo
    {
        return $this->belongsTo(Subscription::class, 'subscription_id');
    }

    public function allocations(): HasMany
    {
        return $this->hasMany(PaymentAllocation::class, 'charge_id');
    }
}
