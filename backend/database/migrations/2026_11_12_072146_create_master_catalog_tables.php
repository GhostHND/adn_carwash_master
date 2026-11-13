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
        Schema::create('software_products', function (Blueprint $table) {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->string('code', 80)->unique();
            $table->string('name');
            $table->string('category')->nullable();
            $table->text('description')->nullable();
            $table->string('status', 24)->default('draft')->index();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('product_versions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained('software_products')->restrictOnDelete();
            $table->string('version', 40);
            $table->text('release_notes')->nullable();
            $table->string('status', 24)->default('draft')->index();
            $table->timestamp('released_at')->nullable();
            $table->timestamps();
            $table->unique(['product_id', 'version']);
        });

        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->string('legal_name');
            $table->string('trade_name')->nullable();
            $table->string('email', 254)->nullable()->index();
            $table->string('phone', 40)->nullable();
            $table->string('tax_identifier', 80)->nullable()->unique();
            $table->string('status', 24)->default('active')->index();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('product_plans', function (Blueprint $table) {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->foreignId('product_id')->constrained('software_products')->restrictOnDelete();
            $table->string('code', 80);
            $table->string('name');
            $table->unsignedBigInteger('price_cents');
            $table->char('currency', 3);
            $table->string('billing_period', 24);
            $table->string('status', 24)->default('draft')->index();
            $table->timestamp('available_from')->nullable();
            $table->timestamp('available_until')->nullable();
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['product_id', 'code']);
            $table->unique(['product_id', 'id']);
        });

        Schema::create('plan_features', function (Blueprint $table) {
            $table->id();
            $table->foreignId('plan_id')->constrained('product_plans')->cascadeOnDelete();
            $table->string('feature_code', 120);
            $table->boolean('enabled')->default(true);
            $table->json('limit_value')->nullable();
            $table->timestamps();
            $table->unique(['plan_id', 'feature_code']);
        });

        Schema::create('software_instances', function (Blueprint $table) {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->foreignId('customer_id')->constrained()->restrictOnDelete();
            $table->foreignId('product_id')->constrained('software_products')->restrictOnDelete();
            $table->unsignedBigInteger('plan_id')->nullable();
            $table->string('name');
            $table->string('domain')->nullable()->index();
            $table->string('environment', 24)->default('production');
            $table->string('provisioning_status', 24)->default('draft')->index();
            $table->string('administrative_status', 24)->default('pending')->index();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();
            $table->index(['customer_id', 'product_id']);
            $table->foreign(['product_id', 'plan_id'])
                ->references(['product_id', 'id'])
                ->on('product_plans')
                ->restrictOnDelete();
        });

        Schema::create('instance_infrastructure', function (Blueprint $table) {
            $table->id();
            $table->foreignId('instance_id')->unique()
                ->constrained('software_instances')->restrictOnDelete();
            $table->string('hosting_provider')->nullable();
            $table->string('hosting_reference')->nullable();
            $table->string('domain_provider')->nullable();
            $table->string('domain_reference')->nullable();
            $table->date('domain_renewal_date')->nullable();
            $table->date('hosting_renewal_date')->nullable();
            $table->char('currency', 3);
            $table->unsignedBigInteger('hosting_cost_cents')->default(0);
            $table->unsignedBigInteger('hosting_charge_cents')->default(0);
            $table->unsignedBigInteger('domain_cost_cents')->default(0);
            $table->unsignedBigInteger('domain_charge_cents')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('instance_infrastructure');
        Schema::dropIfExists('software_instances');
        Schema::dropIfExists('plan_features');
        Schema::dropIfExists('product_plans');
        Schema::dropIfExists('customers');
        Schema::dropIfExists('product_versions');
        Schema::dropIfExists('software_products');
    }
};
