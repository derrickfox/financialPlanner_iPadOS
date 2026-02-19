import SwiftUI

enum Theme {
    static let backgroundTop = Color(red: 0.988, green: 0.949, blue: 0.882)
    static let backgroundMid = Color(red: 0.909, green: 0.949, blue: 0.937)
    static let backgroundBottom = Color(red: 0.992, green: 0.973, blue: 0.937)

    static let panel = Color.white.opacity(0.9)
    static let panelStroke = Color.white.opacity(0.95)

    static let text = Color(red: 0.122, green: 0.165, blue: 0.2)
    static let muted = Color(red: 0.373, green: 0.435, blue: 0.471)

    static let rent = Color(red: 0.898, green: 0.42, blue: 0.122)
    static let buy = Color(red: 0.047, green: 0.561, blue: 0.471)
    static let retirement = Color(red: 0.129, green: 0.373, blue: 0.808)
    static let target = Color(red: 0.722, green: 0.416, blue: 0.122)

    static let positive = buy
    static let negative = rent

    static let pageGradient = LinearGradient(
        colors: [backgroundTop, backgroundMid, backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum Formatters {
    static let money: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static let numberInput: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func currency(_ value: Double) -> String {
        money.string(from: NSNumber(value: value)) ?? "$0"
    }

    static func compactCurrency(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        func formatted(_ number: Double, suffix: String) -> String {
            let text = String(format: "%.1f", number)
            let cleaned = text.hasSuffix(".0") ? String(text.dropLast(2)) : text
            return "\(sign)$\(cleaned)\(suffix)"
        }

        if absValue >= 1_000_000_000 {
            return formatted(absValue / 1_000_000_000, suffix: "B")
        }
        if absValue >= 1_000_000 {
            return formatted(absValue / 1_000_000, suffix: "M")
        }
        if absValue >= 1_000 {
            return formatted(absValue / 1_000, suffix: "K")
        }
        return currency(value)
    }
}
