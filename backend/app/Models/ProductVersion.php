<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['product_id', 'version', 'release_notes', 'status', 'released_at'])]
class ProductVersion extends Model
{
    protected function casts(): array
    {
        return ['released_at' => 'datetime'];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(SoftwareProduct::class, 'product_id');
    }
}
