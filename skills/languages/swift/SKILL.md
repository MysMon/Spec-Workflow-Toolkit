---
name: swift
description: Swift development patterns, tooling, and best practices. Use when working on Swift projects, iOS/macOS applications, or server-side Swift with Vapor.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
model: sonnet
user-invocable: true
---

# Swift Development

Comprehensive patterns and practices for Swift development.

## Project Setup

### Swift Package Structure

```
MyPackage/
├── Sources/
│   ├── MyPackage/
│   │   ├── Models/
│   │   ├── Services/
│   │   └── MyPackage.swift
│   └── MyPackageClient/
│       └── main.swift
├── Tests/
│   └── MyPackageTests/
│       └── MyPackageTests.swift
├── Package.swift
└── README.md
```

### Package.swift

```swift
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MyPackage",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "MyPackage", targets: ["MyPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "MyPackage",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "MyPackageTests",
            dependencies: ["MyPackage"]
        ),
    ]
)
```

## Type Safety

### Optionals

```swift
// Optional declaration
var middleName: String? = nil

// Optional binding
if let name = middleName {
    print("Name: \(name)")
}

// Guard let
guard let name = middleName else {
    return
}

// Nil coalescing
let displayName = middleName ?? "Unknown"

// Optional chaining
let length = middleName?.count

// Force unwrap (use sparingly)
let definitelyHasValue = middleName!
```

### Result Type

```swift
enum AppError: Error {
    case notFound(String)
    case validation([String])
    case network(Error)
}

func fetchUser(id: String) -> Result<User, AppError> {
    guard let user = repository.find(id: id) else {
        return .failure(.notFound("User \(id) not found"))
    }
    return .success(user)
}

// Usage
let result = fetchUser(id: "123")
switch result {
case .success(let user):
    print("Found: \(user.name)")
case .failure(let error):
    print("Error: \(error)")
}

// Map and flatMap
let userName = fetchUser(id: "123")
    .map { $0.name }
    .flatMap { name in
        name.isEmpty ? .failure(.validation(["Name required"])) : .success(name)
    }
```

### Structs and Value Types

```swift
struct User: Codable, Hashable, Sendable {
    let id: String
    let email: String
    let name: String
    let createdAt: Date

    init(id: String = UUID().uuidString, email: String, name: String) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = Date()
    }
}

// Copy with modifications
extension User {
    func with(name: String? = nil, email: String? = nil) -> User {
        User(
            id: self.id,
            email: email ?? self.email,
            name: name ?? self.name
        )
    }
}
```

## Code Style

### Naming Conventions

```swift
// Types: PascalCase
struct UserService { }
protocol UserRepository { }
enum UserRole { case admin, member }

// Properties, methods, variables: camelCase
var currentUser: User?
func getUserById(_ id: String) -> User? { }
let maxRetries = 3

// Boolean properties: prefix with is, has, should
var isActive: Bool
var hasPermission: Bool
var shouldRefresh: Bool

// Factory methods: make prefix
static func makeDefault() -> Config { }
```

### Idiomatic Swift

```swift
// Use trailing closure syntax
users.filter { $0.isActive }
    .map { $0.name }
    .sorted()

// Use guard for early exit
func process(user: User?) {
    guard let user = user, user.isActive else {
        return
    }
    // Process active user
}

// Use computed properties
var fullName: String {
    "\(firstName) \(lastName)"
}

// Use property wrappers
@Published var users: [User] = []
@Environment(\.dismiss) var dismiss

// Use extensions for organization
extension User: CustomStringConvertible {
    var description: String {
        "User(\(id), \(name))"
    }
}
```

## Concurrency (Swift 6)

```swift
// Async/await
func fetchUser(id: String) async throws -> User {
    let data = try await networkClient.get("/users/\(id)")
    return try JSONDecoder().decode(User.self, from: data)
}

// Structured concurrency
func fetchUserWithPosts(userId: String) async throws -> (User, [Post]) {
    async let user = fetchUser(id: userId)
    async let posts = fetchPosts(userId: userId)
    return try await (user, posts)
}

// Actor for thread safety
actor UserCache {
    private var cache: [String: User] = [:]

    func get(_ id: String) -> User? {
        cache[id]
    }

    func set(_ user: User) {
        cache[user.id] = user
    }
}

// @Sendable closures
func process(_ handler: @Sendable @escaping () async -> Void) { }
```

## Testing

### XCTest Example

```swift
import XCTest
@testable import MyPackage

final class UserServiceTests: XCTestCase {
    var sut: UserService!
    var mockRepository: MockUserRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        sut = UserService(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func testFindById_WhenUserExists_ReturnsUser() async throws {
        // Arrange
        let expectedUser = User(email: "john@example.com", name: "John")
        mockRepository.stubbedUser = expectedUser

        // Act
        let result = try await sut.findById("1")

        // Assert
        XCTAssertEqual(result, expectedUser)
    }

    func testFindById_WhenUserNotFound_ThrowsError() async {
        // Arrange
        mockRepository.stubbedUser = nil

        // Act & Assert
        do {
            _ = try await sut.findById("999")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is UserError)
        }
    }
}
```

## Common Commands

```bash
# Swift Package Manager
swift build
swift test
swift run
swift package init --type library
swift package update
swift package resolve

# Xcode
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15'
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15'

# SwiftLint
swiftlint
swiftlint --fix

# SwiftFormat
swiftformat .

# Documentation
swift package generate-documentation
```

## Package Managers

| Task | SPM | CocoaPods |
|------|-----|-----------|
| Init | `swift package init` | `pod init` |
| Add dep | Edit Package.swift | Edit Podfile |
| Install | `swift package resolve` | `pod install` |
| Update | `swift package update` | `pod update` |
| Build | `swift build` | N/A (Xcode) |

## Framework-Specific Patterns

For framework-specific guidance, see:
- [SwiftUI patterns](SWIFTUI.md)
- [UIKit patterns](UIKIT.md)
- [Vapor patterns](VAPOR.md)

## Rules

- ALWAYS use value types (struct) by default
- ALWAYS use optionals instead of nil checks
- NEVER force unwrap without explicit reason
- ALWAYS use guard for early exit
- NEVER use implicitly unwrapped optionals in new code
- ALWAYS use async/await for concurrent code
- NEVER block the main thread
- ALWAYS use actors for shared mutable state
- ALWAYS mark types as Sendable when possible
- NEVER ignore compiler warnings
