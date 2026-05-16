// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import Testing
@testable import OAuth2Client

@Suite("OAuth2Client.parseResponse")
struct ParseResponseTests {
    private static let client = OAuth2Client(
        tokenEndpoint: "https://example.com/token",
        clientID: "app"
    )

    @Test("minimal success response parses with required fields")
    func minimalSuccess() throws(OAuth2ClientError) {
        let bytes = Bytes(Array(#"{"access_token":"abc","token_type":"Bearer"}"#.utf8))
        let response = try Self.client.parseResponse(bytes)
        #expect(response.accessToken == "abc")
        #expect(response.tokenType == "Bearer")
        #expect(response.expiresIn == nil)
        #expect(response.refreshToken == nil)
        #expect(response.scope == nil)
    }

    @Test("full success response parses all fields")
    func fullSuccess() throws(OAuth2ClientError) {
        let json = #"{"access_token":"abc","token_type":"Bearer","expires_in":3600,"refresh_token":"rt-xyz","scope":"openid email"}"#
        let bytes = Bytes(Array(json.utf8))
        let response = try Self.client.parseResponse(bytes)
        #expect(response.accessToken == "abc")
        #expect(response.tokenType == "Bearer")
        #expect(response.expiresIn == 3600)
        #expect(response.refreshToken == "rt-xyz")
        #expect(response.scope == "openid email")
    }

    @Test("error response throws oauthError with code + description")
    func oauthErrorWithDescription() {
        let bytes = Bytes(Array(#"{"error":"invalid_grant","error_description":"bad code"}"#.utf8))
        do {
            _ = try Self.client.parseResponse(bytes)
            Issue.record("expected throw")
        } catch let e {
            if case .oauthError(let code, let desc) = e {
                #expect(code == "invalid_grant")
                #expect(desc == "bad code")
            } else {
                Issue.record("unexpected error: \(e)")
            }
        }
    }

    @Test("error response without description throws oauthError with nil description")
    func oauthErrorNoDescription() {
        let bytes = Bytes(Array(#"{"error":"invalid_client"}"#.utf8))
        do {
            _ = try Self.client.parseResponse(bytes)
            Issue.record("expected throw")
        } catch let e {
            if case .oauthError(let code, let desc) = e {
                #expect(code == "invalid_client")
                #expect(desc == nil)
            } else {
                Issue.record("unexpected error: \(e)")
            }
        }
    }

    @Test("malformed bytes throw malformedJSON")
    func malformedBytes() {
        let bytes = Bytes(Array("not json at all".utf8))
        do {
            _ = try Self.client.parseResponse(bytes)
            Issue.record("expected throw")
        } catch OAuth2ClientError.malformedJSON {
            // expected
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test("missing access_token throws invalidResponse")
    func missingAccessToken() {
        let bytes = Bytes(Array(#"{"token_type":"Bearer"}"#.utf8))
        do {
            _ = try Self.client.parseResponse(bytes)
            Issue.record("expected throw")
        } catch OAuth2ClientError.invalidResponse {
            // expected
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }
}
