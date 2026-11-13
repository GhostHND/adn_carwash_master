<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use LogicException;

class AuditEventBuilder extends Builder
{
    public function update(array $values)
    {
        throw new LogicException('Audit events are immutable.');
    }

    public function upsert(array $values, $uniqueBy, $update = null)
    {
        throw new LogicException('Audit events are immutable.');
    }

    public function delete()
    {
        throw new LogicException('Audit events cannot be deleted.');
    }

    public function forceDelete()
    {
        throw new LogicException('Audit events cannot be deleted.');
    }

    public function increment($column, $amount = 1, array $extra = [])
    {
        throw new LogicException('Audit events are immutable.');
    }

    public function decrement($column, $amount = 1, array $extra = [])
    {
        throw new LogicException('Audit events are immutable.');
    }

    public function incrementEach(array $columns, array $extra = [])
    {
        throw new LogicException('Audit events are immutable.');
    }

    public function decrementEach(array $columns, array $extra = [])
    {
        throw new LogicException('Audit events are immutable.');
    }
}
