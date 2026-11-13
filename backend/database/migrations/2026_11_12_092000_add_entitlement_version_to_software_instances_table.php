<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('software_instances', function (Blueprint $table): void {
            $table->unsignedBigInteger('entitlement_version')->default(0);
        });
    }

    public function down(): void
    {
        Schema::table('software_instances', function (Blueprint $table): void {
            $table->dropColumn('entitlement_version');
        });
    }
};
