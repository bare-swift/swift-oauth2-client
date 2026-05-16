// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import Testing
@testable import OAuth2Client

@Suite("GrantType.appendFields")
struct GrantTypeTests {
    @Test("clientCredentials with nil scope emits only grant_type")
    func clientCredentialsNoScope() {
        var buf = Bytes()
        let grant: GrantType = .clientCredentials(scope: nil)
        grant.appendFields(to: &buf)
        #expect(String(decoding: buf.storage, as: UTF8.self) == "grant_type=client_credentials")
    }

    @Test("clientCredentials with scope emits scope field")
    func clientCredentialsWithScope() {
        var buf = Bytes()
        let grant: GrantType = .clientCredentials(scope: "read write")
        grant.appendFields(to: &buf)
        #expect(String(decoding: buf.storage, as: UTF8.self) == "grant_type=client_credentials&scope=read+write")
    }

    @Test("authorizationCode with codeVerifier emits PKCE field")
    func authorizationCodeWithPKCE() {
        var buf = Bytes()
        let grant: GrantType = .authorizationCode(
            code: "abc123",
            redirectURI: "https://app.example/cb",
            codeVerifier: "v123"
        )
        grant.appendFields(to: &buf)
        let s = String(decoding: buf.storage, as: UTF8.self)
        #expect(s.contains("grant_type=authorization_code"))
        #expect(s.contains("code=abc123"))
        #expect(s.contains("redirect_uri=https%3A%2F%2Fapp.example%2Fcb"))
        #expect(s.contains("code_verifier=v123"))
    }

    @Test("authorizationCode without codeVerifier omits PKCE field")
    func authorizationCodeNoPKCE() {
        var buf = Bytes()
        let grant: GrantType = .authorizationCode(
            code: "abc",
            redirectURI: "https://app.example/cb",
            codeVerifier: nil
        )
        grant.appendFields(to: &buf)
        let s = String(decoding: buf.storage, as: UTF8.self)
        #expect(!s.contains("code_verifier"))
    }

    @Test("refreshToken with scope emits scope field")
    func refreshTokenWithScope() {
        var buf = Bytes()
        let grant: GrantType = .refreshToken("rt-abc", scope: "openid")
        grant.appendFields(to: &buf)
        #expect(String(decoding: buf.storage, as: UTF8.self) == "grant_type=refresh_token&refresh_token=rt-abc&scope=openid")
    }
}
