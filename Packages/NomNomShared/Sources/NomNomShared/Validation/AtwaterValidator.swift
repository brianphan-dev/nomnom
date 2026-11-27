import Foundation

/// Outcome of validating a `NutritionSnapshot` against Atwater energy consistency
/// and physiological calorie density limits.
public struct AtwaterValidationResult: Codable, Sendable, Equatable {
    /// `true` when no validation warnings were raised.
    public var isValid: Bool
    /// Calories predicted by the 4/4/9 Atwater formula (`4*P + 4*C + 9*F`).
    public var expectedCalories: Double
    /// Absolute percentage deviation between reported and expected calories (e.g. `15.0` = 15%).
    public var deltaPercent: Double
    /// Human-readable warnings explaining any consistency or density violations.
    public var warnings: [String]

    public init(
        isValid: Bool,
        expectedCalories: Double,
        deltaPercent: Double,
        warnings: [String]
    ) {
        self.isValid = isValid
        self.expectedCalories = expectedCalories
        self.deltaPercent = deltaPercent
        self.warnings = warnings
    }

    private enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case expectedCalories = "expected_calories"
        case deltaPercent = "delta_percent"
        case warnings
    }
}

/// Validates nutrition snapshots using the 4-4-9 Atwater calorie formula
/// and physical energy density constraints.
public struct AtwaterValidator: Sendable, Equatable {
    /// Default allowed percentage variance between reported and Atwater-expected calories (`±15%`).
    public static let defaultTolerancePercent: Double = 15.0
    /// Default calorie threshold at or below which absolute rounding tolerance applies (`40 kcal`).
    public static let defaultLowCalorieThresholdKcal: Double = 40.0
    /// Default absolute calorie allowance for low-calorie foods (handles FDA label rounding).
    public static let defaultLowCalorieAbsoluteToleranceKcal: Double = 15.0
    /// Default upper bound on energy density (`9.2 kcal/g`, pure lipid ≈ 9.0 kcal/g + small margin).
    public static let defaultMaxCalorieDensityKcalPerGram: Double = 9.2

    public let tolerancePercent: Double
    public let lowCalorieThresholdKcal: Double
    public let lowCalorieAbsoluteToleranceKcal: Double
    public let maxCalorieDensityKcalPerGram: Double

    public static let `default` = AtwaterValidator()

    public init(
        tolerancePercent: Double = defaultTolerancePercent,
        lowCalorieThresholdKcal: Double = defaultLowCalorieThresholdKcal,
        lowCalorieAbsoluteToleranceKcal: Double = defaultLowCalorieAbsoluteToleranceKcal,
        maxCalorieDensityKcalPerGram: Double = defaultMaxCalorieDensityKcalPerGram
    ) {
        self.tolerancePercent = tolerancePercent
        self.lowCalorieThresholdKcal = lowCalorieThresholdKcal
        self.lowCalorieAbsoluteToleranceKcal = lowCalorieAbsoluteToleranceKcal
        self.maxCalorieDensityKcalPerGram = maxCalorieDensityKcalPerGram
    }

    /// Convenience static validation using default thresholds.
    public static func validate(
        _ snapshot: NutritionSnapshot,
        gramWeight: Double? = nil
    ) -> AtwaterValidationResult {
        AtwaterValidator.default.validate(snapshot, gramWeight: gramWeight)
    }

    /// Validates a `NutritionSnapshot` and optional `gramWeight`.
    public func validate(
        _ snapshot: NutritionSnapshot,
        gramWeight: Double? = nil
    ) -> AtwaterValidationResult {
        var warnings: [String] = []

        let coreValues: [(String, Double)] = [
            ("calories", snapshot.caloriesKcal),
            ("protein", snapshot.proteinG),
            ("carbs", snapshot.carbsG),
            ("fat", snapshot.fatG),
        ]
        var hasInvalidNumbers = false
        for (label, value) in coreValues {
            if !value.isFinite {
                warnings.append("Non-finite \(label) value.")
                hasInvalidNumbers = true
            } else if value < 0 {
                warnings.append("Negative \(label) value (\(CanonicalNumberFormatter.fixed1(value))).")
                hasInvalidNumbers = true
            }
        }

        if hasInvalidNumbers {
            return AtwaterValidationResult(
                isValid: false,
                expectedCalories: 0,
                deltaPercent: 100.0,
                warnings: warnings
            )
        }

        let expectedCalories = (4.0 * snapshot.proteinG)
            + (4.0 * snapshot.carbsG)
            + (9.0 * snapshot.fatG)
        let reportedCalories = snapshot.caloriesKcal
        let absDelta = abs(reportedCalories - expectedCalories)

        let deltaPercent: Double
        if expectedCalories > 0 {
            deltaPercent = (absDelta / expectedCalories) * 100.0
        } else {
            deltaPercent = reportedCalories == 0 ? 0.0 : 100.0
        }

        let isLowCalorieFood = max(reportedCalories, expectedCalories) <= lowCalorieThresholdKcal
        let exceedsMacroTolerance: Bool
        if isLowCalorieFood {
            // Allow either percentage tolerance or small absolute rounding floor for low-calorie foods.
            let allowedKcal = max(expectedCalories * (tolerancePercent / 100.0), lowCalorieAbsoluteToleranceKcal)
            exceedsMacroTolerance = absDelta > allowedKcal + 1e-9
        } else {
            exceedsMacroTolerance = deltaPercent > tolerancePercent + 1e-9
        }

        if exceedsMacroTolerance {
            warnings.append(
                "Reported calories (\(CanonicalNumberFormatter.fixed1(reportedCalories)) kcal) deviate by "
                    + "\(CanonicalNumberFormatter.fixed1(deltaPercent))% from Atwater estimate "
                    + "(\(CanonicalNumberFormatter.fixed1(expectedCalories)) kcal)."
            )
        }

        if let grams = gramWeight {
            if !grams.isFinite || grams <= 0 {
                warnings.append("Gram weight must be a positive finite number.")
            } else {
                let density = reportedCalories / grams
                if density > maxCalorieDensityKcalPerGram + 1e-9 {
                    warnings.append(
                        "Calorie density (\(CanonicalNumberFormatter.fixed2(density)) kcal/g) exceeds "
                            + "maximum physiological limit of \(CanonicalNumberFormatter.fixed1(maxCalorieDensityKcalPerGram)) kcal/g."
                    )
                }
            }
        }

        return AtwaterValidationResult(
            isValid: warnings.isEmpty,
            expectedCalories: expectedCalories,
            deltaPercent: deltaPercent,
            warnings: warnings
        )
    }
}
