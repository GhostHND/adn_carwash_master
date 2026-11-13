<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'public_id',
    'instance_id',
    'status',
    'starts_on',
    'ends_on',
    'activated_at',
    'cancelled_at',
    'grace_days',
    'currency',
])]
class Subscription extends Model
{
    protected function casts(): array
    {
        return [
            'starts_on' => 'date',
            'ends_on' => 'date',
            'activated_at' => 'datetime',
            'cancelled_at' => 'datetime',
            'grace_days' => 'integer',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'public_id';
    }

    public function instance(): BelongsTo
    {
        return $this->belongsTo(SoftwareInstance::class, 'instance_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(SubscriptionItem::class, 'subscription_id');
    }

    public function charges(): HasMany
    {
        return $this->hasMany(Charge::class, 'subscription_id');
    }
}
