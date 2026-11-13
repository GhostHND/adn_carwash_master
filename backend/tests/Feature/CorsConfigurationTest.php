<?php

namespace Tests\Feature;

use Tests\TestCase;

class CorsConfigurationTest extends TestCase
{
    public function test_browser_preflight_allows_a_configured_frontend_origin(): void
    {
        config([
            'cors.allowed_origins' => ['https://master.adnpublicidad.site'],
        ]);

        $this->withHeaders([
            'Origin' => 'https://master.adnpublicidad.site',
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'authorization,content-type',
        ])
            ->options('/api/v1/auth/login')
            ->assertNoContent()
            ->assertHeader('Access-Control-Allow-Origin', 'https://master.adnpublicidad.site');
    }

    public function test_browser_preflight_does_not_allow_an_unconfigured_origin(): void
    {
        config([
            'cors.allowed_origins' => ['https://master.adnpublicidad.site'],
        ]);
        $response = $this->withHeaders([
            'Origin' => 'https://untrusted.example',
            'Access-Control-Request-Method' => 'POST',
        ])
            ->options('/api/v1/auth/login')
            ->assertNoContent();

        $allowOrigin = $response->headers->get('Access-Control-Allow-Origin');
        $this->assertNotSame('https://untrusted.example', $allowOrigin);
        $this->assertNotSame('*', $allowOrigin);
    }
}
