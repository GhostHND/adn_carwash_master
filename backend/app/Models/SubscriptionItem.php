<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'subscription_id',
    'concept',
    'amount_cents',
    'billing_frequency',
    'effective_from',
    'effective_until',
])]
class SubscriptionItem extends Model
{
    protected function casts(): array
    {
        return [
            'amount_cents' => 'integer',
            'effective_from' => 'date',
            'effective_until' => 'date',
        ];
    }

    public function subscription(): BelongsTo
    {
        return $this->belongsTo(Subscription::class, 'subscription_id');
    }
}
