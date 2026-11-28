import Foundation
import CoreGraphics
import Testing
@testable import nomnom
import NomNomShared

@Suite("nomnom App Adaptive Layout & Review Draft")
struct NomNomAppTests {
    @Test("Resolves iPhone, iPhone Duo folded, iPhone Duo unfolded, and iPad form factors")
    func layoutClassResolution() {
        // Standard iPhone 18 Pro portrait
        let phone = NNLayoutClass.resolve(
            size: CGSize(width: 402, height: 874),
            horizontalSizeClass: .compact,
            idiom: .phone
        )
        #expect(phone == .phone)

        // iPhone Duo folded 5.4" cover display (466 x 678 pt)
        let duoFolded = NNLayoutClass.resolve(
            size: CGSize(width: 466, height: 678),
            horizontalSizeClass: .compact,
            idiom: .phone
        )
        #expect(duoFolded == .duoFolded)
        #expect(duoFolded.isCompactCover)

        // iPhone Duo unfolded 7.6" inner display (both 890 x 626 pt landscape and 669 x 951 pt portrait)
        let duoUnfolded = NNLayoutClass.resolve(
            size: CGSize(width: 890, height: 626),
            horizontalSizeClass: .regular,
            idiom: .phone
        )
        #expect(duoUnfolded == .dualPane(isDuoUnfolded: true))
        #expect(duoUnfolded.isDualPane)
        #expect(duoUnfolded.isDuoUnfolded)

        let duoUnfoldedPortrait = NNLayoutClass.resolve(
            size: CGSize(width: 669, height: 951),
            horizontalSizeClass: .regular,
            idiom: .phone
        )
        #expect(duoUnfoldedPortrait == .dualPane(isDuoUnfolded: true))

        // iPad Pro 11" landscape/portrait regular width
        let ipad = NNLayoutClass.resolve(
            size: CGSize(width: 834, height: 1194),
            horizontalSizeClass: .regular,
            idiom: .pad
        )
        #expect(ipad == .dualPane(isDuoUnfolded: false))
        #expect(ipad.isDualPane)
        #expect(!ipad.isDuoUnfolded)
    }

    @Test("ReviewDraft totals scale item multipliers and toggle optional sauces accurately")
    func reviewDraftTotals() {
        var draft = ReviewDraft(
            title: "Salmon rice bowl",
            mealType: .lunch,
            captureMethod: .photoAI,
            items: [
                ReviewItemDraft(
                    displayName: "Grilled salmon",
                    servingLabel: "1 fillet",
                    gramWeight: 150,
                    portionMultiplier: 1.5,
                    confidence: 0.91,
                    baseNutrition: NutritionSnapshot(caloriesKcal: 300, proteinG: 32, carbsG: 0, fatG: 18)
                ),
                ReviewItemDraft(
                    displayName: "Steamed rice",
                    servingLabel: "1 cup",
                    gramWeight: 180,
                    portionMultiplier: 1.0,
                    confidence: 0.68,
                    baseNutrition: NutritionSnapshot(caloriesKcal: 200, proteinG: 4, carbsG: 44, fatG: 0.5)
                ),
            ],
            sauces: [
                ReviewSauceDraft(
                    name: "Sesame oil",
                    estimatedGrams: 5,
                    nutrition: NutritionSnapshot(caloriesKcal: 45, proteinG: 0, carbsG: 0, fatG: 5),
                    isIncluded: true
                ),
                ReviewSauceDraft(
                    name: "Spicy mayo",
                    estimatedGrams: 15,
                    nutrition: NutritionSnapshot(caloriesKcal: 90, proteinG: 0, carbsG: 1, fatG: 10),
                    isIncluded: false
                ),
            ]
        )

        #expect(draft.items[0].needsCheck == false)
        #expect(draft.items[1].needsCheck == true)
        #expect(draft.includedSauceCount == 1)
        #expect(Int(draft.totalNutrition.caloriesKcal.rounded()) == 695) // 450 + 200 + 45

        draft.sauces[1].isIncluded = true
        #expect(draft.includedSauceCount == 2)
        #expect(Int(draft.totalNutrition.caloriesKcal.rounded()) == 785)

        let meal = draft.toMeal(localDate: "2026-11-28")
        #expect(meal.title == "Salmon rice bowl")
        #expect(meal.items.count == 2)
        #expect(Int(meal.totalNutrition.caloriesKcal.rounded()) == 785)
    }
}
