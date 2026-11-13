<?php

namespace App\Console\Commands;

use App\Support\MasterPermissionCatalog;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class SeedMasterPermissions extends Command
{
    protected $signature = 'master:permissions:seed';

    protected $description = 'Create the built-in Software Master permission catalogue';

    public function handle(): int
    {
        DB::transaction(fn () => MasterPermissionCatalog::seed());

        $this->info('Master permission catalogue is ready.');

        return self::SUCCESS;
    }
}
