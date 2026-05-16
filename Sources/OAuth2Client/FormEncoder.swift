// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes

/// Internal `application/x-www-form-urlencoded` encoder per HTML5 § 4.10.21.7
/// / WHATWG URL § 5.2. Unreserved characters pass through; space → `+`; all
/// other bytes → `%HH` (uppercase hex).
@usableFromInline
internal enum FormEncoder {
    /// Encode a string as form-urlencoded value bytes.
    @inlinable
    internal static func encode(_ s: String) -> [UInt8] {
        var out: [UInt8] = []
        out.reserveCapacity(s.utf8.count)
        for byte in s.utf8 {
            switch byte {
            case 0x30...0x39,            // 0-9
                 0x41...0x5A,            // A-Z
                 0x61...0x7A,            // a-z
                 0x2A, 0x2D, 0x2E, 0x5F: // * - . _
                out.append(byte)
            case 0x20:                    // space
                out.append(0x2B)          // +
            default:
                out.append(0x25)          // %
                out.append(hexDigit(byte >> 4))
                out.append(hexDigit(byte & 0x0F))
            }
        }
        return out
    }

    @inlinable
    internal static func hexDigit(_ n: UInt8) -> UInt8 {
        n < 10 ? 0x30 + n : 0x41 + n - 10
    }

    /// Append a `key=value` pair to `buffer`. Prefixes with `&` if the
    /// buffer is already non-empty.
    @inlinable
    internal static func appendField(_ buffer: inout Bytes, key: String, value: String) {
        if !buffer.isEmpty { buffer.append(0x26) } // &
        buffer.append(contentsOf: Array(key.utf8))
        buffer.append(0x3D)                         // =
        buffer.append(contentsOf: encode(value))
    }
}
