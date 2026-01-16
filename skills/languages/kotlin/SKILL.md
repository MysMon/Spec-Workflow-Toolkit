---
name: kotlin
description: Kotlin development patterns, tooling, and best practices. Use when working on Kotlin projects, Android applications, Ktor backends, or Spring Boot with Kotlin.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
model: sonnet
user-invocable: true
---

# Kotlin Development

Comprehensive patterns and practices for Kotlin development.

## Project Setup

### Gradle Kotlin DSL (build.gradle.kts)

```kotlin
plugins {
    kotlin("jvm") version "1.9.22"
    kotlin("plugin.spring") version "1.9.22"
    id("org.springframework.boot") version "3.2.0"
}

group = "com.example"
version = "1.0.0"

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("io.mockk:mockk:1.13.8")
    testImplementation("io.kotest:kotest-runner-junit5:5.8.0")
}

kotlin {
    jvmToolchain(21)
}
```

## Type Safety

### Null Safety

```kotlin
// Non-nullable by default
val name: String = "John"

// Nullable type
val middleName: String? = null

// Safe call operator
val length = middleName?.length

// Elvis operator
val displayName = middleName ?: "Unknown"

// Not-null assertion (use sparingly)
val definitelyNotNull = middleName!!

// Safe cast
val user = obj as? User

// Let for null handling
middleName?.let { name ->
    println("Middle name: $name")
}
```

### Sealed Classes and Result Pattern

```kotlin
sealed class Result<out T, out E> {
    data class Success<T>(val value: T) : Result<T, Nothing>()
    data class Failure<E>(val error: E) : Result<Nothing, E>()

    fun <R> map(transform: (T) -> R): Result<R, E> = when (this) {
        is Success -> Success(transform(value))
        is Failure -> this
    }

    fun <R> flatMap(transform: (T) -> Result<R, E>): Result<R, E> = when (this) {
        is Success -> transform(value)
        is Failure -> this
    }
}

// Usage
fun findUser(id: String): Result<User, UserError> {
    return repository.findById(id)
        ?.let { Result.Success(it) }
        ?: Result.Failure(UserError.NotFound(id))
}
```

### Data Classes

```kotlin
data class User(
    val id: String,
    val email: String,
    val name: String,
    val createdAt: Instant = Instant.now()
)

// Immutable copy with modifications
val updatedUser = user.copy(name = "New Name")
```

## Code Style

### Naming Conventions

```kotlin
// Classes, interfaces, objects: PascalCase
class UserService
interface UserRepository
object AppConfig

// Functions, properties, variables: camelCase
fun getUserById(id: String): User?
val currentUser: User
var isActive = true

// Constants: SCREAMING_SNAKE_CASE or camelCase
const val MAX_RETRIES = 3
val DEFAULT_TIMEOUT = Duration.ofSeconds(30)

// Backing properties
private val _users = mutableListOf<User>()
val users: List<User> get() = _users
```

### Idiomatic Kotlin

```kotlin
// Use expression body for simple functions
fun double(x: Int): Int = x * 2

// Use when expression
fun describe(obj: Any): String = when (obj) {
    is String -> "String of length ${obj.length}"
    is Int -> "Integer: $obj"
    is List<*> -> "List of ${obj.size} items"
    else -> "Unknown"
}

// Use scope functions
user?.run {
    println("Name: $name")
    println("Email: $email")
}

// Use extension functions
fun String.toSlug(): String =
    this.lowercase().replace(" ", "-")

// Use default arguments
fun createUser(
    email: String,
    name: String,
    role: Role = Role.MEMBER
): User = User(email = email, name = name, role = role)
```

## Coroutines

```kotlin
// Suspend function
suspend fun fetchUser(id: String): User {
    return withContext(Dispatchers.IO) {
        repository.findById(id)
    }
}

// Structured concurrency
suspend fun fetchUserWithPosts(userId: String): UserWithPosts {
    return coroutineScope {
        val userDeferred = async { userService.findById(userId) }
        val postsDeferred = async { postService.findByUserId(userId) }

        UserWithPosts(
            user = userDeferred.await(),
            posts = postsDeferred.await()
        )
    }
}

// Flow for streams
fun observeUsers(): Flow<User> = flow {
    while (true) {
        emit(repository.getLatestUser())
        delay(1000)
    }
}
```

## Testing

### Kotest Example

```kotlin
class UserServiceTest : FunSpec({
    val repository = mockk<UserRepository>()
    val service = UserService(repository)

    test("findById returns user when found") {
        // Arrange
        val user = User(id = "1", email = "john@example.com", name = "John")
        every { repository.findById("1") } returns user

        // Act
        val result = service.findById("1")

        // Assert
        result shouldBe Result.Success(user)
    }

    test("findById returns failure when not found") {
        every { repository.findById("999") } returns null

        val result = service.findById("999")

        result.shouldBeInstanceOf<Result.Failure<UserError.NotFound>>()
    }
})
```

## Common Commands

```bash
# Gradle
./gradlew build
./gradlew test
./gradlew bootRun  # Spring Boot
./gradlew clean

# Maven (if using)
mvn clean install
mvn test
mvn spring-boot:run

# Kotlin compiler
kotlinc Main.kt -include-runtime -d main.jar
kotlin main.jar

# Formatting
./gradlew ktlintFormat
./gradlew detekt
```

## Build Tools

| Task | Gradle | Maven |
|------|--------|-------|
| Build | `./gradlew build` | `mvn package` |
| Test | `./gradlew test` | `mvn test` |
| Run | `./gradlew run` | `mvn exec:java` |
| Clean | `./gradlew clean` | `mvn clean` |

## Framework-Specific Patterns

For framework-specific guidance, see:
- [Spring Boot patterns](SPRING.md)
- [Ktor patterns](KTOR.md)
- [Android patterns](ANDROID.md)

## Rules

- ALWAYS use immutable data (val over var)
- ALWAYS leverage null safety
- NEVER use `!!` without explicit reason
- ALWAYS use data classes for DTOs
- NEVER block coroutine threads
- ALWAYS use structured concurrency
- NEVER ignore exceptions
- ALWAYS prefer extension functions over utility classes
- ALWAYS use sealed classes for restricted hierarchies
