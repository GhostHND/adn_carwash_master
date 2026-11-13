<?php

namespace App\Console\Commands;

use App\Models\SoftwareProduct;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

class SeedMasterProducts extends Command
{
    protected $signature = 'master:catalog:seed-products';

    protected $description = 'Create base ADN Publicidad products without commercial plans or prices';

    public function handle(): int
    {
        $products = [
            [
                'code' => 'adn-carwash',
                'name' => 'ADN CarWash',
                'category' => 'Gestión de autolavados',
                'description' => 'Sistema de administración para negocios de lavado y cuidado de vehículos.',
            ],
            [
                'code' => 'adn-fidelidad',
                'name' => 'ADN Fidelidad',
                'category' => 'Fidelización de clientes',
                'description' => 'Sistema de programas de fidelidad para clientes de ADN Publicidad.',
            ],
        ];

        foreach ($products as $product) {
            $record = SoftwareProduct::query()->firstOrCreate(
                ['code' => $product['code']],
                [
                    ...$product,
                    'public_id' => (string) Str::uuid(),
                    'status' => 'draft',
                ],
            );
            $this->line(($record->wasRecentlyCreated ? 'Creado: ' : 'Ya existe: ').$record->code);
        }

        $this->info('Catálogo base verificado. No se crearon planes ni precios.');

        return self::SUCCESS;
    }
}
