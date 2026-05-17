// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OAuth2Client

@Suite("TokenStorage (v0.3)")
struct TokenStorageTests {
    private static func makeToken(expiresIn: Int? = 3600) -> TokenResponse {
        TokenResponse(
            accessToken: "at-abc",
            tokenType: "Bearer",
            expiresIn: expiresIn,
            refreshToken: "rt-xyz",
            scope: "read",
            idToken: nil
        )
    }

    // MARK: - InMemoryTokenStorage

    @Test("InMemoryTokenStorage: load on empty returns nil")
    func loadEmpty() async {
        let storage = InMemoryTokenStorage()
        let cached = await storage.load()
        #expect(cached == nil)
    }

    @Test("InMemoryTokenStorage: store then load returns same token")
    func storeLoad() async {
        let storage = InMemoryTokenStorage()
        let token = CachedToken(response: Self.makeToken(), obtainedAt: 1700000000)
        await storage.store(token)
        let cached = await storage.load()
        #expect(cached == token)
    }

    @Test("InMemoryTokenStorage: store replaces previous")
    func storeReplaces() async {
        let storage = InMemoryTokenStorage()
        let token1 = CachedToken(response: Self.makeToken(expiresIn: 100), obtainedAt: 1700000000)
        let token2 = CachedToken(response: Self.makeToken(expiresIn: 200), obtainedAt: 1700000050)
        await storage.store(token1)
        await storage.store(token2)
        let cached = await storage.load()
        #expect(cached == token2)
    }

    @Test("InMemoryTokenStorage: clear removes cached token")
    func clear() async {
        let storage = InMemoryTokenStorage()
        let token = CachedToken(response: Self.makeToken(), obtainedAt: 1700000000)
        await storage.store(token)
        await storage.clear()
        let cached = await storage.load()
        #expect(cached == nil)
    }

    // MARK: - CachedToken expiry

    @Test("CachedToken.expiresAt: nil when expiresIn is nil")
    func expiresAtNilWhenExpiresInNil() {
        let token = CachedToken(
            response: Self.makeToken(expiresIn: nil),
            obtainedAt: 1700000000
        )
        #expect(token.expiresAt == nil)
    }

    @Test("CachedToken.expiresAt: obtainedAt + expiresIn")
    func expiresAtComputed() {
        let token = CachedToken(
            response: Self.makeToken(expiresIn: 3600),
            obtainedAt: 1700000000
        )
        #expect(token.expiresAt == 1700003600)
    }

    @Test("CachedToken.isExpired: false before expiry")
    func notExpiredBefore() {
        let token = CachedToken(
            response: Self.makeToken(expiresIn: 3600),
            obtainedAt: 1700000000
        )
        #expect(!token.isExpired(at: 1700003500))
    }

    @Test("CachedToken.isExpired: true at/past expiry")
    func expiredAtOrPast() {
        let token = CachedToken(
            response: Self.makeToken(expiresIn: 3600),
            obtainedAt: 1700000000
        )
        #expect(token.isExpired(at: 1700003600))
        #expect(token.isExpired(at: 1700003700))
    }

    @Test("CachedToken.isExpired: threshold triggers early expiry")
    func thresholdEarlyExpiry() {
        let token = CachedToken(
            response: Self.makeToken(expiresIn: 3600),
            obtainedAt: 1700000000
        )
        // Token expires at 1700003600. With threshold 60, expires at 1700003540.
        #expect(!token.isExpired(at: 1700003539, threshold: 60))
        #expect(token.isExpired(at: 1700003540, threshold: 60))
    }

    @Test("CachedToken.isExpired: tokens without expiresIn are never expired")
    func neverExpiresWithoutExpiresIn() {
        let token = CachedToken(
            response: Self.makeToken(expiresIn: nil),
            obtainedAt: 1700000000
        )
        #expect(!token.isExpired(at: 9999999999))
        #expect(!token.isExpired(at: 9999999999, threshold: 999999))
    }
}
