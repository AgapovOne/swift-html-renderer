import SwiftUI

// MARK: - ListNumberFormat

public enum ListNumberFormat: Sendable {
    case decimal
    case lowerAlpha
    case upperAlpha
    case lowerRoman
    case upperRoman
    case custom(@Sendable (Int) -> String)

    public func format(_ index: Int) -> String {
        switch self {
        case .decimal:
            return "\(index + 1)."
        case .lowerAlpha:
            return "\(Self.alphaString(for: index, uppercase: false))."
        case .upperAlpha:
            return "\(Self.alphaString(for: index, uppercase: true))."
        case .lowerRoman:
            return "\(Self.romanString(for: index + 1, uppercase: false))."
        case .upperRoman:
            return "\(Self.romanString(for: index + 1, uppercase: true))."
        case .custom(let formatter):
            return formatter(index)
        }
    }

    private static func alphaString(for index: Int, uppercase: Bool) -> String {
        let base: UInt32 = uppercase ? 65 : 97 // A or a
        var result = ""
        var n = index
        repeat {
            let charIndex = n % 26
            result = String(Character(Unicode.Scalar(base + UInt32(charIndex))!)) + result
            n = n / 26 - 1
        } while n >= 0
        return result
    }

    private static func romanString(for number: Int, uppercase: Bool) -> String {
        guard number > 0 else { return "" }
        let values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
        let symbols = ["m", "cm", "d", "cd", "c", "xc", "l", "xl", "x", "ix", "v", "iv", "i"]
        var result = ""
        var remaining = number
        for (value, symbol) in zip(values, symbols) {
            while remaining >= value {
                result += symbol
                remaining -= value
            }
        }
        return uppercase ? result.uppercased() : result
    }
}

