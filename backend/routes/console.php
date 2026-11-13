<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command('fidelidad:sync')->everyMinute()->withoutOverlapping();
Schedule::command('billing:subscriptions:expire')->dailyAt('00:05')->withoutOverlapping();
Schedule::command('billing:charges:generate')->dailyAt('00:10')->withoutOverlapping();
