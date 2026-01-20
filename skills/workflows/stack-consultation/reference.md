# Stack Consultation Reference

Detailed technology reference for stack consultation. Load on demand when deeper information is needed.

## Technology Quick Reference

### Frontend Frameworks (2025)

| Framework | Best For | Learning Curve | Performance | Ecosystem |
|-----------|----------|----------------|-------------|-----------|
| **Next.js** | Full-stack, SEO, Enterprise | Medium | Excellent | Extensive |
| **Remix** | Performance-critical, Forms | Medium | Excellent | Growing |
| **Nuxt** | Vue ecosystem, Full-stack | Medium | Good | Extensive |
| **SvelteKit** | Performance, Simplicity | Low | Excellent | Growing |
| **Astro** | Content sites, Static | Low | Excellent | Good |
| **Vite+React** | SPAs, Dashboards | Low | Good | Extensive |

### Backend Frameworks

| Framework | Language | Best For | Learning Curve |
|-----------|----------|----------|----------------|
| **Express** | Node.js | Flexibility, APIs | Low |
| **Fastify** | Node.js | Performance APIs | Low |
| **Hono** | Node.js/Edge | Edge computing | Low |
| **NestJS** | Node.js | Enterprise, Structure | High |
| **FastAPI** | Python | Modern APIs, ML | Low |
| **Django** | Python | Full-stack, Admin | Medium |
| **Gin** | Go | High-performance | Medium |
| **Axum** | Rust | Maximum performance | High |
| **Laravel** | PHP | Rapid development | Medium |
| **Spring Boot** | Java/Kotlin | Enterprise | High |

### Databases

| Database | Type | Best For | Scaling |
|----------|------|----------|---------|
| **PostgreSQL** | Relational | General purpose, JSONB | Vertical + Read replicas |
| **MySQL** | Relational | Web apps, WordPress | Read replicas |
| **SQLite** | Relational | Embedded, Small apps | Single node |
| **MongoDB** | Document | Flexible schema | Horizontal |
| **Redis** | Key-Value | Caching, Sessions | Cluster |
| **Supabase** | PostgreSQL + BaaS | Rapid development | Managed |
| **PlanetScale** | MySQL + Serverless | Serverless apps | Branching |
| **Turso** | SQLite + Edge | Edge applications | Edge replicas |

### Hosting Platforms

| Platform | Best For | Free Tier | Scaling |
|----------|----------|-----------|---------|
| **Vercel** | Next.js, Jamstack | Generous | Automatic |
| **Netlify** | Static, Serverless | Generous | Automatic |
| **Cloudflare Pages** | Edge, Global | Generous | Automatic |
| **Railway** | Full-stack, DBs | Limited | Automatic |
| **Render** | Full-stack | Limited | Automatic |
| **Fly.io** | Containers, Global | Limited | Manual |
| **AWS** | Everything | Complex | Manual |
| **GCP** | ML, Big Data | Complex | Manual |

### Authentication Solutions

| Solution | Type | Best For | Pricing |
|----------|------|----------|---------|
| **Auth.js** | Library | Next.js, Self-hosted | Free |
| **Clerk** | Service | Fast integration | Freemium |
| **Supabase Auth** | Service | Supabase users | Included |
| **Firebase Auth** | Service | Firebase users | Freemium |
| **Auth0** | Service | Enterprise | Freemium |
| **Keycloak** | Self-hosted | Enterprise, Control | Free |

### ORMs and Database Tools

| Tool | Language | Best For |
|------|----------|----------|
| **Prisma** | TypeScript | Type-safety, DX |
| **Drizzle** | TypeScript | Performance, Control |
| **TypeORM** | TypeScript | Decorators, Legacy |
| **Sequelize** | JavaScript | Legacy, MySQL |
| **SQLAlchemy** | Python | Flexibility |
| **Django ORM** | Python | Django apps |
| **GORM** | Go | Go applications |

---

## Stack Templates

### SaaS Starter (TypeScript)

```
Frontend: Next.js 14+ (App Router)
Backend: Next.js API Routes / tRPC
Database: PostgreSQL (Supabase or Neon)
Auth: Auth.js or Clerk
Payments: Stripe
Hosting: Vercel
Styling: Tailwind CSS
```

**Rationale**: Maximum developer velocity with excellent DX and ecosystem.

### High-Performance API (Go)

```
Framework: Gin or Echo
Database: PostgreSQL
Caching: Redis
API Spec: OpenAPI 3.1
Hosting: AWS ECS / GCP Cloud Run
```

**Rationale**: Excellent performance, low resource usage, strong typing.

### Data-Intensive Application (Python)

```
Backend: FastAPI
Database: PostgreSQL + TimescaleDB
Queue: Celery + Redis
ML: PyTorch / scikit-learn
Hosting: AWS / GCP
```

**Rationale**: Python ecosystem for data processing and ML.

### Content Site / Blog

```
Framework: Astro or Next.js
CMS: Sanity / Contentful / Notion API
Database: None or SQLite
Hosting: Vercel / Cloudflare Pages
```

**Rationale**: Static generation for performance and cost.

### Mobile App Backend

```
Backend: FastAPI or Express
Database: PostgreSQL
Real-time: Supabase Realtime / Socket.io
Push: Firebase Cloud Messaging
Hosting: Railway / Render
```

**Rationale**: Simple setup with mobile-specific features.

---

## Decision Matrices

### When to Choose Next.js

✅ Choose when:
- SEO is important
- You need SSR/SSG
- Team knows React
- Full-stack TypeScript desired
- Vercel deployment preferred

❌ Avoid when:
- Simple SPA is sufficient
- Team prefers Vue/Svelte
- Need maximum backend flexibility
- Avoiding vendor lock-in is priority

### When to Choose PostgreSQL

✅ Choose when:
- Complex queries needed
- Data integrity is critical
- JSON flexibility desired (JSONB)
- Full-text search needed
- Standard SQL preferred

❌ Avoid when:
- Document-oriented data model better
- Extreme horizontal scaling needed
- Simple key-value sufficient
- Edge deployment required

### When to Choose Serverless

✅ Choose when:
- Traffic is unpredictable
- Cost optimization important
- Scaling should be automatic
- Cold starts acceptable
- Simple deployment preferred

❌ Avoid when:
- Consistent low latency required
- Long-running processes needed
- WebSocket connections required
- Cost at scale is concern
- Local development parity needed

---

## Common Pitfalls

### Over-engineering

**Symptom**: Choosing Kubernetes for a blog
**Solution**: Start simple, scale when needed

### Under-engineering

**Symptom**: SQLite for multi-tenant SaaS
**Solution**: Consider growth from start for data layer

### Trend-chasing

**Symptom**: Choosing newest framework without evaluation
**Solution**: Evaluate stability, community, and fit

### Ignoring Team Skills

**Symptom**: Choosing Rust when team knows JavaScript
**Solution**: Factor in learning curve and timeline

---

## Search Query Templates

### For Framework Evaluation

```
"[Framework A] vs [Framework B] [year] production experience"
"[Framework] scalability case study [year]"
"[Framework] performance benchmark [year]"
"migrating from [Framework A] to [Framework B] experience"
```

### For Database Selection

```
"[Database] for [use case] [year]"
"[Database A] vs [Database B] [year] comparison"
"[Database] scaling experience production"
"[Database] cost at scale"
```

### For Hosting Comparison

```
"[Platform A] vs [Platform B] pricing [year]"
"[Platform] for [Framework] deployment"
"[Platform] production experience [year]"
"[Platform] limitations gotchas"
```
