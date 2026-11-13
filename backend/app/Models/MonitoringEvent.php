<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['instance_id', 'service_code', 'observed_at', 'status', 'details'])]
class MonitoringEvent extends Model
{
    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'observed_at' => 'datetime',
            'details' => 'array',
        ];
    }

    public function instance(): BelongsTo
    {
        return $this->belongsTo(SoftwareInstance::class, 'instance_id');
    }
}
