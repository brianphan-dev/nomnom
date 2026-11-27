import Foundation
import Testing
@testable import NomNomShared

@Suite("PureSHA256")
struct PureSHA256Tests {
    @Test("NIST vector: empty string")
    func emptyString() {
        #expect(
            PureSHA256.hex("")
                == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )
        #expect(
            PureSHA256.hex(Data())
                == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )
    }

    @Test("NIST vector: abc")
    func abcVector() {
        #expect(
            PureSHA256.hex("abc")
                == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    @Test("NIST vector: 448-bit (56-byte) two-block boundary")
    func twoBlockBoundary448Bit() {
        let input = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        #expect(input.utf8.count == 56)
        #expect(
            PureSHA256.hex(input)
                == "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"
        )
    }

    @Test("NIST vector: 896-bit (112-byte) multi-block")
    func multiBlock896Bit() {
        let input = "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"
        #expect(input.utf8.count == 112)
        #expect(
            PureSHA256.hex(input)
                == "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1"
        )
    }

    @Test("NIST vector: 1,000,000 repetitions of 'a'")
    func millionAsVector() {
        var context = PureSHA256.Context()
        let chunk = [UInt8](repeating: UInt8(ascii: "a"), count: 1000)
        for _ in 0..<1000 {
            context.update(chunk)
        }
        let digest = context.finalize()
        let hex = digest.map { byte in
            let s = String(byte, radix: 16)
            return s.count == 1 ? "0" + s : s
        }.joined()
        #expect(hex == "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
    }

    @Test("Streaming chunked context matches single-shot digest across block boundaries")
    func streamingMatchesSingleShot() {
        for length in [0, 1, 55, 56, 63, 64, 65, 127, 128, 257] {
            let bytes = (0..<length).map { UInt8($0 & 0xff) }
            let data = Data(bytes)
            let expected = PureSHA256.digest(data)

            var context = PureSHA256.Context()
            var offset = 0
            let step = 7
            while offset < bytes.count {
                let end = min(offset + step, bytes.count)
                context.update(Array(bytes[offset..<end]))
                offset = end
            }
            #expect(context.finalize() == expected)
        }
    }

    @Test("Data and UTF-8 String overloads produce identical lowercase hex")
    func utf8DataParity() {
        let sample = "mfp|2026-11-27|dinner|640.5|42.0|58.3|22.1|🍜"
        let fromString = PureSHA256.hex(sample)
        let fromData = PureSHA256.hex(Data(sample.utf8))
        #expect(fromString == fromData)
        #expect(fromString.count == 64)
        #expect(fromString == fromString.lowercased())
    }
}
