# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0] — 2026-05-16

### Added — Auth flow start
- **Authorization URL builder** — `OAuth2Client.authorizationURL(authorizationEndpoint:redirectURI:scope:state:nonce:codeChallenge:codeChallengeMethod:responseType:additionalParams:) -> String` per RFC 6749 § 4.1.1. Always emits `response_type`/`client_id`/`redirect_uri`; optional params emit only when set; `additionalParams` for issuer-specific extensions (e.g., `prompt`, `audience`, `login_hint`).
- **PKCE primitives** (RFC 7636) — `OAuth2Client.PKCE.generateVerifier(byteCount:) -> String` (default 32 bytes → 43-char base64url verifier) + `OAuth2Client.PKCE.challenge(for:method:) -> String` (`.plain` returns verifier verbatim; `.s256` returns `base64url(SHA256(verifier))`). `PKCEMethod` public enum with `.rfc7636Name` mapping to `"plain"`/`"S256"`.
- **Random token generator** — `OAuth2Client.randomToken(byteCount:) -> String` (default 16 bytes → 22-char base64url) for OAuth `state` / OIDC `nonce` parameters. CSPRNG via Swift's `SystemRandomNumberGenerator`.

### Added — Client authentication
- **`ClientAuthMethod` enum** — `.body` (v0.1 default; credentials in form-encoded body) or `.basic` (credentials in `Authorization: Basic` header per RFC 6749 § 2.3.1).
- **`OAuth2Client.clientAuthMethod`** field + new init parameter (default `.body` preserves v0.1).
- **`OAuth2Client.basicAuthHeader() -> (name: String, value: String)?`** — returns `("Authorization", "Basic <encoded>")` when `.basic` + `clientSecret` set; nil when `.body` or `clientSecret` nil. Per RFC 6749 § 2.3.1, `client_id` and `client_secret` are form-urlencoded BEFORE base64 (different from plain RFC 7617 Basic).
- `requestBody(grant:)` updated: when `.basic`, omits `client_id` + `client_secret` from body (caller attaches header instead). v0.1 byte-equality preserved for `.body` (regression-tested).

### Dependencies
- swift-crypto 3.0+ added (first time on swift-oauth2-client; needed for SHA256 in PKCE S256). Foundation-in-internal-only pattern: `PKCE.swift` imports Foundation for swift-crypto's `Data` bridging; public API stays Foundation-free.
- swift-base64 still NOT a dep — inline `Base64` helper (~80 LOC) covers standard + URL-safe variants.

### Migration (v0.1 → v0.2)
- **Additive only — non-breaking.** All v0.1 APIs unchanged.
- `OAuth2Client(tokenEndpoint:clientID:clientSecret:)` continues to work — new `clientAuthMethod` param has default `.body`.
- `requestBody(grant:)` byte-equal for `.body` auth method (regression-tested).
- `parseResponse(_:)` byte-for-byte unchanged.
- `OAuth2ClientError` unchanged (no new cases).

### Tests
- 26 new tests across 4 new suites: `Base64Tests` (internal helper), `PKCETests` (including RFC 7636 § 4.2 worked-example: verifier `"dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"` → S256 challenge `"E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"`), `AuthorizationURLTests` (per-param emission, encoding, additionalParams), `ClientAuthMethodTests` (.body regression + .basic flow + RFC 6749 § 2.3.1 worked encoding). Total package tests: 52 (up from 26).

### Out of scope (deferred to v0.3+)
- Token caching / lifecycle / auto-refresh.
- OIDC ID-token helpers (composes with swift-jwt-verify).
- Implicit / password / device-code grants.
- mTLS / `private_key_jwt` client authentication.
- JWT-based `client_assertion`.
- HTTP transport (caller wires).

### Phase 26
- Tranche 26A of [RFC-0031](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0031-phase-26-anchor-swift-oauth2-client-v0.2-auth-flow.md). Completes OAuth 2.0 client coverage: v0.1 token endpoint (back half) + v0.2 auth flow start (front half).

## [0.1.0] - 2026-05-16

### Added
- `OAuth2Client` struct — Sendable + value-type OAuth 2.0 token-endpoint client. `(tokenEndpoint, clientID, clientSecret?)` config; `requestBody(grant:)` emits `application/x-www-form-urlencoded` bytes; `parseResponse(_:)` parses RFC 6749 § 5.1 success or § 5.2 error JSON responses.
- `GrantType` enum: `.clientCredentials(scope:)`, `.authorizationCode(code:redirectURI:codeVerifier:)`, `.refreshToken(_:scope:)`. PKCE supported via `codeVerifier:` parameter.
- `TokenResponse` struct: `accessToken`, `tokenType`, `expiresIn?`, `refreshToken?`, `scope?`.
- `OAuth2ClientError` typed-throws enum: `.invalidResponse`, `.oauthError(code:description:)`, `.malformedJSON`.
- 26 tests across 6 suites covering struct shape, per-grant body emission, exact-bytes request bodies, success/error response parsing, FormEncoder spec cases, JSONScanner field extraction.

### Dependencies
- swift-bytes 0.1.0 — single direct dep.
- **Foundation-free entirely.** No swift-crypto, no swift-base64, no swift-uri, no swift-json. Hand-rolled `FormEncoder` (~50 LOC) + `JSONScanner` (~100 LOC).

### Client authentication
- v0.1 emits `client_id` + `client_secret` in the request body per RFC 6749 § 2.3.1.
- Adopters needing HTTP Basic auth: construct with `clientSecret: nil` and build the `Authorization: Basic` header externally (swift-basic-auth + swift-base64 are in the ecosystem).
- `ClientAuthMethod` knob deferred to v0.2.

### Out of scope for v0.1 (deferred to v0.2+)
- Authorization URL building.
- PKCE verifier/challenge generation (caller computes via swift-crypto + swift-base64).
- State / nonce generation.
- Token caching / lifecycle / auto-refresh.
- OIDC-specific helpers (ID-token verification composes with swift-jwt-verify).
- Implicit / password / device-code grants.
- mTLS / `private_key_jwt` client authentication.
- HTTP transport (caller wires).

### Phase 20
- Tranche 20A of [RFC-0025](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0025-phase-20-anchor-swift-oauth2-client.md). Closes the 8-rejection deferral on OAuth 2.0; adds the composition layer that ties swift-jwt-verify + swift-bearer + swift-basic-auth into a complete auth-client stack.
