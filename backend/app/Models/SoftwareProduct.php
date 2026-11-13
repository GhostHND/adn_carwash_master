<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['public_id', 'code', 'name', 'category', 'description', 'status', 'created_by'])]
class SoftwareProduct extends Model
{
    use SoftDeletes;

    public function getRouteKeyName(): string
    {
        return 'public_id';
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function plans(): HasMany
    {
        return $this->hasMany(ProductPlan::class, 'product_id');
    }

    public function versions(): HasMany
    {
        return $this->hasMany(ProductVersion::class, 'product_id');
    }

    public function instances(): HasMany
    {
        return $this->hasMany(SoftwareInstance::class, 'product_id');
    }
}
