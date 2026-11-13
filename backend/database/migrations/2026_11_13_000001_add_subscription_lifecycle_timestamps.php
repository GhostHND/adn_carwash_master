<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('subscriptions', function (Blueprint $table) {
            $table->timestamp('activated_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
        });

        DB::table('subscriptions')
            ->where('status', 'active')
            ->whereNull('activated_at')
            ->update(['activated_at' => now()]);
    }

    public function down(): void
    {
        Schema::table('subscriptions', function (Blueprint $table) {
            $table->dropColumn(['activated_at', 'cancelled_at']);
        });
    }
};
