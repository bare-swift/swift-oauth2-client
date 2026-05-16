// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Crypto
import Foundation  // internal use only — bridge to swift-crypto's Data API

/// RFC 7636 § 4.3 `code_challenge_method` for the PKCE extension to the
/// OAuth 2.0 authorization-code grant.
public enum PKCEMethod: Sendable, Equatable {
    /// `code_challenge = code_verifier` (RFC 7636 § 4.2). Legacy clients only.
    case plain
    /// `code_challenge = BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))` (RFC 7636 § 4.2).
    case s256

    /// The RFC 7636 `code_challenge_method` parameter value (`"plain"` or `"S256"`).
    public var rfc7636Name: String {
        switch self {
        case .plain: return "plain"
        case .s256:  return "S256"
        }
    }
}

extension OAuth2Client {
    /// PKCE (RFC 7636) primitives for the authorization-code grant.
    ///
    /// Typical flow:
    ///
    /// ```swift
    /// let verifier = OAuth2Client.PKCE.generateVerifier()
    /// let challenge = OAuth2Client.PKCE.challenge(for: verifier, method: .s256)
    /// // Send challenge in authorization URL; keep verifier until token exchange.
    /// ```
    public enum PKCE: Sendable {
        /// Generate a random PKCE `code_verifier` per RFC 7636 § 4.1.
        ///
        /// `byteCount` is the number of random bytes; the verifier string is
        /// the base64url-encoded form (no padding). Default 32 bytes →
        /// 43-character verifier. RFC 7636 § 4.1 mandates the verifier length
        /// to be in `43...128`; 32 bytes maps to exactly 43 chars.
        public static func generateVerifier(byteCount: Int = 32) -> String {
            let bytes = OAuth2Client.randomBytes(count: byteCount)
            return Base64.urlEncode(bytes)
        }

        /// Compute the PKCE `code_challenge` per RFC 7636 § 4.2.
        ///
        /// - `.plain`: returns `verifier` verbatim.
        /// - `.s256`: returns `base64url(SHA256(verifier.utf8))`.
        public static func challenge(for verifier: String, method: PKCEMethod) -> String {
            switch method {
            case .plain:
                return verifier
            case .s256:
                let digest = SHA256.hash(data: Data(verifier.utf8))
                return Base64.urlEncode(Array(digest))
            }
        }
    }

    /// Generate a random URL-safe token suitable for OAuth `state` or OIDC
    /// `nonce` parameters. Default 16 bytes → 22-character base64url string.
    public static func randomToken(byteCount: Int = 16) -> String {
        Base64.urlEncode(randomBytes(count: byteCount))
    }

    /// Generate `count` cryptographically secure random bytes via Swift's
    /// `SystemRandomNumberGenerator` (CSPRNG on macOS — `arc4random_buf` —
    /// and Linux — `getentropy` / `/dev/urandom`).
    @usableFromInline
    internal static func randomBytes(count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        var rng = SystemRandomNumberGenerator()
        for i in 0..<count {
            bytes[i] = UInt8.random(in: 0...255, using: &rng)
        }
        return bytes
    }
}
