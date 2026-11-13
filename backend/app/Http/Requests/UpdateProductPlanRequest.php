<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class UpdateProductPlanRequest extends FormRequest
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
        $plan = $this->route('plan');

        return [
            'code' => [
                'sometimes',
                'required',
                'string',
                'max:80',
                'regex:/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/',
                Rule::unique('product_plans', 'code')
                    ->where('product_id', $plan->product_id)
                    ->ignore($plan->id),
            ],
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'price_cents' => ['sometimes', 'nullable', 'integer', 'min:0'],
            'currency' => ['sometimes', 'nullable', 'string', 'size:3', 'regex:/\A[A-Z]{3}\z/'],
            'billing_period' => [
                'sometimes',
                'nullable',
                Rule::in(['monthly', 'quarterly', 'yearly', 'one_time']),
            ],
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
                $plan = $this->route('plan');

                if ($this->input('status', $plan->status) !== 'active') {
                    return;
                }

                $data = array_merge(
                    $plan->only(['price_cents', 'currency', 'billing_period']),
                    $this->all(),
                );

                foreach (['price_cents', 'currency', 'billing_period'] as $field) {
                    if (! isset($data[$field]) || $data[$field] === '') {
                        $validator->errors()->add($field, 'Es obligatorio para activar un plan.');
                    }
                }

                $features = array_key_exists('features', $this->all())
                    ? $this->input('features')
                    : $plan->features()->get()->map(fn ($feature) => [
                        'feature_code' => $feature->feature_code,
                    ])->all();

                if (! is_array($features) || $features === []) {
                    $validator->errors()->add('features', 'Agrega al menos una funcionalidad antes de activar el plan.');
                }

                if ($plan->product()->where('status', 'active')->doesntExist()) {
                    $validator->errors()->add('status', 'Activa el producto antes de activar sus planes.');
                }
            },
        ];
    }
}
