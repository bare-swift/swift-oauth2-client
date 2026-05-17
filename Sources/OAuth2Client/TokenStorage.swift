// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Pluggable storage for cached `TokenResponse` values per OAuth issuer +
/// grant context.
///
/// `TokenStorage` is a passive cache: it stores and retrieves
/// ``CachedToken`` values but does not orchestrate token exchange or
/// refresh. Callers drive HTTP and call `store(_:)` after a successful
/// token exchange; callers check `load()?.isExpired(at:threshold:)` before
/// reusing the cached token.
///
/// Methods are `async` so adopter-side storage backends (Keychain, Redis,
/// filesystem, etc.) can be I/O-backed. The provided
/// ``InMemoryTokenStorage`` is the default in-process backing.
///
/// Typical usage:
/// ```swift
/// let storage = InMemoryTokenStorage()
/// let client = OAuth2Client(tokenEndpoint: ..., clientID: ..., clientSecret: ...)
///
/// // On each request:
/// if let cached = await storage.load(),
///    !cached.isExpired(at: now(), threshold: 60) {
///     // Use cached.response.accessToken
/// } else {
///     // Trigger token exchange — caller wires HTTP:
///     let body = client.requestBody(grant: .clientCredentials())
///     // POST tokenEndpoint with body, receive responseBytes
///     let response = try client.parseResponse(responseBytes)
///     let cached = CachedToken(response: response, obtainedAt: now())
///     await storage.store(cached)
/// }
/// ```
///
/// For multi-key caching (different scopes/grants), instantiate multiple
/// `TokenStorage` instances.
///
/// Added in v0.3.
public protocol TokenStorage: Sendable {
    /// Return the currently cached token, or nil if no token is cached or
    /// the cache has been cleared.
    func load() async -> CachedToken?

    /// Store a token, replacing any previously cached value.
    func store(_ token: CachedToken) async

    /// Remove the cached token, if any.
    func clear() async
}

/// A `TokenResponse` plus the Unix-epoch-seconds time at which it was
/// obtained. Used by ``TokenStorage`` to track expiry.
///
/// `obtainedAt` is in seconds since the Unix epoch (1970-01-01T00:00:00Z).
/// Callers provide it via whatever clock they prefer
/// (`Foundation.Date().timeIntervalSince1970` cast to `UInt64`, a
/// `Clock`-based time, a monotonic clock, etc.). The cache itself never
/// reads the clock — it just compares `obtainedAt` + `expiresIn` to
/// `now` provided by the caller in `isExpired(at:threshold:)`.
///
/// Added in v0.3.
public struct CachedToken: Sendable, Equatable {
    /// The underlying token response.
    public let response: TokenResponse

    /// Unix-epoch-seconds at which `response` was obtained.
    public let obtainedAt: UInt64

    /// Computed Unix-epoch-seconds at which the access token expires, or
    /// nil if the response did not include `expires_in`.
    public var expiresAt: UInt64? {
        guard let expiresIn = response.expiresIn, expiresIn >= 0 else { return nil }
        return obtainedAt &+ UInt64(expiresIn)
    }

    public init(response: TokenResponse, obtainedAt: UInt64) {
        self.response = response
        self.obtainedAt = obtainedAt
    }

    /// Returns true if the cached token is at or past its expiry time
    /// relative to `now` (Unix epoch seconds). The optional `threshold`
    /// (seconds) lets callers refresh proactively before strict expiry —
    /// pass e.g. `60` to consider tokens within 60 seconds of expiry as
    /// already expired.
    ///
    /// Tokens with no expiry information (`expiresIn == nil`) are reported
    /// as never expired.
    public func isExpired(at now: UInt64, threshold: UInt64 = 0) -> Bool {
        guard let expiresAt else { return false }
        return now &+ threshold >= expiresAt
    }
}

/// Actor-backed in-memory ``TokenStorage`` implementation. Suitable for
/// single-process use cases. For multi-process or persistent storage,
/// adopters implement their own ``TokenStorage`` backed by Keychain,
/// Redis, filesystem, etc.
///
/// Added in v0.3.
public actor InMemoryTokenStorage: TokenStorage {
    private var cached: CachedToken?

    public init() {}

    public func load() -> CachedToken? {
        cached
    }

    public func store(_ token: CachedToken) {
        cached = token
    }

    public func clear() {
        cached = nil
    }
}
