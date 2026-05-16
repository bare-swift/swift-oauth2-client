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
