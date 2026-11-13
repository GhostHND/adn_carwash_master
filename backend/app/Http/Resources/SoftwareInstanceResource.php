<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SoftwareInstanceResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'name' => $this->name,
            'domain' => $this->domain,
            'environment' => $this->environment,
            'provisioning_status' => $this->provisioning_status,
            'administrative_status' => $this->administrative_status,
            'customer' => [
                'id' => $this->customer->public_id,
                'name' => $this->customer->trade_name ?: $this->customer->legal_name,
            ],
            'product' => [
                'id' => $this->product->public_id,
                'code' => $this->product->code,
                'name' => $this->product->name,
            ],
            'plan' => [
                'id' => $this->plan?->public_id,
                'code' => $this->plan?->code,
                'name' => $this->plan?->name,
            ],
            'infrastructure' => $this->infrastructure === null ? null : [
                'currency' => $this->infrastructure->currency,
                'hosting_provider' => $this->infrastructure->hosting_provider,
                'domain_provider' => $this->infrastructure->domain_provider,
                'hosting_cost_cents' => $this->infrastructure->hosting_cost_cents,
                'hosting_charge_cents' => $this->infrastructure->hosting_charge_cents,
                'domain_cost_cents' => $this->infrastructure->domain_cost_cents,
                'domain_charge_cents' => $this->infrastructure->domain_charge_cents,
            ],
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
