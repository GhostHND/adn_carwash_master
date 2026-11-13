<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;

class FidelidadBusinessLinkService
{
    public function search(string $query): array
    {
        $businesses = $this->request('/api/v1/master/businesses/search', ['query' => $query]);
        if (! array_is_list($businesses) || count($businesses) > 20) {
            throw new HttpException(502, 'La respuesta de Fidelidad no es válida.');
        }
        foreach ($businesses as $business) {
            if (! is_array($business) || ! is_string($business['uuid'] ?? null) || ! Str::isUuid($business['uuid'])
                || ! is_string($business['name'] ?? null) || ! array_key_exists('master_business_id', $business)
                || ($business['master_business_id'] !== null && (! is_string($business['master_business_id']) || mb_strlen($business['master_business_id']) > 100))) {
                throw new HttpException(502, 'La respuesta de Fidelidad no es válida.');
            }
        }

        return $businesses;
    }

    public function link(string $businessUuid, string $instanceUuid): array
    {
        $data = $this->request('/api/v1/master/businesses/link', [
            'business_uuid' => $businessUuid,
            'master_business_id' => $instanceUuid,
        ]);
        if (($data['uuid'] ?? null) !== $businessUuid || ($data['master_business_id'] ?? null) !== $instanceUuid) {
            throw new HttpException(502, 'Fidelidad no confirmó la vinculación solicitada.');
        }

        return $data;
    }

    private function request(string $path, array $payload): array
    {
        $base = rtrim((string) config('services.fidelidad.api_url'), '/');
        $secret = (string) config('services.fidelidad.link_secret');
        $parts = parse_url($base);
        $scheme = is_array($parts) ? ($parts['scheme'] ?? '') : '';
        $host = is_array($parts) ? ($parts['host'] ?? '') : '';
        if ($host === '' || ! ($scheme === 'https' || ($scheme === 'http' && in_array($host, ['127.0.0.1', 'localhost'], true)))
            || ! empty($parts['path']) || isset($parts['query']) || isset($parts['fragment'])
            || isset($parts['user']) || isset($parts['pass']) || strlen($secret) < 32) {
            throw new HttpException(503, 'Configura la URL de Fidelidad y el secreto de vinculación antes de continuar.');
        }

        $body = json_encode($payload, JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        $timestamp = (string) now()->timestamp;
        $key = (string) Str::uuid();
        $signature = hash_hmac('sha256', "POST\n{$path}\n{$timestamp}\n{$key}\n{$body}", $secret);
        try {
            $response = Http::acceptJson()
                ->timeout(15)
                ->withOptions(['allow_redirects' => false])
                ->withHeaders([
                    'X-ADN-Timestamp' => $timestamp,
                    'X-ADN-Idempotency-Key' => $key,
                    'X-ADN-Signature' => $signature,
                ])
                ->withBody($body, 'application/json')
                ->post($base.$path);
        } catch (ConnectionException $exception) {
            report($exception);
            throw new HttpException(503, 'No se pudo conectar con Fidelidad. Inténtalo de nuevo.');
        }

        if ($response->status() === 422) {
            $errors = $response->json('errors');
            $message = null;
            if (is_array($errors)) {
                foreach ($errors as $messages) {
                    if (is_array($messages) && is_string($messages[0] ?? null)) {
                        $message = $messages[0];
                        break;
                    }
                }
            }
            throw ValidationException::withMessages([
                'fidelidad' => $message ?: 'Fidelidad rechazó la solicitud.',
            ]);
        }
        if (! $response->successful()) {
            throw new HttpException(502, 'Fidelidad rechazó la solicitud (HTTP '.$response->status().').');
        }
        $data = $response->json('data');
        if (! is_array($data)) {
            throw new HttpException(502, 'La respuesta de Fidelidad no es válida.');
        }

        return $data;
    }
}
