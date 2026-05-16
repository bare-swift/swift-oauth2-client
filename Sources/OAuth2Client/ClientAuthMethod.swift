// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// How client credentials (`client_id` + `client_secret`) are conveyed to the
/// token endpoint per RFC 6749 § 2.3.1.
///
/// RFC 6749 § 2.3.1 mandates that token-endpoint servers MUST support HTTP
/// Basic. Many servers also accept body-borne credentials (the v0.1 default).
/// Choose the method matching the issuer's documentation.
public enum ClientAuthMethod: Sendable, Equatable {
    /// Credentials in the form-encoded request body (v0.1 default).
    /// ``OAuth2Client/requestBody(grant:)`` includes `client_id` (and
    /// `client_secret` if non-nil).
    case body

    /// Credentials in an `Authorization: Basic` HTTP header per RFC 6749
    /// § 2.3.1. ``OAuth2Client/requestBody(grant:)`` excludes credentials;
    /// caller attaches the header returned by
    /// ``OAuth2Client/basicAuthHeader()``.
    ///
    /// Per RFC 6749 § 2.3.1, `client_id` and `client_secret` are
    /// form-urlencoded before being concatenated as `"id:secret"` and
    /// base64-encoded.
    case basic
}
