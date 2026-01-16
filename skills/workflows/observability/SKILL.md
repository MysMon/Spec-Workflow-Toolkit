---
name: observability
description: Observability patterns for logging, metrics, and distributed tracing. Use when implementing logging, setting up monitoring, or adding instrumentation to applications.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
user-invocable: true
---

# Observability

Stack-agnostic patterns for building observable systems through logging, metrics, and tracing.

## Three Pillars of Observability

### 1. Logging

Structured, contextual logs for debugging and auditing.

### 2. Metrics

Numerical measurements for monitoring and alerting.

### 3. Tracing

Distributed request tracking across services.

## Structured Logging

### Log Format

```json
{
  "timestamp": "2024-01-15T10:30:00.123Z",
  "level": "INFO",
  "service": "user-service",
  "version": "1.2.3",
  "trace_id": "abc123",
  "span_id": "def456",
  "message": "User created successfully",
  "context": {
    "user_id": "usr_789",
    "email_domain": "example.com"
  },
  "duration_ms": 45
}
```

### Log Levels

| Level | Use Case | Example |
|-------|----------|---------|
| DEBUG | Development details | Query params, cache hits |
| INFO | Normal operations | User created, request completed |
| WARN | Potential issues | Retry needed, deprecated API used |
| ERROR | Operation failed | Database connection failed |
| FATAL | Application crash | Unrecoverable error |

### Best Practices

```
DO:
- Use structured logging (JSON)
- Include correlation IDs
- Log at service boundaries
- Include relevant context
- Use consistent field names

DON'T:
- Log sensitive data (passwords, tokens, PII)
- Log at high frequency in loops
- Use string concatenation for log messages
- Log entire request/response bodies
- Use print statements in production
```

### Language Examples

```javascript
// JavaScript (pino)
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
});

logger.info({ userId: user.id, action: 'create' }, 'User created');
```

```python
# Python (structlog)
import structlog

logger = structlog.get_logger()
logger.info("user_created", user_id=user.id, email_domain=email.split("@")[1])
```

```go
// Go (slog)
slog.Info("user created",
    "user_id", user.ID,
    "email_domain", emailDomain,
)
```

## Metrics

### Metric Types

| Type | Use Case | Example |
|------|----------|---------|
| Counter | Cumulative values | Request count, errors |
| Gauge | Point-in-time values | Active connections, queue size |
| Histogram | Distribution | Request latency, response size |
| Summary | Similar to histogram | Quantiles (p50, p99) |

### Naming Conventions

```
# Format: <namespace>_<name>_<unit>

# Good
http_requests_total
http_request_duration_seconds
database_connections_active
queue_messages_waiting

# Bad
requests              # No namespace, no unit
httpRequestDuration   # camelCase
request-latency       # Hyphens, no unit
```

### Key Metrics to Track

```
# RED Method (Request-oriented)
- Rate: requests per second
- Errors: error rate
- Duration: latency percentiles

# USE Method (Resource-oriented)
- Utilization: % time busy
- Saturation: queue length
- Errors: error count

# Four Golden Signals
- Latency: time to serve requests
- Traffic: demand on system
- Errors: rate of failed requests
- Saturation: how "full" the system is
```

### Prometheus Examples

```python
# Python
from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint'],
    buckets=[.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10]
)
```

## Distributed Tracing

### Trace Concepts

```
Trace (entire request journey)
├── Span A: API Gateway (parent)
│   ├── Span B: Auth Service
│   └── Span C: User Service
│       └── Span D: Database Query
```

### Trace Context

```http
# W3C Trace Context
traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
tracestate: vendor1=value1,vendor2=value2

# B3 (Zipkin)
X-B3-TraceId: 80f198ee56343ba864fe8b2a57d3eff7
X-B3-SpanId: e457b5a2e4d86bd1
X-B3-ParentSpanId: 05e3ac9a4f6e3b90
X-B3-Sampled: 1
```

### OpenTelemetry Example

```javascript
// JavaScript
const { trace } = require('@opentelemetry/api');

const tracer = trace.getTracer('user-service');

async function createUser(userData) {
  return tracer.startActiveSpan('createUser', async (span) => {
    try {
      span.setAttribute('user.email_domain', userData.email.split('@')[1]);

      const user = await db.users.create(userData);

      span.setAttribute('user.id', user.id);
      span.setStatus({ code: SpanStatusCode.OK });

      return user;
    } catch (error) {
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error.message,
      });
      span.recordException(error);
      throw error;
    } finally {
      span.end();
    }
  });
}
```

## Health Checks

### Endpoint Design

```json
// GET /health
{
  "status": "healthy",
  "version": "1.2.3",
  "uptime_seconds": 3600,
  "checks": {
    "database": {
      "status": "healthy",
      "latency_ms": 5
    },
    "redis": {
      "status": "healthy",
      "latency_ms": 2
    },
    "external_api": {
      "status": "degraded",
      "message": "High latency"
    }
  }
}

// Status codes
// 200: All healthy
// 503: One or more critical checks failing
```

### Liveness vs Readiness

| Check | Purpose | Failure Action |
|-------|---------|----------------|
| Liveness | Is app running? | Restart container |
| Readiness | Can handle requests? | Remove from load balancer |

```yaml
# Kubernetes example
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Alerting

### Alert Design

```yaml
# Good alert
name: High Error Rate
condition: error_rate > 1% for 5 minutes
severity: critical
runbook: https://wiki/runbooks/high-error-rate

# Include
- Clear, actionable name
- Threshold with duration
- Severity level
- Link to runbook
- Relevant labels/tags

# Avoid
- Flapping alerts (too sensitive)
- Alerts on symptoms only (dig to root cause)
- Too many alerts (alert fatigue)
```

### SLO-Based Alerting

```
SLI: 99.9% of requests complete in < 200ms
SLO: 99.9% success rate over 30 days
Error Budget: 0.1% = ~43 minutes/month

Alert when:
- Burn rate > 1x: Slow burn, low severity
- Burn rate > 10x: Fast burn, high severity
```

## Implementation Checklist

- [ ] Structured logging configured
- [ ] Log levels appropriate for environment
- [ ] Sensitive data excluded from logs
- [ ] Key metrics identified (RED/USE)
- [ ] Metrics endpoint exposed (/metrics)
- [ ] Trace context propagated
- [ ] Health endpoints implemented (/health)
- [ ] Alerts defined for critical paths
- [ ] Runbooks linked to alerts
- [ ] Dashboards created for key metrics

## Rules

- ALWAYS use structured logging
- NEVER log sensitive data (PII, tokens, passwords)
- ALWAYS propagate trace context
- ALWAYS include correlation IDs in logs
- NEVER alert on metrics without context
- ALWAYS link alerts to runbooks
- NEVER ignore warning-level logs
- ALWAYS expose health check endpoints
