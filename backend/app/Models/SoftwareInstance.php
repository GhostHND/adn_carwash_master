<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'public_id',
    'customer_id',
    'product_id',
    'plan_id',
    'name',
    'domain',
    'environment',
    'provisioning_status',
    'administrative_status',
    'created_by',
])]
class SoftwareInstance extends Model
{
    use SoftDeletes;

    public function getRouteKeyName(): string
    {
        return 'public_id';
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(SoftwareProduct::class, 'product_id');
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(ProductPlan::class, 'plan_id');
    }

    public function infrastructure(): HasOne
    {
        return $this->hasOne(InstanceInfrastructure::class, 'instance_id');
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class, 'instance_id');
    }

    public function license(): HasOne
    {
        return $this->hasOne(LicenseRecord::class, 'instance_id');
    }
}
