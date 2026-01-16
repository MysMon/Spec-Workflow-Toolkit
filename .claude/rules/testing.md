# Testing Standards

## Test Pyramid

```
       /\
      /E2E\        Few: Critical user journeys
     /------\
    / Integ  \     Some: Service boundaries
   /----------\
  /   Unit     \   Many: Business logic
 /--------------\
```

## Unit Testing (Vitest)

### Structure: Arrange-Act-Assert
```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('UserService', () => {
  describe('createUser', () => {
    it('should create user with valid data', async () => {
      // Arrange
      const userData = { email: 'test@example.com', name: 'Test' };
      const mockRepo = { create: vi.fn().mockResolvedValue({ id: '1', ...userData }) };
      const service = new UserService(mockRepo);

      // Act
      const result = await service.createUser(userData);

      // Assert
      expect(result.success).toBe(true);
      expect(result.data.email).toBe(userData.email);
      expect(mockRepo.create).toHaveBeenCalledWith(userData);
    });

    it('should reject invalid email', async () => {
      // Arrange
      const userData = { email: 'invalid', name: 'Test' };
      const service = new UserService(mockRepo);

      // Act
      const result = await service.createUser(userData);

      // Assert
      expect(result.success).toBe(false);
      expect(result.error.code).toBe('VALIDATION_ERROR');
    });
  });
});
```

### Naming Conventions
- Describe blocks: Component/function name
- It blocks: "should [expected behavior] when [condition]"

### What to Test
- Business logic
- Edge cases
- Error conditions
- Input validation

### What NOT to Unit Test
- Framework code
- External libraries
- Simple getters/setters
- Implementation details

## Integration Testing

### API Endpoint Tests
```typescript
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app';

describe('POST /api/users', () => {
  beforeAll(async () => {
    await setupTestDatabase();
  });

  afterAll(async () => {
    await cleanupTestDatabase();
  });

  it('should create user and return 201', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'new@example.com', name: 'New User' });

    expect(response.status).toBe(201);
    expect(response.body.data.email).toBe('new@example.com');
  });

  it('should return 400 for invalid data', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'invalid' });

    expect(response.status).toBe(400);
    expect(response.body.error).toBeDefined();
  });
});
```

## E2E Testing (Playwright)

### Page Object Model
```typescript
// pages/login.page.ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByRole('button', { name: 'Log in' }).click();
  }

  async getErrorMessage() {
    return this.page.getByRole('alert').textContent();
  }
}

// tests/auth.spec.ts
test('successful login redirects to dashboard', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('user@example.com', 'password');

  await expect(page).toHaveURL('/dashboard');
});
```

### Locator Priority (Best to Worst)
1. `getByRole()` - Most accessible
2. `getByLabel()` - Form inputs
3. `getByText()` - Content
4. `getByTestId()` - Last resort

### Avoid
- CSS selectors based on classes
- XPath selectors
- `force: true` without documentation
- `page.waitForTimeout()` (use auto-waiting)

## Test Data

### Factories
```typescript
// factories/user.factory.ts
import { faker } from '@faker-js/faker';

export function createUserData(overrides = {}) {
  return {
    email: faker.internet.email(),
    name: faker.person.fullName(),
    ...overrides,
  };
}

// Usage
const user = createUserData({ email: 'specific@test.com' });
```

### Fixtures
```typescript
// fixtures/users.ts
export const testUsers = {
  admin: {
    id: 'admin-id',
    email: 'admin@test.com',
    role: 'admin',
  },
  regular: {
    id: 'user-id',
    email: 'user@test.com',
    role: 'user',
  },
};
```

## Mocking

### When to Mock
- External services (APIs, databases)
- Time-dependent operations
- Random number generation
- File system operations

### When NOT to Mock
- The code under test
- Simple utilities
- Domain logic

```typescript
// Mock external API
vi.mock('@/lib/external-api', () => ({
  fetchData: vi.fn().mockResolvedValue({ data: 'mocked' }),
}));

// Mock time
vi.useFakeTimers();
vi.setSystemTime(new Date('2024-01-01'));
// ... test ...
vi.useRealTimers();
```

## Coverage

### Targets
- Statements: 80%
- Branches: 80%
- Functions: 80%
- Lines: 80%

### vitest.config.ts
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      exclude: [
        'node_modules/',
        'tests/',
        '**/*.d.ts',
        '**/*.config.*',
      ],
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
    },
  },
});
```

## Rules

- Tests must be independent (no shared state)
- Tests must be deterministic (same result every run)
- Clean up after each test
- Prefer real implementations over mocks when fast
- Write tests BEFORE fixing bugs (regression prevention)
