<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'authorization_id',
    'instance_id',
    'issued_at',
    'expires_at',
    'revoked_at',
    'payload',
    'signature',
    'signing_key_id',
])]
class LicenseAuthorization extends Model
{
    protected function casts(): array
    {
        return [
            'issued_at' => 'datetime',
            'expires_at' => 'datetime',
            'revoked_at' => 'datetime',
            'payload' => 'array',
        ];
    }

    public function instance(): BelongsTo
    {
        return $this->belongsTo(SoftwareInstance::class, 'instance_id');
    }
}
