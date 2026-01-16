
# Go Development

Comprehensive patterns and practices for Go development.

## Project Structure

### Standard Layout

```
project/
├── cmd/
│   └── server/
│       └── main.go       # Entry point
├── internal/
│   ├── handler/          # HTTP handlers
│   ├── service/          # Business logic
│   ├── repository/       # Data access
│   └── model/            # Domain models
├── pkg/                  # Public packages
├── api/                  # API definitions (OpenAPI, protobuf)
├── go.mod
├── go.sum
└── Makefile
```

### go.mod Example

```go
module github.com/username/project

go 1.22

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/jmoiron/sqlx v1.3.5
)
```

## Code Style

### Naming Conventions

```go
// Packages: lowercase, no underscores
package userservice

// Exported (public): PascalCase
type UserService struct {}
func NewUserService() *UserService {}
const MaxRetries = 3

// Unexported (private): camelCase
type userCache struct {}
func (s *UserService) validateInput() error {}
const defaultTimeout = 30

// Interfaces: -er suffix for single method
type Reader interface {
    Read(p []byte) (n int, err error)
}

// Acronyms: all caps
var httpClient *http.Client
type JSONParser struct {}
```

### Interface Design

```go
// Accept interfaces, return structs
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
}

type userService struct {
    repo UserRepository  // Depend on interface
}

func NewUserService(repo UserRepository) *userService {
    return &userService{repo: repo}
}
```

## Error Handling

### Error Wrapping

```go
import (
    "errors"
    "fmt"
)

// Define sentinel errors
var (
    ErrNotFound = errors.New("not found")
    ErrInvalidInput = errors.New("invalid input")
)

// Wrap errors with context
func (s *userService) GetUser(ctx context.Context, id string) (*User, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            return nil, fmt.Errorf("user %s: %w", id, ErrNotFound)
        }
        return nil, fmt.Errorf("get user %s: %w", id, err)
    }
    return user, nil
}

// Check wrapped errors
if errors.Is(err, ErrNotFound) {
    // Handle not found
}
```

### Custom Error Types

```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error on %s: %s", e.Field, e.Message)
}

// Type assertion
var validErr *ValidationError
if errors.As(err, &validErr) {
    // Handle validation error
}
```

## Concurrency Patterns

### Goroutines with WaitGroup

```go
func processItems(items []Item) error {
    var wg sync.WaitGroup
    errCh := make(chan error, len(items))

    for _, item := range items {
        wg.Add(1)
        go func(item Item) {
            defer wg.Done()
            if err := process(item); err != nil {
                errCh <- err
            }
        }(item)
    }

    wg.Wait()
    close(errCh)

    // Collect errors
    var errs []error
    for err := range errCh {
        errs = append(errs, err)
    }
    return errors.Join(errs...)
}
```

### Context Cancellation

```go
func fetchWithTimeout(ctx context.Context, url string) ([]byte, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    return io.ReadAll(resp.Body)
}
```

## Testing

### Table-Driven Tests

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -2, -3, -5},
        {"mixed", -2, 3, 1},
        {"zeros", 0, 0, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

### Mocking with Interfaces

```go
type mockUserRepo struct {
    users map[string]*User
}

func (m *mockUserRepo) FindByID(ctx context.Context, id string) (*User, error) {
    user, ok := m.users[id]
    if !ok {
        return nil, ErrNotFound
    }
    return user, nil
}

func TestGetUser(t *testing.T) {
    repo := &mockUserRepo{
        users: map[string]*User{
            "1": {ID: "1", Name: "John"},
        },
    }
    svc := NewUserService(repo)

    user, err := svc.GetUser(context.Background(), "1")
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if user.Name != "John" {
        t.Errorf("expected John, got %s", user.Name)
    }
}
```

## Common Commands

```bash
# Build
go build ./...
go build -o bin/server ./cmd/server

# Test
go test ./...
go test -v ./...
go test -cover ./...
go test -race ./...

# Lint
golangci-lint run
go vet ./...

# Format
go fmt ./...
goimports -w .

# Dependencies
go mod tidy
go mod download
go get -u ./...

# Vulnerability check
govulncheck ./...
```

## Rules

- ALWAYS handle errors explicitly
- NEVER ignore returned errors
- ALWAYS use context for cancellation
- NEVER use init() unless absolutely necessary
- ALWAYS close resources with defer
- NEVER use panic for normal error handling
- ALWAYS use gofmt/goimports
- NEVER export more than necessary
