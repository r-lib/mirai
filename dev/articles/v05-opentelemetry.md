# mirai - OpenTelemetry

### 1. Introduction

mirai provides comprehensive OpenTelemetry (otel) tracing for observing
async operations and distributed computation.

With `otel` and `otelsdk` installed and tracing enabled, mirai
automatically creates spans tracking daemon management, async
operations, and task execution lifecycles.

**Detailed monitoring of:**

- Task submission and completion times
- Daemon lifecycle and performance
- Error tracking and debugging
- Distributed tracing across network boundaries

### 2. Automatic Tracing Setup

Tracing enables automatically when:

1.  `otel` and `otelsdk` packages are installed
2.  OpenTelemetry tracing is configured and enabled (see
    <https://otelsdk.r-lib.org/reference/collecting.html>)

No additional action needed - mirai automatically detects OpenTelemetry
and begins tracing.

### 3. Span Types and Hierarchy

mirai creates several span types representing different operations.

#### 3.1 Core Span Types

**`daemons set` / `daemons reset`**

Root span for a compute profile, created when daemons are set/reset.
Span name includes URL for easy identification.

- Kind: `internal`
- Attributes:
  - `server.address` (e.g. ‘127.0.0.1’ or ‘hostname’)
  - `server.port` (where applicable)
  - `network.transport` (e.g. ‘tcp’ or ‘ipc’)
  - `mirai.dispatcher` (true/false)
  - `mirai.compute` (profile name)

**`daemon connect` / `daemon disconnect`**

Daemon process span, created when a daemon connects/disconnects. Span
name includes URL for easy identification.

- Kind: `internal`
- Attributes:
  - `server.address` (e.g. ‘127.0.0.1’ or ‘hostname’)
  - `server.port` (where applicable)
  - `network.transport` (e.g. ‘tcp’ or ‘ipc’)

**`mirai_map`**

Parallel map operation span encompassing the entire map operation across
multiple mirai tasks.

- Kind: `internal`

**`mirai`**

Client-side async task span. Created when
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) is called,
ends when it returns.

- Kind: `client`
- Attributes: `mirai.id` (unique task identifier)

**`daemon eval`**

Server-side task evaluation span. Tracks actual mirai evaluation
duration on the daemon.

- Kind: `server`

#### 3.2 Span Relationships and Context Propagation

Spans form a distributed structure tracing the complete async operation
lifecycle:

    daemons set (compute profile - top level)
    daemon connect (daemon process 1 - top level)
    ...
    daemon connect (daemon process N - top level)

    mirai_map (top level) ──link→ daemons set
    ├── mirai (task 1) ──link→ daemons set
    │   └── daemon eval ──link→ daemon connect
    ├── mirai (task 2) ──link→ daemons set
    │   └── daemon eval ──link→ daemon connect
    └── mirai (task N) ──link→ daemons set
        └── daemon eval ──link→ daemon connect
        
    mirai (top level) ──link→ daemons set
    └── daemon eval ──link→ daemon connect

    daemons reset ──link→ daemons set
    daemon disconnect (daemon process 1) ──link→ daemon connect
    ...
    daemon disconnect (daemon process N) ──link→ daemon connect

**Context Propagation**: Context automatically packaged with each
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call and
extracted on the daemon side, enabling proper parent-child relationships
across process boundaries.

**Span Links**: Tasks link to their compute profile’s `daemons set` span
(client-side) and each `daemon connect` span (server-side), showing
exactly where evaluation occurred. When daemons reset and disconnect,
new spans record these events linking back to the originals.

### 4. Status and Error Tracking

`daemon eval` spans automatically track operation success or failure.

**Status Values:**

- `'ok'` or `'unset'` - successful completion
- `'error'` with description `'miraiError'` - error failure
- `'error'` with description `'miraiInterrupt'` - interrupted

### 5. Monitoring and Observability

OpenTelemetry spans provide rich observability into mirai operations.

**Performance Monitoring:**

- Track task execution times (submission to completion)
- Monitor daemon utilization and load balancing
- Identify distributed computation bottlenecks

**Error Analysis:**

- Correlate errors with specific tasks and daemons
- Track error rates across operation types
- Debug distributed environment issues

**Distributed Tracing:**

- Follow task execution across network boundaries
- Understand complete async operation lifecycles
- Correlate client-side requests with server-side execution

### 6. Integration with Observability Platforms

mirai’s OpenTelemetry implementation works seamlessly with any
compatible observability platform:

- Grafana
- Pydantic Logfire
- Jaeger
- Any listed at <https://otelsdk.r-lib.org/reference/collecting.html>

The tracer name `org.r-lib.mirai` enables easy filtering and
identification of mirai-related traces.
