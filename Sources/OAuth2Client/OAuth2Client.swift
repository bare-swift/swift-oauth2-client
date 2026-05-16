// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes

/// RFC 6749 OAuth 2.0 token-endpoint client.
///
/// Sendable + value-type; construct once and reuse across requests.
/// Caller-driven HTTP transport: ``requestBody(grant:)`` emits the request
/// body bytes; the caller wires the HTTP POST.
///
/// ```swift
/// let client = OAuth2Client(
///     tokenEndpoint: "https://issuer.example/oauth/token",
///     clientID: "myapp"
/// )
/// let body = client.requestBody(grant: .authorizationCode(
///     code: "abc", redirectURI: "https://app.example/cb", codeVerifier: "v"
/// ))
/// // POST tokenEndpoint, Content-Type: application/x-www-form-urlencoded
/// let token = try client.parseResponse(responseBody)
/// ```
public struct OAuth2Client: Sendable {
    /// Token endpoint URL (for documentation; caller uses it to wire the HTTP POST).
    public let tokenEndpoint: String

    /// `client_id` per RFC 6749 § 2.2.
    public let clientID: String

    /// `client_secret` per RFC 6749 § 2.3.1, or nil for public clients.
    /// When non-nil, included in the request body alongside `client_id`.
    public let clientSecret: String?

    public init(tokenEndpoint: String, clientID: String, clientSecret: String? = nil) {
        self.tokenEndpoint = tokenEndpoint
        self.clientID = clientID
        self.clientSecret = clientSecret
    }

    /// Emit `application/x-www-form-urlencoded` body bytes for the given grant.
    /// Caller wires the HTTP POST with `Content-Type: application/x-www-form-urlencoded`.
    public func requestBody(grant: GrantType) -> Bytes {
        var buf = Bytes()
        grant.appendFields(to: &buf)
        FormEncoder.appendField(&buf, key: "client_id", value: clientID)
        if let secret = clientSecret {
            FormEncoder.appendField(&buf, key: "client_secret", value: secret)
        }
        return buf
    }

    /// Parse HTTP response body bytes. Detects both RFC 6749 § 5.1 success
    /// and § 5.2 error shapes.
    ///
    /// - Throws:
    ///   - ``OAuth2ClientError/malformedJSON`` if bytes aren't a JSON object.
    ///   - ``OAuth2ClientError/oauthError(code:description:)`` if the response
    ///     is a § 5.2 error.
    ///   - ``OAuth2ClientError/invalidResponse`` if required success fields
    ///     (`access_token`, `token_type`) are missing.
    public func parseResponse(_ body: Bytes) throws(OAuth2ClientError) -> TokenResponse {
        try JSONScanner.validateJSONObject(body)
        // Error-shape detection precedes success-shape (some servers return
        // 200 + error body).
        if let errorCode = try JSONScanner.string(forKey: "error", in: body) {
            let description = try JSONScanner.string(forKey: "error_description", in: body)
            throw .oauthError(code: errorCode, description: description)
        }
        guard let accessToken = try JSONScanner.string(forKey: "access_token", in: body) else {
            throw .invalidResponse
        }
        guard let tokenType = try JSONScanner.string(forKey: "token_type", in: body) else {
            throw .invalidResponse
        }
        let expiresIn = try JSONScanner.int(forKey: "expires_in", in: body)
        let refreshToken = try JSONScanner.string(forKey: "refresh_token", in: body)
        let scope = try JSONScanner.string(forKey: "scope", in: body)
        return TokenResponse(
            accessToken: accessToken,
            tokenType: tokenType,
            expiresIn: expiresIn,
            refreshToken: refreshToken,
            scope: scope
        )
    }
}
