<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Permission;
use App\Models\ProductPlan;
use App\Models\Role;
use App\Models\SoftwareInstance;
use App\Models\SoftwareProduct;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class MasterDirectoryApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_directory_routes_require_authentication_and_permissions(): void
    {
        $this->getJson('/api/v1/products')->assertUnauthorized();

        $user = User::factory()->create();
        $token = $user->createToken('test-client')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/v1/products')
            ->assertForbidden();
    }

    public function test_regular_roles_receive_only_their_assigned_permissions(): void
    {
        $user = User::factory()->create();
        $role = Role::query()->create([
            'code' => 'product-manager',
            'name' => 'Product manager',
            'is_active' => true,
        ]);
        $permission = Permission::query()->create(['code' => 'products.manage']);
        $role->permissions()->attach($permission);
        $user->roles()->attach($role);
        $token = $user->createToken('test-client')->plainTextToken;

        $this->withToken($token)->getJson('/api/v1/products')->assertOk();
        $this->withToken($token)->getJson('/api/v1/customers')->assertForbidden();
    }

    public function test_owner_can_create_update_and_search_products_by_public_id(): void
    {
        $token = $this->ownerToken();

        $created = $this->withToken($token)
            ->postJson('/api/v1/products', [
                'code' => 'adn-fidelidad',
                'name' => 'ADN Fidelidad',
                'category' => 'Fidelización',
                'status' => 'active',
            ])->assertCreated()
            ->assertJsonPath('data.code', 'adn-fidelidad')
            ->assertJsonMissingPath('data.internal_id');

        $publicId = $created->json('data.id');

        $this->withToken($token)
            ->patchJson('/api/v1/products/'.$publicId, [
                'name' => 'ADN Fidelidad Software',
            ])
            ->assertOk()
            ->assertJsonPath('data.name', 'ADN Fidelidad Software');

        $this->withToken($token)
            ->getJson('/api/v1/products?search=fidelidad&status=active')
            ->assertOk()
            ->assertJsonPath('data.0.id', $publicId);
    }

    public function test_product_codes_are_unique_and_validated(): void
    {
        $token = $this->ownerToken();
        $payload = ['code' => 'invalid code', 'name' => 'ADN Product'];

        $this->withToken($token)
            ->postJson('/api/v1/products', $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors('code');

        $payload['code'] = 'adn-product';

        $this->withToken($token)->postJson('/api/v1/products', $payload)->assertCreated();
        $this->withToken($token)
            ->postJson('/api/v1/products', $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors('code');
    }

    public function test_base_product_bootstrap_includes_fidelidad_without_inventing_plans(): void
    {
        $this->artisan('master:catalog:seed-products')->assertExitCode(0);

        $fidelidad = SoftwareProduct::query()
            ->where('code', 'adn-fidelidad')
            ->firstOrFail();
        $this->assertSame('ADN Fidelidad', $fidelidad->name);
        $this->assertSame('draft', $fidelidad->status);
        $this->assertSame(0, $fidelidad->plans()->count());

        $fidelidad->update(['status' => 'active']);
        $this->artisan('master:catalog:seed-products')->assertExitCode(0);

        $this->assertSame('active', $fidelidad->fresh()->status);
        $this->assertDatabaseCount('software_products', 2);
    }

    public function test_owner_can_manage_customers_and_duplicate_tax_identifiers_are_rejected(): void
    {
        $token = $this->ownerToken();

        $created = $this->withToken($token)
            ->postJson('/api/v1/customers', [
                'legal_name' => 'ADN Publicidad',
                'trade_name' => 'ADN',
                'email' => 'VENTAS@ADN.HN',
                'tax_identifier' => ' 08011999123456 ',
            ])->assertCreated()
            ->assertJsonPath('data.email', 'ventas@adn.hn');

        $this->withToken($token)
            ->postJson('/api/v1/customers', [
                'legal_name' => 'Otra empresa',
                'tax_identifier' => '08011999123456',
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('tax_identifier');

        $this->assertDatabaseCount('customers', 1);

        $publicId = $created->json('data.id');
        $this->withToken($token)
            ->getJson('/api/v1/customers/'.$publicId)
            ->assertOk()
            ->assertJsonPath('data.legal_name', 'ADN Publicidad');
    }

    public function test_database_rejects_an_instance_plan_from_another_product(): void
    {
        $product = SoftwareProduct::query()->create([
            'public_id' => (string) Str::uuid(),
            'code' => 'product-one',
            'name' => 'Product One',
        ]);
        $otherProduct = SoftwareProduct::query()->create([
            'public_id' => (string) Str::uuid(),
            'code' => 'product-two',
            'name' => 'Product Two',
        ]);
        $plan = ProductPlan::query()->create([
            'public_id' => (string) Str::uuid(),
            'product_id' => $product->id,
            'code' => 'basic',
            'name' => 'Basic',
            'price_cents' => 10000,
            'currency' => 'HNL',
            'billing_period' => 'monthly',
        ]);
        $customer = Customer::query()->create([
            'public_id' => (string) Str::uuid(),
            'legal_name' => 'Test Customer',
        ]);

        $this->expectException(QueryException::class);

        SoftwareInstance::query()->create([
            'public_id' => (string) Str::uuid(),
            'customer_id' => $customer->id,
            'product_id' => $otherProduct->id,
            'plan_id' => $plan->id,
            'name' => 'Invalid product-plan pairing',
        ]);
    }

    private function ownerToken(): string
    {
        $user = User::factory()->create();
        $ownerRole = Role::query()->create([
            'code' => 'owner',
            'name' => 'Owner',
            'is_active' => true,
        ]);
        $user->roles()->attach($ownerRole);

        return $user->createToken('test-client')->plainTextToken;
    }
}
