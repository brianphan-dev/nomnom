import Foundation

/// Copy and numeral formatting helpers adhering strictly to nomnom Content Fundamentals:
/// - Digits with thousands separators (`1,118`), units lowercase with a space (`612 kcal`, `14 g`)
/// - Tight macro lines omit spaces inside unit suffixes (`62/120g`, `P38 C58 F24`)
/// - Multipliers use the typographic multiplication sign `×` (`1.5×`)
/// - Metadata joined by middle dot ` · ` (`Lunch · 12:40`)
/// - Calm neutral over-target copy (`"140 over"`, `"320 left"`), zero exclamation marks, zero emoji
public enum NNFormatting {
    /// Formats a calorie value with thousands separators, rounded to the nearest whole number (e.g. `"1,118"`).
    public static func kcal(_ value: Double) -> String {
        kcal(Int(value.rounded()))
    }

    /// Formats an integer calorie value with thousands separators (e.g. `"1,118"`).
    public static func kcal(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
    }

    /// Formats a calorie value with the lowercase unit separated by a space (e.g. `"612 kcal"`).
    public static func kcalWithUnit(_ value: Double) -> String {
        "\(kcal(value)) kcal"
    }

    /// Formats grams with a lowercase unit and space (e.g. `"14 g"`).
    public static func grams(_ value: Double) -> String {
        grams(Int(value.rounded()))
    }

    /// Formats integer grams with a lowercase unit and space (e.g. `"14 g"`).
    public static func grams(_ value: Int) -> String {
        "\(kcal(value)) g"
    }

    /// Formats tight macro bar values (e.g. `"62/120g"` when target is given, or `"62g"`).
    public static func gramsCompact(_ value: Double, target: Double? = nil) -> String {
        let roundedValue = Int(value.rounded())
        if let target, target > 0 {
            return "\(roundedValue)/\(Int(target.rounded()))g"
        }
        return "\(roundedValue)g"
    }

    /// Formats a portion multiplier using the typographic multiplication sign `×` (e.g. `"1.5×"`, `"1×"`, `"0.75×"`).
    public static func multiplier(_ value: Double) -> String {
        let rounded = (value * 100.0).rounded() / 100.0
        let formatted: String
        if rounded == rounded.rounded() {
            formatted = String(Int(rounded))
        } else if (rounded * 10.0).rounded() == rounded * 10.0 {
            formatted = String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), rounded)
        } else {
            formatted = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), rounded)
        }
        return "\(formatted)\u{00D7}"
    }

    /// Splits remaining/over-target copy into its formatted numeral and calm suffix (`" left"` or `" over"`).
    public static func remainingParts(consumed: Double, target: Double) -> (amount: String, suffix: String) {
        let difference = target - consumed
        let rounded = Int(abs(difference).rounded())
        let isRemaining = difference >= 0 || rounded == 0
        return (kcal(rounded), isRemaining ? " left" : " over")
    }

    /// Formats calm remaining or over-target copy (`"320 left"` or `"140 over"`). Never scolding, never red.
    public static func remainingText(consumed: Double, target: Double) -> String {
        let parts = remainingParts(consumed: consumed, target: target)
        return parts.amount + parts.suffix
    }

    /// Formats compact inline macro summary (`"P38 C58 F24"`).
    public static func macroCompact(p: Double, c: Double, f: Double) -> String {
        "P\(Int(p.rounded())) C\(Int(c.rounded())) F\(Int(f.rounded()))"
    }

    /// Formats compact inline macro summary with optional values (`"P– C– F–"` for missing values).
    public static func macroCompact(p: Double?, c: Double?, f: Double?) -> String {
        let fmt: (Double?) -> String = { value in
            guard let value else { return "–" }
            return String(Int(value.rounded()))
        }
        return "P\(fmt(p)) C\(fmt(c)) F\(fmt(f))"
    }

    /// Joins non-empty metadata items with the middle dot separator ` · ` (e.g. `"Lunch · 12:40"`).
    public static func metadataLine(_ parts: [String?]) -> String {
        parts
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " \u{00B7} ")
    }

    /// Variadic convenience overload joining non-empty metadata items with ` · `.
    public static func metadataLine(_ parts: String?...) -> String {
        metadataLine(parts)
    }

    /// Formats the primary save CTA label carrying the live total (`"Save 697 kcal to diary"`).
    public static func saveButtonTitle(kcal value: Double, verb: String = "Save") -> String {
        "\(verb) \(kcal(value)) kcal to diary"
    }

    /// Formats the collapsed sauces/oils/seasonings summary (`"3 · +122"`).
    public static func extrasSummary(count: Int, addedKcal: Double) -> String {
        "\(count) \u{00B7} +\(kcal(addedKcal))"
    }

    /// Formats the offline sync pill copy (`"Offline · 2 queued"` or `"Offline · Queued"`).
    public static func syncOfflineLabel(queued: Int?) -> String {
        if let queued, queued > 0 {
            return "Offline \u{00B7} \(queued) queued"
        }
        return "Offline \u{00B7} Queued"
    }
}
