<?php

namespace App\Http\Requests;

use App\Models\Customer;
use App\Models\ProductPlan;
use App\Models\SoftwareProduct;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreSoftwareInstanceRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        $infrastructure = $this->input('infrastructure');
        if (is_array($infrastructure) && is_string($infrastructure['currency'] ?? null)) {
            $infrastructure['currency'] = strtoupper(trim($infrastructure['currency']));
            $this->merge(['infrastructure' => $infrastructure]);
        }

        if (is_string($this->input('domain'))) {
            $this->merge(['domain' => strtolower(trim($this->input('domain'))) ?: null]);
        }
    }

    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'customer_id' => ['required', 'uuid', 'exists:customers,public_id'],
            'product_code' => ['required', 'string', 'exists:software_products,code'],
            'plan_id' => ['required', 'uuid', 'exists:product_plans,public_id'],
            'name' => ['required', 'string', 'max:255'],
            'domain' => [
                'nullable',
                'string',
                'max:253',
                'regex:/\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}\z/',
                Rule::unique('software_instances', 'domain'),
            ],
            'environment' => ['sometimes', Rule::in(['development', 'staging', 'production'])],
            'infrastructure' => ['required', 'array'],
            'infrastructure.currency' => ['required', 'string', 'size:3', 'regex:/\A[A-Z]{3}\z/'],
            'infrastructure.hosting_provider' => ['nullable', 'string', 'max:255'],
            'infrastructure.domain_provider' => ['nullable', 'string', 'max:255'],
            'infrastructure.hosting_cost_cents' => ['required', 'integer', 'min:0'],
            'infrastructure.hosting_charge_cents' => ['required', 'integer', 'min:0'],
            'infrastructure.domain_cost_cents' => ['required', 'integer', 'min:0'],
            'infrastructure.domain_charge_cents' => ['required', 'integer', 'min:0'],
        ];
    }

    public function after(): array
    {
        return [
            function (Validator $validator): void {
                $customer = Customer::query()
                    ->where('public_id', $this->input('customer_id'))
                    ->first();

                if ($customer !== null && $customer->status !== 'active') {
                    $validator->errors()->add('customer_id', 'Selecciona un cliente activo.');
                }

                $product = SoftwareProduct::query()
                    ->where('code', $this->input('product_code'))
                    ->first();
                $plan = ProductPlan::query()
                    ->where('public_id', $this->input('plan_id'))
                    ->first();

                if ($product !== null && $plan !== null && $plan->product_id !== $product->id) {
                    $validator->errors()->add('plan_id', 'El plan no pertenece al producto seleccionado.');
                }
            },
        ];
    }
}
