<?php

namespace App\Http\Requests;

use App\Models\SoftwareProduct;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreProductPlanRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        if (is_string($this->input('currency'))) {
            $this->merge(['currency' => strtoupper(trim($this->input('currency')))]);
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
        $productId = SoftwareProduct::query()
            ->where('code', $this->input('product_code'))
            ->value('id') ?? -1;

        return [
            'product_code' => ['required', 'string', 'exists:software_products,code'],
            'code' => [
                'required',
                'string',
                'max:80',
                'regex:/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/',
                Rule::unique('product_plans', 'code')->where('product_id', $productId),
            ],
            'name' => ['required', 'string', 'max:255'],
            'price_cents' => ['nullable', 'integer', 'min:0'],
            'currency' => ['nullable', 'string', 'size:3', 'regex:/\A[A-Z]{3}\z/'],
            'billing_period' => ['nullable', Rule::in(['monthly', 'quarterly', 'yearly', 'one_time'])],
            'status' => ['sometimes', Rule::in(['draft', 'active', 'retired'])],
            'features' => ['sometimes', 'array', 'max:100'],
            'features.*.feature_code' => [
                'required',
                'string',
                'max:120',
                'regex:/\A[a-z0-9][a-z0-9._-]*\z/',
                'distinct',
            ],
            'features.*.enabled' => ['required', 'boolean'],
            'features.*.limit_value' => ['nullable', 'integer', 'min:0'],
        ];
    }

    public function after(): array
    {
        return [
            function (Validator $validator): void {
                if ($this->input('status', 'draft') !== 'active') {
                    return;
                }

                $this->validateActivation(
                    $validator,
                    $this->input('price_cents'),
                    $this->input('currency'),
                    $this->input('billing_period'),
                    $this->input('features'),
                    $this->input('product_code'),
                );
            },
        ];
    }

    private function validateActivation(
        Validator $validator,
        mixed $price,
        mixed $currency,
        mixed $billingPeriod,
        mixed $features,
        mixed $productCode,
    ): void {
        foreach ([
            'price_cents' => $price,
            'currency' => $currency,
            'billing_period' => $billingPeriod,
        ] as $field => $value) {
            if ($value === null || $value === '') {
                $validator->errors()->add($field, 'Es obligatorio para activar un plan.');
            }
        }

        if (! is_array($features) || $features === []) {
            $validator->errors()->add('features', 'Agrega al menos una funcionalidad antes de activar el plan.');
        }

        $productIsActive = SoftwareProduct::query()
            ->where('code', $productCode)
            ->where('status', 'active')
            ->exists();

        if (! $productIsActive) {
            $validator->errors()->add('product_code', 'Activa el producto antes de activar sus planes.');
        }
    }
}
