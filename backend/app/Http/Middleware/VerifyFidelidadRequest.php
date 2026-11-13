<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class VerifyFidelidadRequest
{
    public function handle(Request $request, Closure $next): Response
    {
        $apiKey = (string) config('services.fidelidad.api_key');
        $secret = (string) config('services.fidelidad.api_secret');
        if ($apiKey === '' || $secret === '') {
            return response()->json(['message' => 'Integración con ADN Fidelidad sin configurar.'], 503);
        }

        $timestamp = trim((string) $request->header('X-ADN-Timestamp', ''));
        $idempotencyKey = trim((string) $request->header('X-ADN-Idempotency-Key', ''));
        $signature = strtolower(trim((string) $request->header('X-ADN-Signature', '')));
        $clockSkew = max(30, (int) config('services.fidelidad.max_clock_skew', 300));

        if (! preg_match('/^\d{10}$/', $timestamp)
            || $idempotencyKey === ''
            || mb_strlen($idempotencyKey) > 190
            || ! preg_match('/^[a-f0-9]{64}$/', $signature)
            || abs(now()->timestamp - (int) $timestamp) > $clockSkew) {
            return response()->json(['message' => 'Firma de integración inválida o vencida.'], 401);
        }

        $expected = hash_hmac(
            'sha256',
            $timestamp."\n".$idempotencyKey."\n".$request->getContent(),
            $secret,
        );
        if (! hash_equals($expected, $signature)) {
            return response()->json(['message' => 'Firma de integración inválida o vencida.'], 401);
        }

        $bearerToken = (string) $request->bearerToken();
        if ($bearerToken === '' || ! hash_equals($apiKey, $bearerToken)) {
            return response()->json(['message' => 'Credenciales de integración inválidas.'], 401);
        }

        return $next($request);
    }
}
