<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\SoftwareInstance;
use App\Services\FidelidadEntitlementSyncService;
use Illuminate\Http\JsonResponse;

class FidelidadIntegrationController extends Controller
{
    public function show(
        string $productCode,
        string $instancePublicId,
        FidelidadEntitlementSyncService $sync,
    ): JsonResponse {
        if (! hash_equals((string) config('services.fidelidad.product_code'), $productCode)) {
            abort(404);
        }

        $instance = SoftwareInstance::query()
            ->where('public_id', $instancePublicId)
            ->whereHas('product', fn ($query) => $query->where('code', $productCode))
            ->firstOrFail();

        $event = $sync->reconcile($instance);
        if (! $event) {
            return response()->json(['message' => 'La instancia no tiene una suscripción sincronizable.'], 404);
        }

        return response()->json($event->payload);
    }
}
