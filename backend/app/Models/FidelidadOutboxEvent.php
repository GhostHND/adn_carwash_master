<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'instance_id',
    'event_id',
    'event_version',
    'event_type',
    'payload',
    'status',
    'attempts',
    'next_attempt_at',
    'delivered_at',
    'last_http_status',
    'last_error',
])]
class FidelidadOutboxEvent extends Model
{
    protected $table = 'fidelidad_integration_outbox';

    protected function casts(): array
    {
        return [
            'event_version' => 'integer',
            'payload' => 'array',
            'attempts' => 'integer',
            'next_attempt_at' => 'datetime',
            'delivered_at' => 'datetime',
            'last_http_status' => 'integer',
        ];
    }

    public function instance(): BelongsTo
    {
        return $this->belongsTo(SoftwareInstance::class, 'instance_id');
    }
}
