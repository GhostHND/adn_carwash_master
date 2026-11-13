<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductPlanResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'product_id' => $this->product->public_id,
            'product_code' => $this->product->code,
            'code' => $this->code,
            'name' => $this->name,
            'price_cents' => $this->price_cents,
            'currency' => $this->currency,
            'billing_period' => $this->billing_period,
            'status' => $this->status,
            'features' => $this->features->map(fn ($feature) => [
                'feature_code' => $feature->feature_code,
                'enabled' => $feature->enabled,
                'limit_value' => $feature->limit_value,
            ])->values(),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
