// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import Testing
@testable import OAuth2Client

@Suite("JSONScanner")
struct JSONScannerTests {
    @Test("finds top-level string value by key")
    func findsString() throws(OAuth2ClientError) {
        let bytes = Bytes(Array(#"{"name":"alice","age":30}"#.utf8))
        let value = try JSONScanner.string(forKey: "name", in: bytes)
        #expect(value == "alice")
    }

    @Test("finds top-level integer value by key")
    func findsInteger() throws(OAuth2ClientError) {
        let bytes = Bytes(Array(#"{"name":"alice","age":30}"#.utf8))
        let value = try JSONScanner.int(forKey: "age", in: bytes)
        #expect(value == 30)
    }

    @Test("returns nil for missing key")
    func missingKey() throws(OAuth2ClientError) {
        let bytes = Bytes(Array(#"{"a":"b"}"#.utf8))
        #expect(try JSONScanner.string(forKey: "missing", in: bytes) == nil)
    }

    @Test("handles backslash-escaped quote in string value")
    func escapedQuote() throws(OAuth2ClientError) {
        let bytes = Bytes(Array(#"{"q":"a\"b"}"#.utf8))
        let value = try JSONScanner.string(forKey: "q", in: bytes)
        #expect(value == "a\"b")
    }
}
