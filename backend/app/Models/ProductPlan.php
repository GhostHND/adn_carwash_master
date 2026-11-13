<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'public_id',
    'product_id',
    'code',
    'name',
    'price_cents',
    'currency',
    'billing_period',
    'status',
    'available_from',
    'available_until',
])]
class ProductPlan extends Model
{
    use SoftDeletes;

    protected function casts(): array
    {
        return [
            'price_cents' => 'integer',
            'available_from' => 'datetime',
            'available_until' => 'datetime',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'public_id';
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(SoftwareProduct::class, 'product_id');
    }

    public function features(): HasMany
    {
        return $this->hasMany(PlanFeature::class, 'plan_id');
    }

    public function instances(): HasMany
    {
        return $this->hasMany(SoftwareInstance::class, 'plan_id');
    }
}
