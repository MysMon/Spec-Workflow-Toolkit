---
name: php
description: PHP development patterns, tooling, and best practices. Use when working on PHP projects, Laravel/Symfony backends, or WordPress development.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
model: sonnet
user-invocable: true
---

# PHP Development

Comprehensive patterns and practices for modern PHP development.

## Project Setup

### Modern PHP Project Structure

```
my-project/
├── app/                    # Application code
│   ├── Http/
│   │   ├── Controllers/
│   │   └── Middleware/
│   ├── Models/
│   ├── Services/
│   └── Repositories/
├── config/                 # Configuration files
├── database/
│   └── migrations/
├── public/                 # Web root
│   └── index.php
├── resources/
│   └── views/
├── routes/
├── storage/
├── tests/
│   ├── Unit/
│   └── Feature/
├── vendor/                 # Composer dependencies
├── composer.json
├── composer.lock
├── phpunit.xml
└── .php-cs-fixer.php
```

### Composer Configuration

```json
{
    "name": "vendor/project",
    "description": "Project description",
    "type": "project",
    "require": {
        "php": "^8.2",
        "laravel/framework": "^11.0"
    },
    "require-dev": {
        "phpunit/phpunit": "^11.0",
        "phpstan/phpstan": "^1.10",
        "laravel/pint": "^1.0"
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Tests\\": "tests/"
        }
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true
    }
}
```

## Type Safety

### Modern PHP Type Declarations

```php
<?php

declare(strict_types=1);

namespace App\Services;

readonly class UserService
{
    public function __construct(
        private UserRepository $repository,
        private LoggerInterface $logger,
    ) {}

    public function findById(string $id): ?User
    {
        return $this->repository->find($id);
    }

    /**
     * @param array<string, mixed> $data
     * @throws ValidationException
     */
    public function create(array $data): User
    {
        // Implementation
    }
}
```

### Union and Intersection Types

```php
// Union types
public function process(string|int $id): void { }

// Intersection types (PHP 8.1+)
public function save(Renderable&Stringable $item): void { }

// Nullable types
public function find(string $id): ?User { }

// Mixed type (avoid when possible)
public function log(mixed $data): void { }
```

### DTOs with Constructor Promotion

```php
<?php

declare(strict_types=1);

readonly class CreateUserDto
{
    public function __construct(
        public string $email,
        public string $name,
        public ?string $phone = null,
    ) {}

    public static function fromRequest(Request $request): self
    {
        return new self(
            email: $request->validated('email'),
            name: $request->validated('name'),
            phone: $request->validated('phone'),
        );
    }
}
```

## Code Style

### Naming Conventions

```php
// Classes: PascalCase
class UserRepository { }

// Interfaces: PascalCase (often with Interface suffix)
interface UserRepositoryInterface { }

// Methods: camelCase
public function getUserById(string $id): User { }

// Properties: camelCase
private string $firstName;

// Constants: SCREAMING_SNAKE_CASE
public const MAX_RETRIES = 3;

// Variables: camelCase
$userCount = 0;

// Files: PascalCase for classes, kebab-case for views
// UserRepository.php, user-profile.blade.php
```

### PSR-12 Standards

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Repositories\UserRepository;
use Psr\Log\LoggerInterface;

final class UserService
{
    public function __construct(
        private readonly UserRepository $repository,
        private readonly LoggerInterface $logger,
    ) {
    }

    public function process(string $id): bool
    {
        if (empty($id)) {
            return false;
        }

        return $this->repository->exists($id);
    }
}
```

## Error Handling

### Custom Exceptions

```php
<?php

declare(strict_types=1);

namespace App\Exceptions;

use Exception;

class DomainException extends Exception
{
    public function __construct(
        string $message,
        public readonly string $code,
        public readonly array $context = [],
    ) {
        parent::__construct($message);
    }
}

class UserNotFoundException extends DomainException
{
    public static function withId(string $id): self
    {
        return new self(
            message: "User not found",
            code: 'USER_NOT_FOUND',
            context: ['user_id' => $id],
        );
    }
}
```

### Result Pattern

```php
<?php

declare(strict_types=1);

/**
 * @template T
 * @template E
 */
readonly class Result
{
    private function __construct(
        public bool $isSuccess,
        public mixed $value = null,
        public mixed $error = null,
    ) {}

    /** @return Result<T, never> */
    public static function success(mixed $value): self
    {
        return new self(isSuccess: true, value: $value);
    }

    /** @return Result<never, E> */
    public static function failure(mixed $error): self
    {
        return new self(isSuccess: false, error: $error);
    }

    /** @param callable(T): mixed $onSuccess */
    public function map(callable $onSuccess): self
    {
        if (!$this->isSuccess) {
            return $this;
        }
        return self::success($onSuccess($this->value));
    }
}
```

## Testing

### PHPUnit Example

```php
<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Services\UserService;
use App\Repositories\UserRepository;
use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\Attributes\DataProvider;

class UserServiceTest extends TestCase
{
    private UserService $service;
    private UserRepository $repository;

    protected function setUp(): void
    {
        $this->repository = $this->createMock(UserRepository::class);
        $this->service = new UserService($this->repository);
    }

    #[Test]
    public function it_returns_user_when_found(): void
    {
        // Arrange
        $user = new User(id: '1', name: 'John');
        $this->repository
            ->method('find')
            ->with('1')
            ->willReturn($user);

        // Act
        $result = $this->service->findById('1');

        // Assert
        $this->assertNotNull($result);
        $this->assertSame('John', $result->name);
    }

    #[Test]
    #[DataProvider('invalidIdProvider')]
    public function it_throws_for_invalid_id(string $id): void
    {
        $this->expectException(InvalidArgumentException::class);

        $this->service->findById($id);
    }

    public static function invalidIdProvider(): array
    {
        return [
            'empty string' => [''],
            'whitespace' => ['   '],
        ];
    }
}
```

## Common Commands

```bash
# Composer
composer install
composer update
composer require package/name
composer require --dev package/name

# Artisan (Laravel)
php artisan serve
php artisan make:controller UserController
php artisan make:model User -mfc
php artisan migrate
php artisan migrate:fresh --seed
php artisan tinker

# Testing
./vendor/bin/phpunit
./vendor/bin/phpunit --filter testName
./vendor/bin/phpunit --coverage-html coverage

# Static Analysis
./vendor/bin/phpstan analyse
./vendor/bin/phpstan analyse --level=max

# Code Style
./vendor/bin/pint
./vendor/bin/php-cs-fixer fix
./vendor/bin/php-cs-fixer fix --dry-run

# Cache (Laravel)
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize
```

## Package Managers

| Task | Composer |
|------|----------|
| Install | `composer install` |
| Add package | `composer require vendor/package` |
| Add dev package | `composer require --dev vendor/package` |
| Update | `composer update` |
| Remove | `composer remove vendor/package` |
| Autoload | `composer dump-autoload` |

## Framework-Specific Patterns

For framework-specific guidance, see:
- [Laravel patterns](LARAVEL.md)
- [Symfony patterns](SYMFONY.md)
- [WordPress patterns](WORDPRESS.md)

## Rules

- ALWAYS use `declare(strict_types=1)`
- ALWAYS use typed properties and return types
- NEVER use global variables
- ALWAYS use dependency injection
- NEVER suppress errors with `@`
- ALWAYS use PSR-4 autoloading
- NEVER use `eval()` or dynamic includes
- ALWAYS use prepared statements for SQL
- ALWAYS validate and sanitize user input
- NEVER store secrets in code
