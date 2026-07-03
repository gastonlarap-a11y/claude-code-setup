---
name: new-module
description: Scaffold a new NestJS feature module (module, controller, service, DTOs, tests) following my template layout.
disable-model-invocation: true
---

# Scaffold a NestJS feature module

Create a new feature module named "$ARGUMENTS" (kebab-case directory, PascalCase classes).

1. Check the repo for an existing feature module and mirror its exact layout and style. If the repo is empty, use my NestJS template under `~/Documents/Git/` as the reference.
2. Create under `src/<feature>/`:
   - `<feature>.module.ts` — imports only what it needs; exports only the service.
   - `<feature>.controller.ts` — versioned route (`@Controller({ path: '<feature>', version: '1' })`), DTO-validated inputs, OpenAPI annotations per the `api-conventions` skill.
   - `<feature>.service.ts` — constructor-injected dependencies, explicit error handling (domain errors → Nest HTTP exceptions).
   - `dto/create-<feature>.dto.ts`, `dto/update-<feature>.dto.ts` (`PartialType` of create), with `class-validator` decorators.
3. Register the module in `AppModule` (or the closest aggregating module).
4. Create tests per the `testing` skill: `<feature>.service.spec.ts`, `<feature>.controller.spec.ts`, and `test/<feature>.e2e-spec.ts` covering happy path + validation + not-found.
5. Run lint, typecheck and tests; report real results.
