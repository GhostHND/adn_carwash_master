<?php

namespace Tests\Feature;

use App\Models\PlanFeature;
use App\Models\ProductPlan;
use App\Models\Role;
use App\Models\SoftwareProduct;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class MasterPlanApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_can_create_and_list_a_draft_plan_without_inventing_a_price(): void
    {
        $token = $this->ownerToken();
        $product = $this->createProduct('adn-carwash');

        $created = $this->withToken($token)
            ->postJson('/api/v1/plans', [
                'product_code' => $product->code,
                'code' => 'basic',
                'name' => 'Básico',
            ])
            ->assertCreated()
            ->assertJsonPath('data.status', 'draft')
            ->assertJsonPath('data.price_cents', null)
            ->assertJsonPath('data.currency', null)
            ->assertJsonPath('data.billing_period', null);

        $this->withToken($token)
            ->getJson('/api/v1/plans?product_code=adn-carwash')
            ->assertOk()
            ->assertJsonPath('data.0.id', $created->json('data.id'));

        $this->assertDatabaseCount('product_plans', 1);
    }

    public function test_plan_must_have_commercial_details_and_features_before_activation(): void
    {
        $token = $this->ownerToken();
        $product = $this->createProduct('adn-fidelidad');
        $plan = ProductPlan::query()->create([
            'public_id' => (string) Str::uuid(),
            'product_id' => $product->id,
            'code' => 'starter',
            'name' => 'Starter',
        ]);

        $this->withToken($token)
            ->patchJson('/api/v1/plans/'.$plan->public_id, ['status' => 'active'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['price_cents', 'currency', 'billing_period', 'features', 'status']);
    }

    public function test_active_plan_persists_its_features_and_product_isolation(): void
    {
        $token = $this->ownerToken();
        $product = $this->createProduct('adn-fidelidad', 'active');

        $created = $this->withToken($token)
            ->postJson('/api/v1/plans', [
                'product_code' => $product->code,
                'code' => 'starter',
                'name' => 'Starter',
                'price_cents' => 10000,
                'currency' => 'hnl',
                'billing_period' => 'monthly',
                'status' => 'active',
                'features' => [
                    ['feature_code' => 'wallet.google', 'enabled' => true, 'limit_value' => 100],
                ],
            ])
            ->assertCreated()
            ->assertJsonPath('data.status', 'active')
            ->assertJsonPath('data.currency', 'HNL')
            ->assertJsonPath('data.features.0.feature_code', 'wallet.google')
            ->assertJsonPath('data.features.0.limit_value', 100);

        $otherProduct = $this->createProduct('adn-carwash');
        $this->withToken($token)
            ->postJson('/api/v1/plans', [
                'product_code' => $otherProduct->code,
                'code' => 'starter',
                'name' => 'CarWash Starter',
            ])
            ->assertCreated();

        $this->assertDatabaseCount('product_plans', 2);
        $this->assertNotSame($created->json('data.product_id'), $otherProduct->public_id);
    }

    public function test_activating_a_draft_product_allows_its_complete_plan_to_be_activated(): void
    {
        $token = $this->ownerToken();
        $product = $this->createProduct('adn-fidelidad');
        $payload = [
            'product_code' => $product->code,
            'code' => 'starter',
            'name' => 'Starter',
            'price_cents' => 10000,
            'currency' => 'HNL',
            'billing_period' => 'monthly',
            'status' => 'active',
            'features' => [['feature_code' => 'reports', 'enabled' => true]],
        ];

        $this->withToken($token)->postJson('/api/v1/plans', $payload)
            ->assertUnprocessable()->assertJsonValidationErrors('product_code');
        $this->withToken($token)->patchJson('/api/v1/products/'.$product->public_id, ['status' => 'active'])
            ->assertOk()->assertJsonPath('data.status', 'active');
        $this->withToken($token)->postJson('/api/v1/plans', $payload)
            ->assertCreated()->assertJsonPath('data.status', 'active');
    }

    public function test_updating_an_active_plan_keeps_its_existing_feature_limits(): void
    {
        $token = $this->ownerToken();
        $product = $this->createProduct('adn-fidelidad', 'active');
        $plan = $product->plans()->create([
            'public_id' => (string) Str::uuid(),
            'code' => 'starter',
            'name' => 'Starter',
            'price_cents' => 10000,
            'currency' => 'HNL',
            'billing_period' => 'monthly',
            'status' => 'active',
        ]);
        PlanFeature::query()->create([
            'plan_id' => $plan->id,
            'feature_code' => 'wallet.google',
            'enabled' => true,
            'limit_value' => 100,
        ]);

        $this->withToken($token)
            ->patchJson('/api/v1/plans/'.$plan->public_id, ['name' => 'Starter Plus'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Starter Plus')
            ->assertJsonPath('data.features.0.limit_value', 100);
    }

    private function createProduct(string $code, string $status = 'draft'): SoftwareProduct
    {
        return SoftwareProduct::query()->create([
            'public_id' => (string) Str::uuid(),
            'code' => $code,
            'name' => $code,
            'status' => $status,
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
