<?php

namespace App\Http\Middleware;

use App\Models\AuditEvent;
use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Throwable;

class AuditApiMutation
{
    public function handle(Request $request, Closure $next): Response
    {
        $actor = $request->user();

        if (! $actor instanceof User || ! in_array($request->method(), ['POST', 'PUT', 'PATCH', 'DELETE'], true)) {
            return $next($request);
        }

        try {
            return DB::transaction(function () use ($request, $next, $actor): Response {
                $response = $next($request);
                $this->record($request, $actor, $response->getStatusCode());

                return $response;
            });
        } catch (Throwable $exception) {
            $this->record(
                $request,
                $actor,
                $exception instanceof HttpExceptionInterface ? $exception->getStatusCode() : 500,
            );

            throw $exception;
        }
    }

    private function record(Request $request, User $actor, int $status): void
    {
        $route = $request->route();
        $resourceId = null;

        foreach ($route?->originalParameters() ?? [] as $name => $value) {
            if (in_array($name, ['product', 'customer', 'plan', 'instance', 'subscription', 'charge', 'payment'], true)
                && is_string($value) && Str::isUuid($value)) {
                $resourceId = $value;
            }
        }

        $reference = $request->header('X-Request-ID');
        if (! is_string($reference) || ! Str::isUuid($reference)) {
            $reference = (string) Str::uuid();
        }

        AuditEvent::query()->create([
            'actor_id' => $actor->getKey(),
            'actor_type' => 'user',
            'action' => $request->method(),
            'resource_type' => substr($route?->uri() ?? 'unknown', 0, 120),
            'resource_id' => $resourceId,
            'occurred_at' => now(),
            'outcome' => $status < 400 ? 'success' : 'failure',
            'request_reference' => $reference,
            'metadata' => ['http_status' => $status],
        ]);
    }
}
