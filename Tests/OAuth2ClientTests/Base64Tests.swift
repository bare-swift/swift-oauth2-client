// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OAuth2Client

@Suite("Base64 (internal)")
struct Base64Tests {
    @Test("empty input → empty output")
    func empty() {
        #expect(Base64.encode([]) == "")
        #expect(Base64.urlEncode([]) == "")
    }

    @Test("3 bytes → 4 chars, no padding")
    func threeBytes() {
        // ASCII "Man" = 0x4D 0x61 0x6E → "TWFu"
        #expect(Base64.encode([0x4D, 0x61, 0x6E]) == "TWFu")
    }

    @Test("1 byte → 2 chars + '==' (standard)")
    func oneByteStandard() {
        // 0x4D → "TQ=="
        #expect(Base64.encode([0x4D]) == "TQ==")
    }

    @Test("2 bytes → 3 chars + '=' (standard)")
    func twoBytesStandard() {
        // 0x4D 0x61 → "TWE="
        #expect(Base64.encode([0x4D, 0x61]) == "TWE=")
    }

    @Test("URL encode: no padding, '-_' instead of '+/'")
    func urlAlphabet() {
        // Bytes producing '+' and '/' in standard: 0xFB 0xEF → standard "++8="
        // (specifically 0xFB 0xEF 0xFF → "++//"; with 1 trailing-byte truncation
        // we test alphabet variance with a focused 3-byte pattern).
        let bytes: [UInt8] = [0xFB, 0xEF, 0xFF]
        let standard = Base64.encode(bytes)
        let url = Base64.urlEncode(bytes)
        #expect(standard.contains("+") || standard.contains("/"))
        #expect(!url.contains("+"))
        #expect(!url.contains("/"))
        #expect(!url.contains("="))
        // The url variant substitutes:
        //   '+' → '-'
        //   '/' → '_'
        // Standard "++//" → URL "--__".
        #expect(standard == "++//")
        #expect(url == "--__")
    }
}
