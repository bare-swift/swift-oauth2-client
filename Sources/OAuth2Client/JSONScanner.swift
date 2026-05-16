// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes

/// Internal minimal JSON object scanner. Extracts top-level string OR integer
/// values for known keys without a full JSON parse.
///
/// Handles: top-level `{...}` shape, `"key":"value"` pairs, `"key":N` for
/// integers, basic backslash escapes (`\"`, `\\`, `\/`, `\n`, `\r`, `\t`,
/// `\b`, `\f`), Unicode whitespace skipping.
///
/// Does NOT handle: nested objects, arrays as values, `\u####` escapes,
/// scientific notation. v0.1 token responses don't need these.
@usableFromInline
internal enum JSONScanner {
    /// Probe for top-level `{` (after whitespace). Throws `.malformedJSON`
    /// if not found.
    @inlinable
    internal static func validateJSONObject(_ bytes: Bytes) throws(OAuth2ClientError) {
        var i = 0
        let n = bytes.count
        while i < n && isWhitespace(bytes[i]) { i += 1 }
        guard i < n, bytes[i] == 0x7B else { throw .malformedJSON }
    }

    /// Find the string value for `key` at the top level. Returns nil if the
    /// key is missing or the value isn't a string. Throws `.malformedJSON`
    /// on completely-malformed input.
    @inlinable
    internal static func string(forKey key: String, in bytes: Bytes) throws(OAuth2ClientError) -> String? {
        guard let valueStart = try findValueStart(forKey: key, in: bytes) else { return nil }
        guard valueStart < bytes.count, bytes[valueStart] == 0x22 else { return nil }
        return try readString(in: bytes, startingAfterQuote: valueStart + 1)
    }

    /// Find the integer value for `key`. Returns nil if missing or not a number.
    @inlinable
    internal static func int(forKey key: String, in bytes: Bytes) throws(OAuth2ClientError) -> Int? {
        guard let valueStart = try findValueStart(forKey: key, in: bytes) else { return nil }
        var i = valueStart
        let n = bytes.count
        let isNegative = i < n && bytes[i] == 0x2D  // -
        if isNegative { i += 1 }
        var value = 0
        var sawDigit = false
        while i < n, bytes[i] >= 0x30, bytes[i] <= 0x39 {
            value = value * 10 + Int(bytes[i] - 0x30)
            sawDigit = true
            i += 1
        }
        guard sawDigit else { return nil }
        return isNegative ? -value : value
    }

    // MARK: - Internal helpers

    /// Find the byte offset of the value start for the given key, or nil if
    /// the key is not found at the top level.
    @inlinable
    internal static func findValueStart(forKey key: String, in bytes: Bytes) throws(OAuth2ClientError) -> Int? {
        let needle: [UInt8] = [0x22] + Array(key.utf8) + [0x22]
        var i = 0
        let n = bytes.count
        outer: while i + needle.count <= n {
            for j in 0..<needle.count {
                if bytes[i + j] != needle[j] {
                    i += 1
                    continue outer
                }
            }
            // Matched needle at i. Skip whitespace + `:` + whitespace.
            var c = i + needle.count
            while c < n && isWhitespace(bytes[c]) { c += 1 }
            guard c < n, bytes[c] == 0x3A else {
                i += 1
                continue
            }
            c += 1
            while c < n && isWhitespace(bytes[c]) { c += 1 }
            return c
        }
        return nil
    }

    /// Read a JSON string starting at the byte AFTER the opening `"`.
    /// Throws `.malformedJSON` on premature EOF.
    @inlinable
    internal static func readString(in bytes: Bytes, startingAfterQuote start: Int) throws(OAuth2ClientError) -> String {
        var out: [UInt8] = []
        var i = start
        let n = bytes.count
        while i < n {
            let b = bytes[i]
            if b == 0x22 {  // closing "
                return String(decoding: out, as: UTF8.self)
            }
            if b == 0x5C {  // backslash escape
                i += 1
                guard i < n else { throw .malformedJSON }
                switch bytes[i] {
                case 0x22: out.append(0x22)   // \"
                case 0x5C: out.append(0x5C)   // \\
                case 0x2F: out.append(0x2F)   // \/
                case 0x6E: out.append(0x0A)   // \n
                case 0x72: out.append(0x0D)   // \r
                case 0x74: out.append(0x09)   // \t
                case 0x62: out.append(0x08)   // \b
                case 0x66: out.append(0x0C)   // \f
                default:
                    // v0.1 doesn't support \u#### — keep the byte literally.
                    out.append(bytes[i])
                }
                i += 1
            } else {
                out.append(b)
                i += 1
            }
        }
        throw .malformedJSON
    }

    @inlinable
    internal static func isWhitespace(_ b: UInt8) -> Bool {
        b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D
    }
}
