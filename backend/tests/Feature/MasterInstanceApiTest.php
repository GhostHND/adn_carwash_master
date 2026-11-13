<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\ProductPlan;
use App\Models\Role;
use App\Models\SoftwareProduct;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class MasterInstanceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_can_create_and_list_an_instance_with_persisted_infrastructure(): void
    {
        $token = $this->ownerToken();
        [$customer, $product, $plan] = $this->createDirectory();

        $created = $this->withToken($token)
            ->postJson('/api/v1/instances', $this->instancePayload($customer, $product, $plan))
            ->assertCreated()
            ->assertJsonPath('data.name', 'Sede principal')
            ->assertJsonPath('data.customer.id', $customer->public_id)
            ->assertJsonPath('data.product.code', 'adn-carwash')
            ->assertJsonPath('data.plan.code', 'basic')
            ->assertJsonPath('data.provisioning_status', 'draft')
            ->assertJsonPath('data.infrastructure.currency', 'HNL')
            ->assertJsonPath('data.infrastructure.hosting_charge_cents', 25000);

        $instanceId = $created->json('data.id');
        $this->withToken($token)
            ->getJson('/api/v1/instances?product_code=adn-carwash')
            ->assertOk()
            ->assertJsonPath('data.0.id', $instanceId);

        $this->assertDatabaseCount('software_instances', 1);
        $this->assertDatabaseCount('instance_infrastructure', 1);
    }

    public function test_owner_can_update_instance_and_infrastructure_without_changing_its_links(): void
    {
        $token = $this->ownerToken();
        [$customer, $product, $plan] = $this->createDirectory();
        $created = $this->withToken($token)
            ->postJson('/api/v1/instances', $this->instancePayload($customer, $product, $plan))
            ->assertCreated();

        $this->withToken($token)
            ->patchJson('/api/v1/instances/'.$created->json('data.id'), [
                'name' => 'Sede secundaria',
                'domain' => 'secundaria.example.hn',
                'infrastructure' => [
                    'currency' => 'HNL',
                    'hosting_provider' => 'Proveedor actualizado',
                    'hosting_cost_cents' => 20000,
                    'hosting_charge_cents' => 30000,
                    'domain_cost_cents' => 70000,
                    'domain_charge_cents' => 100000,
                ],
            ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Sede secundaria')
            ->assertJsonPath('data.domain', 'secundaria.example.hn')
            ->assertJsonPath('data.customer.id', $customer->public_id)
            ->assertJsonPath('data.infrastructure.hosting_charge_cents', 30000);

        $this->assertDatabaseCount('software_instances', 1);
        $this->assertDatabaseCount('instance_infrastructure', 1);
    }

    public function test_instance_rejects_a_plan_from_another_product_and_duplicate_domains(): void
    {
        $token = $this->ownerToken();
        [$customer, $product, $plan] = $this->createDirectory();
        $otherProduct = $this->createProduct('adn-fidelidad');
        $otherPlan = $this->createPlan($otherProduct, 'starter');

        $this->withToken($token)
            ->postJson('/api/v1/instances', $this->instancePayload($customer, $product, $otherPlan))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('plan_id');

        $this->withToken($token)
            ->postJson('/api/v1/instances', $this->instancePayload($customer, $product, $plan))
            ->assertCreated();

        $this->withToken($token)
            ->postJson('/api/v1/instances', $this->instancePayload($customer, $product, $plan))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('domain');
    }

    private function createDirectory(): array
    {
        $customer = Customer::query()->create([
            'public_id' => (string) Str::uuid(),
            'legal_name' => 'ADN Test',
            'status' => 'active',
        ]);
        $product = $this->createProduct('adn-carwash');
        $plan = $this->createPlan($product, 'basic');

        return [$customer, $product, $plan];
    }

    private function createProduct(string $code): SoftwareProduct
    {
        return SoftwareProduct::query()->create([
            'public_id' => (string) Str::uuid(),
            'code' => $code,
            'name' => $code,
            'status' => 'draft',
        ]);
    }

    private function createPlan(SoftwareProduct $product, string $code): ProductPlan
    {
        return $product->plans()->create([
            'public_id' => (string) Str::uuid(),
            'code' => $code,
            'name' => $code,
        ]);
    }

    private function instancePayload(
        Customer $customer,
        SoftwareProduct $product,
        ProductPlan $plan,
    ): array {
        return [
            'customer_id' => $customer->public_id,
            'product_code' => $product->code,
            'plan_id' => $plan->public_id,
            'name' => 'Sede principal',
            'domain' => 'sede.example.hn',
            'infrastructure' => [
                'currency' => 'hnl',
                'hosting_provider' => 'Proveedor',
                'hosting_cost_cents' => 18000,
                'hosting_charge_cents' => 25000,
                'domain_cost_cents' => 70000,
                'domain_charge_cents' => 100000,
            ],
        ];
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
