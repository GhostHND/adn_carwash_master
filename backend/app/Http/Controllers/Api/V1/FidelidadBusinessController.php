<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\SoftwareInstance;
use App\Services\FidelidadBusinessLinkService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FidelidadBusinessController extends AdminController
{
    public function search(Request $request, SoftwareInstance $instance, FidelidadBusinessLinkService $service): JsonResponse
    {
        $this->authorizeOwner($request);
        $this->ensureFidelidad($instance);
        $data = $request->validate(['query' => ['required', 'string', 'min:2', 'max:120', 'not_regex:/[%_\\\\]/']]);

        return response()->json(['data' => $service->search(trim($data['query']))]);
    }

    public function link(Request $request, SoftwareInstance $instance, FidelidadBusinessLinkService $service): JsonResponse
    {
        $this->authorizeOwner($request);
        $this->ensureFidelidad($instance);
        $data = $request->validate(['business_uuid' => ['required', 'uuid']]);

        return response()->json(['data' => $service->link($data['business_uuid'], $instance->public_id)]);
    }

    private function ensureFidelidad(SoftwareInstance $instance): void
    {
        abort_unless($instance->product()->where('code', config('services.fidelidad.product_code'))->exists(), 404);
    }
}
