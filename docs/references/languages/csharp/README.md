
# C# / .NET Development

Comprehensive patterns and practices for C# and .NET development.

## Project Setup

### Modern .NET Project Structure

```
MyProject/
├── src/
│   ├── MyProject.Api/           # ASP.NET Core Web API
│   ├── MyProject.Core/          # Domain/business logic
│   ├── MyProject.Infrastructure/ # Data access, external services
│   └── MyProject.Shared/        # Shared models, utilities
├── tests/
│   ├── MyProject.UnitTests/
│   └── MyProject.IntegrationTests/
├── MyProject.sln
├── Directory.Build.props        # Shared MSBuild properties
├── Directory.Packages.props     # Central package management
├── .editorconfig
└── global.json                  # SDK version pinning
```

### SDK Version Pinning (global.json)

```json
{
  "sdk": {
    "version": "8.0.100",
    "rollForward": "latestMinor"
  }
}
```

### Central Package Management

```xml
<!-- Directory.Packages.props -->
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="8.0.0" />
    <PackageVersion Include="Serilog" Version="3.1.1" />
  </ItemGroup>
</Project>
```

## Type Safety

### Nullable Reference Types

```csharp
// Enable in .csproj
<PropertyGroup>
  <Nullable>enable</Nullable>
</PropertyGroup>

// Usage
public class User
{
    public required string Id { get; init; }
    public required string Email { get; init; }
    public string? MiddleName { get; init; }  // Nullable
}
```

### Result Pattern

```csharp
public readonly record struct Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public Error? Error { get; }

    private Result(T value)
    {
        IsSuccess = true;
        Value = value;
        Error = null;
    }

    private Result(Error error)
    {
        IsSuccess = false;
        Value = default;
        Error = error;
    }

    public static Result<T> Success(T value) => new(value);
    public static Result<T> Failure(Error error) => new(error);

    public TResult Match<TResult>(
        Func<T, TResult> onSuccess,
        Func<Error, TResult> onFailure)
        => IsSuccess ? onSuccess(Value!) : onFailure(Error!);
}

public record Error(string Code, string Message);
```

## Code Style

### Naming Conventions

```csharp
// Interfaces: I prefix
public interface IUserRepository { }

// Classes, records, structs: PascalCase
public class UserService { }
public record UserDto(string Id, string Name);

// Methods: PascalCase
public async Task<User> GetUserAsync(string id) { }

// Properties: PascalCase
public string FirstName { get; set; }

// Private fields: _camelCase
private readonly ILogger<UserService> _logger;

// Parameters and locals: camelCase
public void Process(string userId)
{
    var result = DoSomething();
}

// Constants: PascalCase
public const int MaxRetries = 3;
```

### Modern C# Features

```csharp
// Primary constructors (C# 12)
public class UserService(IUserRepository repository, ILogger<UserService> logger)
{
    public async Task<User?> GetUserAsync(string id)
        => await repository.FindByIdAsync(id);
}

// Collection expressions (C# 12)
int[] numbers = [1, 2, 3, 4, 5];
List<string> names = ["Alice", "Bob", "Charlie"];

// Pattern matching
public decimal CalculateDiscount(Customer customer) => customer switch
{
    { IsPremium: true, YearsActive: > 5 } => 0.25m,
    { IsPremium: true } => 0.15m,
    { YearsActive: > 3 } => 0.10m,
    _ => 0m
};

// Required members
public class Order
{
    public required string Id { get; init; }
    public required decimal Total { get; init; }
}
```

## Dependency Injection

### Service Registration

```csharp
// Program.cs or Startup.cs
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IUserService, UserService>();

// With options
builder.Services.Configure<EmailOptions>(
    builder.Configuration.GetSection("Email"));

// Keyed services (C# 8)
builder.Services.AddKeyedScoped<ICache, RedisCache>("redis");
builder.Services.AddKeyedScoped<ICache, MemoryCache>("memory");
```

## Testing

### xUnit Example

```csharp
public class UserServiceTests
{
    private readonly Mock<IUserRepository> _repositoryMock;
    private readonly UserService _sut;

    public UserServiceTests()
    {
        _repositoryMock = new Mock<IUserRepository>();
        _sut = new UserService(_repositoryMock.Object);
    }

    [Fact]
    public async Task GetUserAsync_WithValidId_ReturnsUser()
    {
        // Arrange
        var user = new User { Id = "1", Name = "John" };
        _repositoryMock
            .Setup(r => r.FindByIdAsync("1"))
            .ReturnsAsync(user);

        // Act
        var result = await _sut.GetUserAsync("1");

        // Assert
        Assert.NotNull(result);
        Assert.Equal("John", result.Name);
    }

    [Theory]
    [InlineData("")]
    [InlineData(null)]
    public async Task GetUserAsync_WithInvalidId_ThrowsArgumentException(string? id)
    {
        // Act & Assert
        await Assert.ThrowsAsync<ArgumentException>(
            () => _sut.GetUserAsync(id!));
    }
}
```

## Common Commands

```bash
# Project management
dotnet new webapi -n MyProject
dotnet new sln
dotnet sln add src/MyProject

# Build
dotnet build
dotnet build --configuration Release

# Run
dotnet run
dotnet watch run  # Hot reload

# Test
dotnet test
dotnet test --collect:"XPlat Code Coverage"

# Publish
dotnet publish -c Release -o ./publish

# Packages
dotnet add package Serilog
dotnet list package --outdated
dotnet restore

# Formatting
dotnet format
dotnet format --verify-no-changes  # CI check

# EF Core migrations
dotnet ef migrations add InitialCreate
dotnet ef database update
```

## Package Managers

| Task | .NET CLI | Visual Studio |
|------|----------|---------------|
| Add package | `dotnet add package X` | NuGet Package Manager |
| Restore | `dotnet restore` | Automatic on build |
| Update | `dotnet outdated` (tool) | NuGet Package Manager |

## Framework-Specific Patterns

For framework-specific guidance, see:
- [ASP.NET Core patterns](ASPNET.md)
- [Entity Framework Core](EFCORE.md)
- [Blazor patterns](BLAZOR.md)

## Rules

- ALWAYS enable nullable reference types
- ALWAYS use async/await for I/O operations
- NEVER use `async void` (except event handlers)
- ALWAYS use `ILogger<T>` for logging
- NEVER catch `Exception` without rethrowing or handling
- ALWAYS use dependency injection
- NEVER use `new` for services with dependencies
- ALWAYS use records for DTOs
- ALWAYS validate input at API boundaries
