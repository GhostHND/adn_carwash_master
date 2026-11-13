<?php

namespace App\Http\Requests;

use App\Models\SoftwareInstance;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateSoftwareInstanceRequest extends FormRequest
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
        /** @var SoftwareInstance $instance */
        $instance = $this->route('instance');

        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'domain' => [
                'sometimes',
                'nullable',
                'string',
                'max:253',
                'regex:/\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}\z/',
                Rule::unique('software_instances', 'domain')->ignore($instance->id),
            ],
            'infrastructure' => ['sometimes', 'required', 'array'],
            'infrastructure.currency' => [
                'required_with:infrastructure',
                'string',
                'size:3',
                'regex:/\A[A-Z]{3}\z/',
            ],
            'infrastructure.hosting_provider' => ['nullable', 'string', 'max:255'],
            'infrastructure.domain_provider' => ['nullable', 'string', 'max:255'],
            'infrastructure.hosting_cost_cents' => ['required_with:infrastructure', 'integer', 'min:0'],
            'infrastructure.hosting_charge_cents' => ['required_with:infrastructure', 'integer', 'min:0'],
            'infrastructure.domain_cost_cents' => ['required_with:infrastructure', 'integer', 'min:0'],
            'infrastructure.domain_charge_cents' => ['required_with:infrastructure', 'integer', 'min:0'],
        ];
    }
}
