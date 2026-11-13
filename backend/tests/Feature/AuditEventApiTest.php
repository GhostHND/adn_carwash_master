<?php

namespace Tests\Feature;

use App\Http\Controllers\Api\V1\AuditEventController;
use App\Http\Middleware\AuditApiMutation;
use App\Models\AuditEvent;
use App\Models\Customer;
use App\Models\Role;
use App\Models\User;
use Illuminate\Contracts\Http\Kernel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Str;
use LogicException;
use Tests\TestCase;

class AuditEventApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->app->make(Kernel::class)->addToMiddlewarePriorityBefore(SubstituteBindings::class, AuditApiMutation::class);
        Route::middleware(['api', 'auth:sanctum', AuditApiMutation::class])->prefix('api/v1/test-audit')->group(function (): void {
            Route::get('/events', [AuditEventController::class, 'index'])->middleware('permission:audit.view');
            Route::post('/mutate', function (Request $request) {
                $request->validate(['name' => 'required']);

                return response()->json(['ok' => true], 201);
            })->middleware('permission:products.manage');
            Route::post('/customers', function (Request $request) {
                return Customer::query()->create([
                    'public_id' => (string) Str::uuid(),
                    'legal_name' => $request->string('name')->toString(),
                    'created_by' => $request->user()->id,
                ]);
            });
            Route::patch('/customers/{customer}', fn (Customer $customer) => response()->noContent());
            Route::post('/token/{token}', fn () => response()->noContent());
            Route::post('/error', fn () => throw new \RuntimeException('private error'));
        });
    }

    public function test_mutations_are_recorded_after_response_without_sensitive_request_data(): void
    {
        $user = $this->owner();
        $reference = (string) Str::uuid();
        $this->actingAs($user, 'sanctum')->withHeader('X-Request-ID', $reference)
            ->postJson('/api/v1/test-audit/mutate?secret=query-secret', [
                'name' => 'ok',
                'password' => 'body-secret',
                'token' => 'token-secret',
            ])->assertCreated();

        $event = AuditEvent::query()->sole();
        $this->assertSame($user->id, $event->actor_id);
        $this->assertSame('POST', $event->action);
        $this->assertSame('api/v1/test-audit/mutate', $event->resource_type);
        $this->assertSame('success', $event->outcome);
        $this->assertSame(['http_status' => 201], $event->metadata);
        $this->assertSame($reference, $event->request_reference);
        $this->assertStringNotContainsString('secret', json_encode($event->toArray()));
    }

    public function test_failed_mutations_including_binding_failures_are_recorded(): void
    {
        $user = $this->owner();
        $missingId = (string) Str::uuid();
        $this->actingAs($user, 'sanctum')->withHeader('X-Request-ID', 'bad-secret');
        $this->postJson('/api/v1/test-audit/mutate', [])->assertUnprocessable();
        $this->patchJson('/api/v1/test-audit/customers/'.$missingId)->assertNotFound();
        $this->postJson('/api/v1/test-audit/error')->assertStatus(500);

        $events = AuditEvent::query()->orderBy('id')->get();
        $this->assertSame([422, 404, 500], $events->pluck('metadata.http_status')->all());
        $this->assertSame(['failure', 'failure', 'failure'], $events->pluck('outcome')->all());
        $this->assertSame($missingId, $events[1]->resource_id);
        $this->assertTrue(Str::isUuid($events[0]->request_reference));
    }

    public function test_unauthenticated_and_read_requests_are_not_recorded_and_denials_are(): void
    {
        $this->postJson('/api/v1/test-audit/mutate', ['name' => 'x'])->assertUnauthorized();
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum')->getJson('/api/v1/test-audit/events')->assertForbidden();
        $this->postJson('/api/v1/test-audit/mutate', ['name' => 'x'])->assertForbidden();
        $this->assertSame(403, AuditEvent::query()->sole()->metadata['http_status']);
    }

    public function test_audit_storage_failure_surfaces_and_rolls_back_mutation(): void
    {
        Event::listen('eloquent.creating: '.AuditEvent::class, fn () => throw new \RuntimeException('storage failed'));
        $this->actingAs($this->owner(), 'sanctum');
        $this->postJson('/api/v1/test-audit/customers', ['name' => 'Customer'])->assertStatus(500);
        $this->assertDatabaseCount('customers', 0);
        $this->assertDatabaseCount('audit_events', 0);
    }

    public function test_uuid_route_tokens_are_not_recorded_as_resource_ids(): void
    {
        $token = (string) Str::uuid();
        $this->actingAs($this->owner(), 'sanctum')->postJson('/api/v1/test-audit/token/'.$token)->assertNoContent();
        $event = AuditEvent::query()->sole();
        $this->assertNull($event->resource_id);
        $this->assertStringNotContainsString($token, json_encode($event->toArray()));
    }

    public function test_read_endpoint_is_paginated_and_permission_protected(): void
    {
        $user = $this->owner();
        $this->actingAs($user, 'sanctum');
        $this->postJson('/api/v1/test-audit/mutate', ['name' => 'x'])->assertCreated();
        $this->postJson('/api/v1/test-audit/mutate', [])->assertUnprocessable();
        $this->getJson('/api/v1/test-audit/events?per_page=1')
            ->assertOk()->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.http_status', 422)
            ->assertJsonPath('meta.total', 2)
            ->assertJsonMissingPath('data.0.metadata');
        $this->getJson('/api/v1/test-audit/events?per_page=101')->assertUnprocessable();
        $this->assertDatabaseCount('audit_events', 2);
    }

    public function test_model_and_bulk_mutations_cannot_change_existing_events(): void
    {
        $this->actingAs($this->owner(), 'sanctum')->postJson('/api/v1/test-audit/mutate', [])->assertUnprocessable();
        $event = AuditEvent::query()->sole();
        $operations = [
            fn () => $event->update(['outcome' => 'success']),
            fn () => $event->saveQuietly(),
            fn () => $event->deleteQuietly(),
            fn () => AuditEvent::query()->update(['outcome' => 'success']),
            fn () => AuditEvent::query()->delete(),
            fn () => AuditEvent::query()->upsert([['id' => $event->id, 'outcome' => 'success']], ['id']),
        ];

        foreach ($operations as $operation) {
            try {
                $operation();
                $this->fail('Audit events must be immutable.');
            } catch (LogicException) {
                $this->assertSame('failure', $event->fresh()->outcome);
            }
        }
    }

    private function owner(): User
    {
        $user = User::factory()->create();
        $role = Role::query()->create(['code' => 'owner', 'name' => 'Owner', 'is_active' => true]);
        $user->roles()->attach($role);

        return $user;
    }
}
