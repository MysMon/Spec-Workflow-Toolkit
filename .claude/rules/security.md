# Security Guidelines

## Core Principles

1. **Defense in Depth**: Never rely on a single security measure
2. **Least Privilege**: Grant minimum required permissions
3. **Fail Secure**: When in doubt, deny access
4. **Input Validation**: Validate at system boundaries

## Secret Management

### Environment Variables
```bash
# .env.example (commit this)
DATABASE_URL=postgresql://user:password@localhost:5432/db
API_KEY=your-api-key-here

# .env (NEVER commit)
DATABASE_URL=postgresql://actual:secret@prod:5432/db
API_KEY=sk-actual-secret-key
```

### Ensure .gitignore
```gitignore
.env
.env.local
.env.*.local
*.pem
*.key
credentials.json
secrets/
```

### Never Hardcode
```typescript
// Bad
const apiKey = "sk-1234567890abcdef";

// Good
const apiKey = process.env.API_KEY;
if (!apiKey) throw new Error("API_KEY is required");
```

## Input Validation

### Validate at Boundaries
```typescript
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().positive().max(150).optional(),
});

// In API handler
const result = CreateUserSchema.safeParse(req.body);
if (!result.success) {
  return res.status(400).json({ error: result.error });
}
// result.data is now typed and validated
```

### SQL Injection Prevention
```typescript
// Bad - NEVER do this
const query = `SELECT * FROM users WHERE id = '${userId}'`;

// Good - Use Prisma (parameterized)
const user = await prisma.user.findUnique({
  where: { id: userId },
});
```

### XSS Prevention
```typescript
// Bad - Dangerous
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// Good - React escapes by default
<div>{userInput}</div>

// If HTML is needed, sanitize first
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(content) }} />
```

## Authentication

### Password Hashing
```typescript
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 12; // Minimum 10, prefer 12+

async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS);
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}
```

### Session Security
```typescript
// Cookie settings
{
  httpOnly: true,      // Prevent XSS access
  secure: true,        // HTTPS only in production
  sameSite: 'lax',     // CSRF protection
  maxAge: 60 * 60 * 24 // 24 hours
}
```

### JWT Best Practices
- Short expiration (15 minutes for access tokens)
- Use refresh tokens for extended sessions
- Include only necessary claims
- Validate all claims on each request

## Authorization

### Check on Every Request
```typescript
// Middleware pattern
async function requireAuth(req, res, next) {
  const user = await getUser(req);
  if (!user) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  req.user = user;
  next();
}

// Resource-level checks
async function getDocument(req, res) {
  const doc = await db.document.findUnique({ where: { id: req.params.id } });
  if (!doc) return res.status(404).json({ error: 'Not found' });

  // Always check ownership/permissions
  if (doc.ownerId !== req.user.id && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  return res.json(doc);
}
```

## Security Headers

```typescript
// Using Helmet.js
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
  },
}));
```

## Logging

### What to Log
- Authentication attempts (success and failure)
- Authorization failures
- Input validation failures
- System errors

### What NOT to Log
- Passwords (even hashed)
- API keys or tokens
- Personal data (PII)
- Credit card numbers

```typescript
// Bad
logger.info('Login attempt', { email, password });

// Good
logger.info('Login attempt', { email, success: false, reason: 'invalid_password' });
```

## Dependency Security

```bash
# Regular audits
npm audit

# Fix automatically where possible
npm audit fix

# Check for outdated packages
npm outdated
```
