<?php

use App\Http\Controllers\Api\V1\AdminPermissionController;
use App\Http\Controllers\Api\V1\AdminRoleController;
use App\Http\Controllers\Api\V1\AdminUserController;
use App\Http\Controllers\Api\V1\AuditEventController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BillingController;
use App\Http\Controllers\Api\V1\CustomerController;
use App\Http\Controllers\Api\V1\FidelidadBusinessController;
use App\Http\Controllers\Api\V1\FidelidadIntegrationController;
use App\Http\Controllers\Api\V1\ProductPlanController;
use App\Http\Controllers\Api\V1\SoftwareInstanceController;
use App\Http\Controllers\Api\V1\SoftwareProductController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', static fn () => response()->json([
        'data' => ['status' => 'ok'],
    ]));

    Route::prefix('auth')->controller(AuthController::class)->group(function (): void {
        Route::post('/login', 'login')->middleware('throttle:master-auth');
        Route::post('/password/forgot', 'sendPasswordResetLink')
            ->middleware('throttle:master-auth');
        Route::post('/password/reset', 'resetPassword')
            ->middleware('throttle:master-auth');

        Route::middleware(['auth:sanctum', 'active', 'audit'])->group(function (): void {
            Route::get('/me', 'me');
            Route::post('/logout', 'logout');
        });
    });

    Route::middleware('fidelidad.signature')->get(
        '/integrations/{productCode}/subscriptions/{instancePublicId}',
        [FidelidadIntegrationController::class, 'show'],
    );

    Route::middleware(['auth:sanctum', 'active', 'audit'])->group(function (): void {
        Route::middleware('permission:users.manage')
            ->apiResource('users', AdminUserController::class)
            ->only(['index', 'store', 'show', 'update', 'destroy']);

        Route::middleware('permission:roles.manage')->group(function (): void {
            Route::apiResource('roles', AdminRoleController::class)
                ->only(['index', 'store', 'show', 'update', 'destroy']);
            Route::get('/permissions', [AdminPermissionController::class, 'index']);
        });

        Route::get('/audit-events', [AuditEventController::class, 'index'])
            ->middleware('permission:audit.view');

        Route::middleware('permission:products.manage')
            ->apiResource('products', SoftwareProductController::class)
            ->only(['index', 'store', 'show', 'update']);

        Route::middleware('permission:customers.manage')
            ->apiResource('customers', CustomerController::class)
            ->only(['index', 'store', 'show', 'update']);

        Route::middleware('permission:products.manage')
            ->apiResource('plans', ProductPlanController::class)
            ->only(['index', 'store', 'show', 'update']);

        Route::middleware('permission:instances.manage')
            ->apiResource('instances', SoftwareInstanceController::class)
            ->only(['index', 'store', 'show', 'update']);

        Route::middleware('permission:instances.manage')->group(function (): void {
            Route::post('/instances/{instance}/fidelidad/search', [FidelidadBusinessController::class, 'search']);
            Route::post('/instances/{instance}/fidelidad/link', [FidelidadBusinessController::class, 'link']);
        });

        Route::middleware('permission:subscriptions.manage')->controller(BillingController::class)->group(function (): void {
            Route::get('/subscriptions', 'subscriptions');
            Route::post('/subscriptions', 'storeSubscription');
            Route::get('/subscriptions/{subscription}', 'showSubscription');
            Route::patch('/subscriptions/{subscription}', 'updateSubscription');
            Route::post('/subscriptions/{subscription}/activate', 'activateSubscription');
            Route::post('/subscriptions/{subscription}/cancel', 'cancelSubscription');
            Route::post('/subscriptions/{subscription}/initial-charge', 'createInitialCharge');
            Route::put('/subscriptions/{subscription}/items', 'replaceItems');
            Route::get('/charges', 'charges');
            Route::post('/charges', 'storeCharge');
            Route::get('/charges/{charge}', 'showCharge');
            Route::post('/charges/{charge}/issue', 'issueCharge');
            Route::post('/charges/{charge}/void', 'voidCharge');
        });

        Route::middleware('permission:payments.manage')->controller(BillingController::class)->group(function (): void {
            Route::get('/payments', 'payments');
            Route::post('/payments', 'storePayment');
            Route::get('/payments/{payment}', 'showPayment');
            Route::post('/payments/{payment}/confirm', 'confirmPayment');
            Route::post('/payments/{payment}/allocations', 'allocatePayment');
        });
    });
});
