<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class ResetMasterAdminPassword extends Command
{
    protected $signature = 'master:admin:password-reset {--email=}';

    protected $description = 'Reset an administrator password without exposing it in command history';

    public function handle(): int
    {
        $email = Str::lower(trim((string) ($this->option('email') ?? $this->ask('Administrator email'))));
        $emailValidator = Validator::make(
            ['email' => $email],
            ['email' => ['required', 'email', 'max:254']],
        );

        if ($emailValidator->fails()) {
            $this->error($emailValidator->errors()->first());

            return self::FAILURE;
        }

        $user = User::query()->where('email', $email)->first();

        if ($user === null) {
            $this->error('No administrator account with that email exists in the configured database.');

            return self::FAILURE;
        }

        if (! $user->is_active) {
            $this->error('The account is inactive. Resetting its password will not enable it.');

            return self::FAILURE;
        }

        $password = $this->secret('New password (minimum 12 characters)');
        $confirmation = $this->secret('Confirm password');
        $passwordValidator = Validator::make(
            ['password' => $password, 'confirmation' => $confirmation],
            [
                'password' => ['required', 'string', 'min:12'],
                'confirmation' => ['required', 'same:password'],
            ],
        );

        if ($passwordValidator->fails()) {
            $this->error($passwordValidator->errors()->first());

            return self::FAILURE;
        }

        DB::transaction(function () use ($user, $password): void {
            $user->forceFill([
                'password' => $password,
                'remember_token' => Str::random(60),
            ])->save();
            $user->tokens()->delete();
        });

        $this->info('Administrator password reset successfully. Existing access tokens were revoked.');

        return self::SUCCESS;
    }
}
