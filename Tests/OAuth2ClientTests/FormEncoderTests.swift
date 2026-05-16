// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import Testing
@testable import OAuth2Client

@Suite("FormEncoder")
struct FormEncoderTests {
    @Test("unreserved characters pass through")
    func unreservedPassThrough() {
        let encoded = FormEncoder.encode("abc-._*123XYZ")
        let expected: [UInt8] = Array("abc-._*123XYZ".utf8)
        #expect(encoded == expected)
    }

    @Test("space encodes as +")
    func spaceAsPlus() {
        let encoded = FormEncoder.encode("hello world")
        let expected: [UInt8] = Array("hello+world".utf8)
        #expect(encoded == expected)
    }

    @Test("special characters percent-encode with uppercase hex")
    func specialPercentEncode() {
        let encoded = FormEncoder.encode("/?&=:")
        let expected: [UInt8] = Array("%2F%3F%26%3D%3A".utf8)
        #expect(encoded == expected)
    }
}
