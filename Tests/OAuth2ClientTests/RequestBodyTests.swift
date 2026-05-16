// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Testing
@testable import OAuth2Client

@Suite("OAuth2Client.requestBody")
struct RequestBodyTests {
    private static func makeClient(secret: String? = "hunter2") -> OAuth2Client {
        OAuth2Client(
            tokenEndpoint: "https://issuer.example/oauth/token",
            clientID: "my-app",
            clientSecret: secret
        )
    }

    @Test("clientCredentials confidential client emits exact bytes")
    func clientCredentialsConfidential() {
        let client = Self.makeClient()
        let body = client.requestBody(grant: .clientCredentials())
        let s = String(decoding: body.storage, as: UTF8.self)
        #expect(s == "grant_type=client_credentials&client_id=my-app&client_secret=hunter2")
    }

    @Test("clientCredentials with scope appends scope field")
    func clientCredentialsWithScope() {
        let client = Self.makeClient()
        let body = client.requestBody(grant: .clientCredentials(scope: "read write"))
        let s = String(decoding: body.storage, as: UTF8.self)
        #expect(s == "grant_type=client_credentials&scope=read+write&client_id=my-app&client_secret=hunter2")
    }

    @Test("authorizationCode with PKCE emits all fields including code_verifier")
    func authorizationCodeWithPKCE() {
        let client = Self.makeClient()
        let body = client.requestBody(grant: .authorizationCode(
            code: "abc123",
            redirectURI: "https://myapp.example/callback",
            codeVerifier: "verifier-xyz"
        ))
        let s = String(decoding: body.storage, as: UTF8.self)
        #expect(s.contains("grant_type=authorization_code"))
        #expect(s.contains("code=abc123"))
        #expect(s.contains("redirect_uri=https%3A%2F%2Fmyapp.example%2Fcallback"))
        #expect(s.contains("code_verifier=verifier-xyz"))
        #expect(s.contains("client_id=my-app"))
        #expect(s.contains("client_secret=hunter2"))
    }

    @Test("authorizationCode public client (no secret) omits client_secret")
    func authorizationCodePublicClient() {
        let client = Self.makeClient(secret: nil)
        let body = client.requestBody(grant: .authorizationCode(
            code: "abc",
            redirectURI: "https://app.example/cb",
            codeVerifier: "v"
        ))
        let s = String(decoding: body.storage, as: UTF8.self)
        #expect(!s.contains("client_secret"))
        #expect(s.contains("client_id=my-app"))
    }

    @Test("refreshToken emits exact body shape")
    func refreshTokenBody() {
        let client = Self.makeClient()
        let body = client.requestBody(grant: .refreshToken("rt-abc123"))
        let s = String(decoding: body.storage, as: UTF8.self)
        #expect(s == "grant_type=refresh_token&refresh_token=rt-abc123&client_id=my-app&client_secret=hunter2")
    }
}
