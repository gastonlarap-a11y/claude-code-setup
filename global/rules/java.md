---
paths:
  - "**/*.java"
---

# Java rules
- Standard library first: `java.net.http.HttpClient` for HTTP, `java.util.concurrent` for concurrency. No Spring / Jakarta EE unless the build file (`pom.xml` / `build.gradle`) already declares it.
- Modern language features: `record` for DTOs/value carriers, pattern matching (`switch`, `instanceof`), sealed types for closed hierarchies.
- Explicit resource management: `try-with-resources` for every `AutoCloseable`; never leak streams, connections or clients.
- Virtual Threads for blocking I/O: `Executors.newVirtualThreadPerTaskExecutor()`; do not pool platform threads for I/O-bound work.
- Map failures to custom runtime exceptions at boundaries; never swallow `InterruptedException` — restore the flag with `Thread.currentThread().interrupt()` or propagate.
