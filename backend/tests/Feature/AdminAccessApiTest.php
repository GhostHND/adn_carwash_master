<?php

namespace Tests\Feature;

use App\Http\Controllers\Api\V1\AdminPermissionController;
use App\Http\Controllers\Api\V1\AdminRoleController;
use App\Http\Controllers\Api\V1\AdminUserController;
use App\Models\Permission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class AdminAccessApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Route::prefix('api/v1')->middleware(['api', 'auth:sanctum', 'active'])->group(function (): void {
            Route::apiResource('users', AdminUserController::class);
            Route::apiResource('roles', AdminRoleController::class);
            Route::get('permissions', [AdminPermissionController::class, 'index']);
        });
    }

    public function test_only_active_owners_can_access_administration_even_with_permissions(): void
    {
        $role = Role::query()->create(['code' => 'manager', 'name' => 'Manager']);
        $permission = Permission::query()->create(['code' => 'users.manage']);
        $role->permissions()->attach($permission);
        $user = User::factory()->create();
        $user->roles()->attach($role);

        $this->getJson('/api/v1/users')->assertUnauthorized();
        $token = $user->createToken('test')->plainTextToken;
        foreach (['users', 'roles', 'permissions'] as $path) {
            $this->withToken($token)->getJson('/api/v1/'.$path)->assertForbidden();
        }
        $this->withToken($token)->postJson('/api/v1/users', [])->assertForbidden();
        $this->withToken($token)->postJson('/api/v1/roles', [])->assertForbidden();
        $this->withToken($token)->patchJson('/api/v1/users/'.$user->id, ['name' => 'Changed'])->assertForbidden();
        $this->withToken($token)->deleteJson('/api/v1/users/'.$user->id)->assertForbidden();
        $this->withToken($token)->patchJson('/api/v1/roles/'.$role->id, ['name' => 'Changed'])->assertForbidden();
        $this->withToken($token)->deleteJson('/api/v1/roles/'.$role->id)->assertForbidden();

        $owner = $this->owner();
        $token = $owner->createToken('test')->plainTextToken;
        $owner->update(['is_active' => false]);
        Auth::forgetGuards();
        $this->withToken($token)->getJson('/api/v1/users')->assertUnauthorized();
    }

    public function test_owner_can_manage_users_without_exposing_credentials(): void
    {
        $owner = $this->owner();
        $role = Role::query()->create(['code' => 'operator', 'name' => 'Operator']);
        $token = $owner->createToken('test')->plainTextToken;

        $created = $this->withToken($token)->postJson('/api/v1/users', [
            'name' => 'Operator', 'email' => ' OPERATOR@example.test ',
            'password' => 'strong-password-123', 'role_ids' => [$role->id],
        ])->assertCreated()->assertJsonPath('data.email', 'operator@example.test')
            ->assertJsonPath('data.roles.0.id', $role->id);
        $id = $created->json('data.id');
        $user = User::query()->findOrFail($id);
        $this->assertTrue(Hash::check('strong-password-123', $user->password));
        $user->createToken('other');

        foreach ([$created, $this->withToken($token)->getJson('/api/v1/users/'.$id),
            $this->withToken($token)->getJson('/api/v1/users')] as $response) {
            $response->assertSuccessful();
            $this->assertStringNotContainsString('password', $response->getContent());
            $this->assertStringNotContainsString('token', $response->getContent());
        }
        $this->withToken($token)->patchJson('/api/v1/users/'.$id, [
            'name' => 'Updated', 'password' => 'new-strong-password', 'role_ids' => [],
        ])->assertOk()->assertJsonPath('data.roles', []);
        $this->assertSame(0, $user->tokens()->count());
        $this->assertTrue(Hash::check('new-strong-password', $user->fresh()->password));
        $this->withToken($token)->deleteJson('/api/v1/users/'.$id)->assertNoContent();
        $this->assertDatabaseMissing('users', ['id' => $id]);
    }

    public function test_user_validation_and_owner_assignment_fail_without_partial_changes(): void
    {
        $owner = $this->owner();
        $ownerRole = $owner->roles()->firstOrFail();
        $regular = Role::query()->create(['code' => 'regular', 'name' => 'Regular']);
        $user = User::factory()->create(['name' => 'Original']);
        $user->roles()->attach($regular);
        $token = $owner->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/v1/users', [])->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'email', 'password']);
        $this->withToken($token)->postJson('/api/v1/users', [
            'name' => 'No', 'email' => 'no@example.test', 'password' => 'strong-password-123',
            'role_ids' => [$ownerRole->id],
        ])->assertUnprocessable();
        $this->assertDatabaseMissing('users', ['email' => 'no@example.test']);
        $this->withToken($token)->patchJson('/api/v1/users/'.$user->id, [
            'name' => 'Changed', 'role_ids' => [$ownerRole->id],
        ])->assertUnprocessable();
        $this->withToken($token)->patchJson('/api/v1/users/'.$user->id, [
            'name' => 'Changed', 'role_ids' => [999999],
        ])->assertUnprocessable()->assertJsonValidationErrors('role_ids.0');
        $this->assertSame('Original', $user->fresh()->name);
        $this->assertSame([$regular->id], $user->roles()->pluck('roles.id')->all());
    }

    public function test_last_active_owner_cannot_be_demoted_deactivated_or_deleted(): void
    {
        $owner = $this->owner();
        $role = $owner->roles()->firstOrFail();
        $inactive = User::factory()->create(['is_active' => false]);
        $inactive->roles()->attach($role);
        $token = $owner->createToken('test')->plainTextToken;
        foreach ([['role_ids' => []], ['is_active' => false]] as $payload) {
            $this->withToken($token)->patchJson('/api/v1/users/'.$owner->id, $payload)->assertUnprocessable();
        }
        $this->withToken($token)->deleteJson('/api/v1/users/'.$owner->id)->assertUnprocessable();
        $this->assertTrue($owner->fresh()->is_active);
        $this->assertTrue($owner->roles()->whereKey($role->id)->exists());

        $second = User::factory()->create();
        $second->roles()->attach($role);
        $this->withToken($token)->patchJson('/api/v1/users/'.$second->id, [
            'role_ids' => [$role->id], 'name' => 'Still owner',
        ])->assertOk();
        $this->withToken($token)->patchJson('/api/v1/users/'.$second->id, [
            'role_ids' => [], 'is_active' => false,
        ])->assertOk();
        $this->assertFalse($second->fresh()->is_active);
    }

    public function test_failed_user_update_rolls_back_changes_and_token_revocation(): void
    {
        $owner = $this->owner();
        $user = User::factory()->create(['name' => 'Original']);
        $user->createToken('test');
        $token = $owner->createToken('test')->plainTextToken;
        User::updated(function (User $updated) use ($user): void {
            if ($updated->id === $user->id) {
                throw new \RuntimeException('Simulated failure');
            }
        });

        $this->withToken($token)->patchJson('/api/v1/users/'.$user->id, [
            'name' => 'Changed', 'is_active' => false,
        ])->assertInternalServerError();
        $this->assertSame('Original', $user->fresh()->name);
        $this->assertTrue($user->fresh()->is_active);
        $this->assertSame(1, $user->tokens()->count());
    }

    public function test_roles_and_permission_assignments_are_validated_and_owner_role_is_immutable(): void
    {
        $owner = $this->owner();
        $ownerRole = $owner->roles()->firstOrFail();
        $permission = Permission::query()->create(['code' => 'products.manage', 'description' => 'Products']);
        $token = $owner->createToken('test')->plainTextToken;

        $this->withToken($token)->getJson('/api/v1/permissions')->assertOk()->assertJsonPath('data.0.id', $permission->id);
        $role = $this->withToken($token)->postJson('/api/v1/roles', [
            'code' => 'Manager', 'name' => 'Manager', 'permission_ids' => [$permission->id],
        ])->assertCreated()->assertJsonPath('data.code', 'manager')
            ->assertJsonPath('data.permissions.0.id', $permission->id)->json('data.id');
        $this->withToken($token)->getJson('/api/v1/roles/'.$role)->assertOk();
        $this->withToken($token)->getJson('/api/v1/roles')->assertOk();
        $this->withToken($token)->patchJson('/api/v1/roles/'.$role, [
            'name' => 'Changed', 'permission_ids' => [999999],
        ])->assertUnprocessable()->assertJsonValidationErrors('permission_ids.0');
        $this->assertDatabaseHas('roles', ['id' => $role, 'name' => 'Manager']);
        $this->assertDatabaseHas('permission_role', ['role_id' => $role, 'permission_id' => $permission->id]);
        $this->withToken($token)->patchJson('/api/v1/roles/'.$role, ['permission_ids' => []])
            ->assertOk()->assertJsonPath('data.permissions', []);
        $this->withToken($token)->postJson('/api/v1/roles', ['code' => 'OWNER', 'name' => 'Other'])
            ->assertUnprocessable();
        $this->withToken($token)->patchJson('/api/v1/roles/'.$role, ['code' => 'owner'])->assertUnprocessable();
        $this->withToken($token)->patchJson('/api/v1/roles/'.$ownerRole->id, ['name' => 'Changed'])->assertForbidden();
        $this->withToken($token)->patchJson('/api/v1/roles/'.$ownerRole->id, ['permission_ids' => [$permission->id]])->assertForbidden();
        $this->withToken($token)->deleteJson('/api/v1/roles/'.$ownerRole->id)->assertForbidden();
        $this->assertSame('Owner', $ownerRole->fresh()->name);
        $this->withToken($token)->deleteJson('/api/v1/roles/'.$role)->assertNoContent();
    }

    private function owner(): User
    {
        $owner = User::factory()->create();
        $role = Role::query()->firstOrCreate(['code' => 'owner'], ['name' => 'Owner', 'is_active' => true]);
        $owner->roles()->attach($role);

        return $owner;
    }
}
