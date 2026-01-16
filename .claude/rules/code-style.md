# Code Style Guidelines

## TypeScript Standards

### Type Safety
- Enable `strict` mode in tsconfig.json
- Never use `any` without explicit justification
- Prefer `unknown` over `any` when type is truly unknown
- Use discriminated unions for complex state

```typescript
// Good: Discriminated union
type Result<T> =
  | { success: true; data: T }
  | { success: false; error: Error };

// Bad: Using any
const data: any = response;
```

### Naming Conventions
- **Variables/Functions**: camelCase
- **Classes/Types/Interfaces**: PascalCase
- **Constants**: SCREAMING_SNAKE_CASE
- **Files**: kebab-case.ts

### Import Organization
```typescript
// 1. External packages
import { useState } from 'react';
import { z } from 'zod';

// 2. Internal absolute imports
import { Button } from '@/components/ui/button';
import { useAuth } from '@/hooks/use-auth';

// 3. Relative imports
import { helper } from './utils';
import type { Props } from './types';
```

## React/Next.js Standards

### Component Structure
```typescript
// 1. Imports
// 2. Types
// 3. Component
// 4. Helper functions (if small)

interface ButtonProps {
  variant: 'primary' | 'secondary';
  children: React.ReactNode;
  onClick?: () => void;
}

export function Button({ variant, children, onClick }: ButtonProps) {
  return (
    <button
      className={cn(baseStyles, variantStyles[variant])}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
```

### Server vs Client Components
- Default to Server Components
- Add `'use client'` only when needed:
  - useState, useEffect, other hooks
  - Event handlers (onClick, onChange)
  - Browser-only APIs

### Hooks Rules
- Always call at top level
- Never call conditionally
- Custom hooks start with `use`

## Error Handling

### API Errors
```typescript
// Use Result types
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
    return { success: false, error: e instanceof Error ? e : new Error(String(e)) };
  }
}
```

### Never Swallow Errors
```typescript
// Bad
try { await risky(); } catch {}

// Good
try {
  await risky();
} catch (error) {
  logger.error('Risky operation failed', { error });
  throw error; // or handle appropriately
}
```

## Comments

### When to Comment
- Complex algorithms
- Business logic that isn't obvious
- Workarounds with context
- Public API documentation (JSDoc)

### When NOT to Comment
- Obvious code
- Restating what code does
- Commented-out code (delete it)

### JSDoc for Public APIs
```typescript
/**
 * Calculates total price including tax.
 *
 * @param items - Cart items to sum
 * @param taxRate - Tax rate as decimal (e.g., 0.08)
 * @returns Total price with tax applied
 */
function calculateTotal(items: CartItem[], taxRate: number): number
```
