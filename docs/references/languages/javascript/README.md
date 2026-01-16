
# JavaScript/TypeScript Development

Comprehensive patterns and practices for JavaScript and TypeScript development.

## TypeScript Configuration

### Recommended tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

### Type Safety Rules

```typescript
// NEVER use 'any' without justification
// BAD
const data: any = response;

// GOOD: Use unknown and narrow
const data: unknown = response;
if (isUserData(data)) {
  // data is now typed
}

// GOOD: Use discriminated unions
type Result<T> =
  | { success: true; data: T }
  | { success: false; error: Error };
```

## Package Management

### npm/yarn/pnpm Commands

| Task | npm | yarn | pnpm |
|------|-----|------|------|
| Install | `npm install` | `yarn` | `pnpm install` |
| Add dep | `npm install pkg` | `yarn add pkg` | `pnpm add pkg` |
| Add dev | `npm install -D pkg` | `yarn add -D pkg` | `pnpm add -D pkg` |
| Remove | `npm uninstall pkg` | `yarn remove pkg` | `pnpm remove pkg` |
| Run script | `npm run script` | `yarn script` | `pnpm script` |
| Audit | `npm audit` | `yarn audit` | `pnpm audit` |

### Lock Files

| Package Manager | Lock File |
|-----------------|-----------|
| npm | `package-lock.json` |
| yarn | `yarn.lock` |
| pnpm | `pnpm-lock.yaml` |

## Code Style

### Naming Conventions

```typescript
// Variables and functions: camelCase
const userName = 'john';
function getUserById(id: string) {}

// Classes and types: PascalCase
class UserService {}
interface UserData {}
type UserId = string;

// Constants: SCREAMING_SNAKE_CASE
const MAX_RETRIES = 3;
const API_BASE_URL = '/api/v1';

// Files: kebab-case
// user-service.ts
// api-client.ts
```

### Import Organization

```typescript
// 1. Node built-ins
import { readFile } from 'node:fs/promises';

// 2. External packages
import { z } from 'zod';
import express from 'express';

// 3. Internal absolute imports
import { UserService } from '@/services/user';
import { Button } from '@/components/ui';

// 4. Relative imports
import { helper } from './utils';
import type { Props } from './types';
```

## Error Handling

### Result Pattern

```typescript
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const user = await db.user.findUnique({ where: { id } });
    if (!user) {
      return { success: false, error: new NotFoundError('User', id) };
    }
    return { success: true, data: user };
  } catch (e) {
    return {
      success: false,
      error: e instanceof Error ? e : new Error(String(e))
    };
  }
}

// Usage
const result = await fetchUser('123');
if (!result.success) {
  console.error(result.error);
  return;
}
const user = result.data; // Type-safe
```

### Never Swallow Errors

```typescript
// BAD
try { await risky(); } catch {}

// GOOD
try {
  await risky();
} catch (error) {
  logger.error('Risky operation failed', { error });
  throw error; // or handle appropriately
}
```

## Testing

### Vitest Example

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

describe('UserService', () => {
  let service: UserService;
  let mockRepo: MockUserRepository;

  beforeEach(() => {
    mockRepo = { findById: vi.fn() };
    service = new UserService(mockRepo);
  });

  describe('getUser', () => {
    it('should return user when found', async () => {
      // Arrange
      const user = { id: '1', name: 'John' };
      mockRepo.findById.mockResolvedValue(user);

      // Act
      const result = await service.getUser('1');

      // Assert
      expect(result.success).toBe(true);
      expect(result.data).toEqual(user);
    });

    it('should return error when not found', async () => {
      // Arrange
      mockRepo.findById.mockResolvedValue(null);

      // Act
      const result = await service.getUser('999');

      // Assert
      expect(result.success).toBe(false);
      expect(result.error).toBeInstanceOf(NotFoundError);
    });
  });
});
```

## Common Commands

```bash
# Linting
npm run lint
npm run lint -- --fix

# Formatting
npm run format
npx prettier --write "src/**/*.{ts,tsx}"

# Type checking
npx tsc --noEmit

# Testing
npm test
npm run test:watch
npm run test:coverage

# Building
npm run build

# Development
npm run dev
```

## Framework-Specific Patterns

For framework-specific guidance, see:
- [React patterns](REACT.md)
- [Node.js patterns](NODEJS.md)
- [Next.js patterns](NEXTJS.md)

## Rules

- ALWAYS use TypeScript strict mode
- NEVER use `any` without explicit justification
- ALWAYS handle errors explicitly
- NEVER commit console.log statements
- ALWAYS use const by default, let when needed
- NEVER use var
- ALWAYS prefer async/await over raw promises
- ALWAYS validate external input with Zod or similar
