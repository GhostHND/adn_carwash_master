<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePermission
{
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $user = $request->user();

        if (! $user instanceof User || ! $user->hasPermission($permission)) {
            return response()->json([
                'message' => 'No tienes permiso para realizar esta operación.',
            ], 403);
        }

        return $next($request);
    }
}
