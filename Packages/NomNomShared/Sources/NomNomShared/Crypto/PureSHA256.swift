import Foundation

/// Pure-Swift RFC 6234 / FIPS 180-4 SHA-256 implementation.
///
/// Zero external dependencies; behaves identically across iOS, macOS, and Linux.
public enum PureSHA256: Sendable {
    private static let k: [UInt32] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ]

    private static let hexAlphabet: [UInt8] = Array("0123456789abcdef".utf8)

    /// Incremental SHA-256 context suitable for streaming large payloads without copying.
    public struct Context: Sendable {
        private var state: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) = (
            0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
            0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
        )
        private var buffer: [UInt8] = []
        private var totalBytes: UInt64 = 0

        public init() {
            buffer.reserveCapacity(64)
        }

        public mutating func update(_ bytes: UnsafeBufferPointer<UInt8>) {
            guard !bytes.isEmpty else { return }
            totalBytes &+= UInt64(bytes.count)

            var offset = 0
            if !buffer.isEmpty {
                let needed = 64 - buffer.count
                let take = min(needed, bytes.count)
                buffer.append(contentsOf: bytes[0..<take])
                offset += take
                if buffer.count == 64 {
                    buffer.withUnsafeBufferPointer { ptr in
                        compress(block: ptr, offset: 0)
                    }
                    buffer.removeAll(keepingCapacity: true)
                }
            }

            while offset + 64 <= bytes.count {
                compress(block: bytes, offset: offset)
                offset += 64
            }

            if offset < bytes.count {
                buffer.append(contentsOf: bytes[offset..<bytes.count])
            }
        }

        public mutating func update(_ data: Data) {
            data.withUnsafeBytes { rawBuffer in
                let typed = rawBuffer.bindMemory(to: UInt8.self)
                update(typed)
            }
        }

        public mutating func update(_ bytes: [UInt8]) {
            bytes.withUnsafeBufferPointer { ptr in
                update(ptr)
            }
        }

        public mutating func finalize() -> [UInt8] {
            let bitLength = totalBytes &* 8

            // Append 0x80 terminator byte, then zero-pad until length % 64 == 56.
            buffer.append(0x80)
            if buffer.count > 56 {
                while buffer.count < 64 {
                    buffer.append(0x00)
                }
                buffer.withUnsafeBufferPointer { ptr in
                    compress(block: ptr, offset: 0)
                }
                buffer.removeAll(keepingCapacity: true)
            }

            while buffer.count < 56 {
                buffer.append(0x00)
            }

            // Append 64-bit big-endian message bit length.
            for shift in stride(from: 56, through: 0, by: -8) {
                buffer.append(UInt8(truncatingIfNeeded: bitLength >> UInt64(shift)))
            }

            buffer.withUnsafeBufferPointer { ptr in
                compress(block: ptr, offset: 0)
            }
            buffer.removeAll(keepingCapacity: true)

            let words: [UInt32] = [
                state.0, state.1, state.2, state.3,
                state.4, state.5, state.6, state.7,
            ]
            var digest = [UInt8]()
            digest.reserveCapacity(32)
            for word in words {
                digest.append(UInt8(truncatingIfNeeded: word >> 24))
                digest.append(UInt8(truncatingIfNeeded: word >> 16))
                digest.append(UInt8(truncatingIfNeeded: word >> 8))
                digest.append(UInt8(truncatingIfNeeded: word))
            }
            return digest
        }

        private mutating func compress(block: UnsafeBufferPointer<UInt8>, offset: Int) {
            var w = [UInt32](repeating: 0, count: 64)

            for i in 0..<16 {
                let idx = offset + (i * 4)
                w[i] = (UInt32(block[idx]) << 24)
                    | (UInt32(block[idx + 1]) << 16)
                    | (UInt32(block[idx + 2]) << 8)
                    | UInt32(block[idx + 3])
            }

            for i in 16..<64 {
                let w15 = w[i - 15]
                let w2 = w[i - 2]
                let s0 = rotateRight(w15, by: 7) ^ rotateRight(w15, by: 18) ^ (w15 >> 3)
                let s1 = rotateRight(w2, by: 17) ^ rotateRight(w2, by: 19) ^ (w2 >> 10)
                w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1
            }

            var a = state.0
            var b = state.1
            var c = state.2
            var d = state.3
            var e = state.4
            var f = state.5
            var g = state.6
            var h = state.7

            let roundConstants = PureSHA256.k
            for i in 0..<64 {
                let s1 = rotateRight(e, by: 6) ^ rotateRight(e, by: 11) ^ rotateRight(e, by: 25)
                let ch = (e & f) ^ ((~e) & g)
                let temp1 = h &+ s1 &+ ch &+ roundConstants[i] &+ w[i]
                let s0 = rotateRight(a, by: 2) ^ rotateRight(a, by: 13) ^ rotateRight(a, by: 22)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let temp2 = s0 &+ maj

                h = g
                g = f
                f = e
                e = d &+ temp1
                d = c
                c = b
                b = a
                a = temp1 &+ temp2
            }

            state.0 &+= a
            state.1 &+= b
            state.2 &+= c
            state.3 &+= d
            state.4 &+= e
            state.5 &+= f
            state.6 &+= g
            state.7 &+= h
        }

        @inline(__always)
        private func rotateRight(_ value: UInt32, by bits: UInt32) -> UInt32 {
            (value >> bits) | (value << (32 - bits))
        }
    }

    /// Computes raw 32-byte SHA-256 digest of `data`.
    public static func digest(_ data: Data) -> [UInt8] {
        var context = Context()
        context.update(data)
        return context.finalize()
    }

    /// Computes raw 32-byte SHA-256 digest of a UTF-8 string.
    public static func digest(_ string: String) -> [UInt8] {
        var context = Context()
        let bytes = Array(string.utf8)
        context.update(bytes)
        return context.finalize()
    }

    /// Computes lowercase 64-character hexadecimal SHA-256 digest of `data`.
    public static func hex(_ data: Data) -> String {
        encodeHex(digest(data))
    }

    /// Computes lowercase 64-character hexadecimal SHA-256 digest of UTF-8 `string`.
    public static func hex(_ string: String) -> String {
        encodeHex(digest(string))
    }

    private static func encodeHex(_ bytes: [UInt8]) -> String {
        var output = [UInt8]()
        output.reserveCapacity(bytes.count * 2)
        for byte in bytes {
            output.append(hexAlphabet[Int(byte >> 4)])
            output.append(hexAlphabet[Int(byte & 0x0f)])
        }
        return String(decoding: output, as: UTF8.self)
    }
}
