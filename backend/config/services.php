<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'fidelidad' => [
        'api_url' => env('FIDELIDAD_API_URL'),
        'product_code' => env('FIDELIDAD_PRODUCT_CODE', 'adn-fidelidad'),
        'webhook_secret' => env('FIDELIDAD_WEBHOOK_SECRET'),
        'link_secret' => env('FIDELIDAD_LINK_SECRET'),
        'api_key' => env('FIDELIDAD_API_KEY'),
        'api_secret' => env('FIDELIDAD_API_SECRET'),
        'max_clock_skew' => (int) env('FIDELIDAD_MAX_CLOCK_SKEW', 300),
    ],

];
