<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use App\Support\MasterPermissionCatalog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MasterAdminRoutesTest extends TestCase
{
    use RefreshDatabase;

    public function test_registered_owner_routes_manage_users_and_expose_audit_events(): void
    {
        MasterPermissionCatalog::seed();

        $owner = User::factory()->create();
        $owner->roles()->attach(Role::query()->create([
            'code' => 'owner',
            'name' => 'Owner',
            'is_active' => true,
        ]));
        $token = $owner->createToken('test')->plainTextToken;

        $this->withToken($token)->getJson('/api/v1/permissions')
            ->assertOk()
            ->assertJsonPath('meta.total', 8);

        $this->withToken($token)->postJson('/api/v1/users', [
            'name' => 'Operator',
            'email' => 'operator@example.test',
            'password' => 'secure-password-123',
        ])->assertCreated()
            ->assertJsonMissingPath('data.password');

        $this->assertDatabaseCount('audit_events', 1);
        $this->withToken($token)->getJson('/api/v1/audit-events')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.action', 'POST');
    }
}
