// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// RFC 6749 § 5.1 access-token success response.
public struct TokenResponse: Sendable, Equatable {
    /// The access token issued by the authorization server.
    public let accessToken: String

    /// The type of token (typically `"Bearer"`).
    public let tokenType: String

    /// Lifetime in seconds of the access token (optional per spec).
    public let expiresIn: Int?

    /// Optional refresh token usable to obtain new access tokens.
    public let refreshToken: String?

    /// Optional scope string (caller splits on space if multi-scope).
    public let scope: String?

    /// OIDC `id_token` (RFC 7519 JWT) if present in the response (v0.3+).
    /// Caller verifies signature externally (e.g., via swift-jwt-verify);
    /// use ``OIDCClaims/parse(_:)`` to extract standard claims.
    public let idToken: String?

    public init(
        accessToken: String,
        tokenType: String,
        expiresIn: Int? = nil,
        refreshToken: String? = nil,
        scope: String? = nil,
        idToken: String? = nil
    ) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
        self.scope = scope
        self.idToken = idToken
    }
}
