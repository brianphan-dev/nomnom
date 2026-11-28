import Testing
@testable import NomNomShared

@Suite("AtwaterValidator")
struct AtwaterValidatorTests {
    @Test("Valid meal within 15% Atwater tolerance passes with zero warnings")
    func validMealPasses() {
        // Expected: 4*35 + 4*45 + 9*14 = 140 + 180 + 126 = 446 kcal
        let snapshot = NutritionSnapshot(
            caloriesKcal: 460,
            proteinG: 35,
            carbsG: 45,
            fatG: 14
        )
        let result = AtwaterValidator.validate(snapshot, gramWeight: 320)
        #expect(result.isValid)
        #expect(result.expectedCalories == 446)
        #expect(result.deltaPercent < 4.0)
        #expect(result.warnings.isEmpty)
    }

    @Test("Boundary at exact 15% passes while >15% produces warning")
    func exactToleranceBoundary() {
        // Expected: 4*25 + 4*25 + 9*0 = 200 kcal -> 15% = 230 kcal
        let atBoundary = NutritionSnapshot(caloriesKcal: 230, proteinG: 25, carbsG: 25, fatG: 0)
        let boundaryResult = AtwaterValidator.validate(atBoundary)
        #expect(boundaryResult.isValid)
        #expect(boundaryResult.deltaPercent == 15.0)

        let overBoundary = NutritionSnapshot(caloriesKcal: 235, proteinG: 25, carbsG: 25, fatG: 0)
        let overResult = AtwaterValidator.validate(overBoundary)
        #expect(!overResult.isValid)
        #expect(overResult.deltaPercent > 15.0)
        #expect(overResult.warnings.count == 1)
    }

    @Test("Severe macro mismatch emits warning")
    func macroMismatchWarning() {
        // Expected: 4*20 + 4*30 + 9*10 = 290 kcal, reported 520 kcal (~79% off)
        let snapshot = NutritionSnapshot(caloriesKcal: 520, proteinG: 20, carbsG: 30, fatG: 10)
        let result = AtwaterValidator.validate(snapshot)
        #expect(!result.isValid)
        #expect(result.expectedCalories == 290)
        #expect(result.deltaPercent > 75.0)
        #expect(!result.warnings.isEmpty)
    }

    @Test("Calorie density checks enforce <= 9.2 kcal/g limit")
    func calorieDensityLimits() {
        // Pure olive oil: ~884 kcal per 100g (8.84 kcal/g) -> valid
        let oliveOil = NutritionSnapshot(caloriesKcal: 884, proteinG: 0, carbsG: 0, fatG: 100)
        let oilResult = AtwaterValidator.validate(oliveOil, gramWeight: 100)
        #expect(oilResult.isValid)
        #expect(oilResult.warnings.isEmpty)

        // Exact 9.2 kcal/g boundary -> valid
        let atLimit = NutritionSnapshot(caloriesKcal: 920, proteinG: 0, carbsG: 0, fatG: 102)
        #expect(AtwaterValidator.validate(atLimit, gramWeight: 100).isValid)

        // Physically impossible 12.0 kcal/g -> warning
        let tooDense = NutritionSnapshot(caloriesKcal: 600, proteinG: 0, carbsG: 0, fatG: 66.7)
        let denseResult = AtwaterValidator.validate(tooDense, gramWeight: 50)
        #expect(!denseResult.isValid)
        #expect(denseResult.warnings.contains { $0.contains("Calorie density") })
    }

    @Test("Low-calorie foods (<= 40 kcal) use sensible rounding tolerance floor")
    func lowCalorieToleranceFloor() {
        // Pickle / condiment: 15 kcal reported vs 12 kcal Atwater (25% diff, only 3 kcal delta) -> valid
        let condiment = NutritionSnapshot(caloriesKcal: 15, proteinG: 1, carbsG: 2, fatG: 0)
        let condimentResult = AtwaterValidator.validate(condiment)
        #expect(condimentResult.isValid)
        #expect(condimentResult.expectedCalories == 12)
        #expect(condimentResult.deltaPercent == 25.0)
        #expect(condimentResult.warnings.isEmpty)

        // Zero-calorie beverage -> valid
        let water = NutritionSnapshot(caloriesKcal: 0, proteinG: 0, carbsG: 0, fatG: 0)
        let waterResult = AtwaterValidator.validate(water)
        #expect(waterResult.isValid)
        #expect(waterResult.deltaPercent == 0.0)

        // Blatantly inconsistent 40 kcal with 0g of all macros exceeds 15 kcal floor -> invalid
        let brokenLowCal = NutritionSnapshot(caloriesKcal: 40, proteinG: 0, carbsG: 0, fatG: 0)
        let brokenResult = AtwaterValidator.validate(brokenLowCal)
        #expect(!brokenResult.isValid)
        #expect(!brokenResult.warnings.isEmpty)
    }

    @Test("Negative macros and invalid gram weights fail validation")
    func invalidInputsRejected() {
        let negativeProtein = NutritionSnapshot(caloriesKcal: 100, proteinG: -5, carbsG: 10, fatG: 5)
        let negResult = AtwaterValidator.validate(negativeProtein)
        #expect(!negResult.isValid)
        #expect(negResult.warnings.contains { $0.contains("Negative protein") })

        let validFood = NutritionSnapshot(caloriesKcal: 200, proteinG: 20, carbsG: 20, fatG: 4.5)
        let zeroGrams = AtwaterValidator.validate(validFood, gramWeight: 0)
        #expect(!zeroGrams.isValid)
        #expect(zeroGrams.warnings.contains { $0.contains("Gram weight") })
    }
}
