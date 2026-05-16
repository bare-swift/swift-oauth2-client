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
    /// When `clientAuthMethod == .body` and `clientSecret != nil`, the secret
    /// is included in the request body alongside `client_id`. When
    /// `.basic`, the secret feeds into ``basicAuthHeader()``.
    public let clientSecret: String?

    /// How `client_id` + `client_secret` are conveyed to the token endpoint
    /// (RFC 6749 § 2.3.1). Default `.body` preserves v0.1 behavior.
    public let clientAuthMethod: ClientAuthMethod

    public init(
        tokenEndpoint: String,
        clientID: String,
        clientSecret: String? = nil,
        clientAuthMethod: ClientAuthMethod = .body
    ) {
        self.tokenEndpoint = tokenEndpoint
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.clientAuthMethod = clientAuthMethod
    }

    /// Emit `application/x-www-form-urlencoded` body bytes for the given grant.
    /// Caller wires the HTTP POST with `Content-Type: application/x-www-form-urlencoded`.
    ///
    /// When ``clientAuthMethod`` is `.body` (v0.1 default), the body includes
    /// `client_id` (and `client_secret` if non-nil). When `.basic`, credentials
    /// are omitted from the body — the caller attaches the
    /// ``basicAuthHeader()`` value instead.
    public func requestBody(grant: GrantType) -> Bytes {
        var buf = Bytes()
        grant.appendFields(to: &buf)
        if clientAuthMethod == .body {
            FormEncoder.appendField(&buf, key: "client_id", value: clientID)
            if let secret = clientSecret {
                FormEncoder.appendField(&buf, key: "client_secret", value: secret)
            }
        }
        return buf
    }

    /// Returns the `Authorization: Basic` header tuple for HTTP Basic client
    /// authentication per RFC 6749 § 2.3.1, or nil if not applicable.
    ///
    /// Returns nil when ``clientAuthMethod`` is `.body` (no Basic header
    /// needed) or when `clientSecret` is nil (no credential to encode).
    ///
    /// Per RFC 6749 § 2.3.1, `client_id` and `client_secret` are
    /// `application/x-www-form-urlencoded` BEFORE being concatenated as
    /// `"id:secret"` and base64-encoded (this is different from plain RFC
    /// 7617 Basic where the values are used verbatim).
    public func basicAuthHeader() -> (name: String, value: String)? {
        guard clientAuthMethod == .basic, let secret = clientSecret else {
            return nil
        }
        let encodedID = FormEncoder.encode(clientID)
        let encodedSecret = FormEncoder.encode(secret)
        var pair: [UInt8] = []
        pair.reserveCapacity(encodedID.count + 1 + encodedSecret.count)
        pair.append(contentsOf: encodedID)
        pair.append(0x3A)  // ":"
        pair.append(contentsOf: encodedSecret)
        let value = "Basic " + Base64.encode(pair)
        return ("Authorization", value)
    }

    /// Build an RFC 6749 § 4.1.1 authorization URL for the front-channel
    /// redirect to the authorization endpoint.
    ///
    /// Required parameters (`response_type`, `client_id`, `redirect_uri`) are
    /// always emitted. Optional parameters are emitted only when non-nil.
    /// `additionalParams` are appended in order after the standard params —
    /// useful for issuer-specific extensions (e.g., `prompt`, `audience`,
    /// `login_hint`).
    ///
    /// Query parameters are form-urlencoded per RFC 6749 § 3.1 (which
    /// references the HTML5 `application/x-www-form-urlencoded` syntax).
    ///
    /// ```swift
    /// let url = client.authorizationURL(
    ///     authorizationEndpoint: "https://issuer.example/oauth/authorize",
    ///     redirectURI: "https://app.example/cb",
    ///     scope: "openid profile",
    ///     state: OAuth2Client.randomToken(),
    ///     codeChallenge: challenge,
    ///     codeChallengeMethod: .s256
    /// )
    /// ```
    public func authorizationURL(
        authorizationEndpoint: String,
        redirectURI: String,
        scope: String? = nil,
        state: String? = nil,
        nonce: String? = nil,
        codeChallenge: String? = nil,
        codeChallengeMethod: PKCEMethod? = nil,
        responseType: String = "code",
        additionalParams: [(name: String, value: String)] = []
    ) -> String {
        var query = Bytes()
        FormEncoder.appendField(&query, key: "response_type", value: responseType)
        FormEncoder.appendField(&query, key: "client_id", value: clientID)
        FormEncoder.appendField(&query, key: "redirect_uri", value: redirectURI)
        if let scope { FormEncoder.appendField(&query, key: "scope", value: scope) }
        if let state { FormEncoder.appendField(&query, key: "state", value: state) }
        if let nonce { FormEncoder.appendField(&query, key: "nonce", value: nonce) }
        if let codeChallenge {
            FormEncoder.appendField(&query, key: "code_challenge", value: codeChallenge)
        }
        if let codeChallengeMethod {
            FormEncoder.appendField(
                &query, key: "code_challenge_method", value: codeChallengeMethod.rfc7636Name
            )
        }
        for (name, value) in additionalParams {
            FormEncoder.appendField(&query, key: name, value: value)
        }
        let queryString = String(decoding: query.storage, as: UTF8.self)
        return authorizationEndpoint + "?" + queryString
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
