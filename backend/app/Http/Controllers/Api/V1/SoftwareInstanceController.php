<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSoftwareInstanceRequest;
use App\Http\Requests\UpdateSoftwareInstanceRequest;
use App\Http\Resources\SoftwareInstanceResource;
use App\Models\Customer;
use App\Models\SoftwareInstance;
use App\Models\SoftwareProduct;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class SoftwareInstanceController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->validate([
            'product_code' => ['nullable', 'string', 'exists:software_products,code'],
            'customer_id' => ['nullable', 'uuid', 'exists:customers,public_id'],
            'provisioning_status' => [
                'nullable',
                'in:draft,provisioning,ready,failed,suspended,terminated',
            ],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $instances = SoftwareInstance::query()
            ->with(['customer', 'product', 'plan', 'infrastructure'])
            ->when(
                $filters['product_code'] ?? null,
                fn ($query, $code) => $query->whereHas(
                    'product',
                    fn ($query) => $query->where('code', $code),
                ),
            )
            ->when(
                $filters['customer_id'] ?? null,
                fn ($query, $publicId) => $query->whereHas(
                    'customer',
                    fn ($query) => $query->where('public_id', $publicId),
                ),
            )
            ->when(
                $filters['provisioning_status'] ?? null,
                fn ($query, $status) => $query->where('provisioning_status', $status),
            )
            ->orderByDesc('created_at')
            ->paginate($filters['per_page'] ?? 25);

        return SoftwareInstanceResource::collection($instances);
    }

    public function store(StoreSoftwareInstanceRequest $request): SoftwareInstanceResource
    {
        $data = $request->validated();
        $customer = Customer::query()->where('public_id', $data['customer_id'])->firstOrFail();
        $product = SoftwareProduct::query()->where('code', $data['product_code'])->firstOrFail();
        $plan = $product->plans()->where('public_id', $data['plan_id'])->firstOrFail();

        $instance = DB::transaction(function () use ($data, $customer, $product, $plan, $request) {
            $instance = SoftwareInstance::query()->create([
                'public_id' => (string) Str::uuid(),
                'customer_id' => $customer->id,
                'product_id' => $product->id,
                'plan_id' => $plan->id,
                'name' => $data['name'],
                'domain' => $data['domain'] ?? null,
                'environment' => $data['environment'] ?? 'production',
                'provisioning_status' => 'draft',
                'administrative_status' => 'pending',
                'created_by' => $request->user()->id,
            ]);

            $instance->infrastructure()->create($data['infrastructure']);

            return $instance;
        });

        return SoftwareInstanceResource::make(
            $instance->load(['customer', 'product', 'plan', 'infrastructure']),
        );
    }

    public function show(SoftwareInstance $instance): SoftwareInstanceResource
    {
        return SoftwareInstanceResource::make(
            $instance->load(['customer', 'product', 'plan', 'infrastructure']),
        );
    }

    public function update(
        UpdateSoftwareInstanceRequest $request,
        SoftwareInstance $instance,
    ): SoftwareInstanceResource {
        $data = $request->validated();

        DB::transaction(function () use ($data, $instance): void {
            $instance->fill(collect($data)->except('infrastructure')->all())->save();

            if (array_key_exists('infrastructure', $data)) {
                $instance->infrastructure()->updateOrCreate([], $data['infrastructure']);
            }
        });

        return SoftwareInstanceResource::make(
            $instance->refresh()->load(['customer', 'product', 'plan', 'infrastructure']),
        );
    }
}
