<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AuditEventResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'actor_id' => $this->actor_id,
            'actor_type' => $this->actor_type,
            'action' => $this->action,
            'resource_type' => $this->resource_type,
            'resource_id' => $this->resource_id,
            'occurred_at' => $this->occurred_at,
            'outcome' => $this->outcome,
            'http_status' => $this->metadata['http_status'] ?? null,
            'request_reference' => $this->request_reference,
        ];
    }
}
