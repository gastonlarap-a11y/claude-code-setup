---
name: architecture
description: NestJS project architecture with the Fastify adapter — module boundaries, dependency injection, configuration and DTO conventions. Use when creating or restructuring NestJS modules, providers, controllers, or wiring configuration.
---

# NestJS architecture conventions

## Runtime
- Always use the Fastify adapter (`@nestjs/platform-fastify`), never Express.
- Enable `rawBody` only in modules that verify webhook signatures.
- Global pipes: `ValidationPipe` with `{ whitelist: true, forbidNonWhitelisted: true, transform: true }`.

## Module boundaries
- One feature = one module (`src/<feature>/`): `<feature>.module.ts`, controller, service, `dto/`, `entities/`.
- Modules expose a small public surface: export only the service(s) other modules need; never export repositories.
- Shared cross-cutting code lives in `src/common/` (guards, interceptors, filters, decorators) — no business logic there.
- No circular imports between feature modules; if two modules need each other, extract the shared part into its own module or emit events.

## Dependency injection
- Constructor injection only; mark dependencies `private readonly`.
- Depend on abstractions when there are multiple implementations (injection token + interface); otherwise inject concrete providers — don't add tokens speculatively.
- `forwardRef` is a design smell: restructure instead of using it.

## Configuration
- `@nestjs/config` with a validation schema (zod or Joi) — the app must fail fast on missing env vars.
- Use namespaced config (`registerAs`) and inject typed config objects; never read `process.env` outside the config layer.

## DTOs and validation
- Every controller input has a DTO class with `class-validator` decorators; responses use explicit serialization (`ClassSerializerInterceptor` or mapped response DTOs).
- DTOs live in the feature's `dto/` directory; suffix `*.dto.ts`. Use `PartialType`/`PickType` from `@nestjs/mapped-types` (or `@nestjs/swagger`) instead of duplicating fields.

## Error handling
- Throw Nest HTTP exceptions (`NotFoundException`, etc.) at the controller/service boundary; map domain errors to HTTP errors in one exception filter, not scattered try/catch.
- Never swallow errors: log with context (request id, entity id) and rethrow or translate.
