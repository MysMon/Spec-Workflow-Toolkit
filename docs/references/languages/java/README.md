
# Java Development

Comprehensive patterns and practices for Java development.

## Project Structure

### Maven Layout

```
project/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/
│   │   │       ├── Application.java
│   │   │       ├── controller/
│   │   │       ├── service/
│   │   │       ├── repository/
│   │   │       └── model/
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/
│   └── test/
│       └── java/
├── pom.xml
└── README.md
```

### pom.xml Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project>
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
    </parent>

    <groupId>com.example</groupId>
    <artifactId>my-project</artifactId>
    <version>0.0.1-SNAPSHOT</version>

    <properties>
        <java.version>21</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
```

## Modern Java Features

### Records (Java 16+)

```java
// Immutable data classes
public record User(String id, String name, String email) {
    // Compact constructor for validation
    public User {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(name, "name must not be null");
    }
}

// Usage
var user = new User("1", "John", "john@example.com");
String name = user.name();  // Accessor
```

### Pattern Matching

```java
// instanceof pattern matching (Java 16+)
if (obj instanceof String s) {
    System.out.println(s.length());
}

// Switch pattern matching (Java 21+)
String result = switch (shape) {
    case Circle c -> "Circle with radius " + c.radius();
    case Rectangle r -> "Rectangle " + r.width() + "x" + r.height();
    case null -> "No shape";
    default -> "Unknown shape";
};
```

### Sealed Classes

```java
public sealed interface Result<T> permits Success, Failure {
}

public record Success<T>(T data) implements Result<T> {}
public record Failure<T>(String error) implements Result<T> {}
```

## Error Handling

### Custom Exceptions

```java
public class AppException extends RuntimeException {
    private final String code;

    public AppException(String message, String code) {
        super(message);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}

public class NotFoundException extends AppException {
    public NotFoundException(String resource, String id) {
        super(resource + " with id " + id + " not found", "NOT_FOUND");
    }
}
```

### Result Type

```java
public sealed interface Result<T> permits Result.Success, Result.Failure {

    record Success<T>(T data) implements Result<T> {}
    record Failure<T>(AppException error) implements Result<T> {}

    static <T> Result<T> success(T data) {
        return new Success<>(data);
    }

    static <T> Result<T> failure(AppException error) {
        return new Failure<>(error);
    }

    default T getOrThrow() {
        return switch (this) {
            case Success<T> s -> s.data();
            case Failure<T> f -> throw f.error();
        };
    }
}
```

## Spring Boot Patterns

### Controller

```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUser(@PathVariable String id) {
        return userService.findById(id)
            .map(UserResponse::from)
            .map(ResponseEntity::ok)
            .orElseThrow(() -> new NotFoundException("User", id));
    }

    @PostMapping
    public ResponseEntity<UserResponse> createUser(
            @Valid @RequestBody CreateUserRequest request) {
        User user = userService.create(request);
        return ResponseEntity
            .created(URI.create("/api/v1/users/" + user.getId()))
            .body(UserResponse.from(user));
    }
}
```

### Service

```java
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;

    public Optional<User> findById(String id) {
        return userRepository.findById(id);
    }

    @Transactional
    public User create(CreateUserRequest request) {
        var user = User.builder()
            .name(request.name())
            .email(request.email())
            .build();
        return userRepository.save(user);
    }
}
```

## Testing

### JUnit 5

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    @Test
    void findById_shouldReturnUser_whenExists() {
        // Arrange
        var user = new User("1", "John");
        when(userRepository.findById("1")).thenReturn(Optional.of(user));

        // Act
        var result = userService.findById("1");

        // Assert
        assertThat(result).isPresent();
        assertThat(result.get().getName()).isEqualTo("John");
    }

    @Test
    void findById_shouldReturnEmpty_whenNotExists() {
        // Arrange
        when(userRepository.findById("999")).thenReturn(Optional.empty());

        // Act
        var result = userService.findById("999");

        // Assert
        assertThat(result).isEmpty();
    }
}
```

## Common Commands

```bash
# Maven
mvn clean install
mvn test
mvn spring-boot:run
mvn dependency:tree

# Gradle
./gradlew build
./gradlew test
./gradlew bootRun
./gradlew dependencies

# Linting/Formatting
mvn spotless:apply
mvn checkstyle:check
```

## Rules

- ALWAYS use Optional instead of null returns
- NEVER return null from public methods
- ALWAYS use records for DTOs
- NEVER expose mutable collections
- ALWAYS use constructor injection
- NEVER catch Exception or Throwable
- ALWAYS close resources (try-with-resources)
- NEVER use raw types (List instead of List<T>)
