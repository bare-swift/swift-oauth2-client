// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Errors thrown by ``OAuth2Client/parseResponse(_:)``.
public enum OAuth2ClientError: Error, Equatable, Sendable {
    /// Response was a valid JSON object but didn't contain the required success
    /// fields (e.g., missing `access_token` or `token_type`).
    case invalidResponse

    /// RFC 6749 § 5.2 error response from the authorization server.
    /// - `code`: the `error` field value (e.g., `invalid_grant`, `invalid_client`).
    /// - `description`: optional `error_description` field.
    case oauthError(code: String, description: String?)

    /// Response bytes are not a valid top-level JSON object.
    case malformedJSON
}
