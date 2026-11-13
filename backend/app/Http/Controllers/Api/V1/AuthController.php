<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Auth\Passwords\PasswordBroker;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'string', 'email', 'max:254'],
            'password' => ['required', 'string', 'max:4096'],
            'device_name' => ['nullable', 'string', 'max:80'],
        ]);

        $user = User::query()
            ->where('email', Str::lower(trim($credentials['email'])))
            ->first();

        if (
            $user === null
            || ! $user->is_active
            || ! Hash::check($credentials['password'], $user->password)
        ) {
            return response()->json([
                'message' => 'Las credenciales no son válidas.',
            ], 401);
        }

        $expiresAt = now()->addMinutes((int) config('sanctum.expiration', 480));
        $token = $user->createToken(
            $credentials['device_name'] ?? 'master-client',
            ['*'],
            $expiresAt,
        );

        return response()->json([
            'data' => [
                'token' => $token->plainTextToken,
                'token_type' => 'Bearer',
                'expires_at' => $expiresAt->toISOString(),
                'user' => $this->userData($user),
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(status: 204);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'data' => [
                'user' => $this->userData($request->user()),
            ],
        ]);
    }

    public function sendPasswordResetLink(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email', 'max:254'],
        ]);

        $status = Password::sendResetLink([
            'email' => Str::lower(trim($validated['email'])),
        ]);

        if ($status === PasswordBroker::RESET_THROTTLED) {
            return response()->json([
                'message' => 'Espera antes de solicitar otro enlace.',
            ], 429);
        }

        return response()->json([
            'message' => 'Si la cuenta existe, se enviarán instrucciones para restablecer la contraseña.',
        ]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'string', 'email', 'max:254'],
            'token' => ['required', 'string'],
            'password' => ['required', 'string', 'min:12', 'confirmed'],
        ]);

        $status = Password::reset(
            [
                'email' => Str::lower(trim($credentials['email'])),
                'token' => $credentials['token'],
                'password' => $credentials['password'],
                'password_confirmation' => $request->input('password_confirmation'),
            ],
            function (User $user, string $password): void {
                DB::transaction(function () use ($user, $password): void {
                    $user->forceFill([
                        'password' => $password,
                        'remember_token' => Str::random(60),
                    ])->save();
                    $user->tokens()->delete();
                    event(new PasswordReset($user));
                });
            },
        );

        if ($status !== PasswordBroker::PASSWORD_RESET) {
            return response()->json([
                'message' => 'El enlace de restablecimiento no es válido o venció.',
            ], 422);
        }

        return response()->json([
            'message' => 'La contraseña se restableció correctamente.',
        ]);
    }

    /**
     * @return array{id: int, name: string, email: string}
     */
    private function userData(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
        ];
    }
}
