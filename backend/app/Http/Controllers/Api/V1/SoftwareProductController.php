<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSoftwareProductRequest;
use App\Http\Requests\UpdateSoftwareProductRequest;
use App\Http\Resources\SoftwareProductResource;
use App\Models\SoftwareProduct;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class SoftwareProductController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'status' => ['nullable', 'in:draft,active,retired'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $products = SoftwareProduct::query()
            ->when(
                $filters['search'] ?? null,
                fn ($query, $search) => $query->where(
                    fn ($query) => $query->where('name', 'like', '%'.$search.'%')
                        ->orWhere('code', 'like', '%'.$search.'%'),
                ),
            )
            ->when($filters['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->orderBy('name')
            ->paginate($filters['per_page'] ?? 25);

        return SoftwareProductResource::collection($products);
    }

    public function store(StoreSoftwareProductRequest $request): SoftwareProductResource
    {
        $product = SoftwareProduct::query()->create([
            ...$request->validated(),
            'public_id' => (string) Str::uuid(),
            'created_by' => $request->user()->id,
        ]);

        return SoftwareProductResource::make($product);
    }

    public function show(SoftwareProduct $product): SoftwareProductResource
    {
        return SoftwareProductResource::make($product);
    }

    public function update(
        UpdateSoftwareProductRequest $request,
        SoftwareProduct $product,
    ): SoftwareProductResource {
        $product->fill($request->validated())->save();

        return SoftwareProductResource::make($product->refresh());
    }
}
