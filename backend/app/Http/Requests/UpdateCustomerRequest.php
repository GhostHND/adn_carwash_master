<?php

namespace App\Http\Requests;

use App\Models\Customer;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class UpdateCustomerRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        $input = $this->all();
        $normalized = [];

        if (array_key_exists('email', $input) && $input['email'] !== null) {
            $normalized['email'] = Str::lower(trim((string) $input['email'])) ?: null;
        }

        if (array_key_exists('tax_identifier', $input) && $input['tax_identifier'] !== null) {
            $normalized['tax_identifier'] = Str::upper(trim((string) $input['tax_identifier'])) ?: null;
        }

        $this->merge($normalized);
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
        $customer = $this->route('customer');

        return [
            'legal_name' => ['sometimes', 'required', 'string', 'max:255'],
            'trade_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'email' => ['sometimes', 'nullable', 'email', 'max:254'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:40'],
            'tax_identifier' => [
                'sometimes',
                'nullable',
                'string',
                'max:80',
                Rule::unique('customers', 'tax_identifier')
                    ->ignore($customer instanceof Customer ? $customer->id : null),
            ],
            'status' => ['sometimes', Rule::in(['active', 'inactive'])],
        ];
    }
}
