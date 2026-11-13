<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\Request;

abstract class AdminController extends Controller
{
    protected function authorizeOwner(Request $request): void
    {
        $user = $request->user();
        abort_unless($user instanceof User && $user->is_active
            && $user->roles()->where('code', 'owner')->where('is_active', true)->exists(), 403);
    }

    protected function lockAndAuthorizeOwner(Request $request): Role
    {
        // All administrative writes serialize on this row, including owner removal.
        $owner = Role::query()->where('code', 'owner')->lockForUpdate()->first();
        $request->user()?->refresh();
        $this->authorizeOwner($request);
        abort_unless($owner && $owner->is_active, 403);

        return $owner;
    }
}
