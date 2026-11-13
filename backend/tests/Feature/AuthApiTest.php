<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\MasterPasswordResetNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_health_endpoint_reports_api_liveness(): void
    {
        $this->getJson('/api/v1/health')
            ->assertOk()
            ->assertJsonPath('data.status', 'ok');
    }

    public function test_active_user_can_login_and_read_their_profile(): void
    {
        $user = User::factory()->create([
            'email' => 'admin@example.test',
            'password' => 'correct-password',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'ADMIN@example.test',
            'password' => 'correct-password',
            'device_name' => 'test-client',
        ])->assertOk()
            ->assertJsonPath('data.user.id', $user->id)
            ->assertJsonPath('data.user.email', $user->email)
            ->assertJsonPath('data.token_type', 'Bearer');

        $token = $response->json('data.token');

        $this->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.user.name', $user->name);
    }

    public function test_invalid_or_inactive_accounts_cannot_login(): void
    {
        $user = User::factory()->create([
            'email' => 'disabled@example.test',
            'password' => 'correct-password',
            'is_active' => false,
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'correct-password',
        ])->assertUnauthorized();

        $this->postJson('/api/v1/auth/login', [
            'email' => 'missing@example.test',
            'password' => 'wrong-password',
        ])->assertUnauthorized();

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_logout_revokes_only_the_current_access_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-client')->plainTextToken;
        $otherToken = $user->createToken('other-client')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/v1/auth/logout')
            ->assertNoContent();

        $this->assertDatabaseCount('personal_access_tokens', 1);
        Auth::forgetGuards();

        $this->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized();

        Auth::forgetGuards();

        $this->withToken($otherToken)
            ->getJson('/api/v1/auth/me')
            ->assertOk();
    }

    public function test_deactivating_a_user_revokes_all_access_tokens(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-client')->plainTextToken;

        $user->forceFill(['is_active' => false])->save();

        $this->assertDatabaseCount('personal_access_tokens', 0);

        $this->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized();
    }

    public function test_console_bootstrap_creates_an_owner_with_a_hashed_password(): void
    {
        $this->artisan('master:admin:create', [
            '--email' => 'owner@example.test',
            '--name' => 'Initial Owner',
        ])
            ->expectsQuestion('Password (minimum 12 characters)', 'strong-owner-password-123')
            ->expectsQuestion('Confirm password', 'strong-owner-password-123')
            ->expectsOutputToContain('Administrator account created.')
            ->assertExitCode(0);

        $user = User::query()->where('email', 'owner@example.test')->firstOrFail();

        $this->assertNotSame('strong-owner-password-123', $user->password);
        $this->assertTrue(Hash::check('strong-owner-password-123', $user->password));
        $this->assertTrue($user->hasPermission('products.manage'));
        $this->assertDatabaseCount('users', 1);
    }

    public function test_console_password_reset_updates_the_password_and_revokes_tokens(): void
    {
        $user = User::factory()->create([
            'email' => 'owner@example.test',
            'password' => 'old-owner-password',
        ]);
        $user->createToken('existing-client');

        $this->artisan('master:admin:password-reset', [
            '--email' => 'OWNER@example.test',
        ])
            ->expectsQuestion('New password (minimum 12 characters)', 'new-owner-password-123')
            ->expectsQuestion('Confirm password', 'new-owner-password-123')
            ->expectsOutputToContain('Administrator password reset successfully.')
            ->assertExitCode(0);

        $this->assertTrue(Hash::check('new-owner-password-123', $user->fresh()->password));
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_console_password_reset_reports_an_account_missing_from_the_configured_database(): void
    {
        $this->artisan('master:admin:password-reset', [
            '--email' => 'missing@example.test',
        ])
            ->expectsOutputToContain('No administrator account with that email exists in the configured database.')
            ->assertExitCode(1);
    }

    public function test_password_reset_request_does_not_disclose_account_existence(): void
    {
        Notification::fake();
        $user = User::factory()->create(['email' => 'admin@example.test']);

        $known = $this->postJson('/api/v1/auth/password/forgot', [
            'email' => $user->email,
        ])->assertOk();

        $unknown = $this->postJson('/api/v1/auth/password/forgot', [
            'email' => 'missing@example.test',
        ])->assertOk();

        $this->assertSame(
            $known->json('message'),
            $unknown->json('message'),
        );
        Notification::assertSentTo($user, MasterPasswordResetNotification::class);
    }

    public function test_password_reset_changes_password_and_revokes_existing_tokens(): void
    {
        $user = User::factory()->create(['email' => 'admin@example.test']);
        $token = Password::createToken($user);
        $accessToken = $user->createToken('old-client')->plainTextToken;

        $this->postJson('/api/v1/auth/password/reset', [
            'email' => $user->email,
            'token' => $token,
            'password' => 'a-strong-password-123',
            'password_confirmation' => 'a-strong-password-123',
        ])->assertOk();

        $this->assertTrue(Hash::check('a-strong-password-123', $user->fresh()->password));
        $this->assertDatabaseCount('personal_access_tokens', 0);

        $this->withToken($accessToken)
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized();
    }
}
