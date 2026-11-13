<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('software_instances', function (Blueprint $table): void {
            $table->dropIndex('software_instances_domain_index');
            $table->unique('domain', 'software_instances_domain_unique');
        });
    }

    public function down(): void
    {
        Schema::table('software_instances', function (Blueprint $table): void {
            $table->dropUnique('software_instances_domain_unique');
            $table->index('domain');
        });
    }
};
