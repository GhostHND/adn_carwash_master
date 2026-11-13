<?php

namespace App\Http\Requests;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AdminUserRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        if (is_string($this->input('email'))) {
            $this->merge(['email' => Str::lower(trim($this->input('email')))]);
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
        $target = $this->route('user');
        $required = $this->isMethod('post') ? 'required' : 'sometimes';

        return [
            'name' => [$required, 'required', 'string', 'max:255'],
            'email' => [$required, 'required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($target instanceof User ? $target->id : null)],
            'password' => [$required, 'required', 'string', 'min:12', 'max:255'],
            'is_active' => ['sometimes', 'boolean'],
            'role_ids' => ['sometimes', 'array'],
            'role_ids.*' => ['required', 'integer', 'distinct', Rule::exists('roles', 'id')],
        ];
    }
}
