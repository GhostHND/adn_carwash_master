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
        Schema::create('monitoring_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('instance_id')->constrained('software_instances')->restrictOnDelete();
            $table->string('service_code', 80);
            $table->timestamp('observed_at')->index();
            $table->string('status', 24)->index();
            $table->json('details')->nullable();
            $table->index(['instance_id', 'observed_at']);
        });

        Schema::create('backup_jobs', function (Blueprint $table) {
            $table->id();
            $table->string('scope', 40);
            $table->foreignId('instance_id')->nullable()
                ->constrained('software_instances')->restrictOnDelete();
            $table->foreignId('requested_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status', 24)->default('requested')->index();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('integrity_verified_at')->nullable();
            $table->string('storage_reference')->nullable();
            $table->timestamps();
        });

        Schema::create('audit_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('actor_type', 40)->default('user');
            $table->string('action', 120);
            $table->string('resource_type', 120);
            $table->string('resource_id', 80)->nullable();
            $table->timestamp('occurred_at')->useCurrent()->index();
            $table->string('outcome', 24);
            $table->string('request_reference', 120)->nullable()->index();
            $table->json('metadata')->nullable();
            $table->index(['resource_type', 'resource_id']);
        });

        Schema::create('system_settings', function (Blueprint $table) {
            $table->id();
            $table->string('setting_key', 120)->unique();
            $table->json('setting_value');
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('system_settings');
        Schema::dropIfExists('audit_events');
        Schema::dropIfExists('backup_jobs');
        Schema::dropIfExists('monitoring_events');
    }
};
