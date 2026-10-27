import Foundation

/// Foundation establishes JSON syntax first; this pass retains key multiplicity
/// that dictionary decoding would otherwise erase before workspace validation.
enum JSONKeyUniqueness {
    private struct Frame {
        let isObject: Bool
        var expectsKey: Bool
        var keys: Set<String> = []
    }

    static func validate(_ data: Data) throws {
        let bytes = Array(data)
        var frames: [Frame] = []
        var index = 0
        let keyDecoder = JSONDecoder()
        while index < bytes.count {
            switch bytes[index] {
            case 0x7b: // {
                frames.append(Frame(isObject: true, expectsKey: true))
                index += 1
            case 0x5b: // [
                frames.append(Frame(isObject: false, expectsKey: false))
                index += 1
            case 0x7d, 0x5d: // } ]
                guard !frames.isEmpty else { throw invalid() }
                frames.removeLast()
                index += 1
            case 0x2c: // ,
                if let last = frames.indices.last, frames[last].isObject { frames[last].expectsKey = true }
                index += 1
            case 0x3a: // :
                if let last = frames.indices.last, frames[last].isObject { frames[last].expectsKey = false }
                index += 1
            case 0x22: // quoted key or string value
                let end = try stringEnd(in: bytes, from: index)
                if let last = frames.indices.last, frames[last].isObject && frames[last].expectsKey {
                    let key = try keyDecoder.decode(String.self, from: Data(bytes[index...end]))
                    guard frames[last].keys.insert(key).inserted else {
                        throw ConductorError.invalidData("The saved workspace contains duplicate JSON fields. Keep the original file for recovery.")
                    }
                    frames[last].expectsKey = false
                }
                index = end + 1
            default:
                index += 1
            }
        }
        guard frames.isEmpty else { throw invalid() }
    }

    private static func stringEnd(in bytes: [UInt8], from start: Int) throws -> Int {
        var index = start + 1
        while index < bytes.count {
            if bytes[index] == 0x5c { index += 2 }
            else if bytes[index] == 0x22 { return index }
            else { index += 1 }
        }
        throw invalid()
    }

    private static func invalid() -> ConductorError {
        .invalidData("The saved workspace is not supported JSON. Keep the original file for recovery.")
    }
}
