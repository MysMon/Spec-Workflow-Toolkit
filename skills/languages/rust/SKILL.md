---
name: rust
description: Rust development patterns, tooling, and best practices. Use when working on Rust projects, systems programming, or high-performance applications.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
model: sonnet
user-invocable: true
---

# Rust Development

Comprehensive patterns and practices for Rust development.

## Project Structure

### Cargo Project Layout

```
project/
├── src/
│   ├── main.rs           # Binary entry point
│   ├── lib.rs            # Library root
│   ├── config.rs         # Configuration
│   ├── error.rs          # Error types
│   └── handlers/
│       ├── mod.rs
│       └── user.rs
├── tests/                # Integration tests
│   └── api_tests.rs
├── benches/              # Benchmarks
├── Cargo.toml
└── Cargo.lock
```

### Cargo.toml Example

```toml
[package]
name = "my-project"
version = "0.1.0"
edition = "2021"
rust-version = "1.75"

[dependencies]
tokio = { version = "1", features = ["full"] }
axum = "0.7"
serde = { version = "1", features = ["derive"] }
thiserror = "1"

[dev-dependencies]
tokio-test = "0.4"

[profile.release]
lto = true
codegen-units = 1
```

## Error Handling

### Using thiserror

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("User {0} not found")]
    NotFound(String),

    #[error("Validation failed: {0}")]
    Validation(String),

    #[error("Database error")]
    Database(#[from] sqlx::Error),

    #[error("Internal error")]
    Internal(#[source] anyhow::Error),
}

// Usage
fn get_user(id: &str) -> Result<User, AppError> {
    let user = db.find_user(id)
        .map_err(AppError::Database)?;

    user.ok_or_else(|| AppError::NotFound(id.to_string()))
}
```

### Result Combinators

```rust
// Map success value
let name = get_user(id)?.name.to_uppercase();

// Map error type
let user = get_user(id)
    .map_err(|e| format!("Failed to get user: {}", e))?;

// Provide default
let user = get_user(id).unwrap_or_default();

// Chain operations
let result = get_user(id)
    .and_then(|u| validate_user(&u))
    .map(|u| UserResponse::from(u));
```

## Ownership & Borrowing

### Common Patterns

```rust
// Take ownership when you need it
fn consume(s: String) {
    // s is moved here, caller can't use it
}

// Borrow when you just need to read
fn read(s: &str) {
    // s is borrowed, caller keeps ownership
}

// Mutable borrow when you need to modify
fn modify(s: &mut String) {
    s.push_str(" modified");
}

// Clone when you need your own copy
fn clone_and_modify(s: &str) -> String {
    let mut owned = s.to_string();
    owned.push_str(" modified");
    owned
}
```

### Smart Pointers

```rust
use std::sync::Arc;
use tokio::sync::RwLock;

// Shared ownership (thread-safe)
type SharedState = Arc<RwLock<AppState>>;

// Interior mutability
let state = Arc::new(RwLock::new(AppState::default()));
let reader = state.read().await;
let mut writer = state.write().await;
```

## Async Patterns

### Tokio Runtime

```rust
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let result = fetch_data().await?;
    Ok(())
}

// Spawn concurrent tasks
async fn parallel_fetch() -> Vec<Data> {
    let handles: Vec<_> = urls.iter()
        .map(|url| tokio::spawn(fetch(url.clone())))
        .collect();

    let results = futures::future::join_all(handles).await;
    results.into_iter()
        .filter_map(|r| r.ok())
        .filter_map(|r| r.ok())
        .collect()
}
```

### Graceful Shutdown

```rust
use tokio::signal;

async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("failed to install signal handler")
            .recv()
            .await;
    };

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }
}
```

## Testing

### Unit Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn test_error_case() {
        let result = might_fail(false);
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_async_function() {
        let result = async_fetch().await;
        assert!(result.is_ok());
    }
}
```

### Integration Tests

```rust
// tests/api_tests.rs
use my_project::create_app;
use axum_test::TestServer;

#[tokio::test]
async fn test_get_user() {
    let app = create_app().await;
    let server = TestServer::new(app).unwrap();

    let response = server
        .get("/users/1")
        .await;

    response.assert_status_ok();
    response.assert_json(&json!({
        "id": "1",
        "name": "John"
    }));
}
```

## Common Commands

```bash
# Build
cargo build
cargo build --release

# Test
cargo test
cargo test -- --nocapture
cargo test --test integration

# Lint
cargo clippy -- -D warnings

# Format
cargo fmt
cargo fmt -- --check

# Check (faster than build)
cargo check

# Documentation
cargo doc --open

# Dependencies
cargo update
cargo audit
cargo outdated

# Run
cargo run
cargo run --release
```

## Clippy Lints

```rust
// Cargo.toml
[lints.clippy]
pedantic = "warn"
nursery = "warn"
unwrap_used = "deny"
expect_used = "deny"
```

## Rules

- ALWAYS handle Results explicitly
- NEVER use unwrap() in production code
- ALWAYS use clippy and rustfmt
- NEVER ignore compiler warnings
- ALWAYS prefer borrowing over cloning
- NEVER use unsafe without justification
- ALWAYS document public APIs
- NEVER leak implementation details
