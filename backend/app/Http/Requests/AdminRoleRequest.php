<?php

namespace App\Http\Requests;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AdminRoleRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        if (is_string($this->input('code'))) {
            $this->merge(['code' => Str::lower(trim($this->input('code')))]);
        }
    }

    public function authorize(): bool
    {
        $user = $this->user();

        return $user instanceof User && $user->is_active
            && $user->roles()->where('code', 'owner')->where('is_active', true)->exists();
    }

    public function rules(): array
    {
        $role = $this->route('role');
        $required = $this->isMethod('post') ? 'required' : 'sometimes';

        return [
            'code' => [$required, 'required', 'string', 'max:80', 'regex:/^[a-z0-9][a-z0-9_-]*$/', Rule::notIn(['owner']), Rule::unique('roles', 'code')->ignore($role instanceof Role ? $role->id : null)],
            'name' => [$required, 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'is_active' => ['sometimes', 'boolean'],
            'permission_ids' => ['sometimes', 'array'],
            'permission_ids.*' => ['required', 'integer', 'distinct', Rule::exists('permissions', 'id')],
        ];
    }
}
