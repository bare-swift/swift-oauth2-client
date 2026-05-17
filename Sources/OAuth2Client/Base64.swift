// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Internal base64 encoder supporting standard (with `=` padding, `+/`) and
/// URL-safe (no padding, `-_`) variants. Avoids a swift-base64 dep — the
/// encoder is small enough to inline (v0.2 follows v0.1's hand-rolled
/// pattern alongside FormEncoder + JSONScanner).
@usableFromInline
internal enum Base64 {
    private static let standardAlphabet: [UInt8] = Array(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8
    )
    private static let urlAlphabet: [UInt8] = Array(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".utf8
    )

    /// Standard base64 with `=` padding, `+/`.
    internal static func encode(_ bytes: [UInt8]) -> String {
        encode(bytes, alphabet: standardAlphabet, padding: true)
    }

    /// URL-safe base64 with no padding, `-_`.
    internal static func urlEncode(_ bytes: [UInt8]) -> String {
        encode(bytes, alphabet: urlAlphabet, padding: false)
    }

    /// Decode URL-safe base64 (with or without `=` padding; accepts `-_`).
    /// Returns nil on invalid characters or invalid length. Added in v0.3
    /// for JWT payload decoding (OIDC ID-token claim extraction).
    internal static func urlDecode(_ s: String) -> [UInt8]? {
        var input = Array(s.utf8)
        // Add padding if missing — base64 length must be a multiple of 4.
        let remainder = input.count % 4
        if remainder == 2 {
            input.append(0x3D); input.append(0x3D)  // "=="
        } else if remainder == 3 {
            input.append(0x3D)  // "="
        } else if remainder == 1 {
            return nil  // invalid length
        }

        var out: [UInt8] = []
        out.reserveCapacity((input.count / 4) * 3)

        var i = 0
        while i < input.count {
            let v0 = Self.decodeURLChar(input[i])
            let v1 = Self.decodeURLChar(input[i + 1])
            let v2 = Self.decodeURLChar(input[i + 2])
            let v3 = Self.decodeURLChar(input[i + 3])

            guard let b0 = v0, let b1 = v1 else { return nil }

            // Two padding chars: only first 2 chars encode data; emit 1 byte.
            if v2 == nil && input[i + 2] == 0x3D && input[i + 3] == 0x3D {
                out.append(UInt8((b0 << 2) | (b1 >> 4)))
                i += 4
                continue
            }
            // One padding char: first 3 chars encode data; emit 2 bytes.
            if v3 == nil && input[i + 3] == 0x3D {
                guard let b2 = v2 else { return nil }
                out.append(UInt8((b0 << 2) | (b1 >> 4)))
                out.append(UInt8(((b1 & 0x0F) << 4) | (b2 >> 2)))
                i += 4
                continue
            }
            guard let b2 = v2, let b3 = v3 else { return nil }
            out.append(UInt8((b0 << 2) | (b1 >> 4)))
            out.append(UInt8(((b1 & 0x0F) << 4) | (b2 >> 2)))
            out.append(UInt8(((b2 & 0x03) << 6) | b3))
            i += 4
        }
        return out
    }

    private static func decodeURLChar(_ c: UInt8) -> UInt32? {
        switch c {
        case 0x41...0x5A: return UInt32(c - 0x41)         // A-Z → 0-25
        case 0x61...0x7A: return UInt32(c - 0x61) + 26    // a-z → 26-51
        case 0x30...0x39: return UInt32(c - 0x30) + 52    // 0-9 → 52-61
        case 0x2D: return 62                              // - → 62 (URL-safe + standard +)
        case 0x5F: return 63                              // _ → 63 (URL-safe / standard /)
        case 0x2B: return 62                              // + (standard alphabet, accept)
        case 0x2F: return 63                              // / (standard alphabet, accept)
        default: return nil
        }
    }

    private static func encode(_ bytes: [UInt8], alphabet: [UInt8], padding: Bool) -> String {
        if bytes.isEmpty { return "" }
        var out: [UInt8] = []
        let groupCount = bytes.count / 3
        let remainder = bytes.count % 3
        out.reserveCapacity((groupCount + (remainder > 0 ? 1 : 0)) * 4)

        for g in 0..<groupCount {
            let i = g * 3
            let b0 = UInt32(bytes[i])
            let b1 = UInt32(bytes[i + 1])
            let b2 = UInt32(bytes[i + 2])
            let triplet = (b0 << 16) | (b1 << 8) | b2
            out.append(alphabet[Int((triplet >> 18) & 0x3F)])
            out.append(alphabet[Int((triplet >> 12) & 0x3F)])
            out.append(alphabet[Int((triplet >> 6) & 0x3F)])
            out.append(alphabet[Int(triplet & 0x3F)])
        }
        if remainder == 1 {
            let b0 = UInt32(bytes[groupCount * 3])
            let triplet = b0 << 16
            out.append(alphabet[Int((triplet >> 18) & 0x3F)])
            out.append(alphabet[Int((triplet >> 12) & 0x3F)])
            if padding {
                out.append(0x3D); out.append(0x3D)  // ==
            }
        } else if remainder == 2 {
            let b0 = UInt32(bytes[groupCount * 3])
            let b1 = UInt32(bytes[groupCount * 3 + 1])
            let triplet = (b0 << 16) | (b1 << 8)
            out.append(alphabet[Int((triplet >> 18) & 0x3F)])
            out.append(alphabet[Int((triplet >> 12) & 0x3F)])
            out.append(alphabet[Int((triplet >> 6) & 0x3F)])
            if padding {
                out.append(0x3D)  // =
            }
        }
        return String(decoding: out, as: UTF8.self)
    }
}
