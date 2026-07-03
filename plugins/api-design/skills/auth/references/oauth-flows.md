# OAuth2 / OIDC flow reference

## Authorization Code + PKCE (the default — web, mobile, SPA, desktop)
1. Client generates `code_verifier` (random 43–128 chars) and `code_challenge = BASE64URL(SHA256(verifier))`.
2. Redirect to authorize endpoint: `response_type=code`, `client_id`, `redirect_uri`, `scope` (include `openid` for OIDC), `state` (CSRF), `code_challenge(+_method=S256)`, `nonce` (OIDC).
3. Callback: verify `state`; exchange `code` + `code_verifier` at token endpoint → `access_token`, `refresh_token?`, `id_token` (OIDC).
4. Validate `id_token`: signature via JWKS, `iss`, `aud`, `exp`, `nonce`.
- Confidential clients (server-side web) also send `client_secret` at exchange; public clients (mobile/SPA) rely on PKCE only.
- Mobile: use the platform's app-auth library with a custom scheme or App Links/Universal Links redirect; never a WebView (use Custom Tabs / ASWebAuthenticationSession).

## Client Credentials (service→service)
- `grant_type=client_credentials` + client id/secret (or private_key_jwt / mTLS for higher assurance) → access token with service scopes. No refresh tokens; just request again.

## Device Authorization Grant (TVs, CLIs)
- Device gets `device_code` + `user_code` + verification URL; polls token endpoint while user approves on another device. Use for CLI tools instead of pasting long-lived tokens.

## Refresh token rotation
- Each refresh issues a new refresh token and invalidates the old one; presenting an already-used token means theft → revoke the whole token family and force re-login.

## Deprecated — do not implement
- Implicit flow (`response_type=token`), Resource Owner Password Credentials (ROPC), long-lived non-rotating refresh tokens in browsers.

## Scopes
- Coarse, product-shaped scopes (`orders:read`, `orders:write`), documented; fine-grained permissions live in your authZ layer, not in a 40-scope token.
