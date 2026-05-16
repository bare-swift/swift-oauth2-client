# swift-oauth2-client

RFC 6749 OAuth 2.0 token-endpoint client — Sendable, Foundation-free; caller-driven HTTP transport.

Composes with [`swift-bearer`](https://github.com/bare-swift/swift-bearer) (resource access), [`swift-jwt-verify`](https://github.com/bare-swift/swift-jwt-verify) (ID token verification + signing), and [`swift-basic-auth`](https://github.com/bare-swift/swift-basic-auth) (client authentication via Basic header) for the complete OIDC relying-party stack.

Part of the [bare-swift](https://github.com/bare-swift) ecosystem. Phase 20 Tranche 20A.

## Install

```swift
.package(url: "https://github.com/bare-swift/swift-oauth2-client.git", from: "0.1.0")
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

## Documentation

Full DocC documentation: <https://bare-swift.github.io/swift-oauth2-client/>

## License

Apache 2.0 with LLVM exception. See [LICENSE](./LICENSE) and [NOTICE](./NOTICE).
