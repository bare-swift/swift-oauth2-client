// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OAuth2Client

@Suite("OIDC ID-token claims (v0.3)")
struct OIDCClaimsTests {
    // MARK: - Base64URL decode (internal helper)

    @Test("Base64.urlDecode: decodes 'TWFu' to 'Man'")
    func urlDecodeThreeBytes() {
        let bytes = Base64.urlDecode("TWFu")
        #expect(bytes == [0x4D, 0x61, 0x6E])
    }

    @Test("Base64.urlDecode: decodes unpadded base64url")
    func urlDecodeUnpadded() {
        // "Ma" → "TWE" (3 chars, no padding in URL variant)
        let bytes = Base64.urlDecode("TWE")
        #expect(bytes == [0x4D, 0x61])
    }

    @Test("Base64.urlDecode: handles '-_' alphabet")
    func urlDecodeAlphabet() {
        // bytes 0xFB 0xEF 0xFF → standard "++//" → URL "--__"
        let bytes = Base64.urlDecode("--__")
        #expect(bytes == [0xFB, 0xEF, 0xFF])
    }

    @Test("Base64.urlDecode: rejects invalid characters")
    func urlDecodeInvalidChar() {
        #expect(Base64.urlDecode("!@#$") == nil)
    }

    // MARK: - OIDCClaims.parse

    @Test("OIDCClaims.parse: extracts standard claims from a JWT payload")
    func parseStandardClaims() throws(OAuth2ClientError) {
        // JWT payload (middle segment) decoded:
        // {"iss":"https://issuer.example","sub":"user-123","aud":"myapp","exp":1700003600,"iat":1700000000,"nonce":"abc"}
        // Encoded as base64url: "eyJpc3MiOiJodHRwczovL2lzc3Vlci5leGFtcGxlIiwic3ViIjoidXNlci0xMjMiLCJhdWQiOiJteWFwcCIsImV4cCI6MTcwMDAwMzYwMCwiaWF0IjoxNzAwMDAwMDAwLCJub25jZSI6ImFiYyJ9"
        let header = "eyJhbGciOiJIUzI1NiJ9"  // {"alg":"HS256"}
        let payload = "eyJpc3MiOiJodHRwczovL2lzc3Vlci5leGFtcGxlIiwic3ViIjoidXNlci0xMjMiLCJhdWQiOiJteWFwcCIsImV4cCI6MTcwMDAwMzYwMCwiaWF0IjoxNzAwMDAwMDAwLCJub25jZSI6ImFiYyJ9"
        let signature = "ZmFrZQ"  // "fake" (we don't verify)
        let idToken = "\(header).\(payload).\(signature)"

        let claims = try OIDCClaims.parse(idToken)
        #expect(claims.iss == "https://issuer.example")
        #expect(claims.sub == "user-123")
        #expect(claims.aud == ["myapp"])
        #expect(claims.exp == 1700003600)
        #expect(claims.iat == 1700000000)
        #expect(claims.nonce == "abc")
    }

    @Test("OIDCClaims.parse: throws invalidIDToken on non-three-segment input")
    func parseInvalidStructure() {
        do {
            _ = try OIDCClaims.parse("just.two")
            Issue.record("expected throw")
        } catch OAuth2ClientError.invalidIDToken {
            // expected
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test("OIDCClaims.parse: throws invalidIDToken on malformed base64url payload")
    func parseMalformedPayload() {
        do {
            _ = try OIDCClaims.parse("header.!@#$.signature")
            Issue.record("expected throw")
        } catch OAuth2ClientError.invalidIDToken {
            // expected
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test("OIDCClaims.parse: throws invalidIDToken when payload isn't JSON object")
    func parseNonJSONPayload() {
        // base64url("not json") = "bm90IGpzb24"
        do {
            _ = try OIDCClaims.parse("header.bm90IGpzb24.signature")
            Issue.record("expected throw")
        } catch OAuth2ClientError.invalidIDToken {
            // expected
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test("OIDCClaims.parse: missing fields default to nil/empty")
    func parseMissingFields() throws(OAuth2ClientError) {
        // payload = {"iss":"x"}
        let header = "eyJhbGciOiJIUzI1NiJ9"
        let payload = "eyJpc3MiOiJ4In0"
        let signature = "ZmFrZQ"
        let idToken = "\(header).\(payload).\(signature)"

        let claims = try OIDCClaims.parse(idToken)
        #expect(claims.iss == "x")
        #expect(claims.sub == nil)
        #expect(claims.aud == [])
        #expect(claims.exp == nil)
        #expect(claims.iat == nil)
        #expect(claims.nonce == nil)
    }
}
