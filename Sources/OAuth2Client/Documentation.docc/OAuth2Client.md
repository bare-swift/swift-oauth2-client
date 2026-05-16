# ``OAuth2Client``

RFC 6749 OAuth 2.0 client — Sendable, public API Foundation-free; caller-driven HTTP transport. v0.1 covers the token endpoint (back half); v0.2 adds the auth flow start (front half).

## Overview

`OAuth2Client` emits `application/x-www-form-urlencoded` request bodies for the OAuth 2.0 token endpoint and parses RFC 6749 § 5.1 success / § 5.2 error JSON responses. Caller wires the HTTP POST (matches the bare-swift trinity's "package emits/accepts `Bytes`" pattern). PKCE is supported via the `codeVerifier:` parameter on the authorization-code grant; PKCE verifier/challenge generation is the caller's responsibility (compose with swift-crypto).

```swift
import OAuth2Client
import Bytes

let client = OAuth2Client(
    tokenEndpoint: "https://issuer.example/oauth/token",
    clientID: "myapp"
)
let body: Bytes = client.requestBody(grant: .authorizationCode(
    code: "abc",
    redirectURI: "https://myapp.example/callback",
    codeVerifier: "verifier-xyz"
))
// POST tokenEndpoint with Content-Type: application/x-www-form-urlencoded
let token = try client.parseResponse(responseBody)
```

Composes with `swift-bearer` (resource access), `swift-jwt-verify` (ID token verification + signing), and `swift-basic-auth` (client authentication via Basic header) for the complete OIDC relying-party stack.

Per [RFC-0025](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0025-phase-20-anchor-swift-oauth2-client.md) (Phase 20 Tranche 20A — v0.1 token endpoint) and [RFC-0031](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0031-phase-26-anchor-swift-oauth2-client-v0.2-auth-flow.md) (Phase 26 Tranche 26A — v0.2 auth flow start).

**Auth flow start** (v0.2+):

```swift
let verifier = OAuth2Client.PKCE.generateVerifier()
let challenge = OAuth2Client.PKCE.challenge(for: verifier, method: .s256)
let state = OAuth2Client.randomToken()

let url = client.authorizationURL(
    authorizationEndpoint: "https://issuer.example/oauth/authorize",
    redirectURI: "https://app.example/cb",
    scope: "openid profile",
    state: state,
    codeChallenge: challenge,
    codeChallengeMethod: .s256
)
```

## Topics

### Client

- ``OAuth2Client``
- ``ClientAuthMethod``

### Grants

- ``GrantType``

### Authorization flow (v0.2+)

- ``OAuth2Client/PKCE``
- ``PKCEMethod``
- ``OAuth2Client/randomToken(byteCount:)``

### Response

- ``TokenResponse``

### Errors

- ``OAuth2ClientError``
