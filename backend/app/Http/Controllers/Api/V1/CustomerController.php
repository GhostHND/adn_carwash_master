<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCustomerRequest;
use App\Http\Requests\UpdateCustomerRequest;
use App\Http\Resources\CustomerResource;
use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CustomerController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'status' => ['nullable', 'in:active,inactive'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $customers = Customer::query()
            ->when(
                $filters['search'] ?? null,
                fn ($query, $search) => $query->where(
                    fn ($query) => $query->where('legal_name', 'like', '%'.$search.'%')
                        ->orWhere('trade_name', 'like', '%'.$search.'%')
                        ->orWhere('email', 'like', '%'.$search.'%')
                        ->orWhere('tax_identifier', 'like', '%'.$search.'%'),
                ),
            )
            ->when($filters['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->orderBy('legal_name')
            ->paginate($filters['per_page'] ?? 25);

        return CustomerResource::collection($customers);
    }

    public function store(StoreCustomerRequest $request): CustomerResource
    {
        $data = $request->validated();

        $customer = Customer::query()->create([
            ...$data,
            'public_id' => (string) Str::uuid(),
            'created_by' => $request->user()->id,
        ]);

        return CustomerResource::make($customer);
    }

    public function show(Customer $customer): CustomerResource
    {
        return CustomerResource::make($customer);
    }

    public function update(
        UpdateCustomerRequest $request,
        Customer $customer,
    ): CustomerResource {
        $data = $request->validated();

        $customer->fill($data)->save();

        return CustomerResource::make($customer->refresh());
    }
}
