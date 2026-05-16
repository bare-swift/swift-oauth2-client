// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OAuth2Client

@Suite("PKCE primitives (RFC 7636)")
struct PKCETests {
    @Test("generateVerifier() produces a 43-character URL-safe string (32 bytes default)")
    func defaultVerifierLength() {
        let verifier = OAuth2Client.PKCE.generateVerifier()
        // 32 bytes → 43 URL-safe-base64 chars (no padding).
        #expect(verifier.count == 43)
        // URL-safe alphabet only.
        for ch in verifier {
            let v = ch.asciiValue ?? 0
            let isUnreserved = (v >= 0x30 && v <= 0x39)
                || (v >= 0x41 && v <= 0x5A)
                || (v >= 0x61 && v <= 0x7A)
                || v == 0x2D || v == 0x5F
            #expect(isUnreserved, "verifier char '\(ch)' is not in URL-safe alphabet")
        }
    }

    @Test("generateVerifier(byteCount: 48) produces a 64-character string")
    func customByteCount() {
        let verifier = OAuth2Client.PKCE.generateVerifier(byteCount: 48)
        // 48 bytes → 64 URL-safe-base64 chars (48/3 = 16 groups; 16*4 = 64; no remainder).
        #expect(verifier.count == 64)
    }

    @Test(".plain method returns verifier verbatim")
    func plainPassthrough() {
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let challenge = OAuth2Client.PKCE.challenge(for: verifier, method: .plain)
        #expect(challenge == verifier)
    }

    @Test("RFC 7636 § 4.2 worked example: S256 of fixed verifier matches expected challenge")
    func rfc7636WorkedExample() {
        // Per RFC 7636 § 4.2:
        //   verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        //   SHA256(verifier) base64url = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let challenge = OAuth2Client.PKCE.challenge(for: verifier, method: .s256)
        #expect(challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test("PKCEMethod.rfc7636Name maps correctly")
    func methodNames() {
        #expect(PKCEMethod.plain.rfc7636Name == "plain")
        #expect(PKCEMethod.s256.rfc7636Name == "S256")
    }

    @Test("randomToken() produces 22-character URL-safe string (16 bytes default)")
    func randomTokenDefault() {
        let token = OAuth2Client.randomToken()
        // 16 bytes → 22 URL-safe-base64 chars (16/3 = 5 groups + 1 remainder → 5*4 + 2 = 22 chars, no padding).
        #expect(token.count == 22)
    }
}
