<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'instance_id',
    'hosting_provider',
    'hosting_reference',
    'domain_provider',
    'domain_reference',
    'domain_renewal_date',
    'hosting_renewal_date',
    'currency',
    'hosting_cost_cents',
    'hosting_charge_cents',
    'domain_cost_cents',
    'domain_charge_cents',
])]
class InstanceInfrastructure extends Model
{
    protected $table = 'instance_infrastructure';

    protected function casts(): array
    {
        return [
            'domain_renewal_date' => 'date',
            'hosting_renewal_date' => 'date',
            'hosting_cost_cents' => 'integer',
            'hosting_charge_cents' => 'integer',
            'domain_cost_cents' => 'integer',
            'domain_charge_cents' => 'integer',
        ];
    }

    public function instance(): BelongsTo
    {
        return $this->belongsTo(SoftwareInstance::class, 'instance_id');
    }
}
