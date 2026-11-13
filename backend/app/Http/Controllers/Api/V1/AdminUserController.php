<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Requests\AdminUserRequest;
use App\Http\Resources\AdminUserResource;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;

class AdminUserController extends AdminController
{
    public function index(Request $request)
    {
        $this->authorizeOwner($request);
        $data = $request->validate(['per_page' => ['sometimes', 'integer', 'min:1', 'max:100']]);

        return AdminUserResource::collection(User::query()->with('roles.permissions')->orderBy('id')->paginate($data['per_page'] ?? 25));
    }

    public function show(Request $request, User $user): AdminUserResource
    {
        $this->authorizeOwner($request);

        return AdminUserResource::make($user->load('roles.permissions'));
    }

    public function store(AdminUserRequest $request): AdminUserResource
    {
        $user = DB::transaction(function () use ($request): User {
            $owner = $this->lockAndAuthorizeOwner($request);
            $data = $request->validated();
            $roles = $data['role_ids'] ?? [];
            $this->validateRoles($roles, $owner, false);
            $user = User::query()->create(Arr::except($data, 'role_ids'));
            $user->roles()->sync($roles);

            return $user->load('roles.permissions');
        });

        return AdminUserResource::make($user);
    }

    public function update(AdminUserRequest $request, User $user): AdminUserResource
    {
        $user = DB::transaction(function () use ($request, $user): User {
            $owner = $this->lockAndAuthorizeOwner($request);
            $user = User::query()->findOrFail($user->id);
            $data = $request->validated();
            $hadOwner = $user->roles()->whereKey($owner->id)->exists();
            if (array_key_exists('role_ids', $data)) {
                $this->validateRoles($data['role_ids'], $owner, $hadOwner);
            }
            $retainsOwner = ! array_key_exists('role_ids', $data) || in_array($owner->id, array_map('intval', $data['role_ids']), true);
            if ($hadOwner && $user->is_active && (! $retainsOwner || (array_key_exists('is_active', $data) && ! $data['is_active']))) {
                $this->ensureAnotherActiveOwner($user, $owner);
            }
            $user->fill(Arr::except($data, 'role_ids'))->save();
            if (array_key_exists('role_ids', $data)) {
                $user->roles()->sync($data['role_ids']);
            }
            if (array_key_exists('password', $data)) {
                $user->tokens()->delete();
            }

            return $user->load('roles.permissions');
        });

        return AdminUserResource::make($user);
    }

    public function destroy(Request $request, User $user): Response
    {
        DB::transaction(function () use ($request, $user): void {
            $owner = $this->lockAndAuthorizeOwner($request);
            $user = User::query()->findOrFail($user->id);
            if ($user->is_active && $user->roles()->whereKey($owner->id)->exists()) {
                $this->ensureAnotherActiveOwner($user, $owner);
            }
            $user->tokens()->delete();
            $user->delete();
        });

        return response()->noContent();
    }

    private function validateRoles(array $ids, Role $owner, bool $alreadyOwner): void
    {
        $ids = array_map('intval', $ids);
        if (count($ids) !== Role::query()->whereIn('id', $ids)->count()) {
            throw ValidationException::withMessages(['role_ids' => 'One or more roles no longer exist.']);
        }
        if (! $alreadyOwner && in_array($owner->id, $ids, true)) {
            throw ValidationException::withMessages(['role_ids' => 'The owner role cannot be assigned.']);
        }
    }

    private function ensureAnotherActiveOwner(User $user, Role $owner): void
    {
        if (! $owner->users()->where('users.id', '!=', $user->id)->where('users.is_active', true)->exists()) {
            throw ValidationException::withMessages(['user' => 'The last active owner cannot be removed or deactivated.']);
        }
    }
}
