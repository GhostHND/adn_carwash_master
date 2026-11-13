<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fidelidad_integration_outbox', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('instance_id')->constrained('software_instances')->cascadeOnDelete();
            $table->string('event_id', 100)->unique();
            $table->unsignedBigInteger('event_version');
            $table->string('event_type', 60);
            $table->json('payload');
            $table->string('status', 24)->default('pending')->index();
            $table->unsignedSmallInteger('attempts')->default(0);
            $table->timestamp('next_attempt_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->unsignedSmallInteger('last_http_status')->nullable();
            $table->text('last_error')->nullable();
            $table->timestamps();
            $table->unique(['instance_id', 'event_version']);
            $table->index(['status', 'next_attempt_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fidelidad_integration_outbox');
    }
};
