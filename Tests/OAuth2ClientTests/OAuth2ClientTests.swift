// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Testing
@testable import OAuth2Client

@Suite("OAuth2Client struct")
struct OAuth2ClientTests {
    @Test("init stores all three fields")
    func initStoresFields() {
        let client = OAuth2Client(
            tokenEndpoint: "https://example.com/token",
            clientID: "app",
            clientSecret: "secret"
        )
        #expect(client.tokenEndpoint == "https://example.com/token")
        #expect(client.clientID == "app")
        #expect(client.clientSecret == "secret")
    }

    @Test("init with nil clientSecret is allowed (public client)")
    func publicClient() {
        let client = OAuth2Client(
            tokenEndpoint: "https://example.com/token",
            clientID: "myapp"
        )
        #expect(client.clientSecret == nil)
    }

    @Test("requestBody is deterministic across repeated calls")
    func requestBodyDeterministic() {
        let client = OAuth2Client(
            tokenEndpoint: "https://example.com/token",
            clientID: "app",
            clientSecret: "secret"
        )
        let b1 = client.requestBody(grant: .clientCredentials())
        let b2 = client.requestBody(grant: .clientCredentials())
        #expect(b1.storage == b2.storage)
    }
}
