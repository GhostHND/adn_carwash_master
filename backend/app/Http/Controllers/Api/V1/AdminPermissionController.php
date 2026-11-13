<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Resources\PermissionResource;
use App\Models\Permission;
use Illuminate\Http\Request;

class AdminPermissionController extends AdminController
{
    public function index(Request $request)
    {
        $this->authorizeOwner($request);
        $data = $request->validate(['per_page' => ['sometimes', 'integer', 'min:1', 'max:100']]);

        return PermissionResource::collection(Permission::query()->orderBy('id')->paginate($data['per_page'] ?? 25));
    }
}
