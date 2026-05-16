# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
