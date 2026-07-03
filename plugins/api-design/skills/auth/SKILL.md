---
name: auth
description: API authentication and authorization patterns — choosing between JWT sessions, OAuth2/OIDC flows, API keys and mTLS; token lifetimes, storage and rotation. Use when adding auth to an API or client, or reviewing auth code.
---

# API auth

## Which mechanism
- **First-party login (your users, your API)**: short-lived JWT access token (5–15 min) + rotating refresh token. Web: refresh token in `HttpOnly; Secure; SameSite` cookie — never localStorage. Mobile: secure storage (Keystore/Keychain).
- **Third-party identity ("login with X") / SSO**: OAuth2 Authorization Code **with PKCE** via OIDC. Never implicit flow, never ROPC. Flow details: [references/oauth-flows.md](references/oauth-flows.md).
- **Service-to-service**: OAuth2 Client Credentials (or mTLS inside a mesh). No user tokens between services.
- **External developers/machines calling your API**: API keys — hashed at rest, prefixed (`sk_live_`), scoped, revocable, with per-key rate limits. Keys identify, they don't authorize by themselves.

## JWT rules
- Validate on every request: signature (`alg` allowlist — reject `none`), `iss`, `aud`, `exp` with small clock skew. Verify against JWKS with caching + key rotation support.
- Keep claims minimal (sub, scopes/roles, tenant); no PII. Access tokens are bearer: treat leakage as compromise — hence short TTLs.
- Revocation: access tokens expire fast; refresh tokens are server-side records (rotate on use, detect reuse → revoke family).

## Authorization
- AuthN says who; authZ decides what. Enforce at one layer (guard/middleware/interceptor) driven by declarative requirements (roles/permissions per route), not ad-hoc `if` checks in handlers.
- Multi-tenant: tenant id derives from the token, never from the request body/query; every query is tenant-scoped at the data layer.

## Hygiene
- All auth endpoints rate-limited + audit-logged (login, refresh, key creation).
- Secrets/keys via env or secret manager; rotation documented. TLS everywhere; HSTS on web.
- Don't hand-roll crypto or password hashing: argon2id/bcrypt via the platform's vetted library.
