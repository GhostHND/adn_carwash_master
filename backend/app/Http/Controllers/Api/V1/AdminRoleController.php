<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Requests\AdminRoleRequest;
use App\Http\Resources\AdminRoleResource;
use App\Models\Permission;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;

class AdminRoleController extends AdminController
{
    public function index(Request $request)
    {
        $this->authorizeOwner($request);
        $data = $request->validate(['per_page' => ['sometimes', 'integer', 'min:1', 'max:100']]);

        return AdminRoleResource::collection(Role::query()->with('permissions')->orderBy('id')->paginate($data['per_page'] ?? 25));
    }

    public function show(Request $request, Role $role): AdminRoleResource
    {
        $this->authorizeOwner($request);

        return AdminRoleResource::make($role->load('permissions'));
    }

    public function store(AdminRoleRequest $request): AdminRoleResource
    {
        $role = DB::transaction(function () use ($request): Role {
            $this->lockAndAuthorizeOwner($request);
            $data = $request->validated();
            $permissions = $data['permission_ids'] ?? [];
            $this->validatePermissions($permissions);
            $role = Role::query()->create(Arr::except($data, 'permission_ids'));
            $role->permissions()->sync($permissions);

            return $role->load('permissions');
        });

        return AdminRoleResource::make($role);
    }

    public function update(AdminRoleRequest $request, Role $role): AdminRoleResource
    {
        $role = DB::transaction(function () use ($request, $role): Role {
            $owner = $this->lockAndAuthorizeOwner($request);
            $role = Role::query()->findOrFail($role->id);
            abort_if($role->id === $owner->id, 403, 'The owner role is immutable.');
            $data = $request->validated();
            if (array_key_exists('permission_ids', $data)) {
                $this->validatePermissions($data['permission_ids']);
            }
            $role->fill(Arr::except($data, 'permission_ids'))->save();
            if (array_key_exists('permission_ids', $data)) {
                $role->permissions()->sync($data['permission_ids']);
            }

            return $role->load('permissions');
        });

        return AdminRoleResource::make($role);
    }

    public function destroy(Request $request, Role $role): Response
    {
        DB::transaction(function () use ($request, $role): void {
            $owner = $this->lockAndAuthorizeOwner($request);
            $role = Role::query()->findOrFail($role->id);
            abort_if($role->id === $owner->id, 403, 'The owner role is immutable.');
            $role->delete();
        });

        return response()->noContent();
    }

    private function validatePermissions(array $ids): void
    {
        if (count($ids) !== Permission::query()->whereIn('id', $ids)->count()) {
            throw ValidationException::withMessages(['permission_ids' => 'One or more permissions no longer exist.']);
        }
    }
}
