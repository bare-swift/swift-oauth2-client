// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes

/// Standard OIDC ID-token claims per OpenID Connect Core 1.0 § 2.
/// Caller verifies signature externally (e.g., via swift-jwt-verify) and
/// validates claim semantics (`iss`, `aud`, `exp`, `nonce`).
///
/// Added in v0.3.
public struct OIDCClaims: Sendable, Equatable {
    /// Issuer identifier (`iss` claim).
    public let iss: String?

    /// Subject identifier (`sub` claim).
    public let sub: String?

    /// Audience(s) (`aud` claim). Normalized to a list: spec allows either
    /// a single string or array.
    public let aud: [String]

    /// Expiration time (`exp` claim) — Unix epoch seconds.
    public let exp: Int?

    /// Issued-at time (`iat` claim) — Unix epoch seconds.
    public let iat: Int?

    /// String value used to associate a client session with an ID token
    /// (`nonce` claim).
    public let nonce: String?

    public init(
        iss: String? = nil,
        sub: String? = nil,
        aud: [String] = [],
        exp: Int? = nil,
        iat: Int? = nil,
        nonce: String? = nil
    ) {
        self.iss = iss
        self.sub = sub
        self.aud = aud
        self.exp = exp
        self.iat = iat
        self.nonce = nonce
    }

    /// Parse the standard claims from a JWS-compact JWT ID token. Decodes
    /// the payload (middle segment) as base64url, scans it as JSON, and
    /// extracts standard OIDC claim fields. **Does NOT verify the JWT
    /// signature** — caller verifies externally (e.g., via swift-jwt-verify).
    ///
    /// - Throws: ``OAuth2ClientError/invalidIDToken`` if the token is not a
    ///   three-segment JWT, if the payload isn't valid base64url, or if the
    ///   payload isn't a valid JSON object.
    public static func parse(_ idToken: String) throws(OAuth2ClientError) -> OIDCClaims {
        // Split on '.' into three segments per RFC 7515 § 3.1.
        var segments: [String] = []
        var current = ""
        for ch in idToken {
            if ch == "." {
                segments.append(current)
                current = ""
            } else {
                current.append(ch)
            }
        }
        segments.append(current)
        guard segments.count == 3 else { throw .invalidIDToken }

        // Decode the payload (middle segment).
        guard let payloadBytes = Base64.urlDecode(segments[1]) else {
            throw .invalidIDToken
        }
        let payload = Bytes(payloadBytes)

        // Validate JSON shape.
        do {
            try JSONScanner.validateJSONObject(payload)
        } catch {
            throw .invalidIDToken
        }

        // Extract claims.
        let iss = (try? JSONScanner.string(forKey: "iss", in: payload)) ?? nil
        let sub = (try? JSONScanner.string(forKey: "sub", in: payload)) ?? nil
        let exp = (try? JSONScanner.int(forKey: "exp", in: payload)) ?? nil
        let iat = (try? JSONScanner.int(forKey: "iat", in: payload)) ?? nil
        let nonce = (try? JSONScanner.string(forKey: "nonce", in: payload)) ?? nil

        // `aud` may be a string or array. JSONScanner can only extract strings;
        // for arrays, callers need a richer JSON parser. v0.3 handles the
        // common single-string-aud case; array-form aud returns nil (which we
        // treat as empty `[]`).
        var aud: [String] = []
        if let single = (try? JSONScanner.string(forKey: "aud", in: payload)) ?? nil {
            aud = [single]
        }

        return OIDCClaims(
            iss: iss,
            sub: sub,
            aud: aud,
            exp: exp,
            iat: iat,
            nonce: nonce
        )
    }
}
