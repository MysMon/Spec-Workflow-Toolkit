---
name: observability
description: |
  Observability patterns for logging, metrics, and distributed tracing. Use when:
  - Implementing structured logging
  - Setting up metrics and monitoring
  - Adding distributed tracing
  - Implementing health checks (liveness, readiness)
  - Designing alerts or SLO-based monitoring
  Trigger phrases: logging, metrics, tracing, monitoring, health check, alerting, SLO, structured logs, observability
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, WebSearch, WebFetch
model: sonnet
user-invocable: true
---

# Observability

Stack-agnostic patterns for building observable systems through logging, metrics, and tracing. This skill defines **concepts and patterns**, not specific library implementations.

## Design Principles

1. **Concepts over libraries**: Teach patterns that work across any stack
2. **Discover project tools**: Check what observability tools the project uses
3. **Research when implementing**: Use WebSearch for current library recommendations
4. **Follow project conventions**: Match existing logging/metrics patterns

---

## Three Pillars of Observability

### 1. Logging

Structured, contextual logs for debugging and auditing.

### 2. Metrics

Numerical measurements for monitoring and alerting.

### 3. Tracing

Distributed request tracking across services.

---

## Structured Logging

### Log Format Principles

A well-structured log entry should include:

```json
{
  "timestamp": "ISO 8601 format",
  "level": "INFO/WARN/ERROR/DEBUG",
  "service": "service identifier",
  "trace_id": "correlation ID for request tracking",
  "message": "human-readable description",
  "context": {
    "relevant": "contextual data"
  }
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

**DO:**
- Use structured logging (JSON or similar)
- Include correlation/trace IDs
- Log at service boundaries
- Include relevant context
- Use consistent field names across services

**DON'T:**
- Log sensitive data (passwords, tokens, PII)
- Log at high frequency in loops
- Use string concatenation for log messages
- Log entire request/response bodies
- Use print statements in production

### Implementation

When implementing logging:

1. **Discover existing patterns**: Check how the project currently logs
2. **Research current libraries**:
   ```
   WebSearch: "[language] structured logging library [year]"
   ```
3. **Follow project conventions**: Match existing log format and style

---

## Metrics

### Metric Types

| Type | Use Case | Example |
|------|----------|---------|
| Counter | Cumulative values (only increase) | Request count, errors |
| Gauge | Point-in-time values (can go up/down) | Active connections, queue size |
| Histogram | Distribution of values | Request latency, response size |
| Summary | Pre-calculated quantiles | p50, p99 latency |

### Naming Conventions

```
Format: <namespace>_<name>_<unit>

Good examples:
- http_requests_total
- http_request_duration_seconds
- database_connections_active
- queue_messages_waiting

Bad examples:
- requests              (no namespace, no unit)
- httpRequestDuration   (camelCase, inconsistent)
- request-latency       (hyphens, no unit)
```

### Key Metrics Frameworks

**RED Method (Request-oriented):**
- **R**ate: Requests per second
- **E**rrors: Error rate
- **D**uration: Latency percentiles

**USE Method (Resource-oriented):**
- **U**tilization: Percentage time busy
- **S**aturation: Queue length/backlog
- **E**rrors: Error count

**Four Golden Signals:**
- Latency: Time to serve requests
- Traffic: Demand on system
- Errors: Rate of failed requests
- Saturation: How "full" the system is

### Implementation

When implementing metrics:

1. **Identify what to measure**: Use RED/USE/Golden Signals as guide
2. **Discover existing setup**: Check if project has metrics infrastructure
3. **Research current tools**:
   ```
   WebSearch: "[language] metrics library [year]"
   WebSearch: "metrics collection [your infrastructure] [year]"
   ```

---

## Distributed Tracing

### Trace Concepts

```
Trace (entire request journey)
├── Span A: API Gateway (parent)
│   ├── Span B: Auth Service
│   └── Span C: User Service
│       └── Span D: Database Query
```

- **Trace**: End-to-end request journey across services
- **Span**: Single operation within a trace
- **Context**: Propagated trace/span IDs

### Trace Context Propagation

Standard headers for context propagation:

| Standard | Description |
|----------|-------------|
| W3C Trace Context | Modern standard (traceparent, tracestate) |
| B3 | Zipkin format (X-B3-* headers) |

### Best Practices

- Propagate trace context across all service boundaries
- Include trace IDs in logs for correlation
- Sample traces in high-traffic environments
- Add meaningful span names and attributes

### Implementation

When implementing tracing:

1. **Check existing setup**: Does project already have tracing?
2. **Research current standards**:
   ```
   WebSearch: "distributed tracing [language] [year]"
   WebSearch: "[tracing platform] integration guide"
   ```

---

## Health Checks

### Endpoint Design

```json
// GET /health
{
  "status": "healthy|degraded|unhealthy",
  "version": "app version",
  "uptime_seconds": 3600,
  "checks": {
    "database": {
      "status": "healthy",
      "latency_ms": 5
    },
    "cache": {
      "status": "healthy",
      "latency_ms": 2
    },
    "external_api": {
      "status": "degraded",
      "message": "High latency"
    }
  }
}
```

### Kubernetes Health Checks

| Check | Purpose | Failure Action |
|-------|---------|----------------|
| Liveness | Is app running? | Restart container |
| Readiness | Can handle requests? | Remove from load balancer |
| Startup | Has app started? | Don't check liveness yet |

---

## Alerting

### Alert Design Principles

**Good alerts include:**
- Clear, actionable name
- Threshold with duration (avoid flapping)
- Severity level
- Link to runbook
- Relevant labels/context

**Avoid:**
- Flapping alerts (too sensitive thresholds)
- Alerts on symptoms only (dig to root cause)
- Too many alerts (alert fatigue)
- Alerts without runbooks

### SLO-Based Alerting

```
SLI: 99.9% of requests complete in < 200ms
SLO: 99.9% success rate over 30 days
Error Budget: 0.1% = ~43 minutes/month

Alert when:
- Burn rate > 1x: Slow burn, low severity
- Burn rate > 10x: Fast burn, high severity
```

---

## Implementation Checklist

- [ ] Structured logging configured
- [ ] Log levels appropriate for environment
- [ ] Sensitive data excluded from logs
- [ ] Key metrics identified (RED/USE framework)
- [ ] Metrics endpoint exposed (/metrics)
- [ ] Trace context propagated across services
- [ ] Health endpoints implemented (/health)
- [ ] Alerts defined for critical paths
- [ ] Runbooks linked to alerts

---

## Rules (L1 - Hard)

Critical for security and operational safety.

- NEVER log sensitive data (PII, tokens, passwords) - security requirement
- ALWAYS propagate trace context across services (enables debugging)
- ALWAYS include correlation IDs in logs (request tracing)

## Defaults (L2 - Soft)

Important for operational quality. Override with reasoning when appropriate.

- Use structured logging (not print/console.log)
- Expose health check endpoints for orchestration
- Discover existing project patterns before implementing
- Use WebSearch for current library recommendations
- Link alerts to runbooks

## Guidelines (L3)

Recommendations for comprehensive observability.

- Consider using RED/USE/Golden Signals frameworks for metrics
- Prefer sampling traces in high-traffic environments
- Consider SLO-based alerting over threshold-based
