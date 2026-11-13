<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('product_plans', function (Blueprint $table): void {
            $table->unsignedBigInteger('price_cents')->nullable()->change();
            $table->char('currency', 3)->nullable()->change();
            $table->string('billing_period', 24)->nullable()->change();
        });
    }

    public function down(): void
    {
        if (DB::table('product_plans')
            ->whereNull('price_cents')
            ->orWhereNull('currency')
            ->orWhereNull('billing_period')
            ->exists()) {
            throw new RuntimeException(
                'Cannot roll back while plans have undefined commercial values.',
            );
        }

        Schema::table('product_plans', function (Blueprint $table): void {
            $table->unsignedBigInteger('price_cents')->nullable(false)->change();
            $table->char('currency', 3)->nullable(false)->change();
            $table->string('billing_period', 24)->nullable(false)->change();
        });
    }
};
