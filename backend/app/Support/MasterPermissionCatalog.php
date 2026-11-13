<?php

namespace App\Support;

use App\Models\Permission;

class MasterPermissionCatalog
{
    public static function seed(): void
    {
        foreach ([
            'products.manage' => 'Manage software products and plans.',
            'customers.manage' => 'Manage customers.',
            'instances.manage' => 'Manage software instances.',
            'subscriptions.manage' => 'Manage subscriptions and charges.',
            'payments.manage' => 'Manage payments and allocations.',
            'users.manage' => 'Manage user accounts.',
            'roles.manage' => 'Manage roles and permission assignments.',
            'audit.view' => 'View the immutable administrative audit trail.',
        ] as $code => $description) {
            Permission::query()->firstOrCreate(['code' => $code], ['description' => $description]);
        }
    }
}
