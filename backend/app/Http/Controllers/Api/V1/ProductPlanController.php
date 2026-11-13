<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreProductPlanRequest;
use App\Http\Requests\UpdateProductPlanRequest;
use App\Http\Resources\ProductPlanResource;
use App\Models\ProductPlan;
use App\Models\SoftwareProduct;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ProductPlanController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->validate([
            'product_code' => ['nullable', 'string', 'exists:software_products,code'],
            'status' => ['nullable', 'in:draft,active,retired'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $plans = ProductPlan::query()
            ->with(['product', 'features'])
            ->when(
                $filters['product_code'] ?? null,
                fn ($query, $code) => $query->whereHas(
                    'product',
                    fn ($query) => $query->where('code', $code),
                ),
            )
            ->when($filters['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->orderBy('product_id')
            ->orderBy('name')
            ->paginate($filters['per_page'] ?? 25);

        return ProductPlanResource::collection($plans);
    }

    public function store(StoreProductPlanRequest $request): ProductPlanResource
    {
        $data = $request->validated();
        $product = SoftwareProduct::query()
            ->where('code', $data['product_code'])
            ->firstOrFail();

        $plan = DB::transaction(function () use ($data, $product): ProductPlan {
            $plan = $product->plans()->create([
                'public_id' => (string) Str::uuid(),
                'code' => $data['code'],
                'name' => $data['name'],
                'price_cents' => $data['price_cents'] ?? null,
                'currency' => $data['currency'] ?? null,
                'billing_period' => $data['billing_period'] ?? null,
                'status' => $data['status'] ?? 'draft',
            ]);

            $this->syncFeatures($plan, $data['features'] ?? []);

            return $plan;
        });

        return ProductPlanResource::make($plan->load(['product', 'features']));
    }

    public function show(ProductPlan $plan): ProductPlanResource
    {
        return ProductPlanResource::make($plan->load(['product', 'features']));
    }

    public function update(
        UpdateProductPlanRequest $request,
        ProductPlan $plan,
    ): ProductPlanResource {
        $data = $request->validated();

        DB::transaction(function () use ($data, $plan): void {
            $plan->fill(collect($data)->except('features')->all())->save();

            if (array_key_exists('features', $data)) {
                $this->syncFeatures($plan, $data['features']);
            }
        });

        return ProductPlanResource::make($plan->refresh()->load(['product', 'features']));
    }

    /**
     * @param  array<int, array{feature_code: string, enabled: bool, limit_value?: int|null}>  $features
     */
    private function syncFeatures(ProductPlan $plan, array $features): void
    {
        $plan->features()->delete();

        foreach ($features as $feature) {
            $plan->features()->create([
                'feature_code' => $feature['feature_code'],
                'enabled' => $feature['enabled'],
                'limit_value' => $feature['limit_value'] ?? null,
            ]);
        }
    }
}
