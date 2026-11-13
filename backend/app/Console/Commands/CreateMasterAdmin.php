<?php

namespace App\Console\Commands;

use App\Models\Role;
use App\Models\User;
use App\Support\MasterPermissionCatalog;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class CreateMasterAdmin extends Command
{
    protected $signature = 'master:admin:create {--email=} {--name=}';

    protected $description = 'Create an administrator account without exposing its password in command history';

    public function handle(): int
    {
        $name = trim((string) ($this->option('name') ?? $this->ask('Administrator name')));
        $email = Str::lower(trim((string) ($this->option('email') ?? $this->ask('Administrator email'))));

        $validator = Validator::make(
            ['name' => $name, 'email' => $email],
            [
                'name' => ['required', 'string', 'max:255'],
                'email' => ['required', 'email', 'max:254', Rule::unique('users', 'email')],
            ],
        );

        if ($validator->fails()) {
            $this->error($validator->errors()->first());

            return self::FAILURE;
        }

        $password = $this->secret('Password (minimum 12 characters)');
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

        DB::transaction(function () use ($name, $email, $password): void {
            MasterPermissionCatalog::seed();

            $role = Role::query()->updateOrCreate(
                ['code' => 'owner'],
                ['name' => 'Owner', 'description' => 'Full administrative access.', 'is_active' => true],
            );

            $user = User::query()->create([
                'name' => $name,
                'email' => $email,
                'password' => $password,
                'is_active' => true,
            ]);
            $user->roles()->attach($role);
        });

        $this->info('Administrator account created.');

        return self::SUCCESS;
    }
}
