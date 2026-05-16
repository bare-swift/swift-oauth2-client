// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes

/// RFC 6749 grant types supported by ``OAuth2Client/requestBody(grant:)``.
public enum GrantType: Sendable {
    /// RFC 6749 § 4.4 client credentials grant. Used for service-to-service
    /// authentication where the client itself is the resource owner.
    case clientCredentials(scope: String? = nil)

    /// RFC 6749 § 4.1 authorization code grant. `codeVerifier` is the RFC
    /// 7636 PKCE verifier (nil if PKCE was not used). Caller generates the
    /// verifier+challenge pair externally (e.g., via swift-crypto's
    /// SystemRandomNumberGenerator + SHA256 + base64url).
    case authorizationCode(code: String, redirectURI: String, codeVerifier: String? = nil)

    /// RFC 6749 § 6 refresh token grant. Optional `scope` parameter narrows
    /// the new access token's scope vs the original.
    case refreshToken(_ token: String, scope: String? = nil)
}

extension GrantType {
    /// Append the grant-specific form fields to `buffer`. The caller is
    /// responsible for appending `client_id` and `client_secret` afterward.
    @usableFromInline
    internal func appendFields(to buffer: inout Bytes) {
        switch self {
        case .clientCredentials(let scope):
            FormEncoder.appendField(&buffer, key: "grant_type", value: "client_credentials")
            if let scope {
                FormEncoder.appendField(&buffer, key: "scope", value: scope)
            }
        case .authorizationCode(let code, let redirectURI, let codeVerifier):
            FormEncoder.appendField(&buffer, key: "grant_type", value: "authorization_code")
            FormEncoder.appendField(&buffer, key: "code", value: code)
            FormEncoder.appendField(&buffer, key: "redirect_uri", value: redirectURI)
            if let codeVerifier {
                FormEncoder.appendField(&buffer, key: "code_verifier", value: codeVerifier)
            }
        case .refreshToken(let token, let scope):
            FormEncoder.appendField(&buffer, key: "grant_type", value: "refresh_token")
            FormEncoder.appendField(&buffer, key: "refresh_token", value: token)
            if let scope {
                FormEncoder.appendField(&buffer, key: "scope", value: scope)
            }
        }
    }
}
