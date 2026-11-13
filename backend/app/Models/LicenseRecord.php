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
    'contract_valid_until',
    'administrative_hold',
    'last_verified_at',
])]
class LicenseRecord extends Model
{
    protected function casts(): array
    {
        return [
            'contract_valid_until' => 'date',
            'administrative_hold' => 'boolean',
            'last_verified_at' => 'datetime',
        ];
    }

    public function instance(): BelongsTo
    {
        return $this->belongsTo(SoftwareInstance::class, 'instance_id');
    }

    public function authorizations(): HasMany
    {
        return $this->hasMany(LicenseAuthorization::class, 'instance_id', 'instance_id');
    }
}
