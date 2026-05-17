# swift-oauth2-client

RFC 6749 OAuth 2.0 client — Sendable, public API Foundation-free; caller-driven HTTP transport. v0.1 token endpoint + v0.2 auth flow start (auth URL + PKCE + state/nonce + Basic auth) + v0.3 token caching + OIDC ID-token claim helpers.

Composes with [`swift-bearer`](https://github.com/bare-swift/swift-bearer) (resource access), [`swift-jwt-verify`](https://github.com/bare-swift/swift-jwt-verify) (ID token verification + signing), and [`swift-basic-auth`](https://github.com/bare-swift/swift-basic-auth) for the complete OIDC relying-party stack.

Part of the [bare-swift](https://github.com/bare-swift) ecosystem.

## Install

```swift
.package(url: "https://github.com/bare-swift/swift-oauth2-client.git", from: "0.3.0")
```

```swift
.product(name: "OAuth2Client", package: "swift-oauth2-client")
```

## Usage

### Authorization code flow with PKCE (public client)

```swift
import OAuth2Client
import Bytes

let client = OAuth2Client(
    tokenEndpoint: "https://issuer.example/oauth/token",
    clientID: "myapp"
)

let body: Bytes = client.requestBody(grant: .authorizationCode(
    code: "abc123",
    redirectURI: "https://myapp.example/callback",
    codeVerifier: "f9b7e8d6...some-43-char-base64url-random..."
))

// Caller wires the HTTP POST:
// POST https://issuer.example/oauth/token
// Content-Type: application/x-www-form-urlencoded
// Body: body.storage

let responseBody: Bytes = ... // from HTTP response
let token = try client.parseResponse(responseBody)
print(token.accessToken)
print(token.expiresIn ?? -1)
```

### Full auth flow (v0.2+) — auth URL build + PKCE + token exchange

```swift
import OAuth2Client

let client = OAuth2Client(
    tokenEndpoint: "https://issuer.example/oauth/token",
    clientID: "myapp"
)

// 1. Auth flow start: generate verifier + state, build URL, redirect user.
let verifier = OAuth2Client.PKCE.generateVerifier()
let challenge = OAuth2Client.PKCE.challenge(for: verifier, method: .s256)
let state = OAuth2Client.randomToken()
let nonce = OAuth2Client.randomToken()

let authURL = client.authorizationURL(
    authorizationEndpoint: "https://issuer.example/oauth/authorize",
    redirectURI: "https://myapp.example/callback",
    scope: "openid profile email",
    state: state,
    nonce: nonce,
    codeChallenge: challenge,
    codeChallengeMethod: .s256
)
// → "https://issuer.example/oauth/authorize?response_type=code&client_id=myapp&..."
// Caller redirects user to authURL. Persist `verifier` and `state` until callback.

// 2. Token exchange (after redirect callback delivers `code` + verified `state`).
let body = client.requestBody(grant: .authorizationCode(
    code: codeFromRedirect,
    redirectURI: "https://myapp.example/callback",
    codeVerifier: verifier
))
// ... wire HTTP POST, parse response with client.parseResponse(...) ...
```

### HTTP Basic client authentication (v0.2+)

```swift
let client = OAuth2Client(
    tokenEndpoint: "https://issuer.example/oauth/token",
    clientID: "myapp",
    clientSecret: "s3cret!",
    clientAuthMethod: .basic    // v0.2+; default .body
)

let body = client.requestBody(grant: .clientCredentials())
// `client_id` + `client_secret` omitted from body when .basic.

let header = client.basicAuthHeader()
// header = ("Authorization", "Basic bXlhcHA6czNjcmV0JTIx")

// Caller wires the HTTP POST with both:
//   Content-Type: application/x-www-form-urlencoded
//   Authorization: Basic bXlhcHA6czNjcmV0JTIx
//   Body: body.storage
```

Per RFC 6749 § 2.3.1, `client_id` and `client_secret` are form-urlencoded BEFORE being base64-encoded as `"id:secret"` (different from plain RFC 7617 Basic).

### Client credentials flow (confidential client)

```swift
let client = OAuth2Client(
    tokenEndpoint: "https://issuer.example/oauth/token",
    clientID: "service-account",
    clientSecret: "hunter2"
)
let body = client.requestBody(grant: .clientCredentials(scope: "read write"))
// ... wire HTTP POST and parse response ...
```

### Refresh token flow

```swift
let body = client.requestBody(grant: .refreshToken("rt-abc123"))
```

### Token caching (v0.3+)

```swift
import OAuth2Client

let storage = InMemoryTokenStorage()
let client = OAuth2Client(...)

// On each request:
func now() -> UInt64 {
    UInt64(Date().timeIntervalSince1970)  // or any other clock
}

if let cached = await storage.load(),
   !cached.isExpired(at: now(), threshold: 60) {
    // Reuse cached.response.accessToken
    useToken(cached.response)
} else {
    // Trigger token exchange — caller wires HTTP:
    let body = client.requestBody(grant: .clientCredentials(scope: "read"))
    // ... POST tokenEndpoint, receive responseBytes ...
    let response = try client.parseResponse(responseBytes)
    let cached = CachedToken(response: response, obtainedAt: now())
    await storage.store(cached)
    useToken(response)
}
```

`TokenStorage` is a passive cache — it stores tokens and reports expiry,
but callers orchestrate HTTP refresh externally (matching the
caller-driven-HTTP pattern from v0.1/v0.2). The provided
`InMemoryTokenStorage` actor backs the default in-process case;
adopters implement `TokenStorage` for Keychain, Redis, filesystem, etc.

`CachedToken.isExpired(at:threshold:)` supports refresh-before-strict-
expiry via the optional `threshold` parameter (seconds).

### OIDC ID-token claims (v0.3+)

When the token endpoint returns an `id_token` field (OpenID Connect Core
1.0 § 3.1.3.3), it's surfaced on `TokenResponse.idToken: String?`.
Standard claims can be extracted via `OIDCClaims.parse(_:)`:

```swift
let response = try client.parseResponse(responseBytes)
if let idToken = response.idToken {
    let claims = try OIDCClaims.parse(idToken)
    // claims.iss, claims.sub, claims.aud, claims.exp, claims.iat, claims.nonce
}
```

**`OIDCClaims.parse(_:)` does NOT verify the JWT signature.** It only
base64url-decodes the JWT payload and extracts standard claim fields.
Callers verify the signature externally (e.g., via swift-jwt-verify) and
validate claim semantics (`iss` against expected issuer, `aud` against
client ID, `exp` against current time, `nonce` against the original
`OAuth2Client.randomToken()` value).

For multi-value `aud` (array form), v0.3 returns empty `[]`; v0.4 may
add richer claim parsing if adopter demand surfaces.

## Documentation

Full DocC documentation: <https://bare-swift.github.io/swift-oauth2-client/>

## License

Apache 2.0 with LLVM exception. See [LICENSE](./LICENSE) and [NOTICE](./NOTICE).
