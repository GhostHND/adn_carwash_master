<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->foreignId('instance_id')->constrained('software_instances')->restrictOnDelete();
            $table->string('status', 24)->default('draft')->index();
            $table->date('starts_on')->nullable();
            $table->date('ends_on')->nullable();
            $table->unsignedSmallInteger('grace_days')->default(0);
            $table->char('currency', 3);
            $table->timestamps();
            $table->index(['instance_id', 'status']);
        });

        Schema::create('subscription_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('subscription_id')->constrained()->restrictOnDelete();
            $table->string('concept');
            $table->unsignedBigInteger('amount_cents');
            $table->string('billing_frequency', 24);
            $table->date('effective_from');
            $table->date('effective_until')->nullable();
            $table->timestamps();
        });

        Schema::create('charges', function (Blueprint $table) {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->foreignId('subscription_id')->constrained()->restrictOnDelete();
            $table->string('concept');
            $table->date('due_date')->index();
            $table->unsignedBigInteger('amount_cents');
            $table->char('currency', 3);
            $table->string('status', 24)->default('draft')->index();
            $table->timestamp('issued_at')->nullable();
            $table->uuid('idempotency_key')->nullable()->unique();
            $table->timestamps();
            $table->index(['subscription_id', 'status']);
        });

        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->foreignId('customer_id')->constrained()->restrictOnDelete();
            $table->unsignedBigInteger('amount_cents');
            $table->char('currency', 3);
            $table->string('payment_method', 40);
            $table->string('external_reference')->nullable();
            $table->uuid('idempotency_key')->nullable()->unique();
            $table->string('confirmation_status', 24)->default('pending')->index();
            $table->timestamp('confirmed_at')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['customer_id', 'confirmation_status']);
        });

        Schema::create('payment_allocations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payment_id')->constrained()->restrictOnDelete();
            $table->foreignId('charge_id')->constrained()->restrictOnDelete();
            $table->unsignedBigInteger('amount_cents');
            $table->timestamps();
            $table->unique(['payment_id', 'charge_id']);
        });

        Schema::create('license_records', function (Blueprint $table) {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->foreignId('instance_id')->unique()
                ->constrained('software_instances')->restrictOnDelete();
            $table->string('status', 24)->default('pending')->index();
            $table->date('contract_valid_until')->nullable();
            $table->boolean('administrative_hold')->default(false);
            $table->timestamp('last_verified_at')->nullable();
            $table->timestamps();
        });

        Schema::create('license_authorizations', function (Blueprint $table) {
            $table->id();
            $table->uuid('authorization_id')->unique();
            $table->foreignId('instance_id')->constrained('software_instances')->restrictOnDelete();
            $table->timestamp('issued_at');
            $table->timestamp('expires_at')->index();
            $table->timestamp('revoked_at')->nullable();
            $table->json('payload');
            $table->text('signature');
            $table->string('signing_key_id', 80);
            $table->timestamps();
            $table->index(['instance_id', 'expires_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('license_authorizations');
        Schema::dropIfExists('license_records');
        Schema::dropIfExists('payment_allocations');
        Schema::dropIfExists('payments');
        Schema::dropIfExists('charges');
        Schema::dropIfExists('subscription_items');
        Schema::dropIfExists('subscriptions');
    }
};
