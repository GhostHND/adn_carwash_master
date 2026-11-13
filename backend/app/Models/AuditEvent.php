<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use LogicException;

#[Fillable([
    'actor_id',
    'actor_type',
    'action',
    'resource_type',
    'resource_id',
    'occurred_at',
    'outcome',
    'request_reference',
    'metadata',
])]
class AuditEvent extends Model
{
    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'occurred_at' => 'datetime',
            'metadata' => 'array',
        ];
    }

    protected static function booted(): void
    {
        static::updating(fn () => throw new LogicException('Audit events are immutable.'));
        static::deleting(fn () => throw new LogicException('Audit events cannot be deleted.'));
    }

    public function newEloquentBuilder($query): AuditEventBuilder
    {
        return new AuditEventBuilder($query);
    }

    protected function performUpdate(Builder $query)
    {
        throw new LogicException('Audit events are immutable.');
    }

    protected function performDeleteOnModel()
    {
        throw new LogicException('Audit events cannot be deleted.');
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_id');
    }
}
