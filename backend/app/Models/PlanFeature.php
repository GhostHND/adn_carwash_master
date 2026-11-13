<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['plan_id', 'feature_code', 'enabled', 'limit_value'])]
class PlanFeature extends Model
{
    protected function casts(): array
    {
        return [
            'enabled' => 'boolean',
            'limit_value' => 'array',
        ];
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(ProductPlan::class, 'plan_id');
    }
}
