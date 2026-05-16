# ``OAuth2Client``

RFC 6749 OAuth 2.0 token-endpoint client — Sendable, Foundation-free; caller-driven HTTP transport.

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

Per [RFC-0025](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0025-phase-20-anchor-swift-oauth2-client.md), this is Tranche 20A of Phase 20.

## Topics

### Client

- ``OAuth2Client``

### Grants

- ``GrantType``

### Response

- ``TokenResponse``

### Errors

- ``OAuth2ClientError``
