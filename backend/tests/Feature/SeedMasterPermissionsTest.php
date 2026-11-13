<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SeedMasterPermissionsTest extends TestCase
{
    use RefreshDatabase;

    public function test_permission_catalog_command_is_idempotent(): void
    {
        $this->artisan('master:permissions:seed')->assertSuccessful();
        $this->artisan('master:permissions:seed')->assertSuccessful();

        $this->assertDatabaseCount('permissions', 8);
        $this->assertDatabaseHas('permissions', ['code' => 'audit.view']);
        $this->assertDatabaseHas('permissions', ['code' => 'instances.manage']);
    }
}
