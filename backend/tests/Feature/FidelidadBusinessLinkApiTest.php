<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Role;
use App\Models\SoftwareInstance;
use App\Models\SoftwareProduct;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Tests\TestCase;

class FidelidadBusinessLinkApiTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'a-test-secret-at-least-32-bytes-long';

    public function test_owner_can_search_and_link_existing_business_with_signed_requests(): void
    {
        config([
            'services.fidelidad.api_url' => 'https://fidelidad.example.test',
            'services.fidelidad.link_secret' => self::SECRET,
        ]);
        $instance = $this->createFidelidadInstance();
        $businessId = (string) Str::uuid();
        Http::fake(function (Request $request) use ($instance, $businessId) {
            $timestamp = $request->header('X-ADN-Timestamp')[0];
            $key = $request->header('X-ADN-Idempotency-Key')[0];
            $path = parse_url($request->url(), PHP_URL_PATH);
            $expected = hash_hmac('sha256', "POST\n{$path}\n{$timestamp}\n{$key}\n".$request->body(), self::SECRET);
            $this->assertSame($expected, $request->header('X-ADN-Signature')[0]);
            if (str_ends_with($path, '/search')) {
                return Http::response(['data' => [[
                    'uuid' => $businessId, 'name' => 'GUZA', 'master_business_id' => null,
                ]]]);
            }
            $this->assertSame($instance->public_id, $request['master_business_id']);

            return Http::response(['data' => [
                'uuid' => $businessId, 'name' => 'GUZA', 'master_business_id' => $instance->public_id,
            ]]);
        });
        $this->actingAs($this->owner(), 'sanctum');
        $this->postJson("/api/v1/instances/{$instance->public_id}/fidelidad/search", ['query' => 'GUZA'])
            ->assertOk()->assertJsonPath('data.0.uuid', $businessId);
        $this->postJson("/api/v1/instances/{$instance->public_id}/fidelidad/link", ['business_uuid' => $businessId])
            ->assertOk()->assertJsonPath('data.master_business_id', $instance->public_id);
        $this->assertSame('draft', $instance->fresh()->provisioning_status);
        $this->assertDatabaseCount('subscriptions', 0);
    }

    public function test_only_owner_can_link_and_unconfirmed_response_is_an_error(): void
    {
        config([
            'services.fidelidad.api_url' => 'https://fidelidad.example.test',
            'services.fidelidad.link_secret' => self::SECRET,
        ]);
        $instance = $this->createFidelidadInstance();
        $businessId = (string) Str::uuid();
        Http::fake(['*' => Http::response(['data' => ['uuid' => $businessId, 'master_business_id' => (string) Str::uuid()]])]);
        $this->actingAs(User::factory()->create(), 'sanctum')
            ->postJson("/api/v1/instances/{$instance->public_id}/fidelidad/link", ['business_uuid' => $businessId])
            ->assertForbidden();
        Http::assertNothingSent();
        $this->actingAs($this->owner(), 'sanctum')
            ->postJson("/api/v1/instances/{$instance->public_id}/fidelidad/link", ['business_uuid' => $businessId])
            ->assertStatus(502);
    }

    public function test_conflicts_are_reported_and_invalid_search_responses_are_rejected(): void
    {
        config([
            'services.fidelidad.api_url' => 'https://fidelidad.example.test',
            'services.fidelidad.link_secret' => self::SECRET,
        ]);
        $instance = $this->createFidelidadInstance();
        $this->actingAs($this->owner(), 'sanctum');
        Http::fake([
            '*/link' => Http::response(['message' => 'Invalid.', 'errors' => ['business_uuid' => ['Ya está vinculado.']]], 422),
            '*/search' => Http::response(['data' => [['uuid' => 'invalid']]]),
        ]);
        $this->postJson("/api/v1/instances/{$instance->public_id}/fidelidad/link", ['business_uuid' => (string) Str::uuid()])
            ->assertUnprocessable()->assertJsonPath('errors.fidelidad.0', 'Ya está vinculado.');
        $this->postJson("/api/v1/instances/{$instance->public_id}/fidelidad/search", ['query' => 'GUZA'])
            ->assertStatus(502);
    }

    public function test_other_products_and_insecure_configuration_are_rejected(): void
    {
        config([
            'services.fidelidad.api_url' => 'http://fidelidad.example.test',
            'services.fidelidad.link_secret' => self::SECRET,
        ]);
        $instance = $this->createFidelidadInstance();
        $this->actingAs($this->owner(), 'sanctum');
        Http::fake();
        $this->postJson("/api/v1/instances/{$instance->public_id}/fidelidad/search", ['query' => 'GUZA'])
            ->assertStatus(503);
        $instance->product->update(['code' => 'adn-carwash']);
        $this->postJson("/api/v1/instances/{$instance->public_id}/fidelidad/search", ['query' => 'GUZA'])
            ->assertNotFound();
        Http::assertNothingSent();
    }

    public function test_search_preserves_existing_legacy_master_identifiers(): void
    {
        config([
            'services.fidelidad.api_url' => 'https://fidelidad.example.test',
            'services.fidelidad.link_secret' => self::SECRET,
        ]);
        $instance = $this->createFidelidadInstance();
        $this->actingAs($this->owner(), 'sanctum');
        Http::fake(['*' => Http::response(['data' => [[
            'uuid' => (string) Str::uuid(),
            'name' => 'GUZA',
            'master_business_id' => 'legacy-id',
        ]]])]);

        $this->postJson("/api/v1/instances/{$instance->public_id}/fidelidad/search", ['query' => 'GUZA'])
            ->assertOk()->assertJsonPath('data.0.master_business_id', 'legacy-id');
    }

    private function createFidelidadInstance(): SoftwareInstance
    {
        $customer = Customer::query()->create(['public_id' => (string) Str::uuid(), 'legal_name' => 'GUZA']);
        $product = SoftwareProduct::query()->create([
            'public_id' => (string) Str::uuid(), 'code' => 'adn-fidelidad', 'name' => 'ADN Fidelidad',
        ]);

        return SoftwareInstance::query()->create([
            'public_id' => (string) Str::uuid(), 'customer_id' => $customer->id,
            'product_id' => $product->id, 'name' => 'GUZA',
        ]);
    }

    private function owner(): User
    {
        $user = User::factory()->create();
        $role = Role::query()->create(['code' => 'owner', 'name' => 'Owner', 'is_active' => true]);
        $user->roles()->attach($role);

        return $user->fresh();
    }
}
