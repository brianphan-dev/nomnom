import Foundation
import Testing
@testable import NomNomShared

@Suite("PortableExporter")
struct PortableExporterTests {
    private func sampleMeals() -> [Meal] {
        let tBreakfast = NomNomJSON.parseISO8601("2026-11-27T16:00:00.000Z")!
        let tDinner = NomNomJSON.parseISO8601("2026-11-27T02:30:00.000Z")!
        let tOtherDay = NomNomJSON.parseISO8601("2026-11-26T20:00:00.000Z")!

        let breakfast = Meal(
            localDate: "2026-11-27",
            eatenAt: tBreakfast,
            timezoneId: "America/Los_Angeles",
            mealType: .breakfast,
            title: "Greek Yogurt, Berries & \"Crunchy\" Granola",
            notes: "Great start,\nadded cinnamon",
            captureMethod: .photoAI,
            aiStatus: .analyzed,
            items: [
                MealEntryItem(
                    displayName: "Greek Yogurt",
                    brand: "Fage, 2%",
                    servingLabel: "1 cup",
                    quantity: 1,
                    gramWeight: 200,
                    portionMultiplier: 1.0,
                    confidence: 0.95,
                    nutrition: NutritionSnapshot(
                        caloriesKcal: 150,
                        proteinG: 20,
                        carbsG: 8,
                        fatG: 4,
                        fiberG: 0,
                        sugarG: 6,
                        sodiumMg: 70
                    )
                ),
                MealEntryItem(
                    displayName: "Honey Granola",
                    servingLabel: "1/2 cup",
                    quantity: 1,
                    gramWeight: 50,
                    portionMultiplier: 1.5,
                    confidence: 0.82,
                    nutrition: NutritionSnapshot(
                        caloriesKcal: 200,
                        proteinG: 4,
                        carbsG: 30,
                        fatG: 7,
                        fiberG: 4,
                        sugarG: 10
                    )
                ),
            ],
            createdAt: tBreakfast,
            updatedAt: tBreakfast
        )

        let dinner = Meal(
            localDate: "2026-11-27",
            eatenAt: tDinner,
            timezoneId: "America/Los_Angeles",
            mealType: .dinner,
            title: "Teriyaki Salmon Bowl",
            notes: nil,
            captureMethod: .photoAI,
            aiStatus: .analyzed,
            items: [
                MealEntryItem(
                    displayName: "Grilled Salmon",
                    servingLabel: "1 fillet (~150g)",
                    quantity: 1,
                    gramWeight: 150,
                    portionMultiplier: 1.0,
                    confidence: 0.90,
                    nutrition: NutritionSnapshot(
                        caloriesKcal: 300,
                        proteinG: 34,
                        carbsG: 0,
                        fatG: 18,
                        sodiumMg: 90
                    ),
                    ingredients: [
                        IngredientEstimate(
                            name: "Olive oil",
                            category: .oil,
                            estimatedGrams: 10,
                            nutrition: NutritionSnapshot(caloriesKcal: 88, proteinG: 0, carbsG: 0, fatG: 10),
                            isOptionalEstimate: true,
                            isIncluded: true
                        ),
                        IngredientEstimate(
                            name: "Teriyaki glaze",
                            category: .sauce,
                            estimatedGrams: 15,
                            nutrition: NutritionSnapshot(caloriesKcal: 30, proteinG: 0.5, carbsG: 7, fatG: 0),
                            isOptionalEstimate: true,
                            isIncluded: false
                        ),
                    ]
                ),
            ],
            createdAt: tDinner,
            updatedAt: tDinner
        )

        let deletedMeal = Meal(
            localDate: "2026-11-27",
            eatenAt: tBreakfast,
            mealType: .snack,
            title: "Deleted Snack",
            captureMethod: .manualDB,
            items: [
                MealEntryItem(
                    displayName: "Cookie",
                    servingLabel: "1 cookie",
                    nutrition: NutritionSnapshot(caloriesKcal: 250, proteinG: 2, carbsG: 30, fatG: 12)
                ),
            ],
            createdAt: tBreakfast,
            updatedAt: tBreakfast,
            deletedAt: tBreakfast
        )

        let previousDayMeal = Meal(
            localDate: "2026-11-26",
            eatenAt: tOtherDay,
            mealType: .lunch,
            title: "Yesterday Lunch",
            captureMethod: .barcode,
            items: [
                MealEntryItem(
                    displayName: "Turkey Wrap",
                    servingLabel: "1 wrap",
                    nutrition: NutritionSnapshot(caloriesKcal: 420, proteinG: 32, carbsG: 44, fatG: 12)
                ),
            ],
            createdAt: tOtherDay,
            updatedAt: tOtherDay
        )

        return [breakfast, dinner, deletedMeal, previousDayMeal]
    }

    @Test("DiaryExport & ExportManifest JSON round-trip preserves schema version and active counts")
    func diaryExportRoundTrip() throws {
        let exportedAt = NomNomJSON.parseISO8601("2026-11-27T23:59:59.000Z")!
        let meals = sampleMeals()
        let export = PortableExporter.makeDiaryExport(
            meals: meals,
            appVersion: "1.0.0",
            exportedAt: exportedAt
        )

        #expect(export.manifest.schemaVersion == "1.0")
        #expect(export.manifest.appVersion == "1.0.0")
        #expect(export.manifest.mealCount == 3) // deleted meal excluded
        #expect(export.meals.count == 3)

        let data = try PortableExporter.encodeJSON(export)
        let decoded = try PortableExporter.decodeJSON(data)
        #expect(decoded == export)
    }

    @Test("mealsCSV and mealItemsCSV escape commas, quotes, and newlines per RFC-4180")
    func csvExportAndEscaping() throws {
        let meals = sampleMeals()

        let mealsCSV = PortableExporter.mealsCSV(meals: meals)
        let parsedMealsRows = try RFC4180CSVParser.parse(mealsCSV)
        // Header + 3 non-deleted meals (sorted chronologically: 2026-11-26, 2026-11-27 dinner, 2026-11-27 breakfast)
        #expect(parsedMealsRows.count == 4)
        #expect(parsedMealsRows[0].first == "meal_id")
        #expect(parsedMealsRows[0].last == "notes")

        // Verify quoted title and multiline notes round-trip accurately
        let breakfastRow = try #require(parsedMealsRows.first { $0[4] == "breakfast" })
        #expect(breakfastRow[5] == "Greek Yogurt, Berries & \"Crunchy\" Granola")
        // 150 + (200 * 1.5) = 450.0 kcal
        #expect(breakfastRow[8] == "450.0")
        #expect(breakfastRow[17] == "Great start,\nadded cinnamon")

        let itemsCSV = PortableExporter.mealItemsCSV(meals: meals)
        let parsedItemRows = try RFC4180CSVParser.parse(itemsCSV)
        // Header + 4 active items (1 on Nov 26, 1 salmon, 2 breakfast items)
        #expect(parsedItemRows.count == 5)

        let yogurtRow = try #require(parsedItemRows.first { $0[4] == "Greek Yogurt" })
        #expect(yogurtRow[5] == "Fage, 2%")

        let salmonRow = try #require(parsedItemRows.first { $0[4] == "Grilled Salmon" })
        // Effective calories = 300 + 88 (olive oil included; teriyaki excluded) = 388.0
        #expect(salmonRow[11] == "388.0")
        #expect(salmonRow[18] == "Olive oil")
    }

    @Test("obsidianDailyMarkdown emits YAML frontmatter, daily totals, meal headings, and collapsible sauces/oils callout")
    func obsidianDailyMarkdown() {
        let meals = sampleMeals()
        let md = PortableExporter.obsidianDailyMarkdown(date: "2026-11-27", meals: meals)

        // Daily totals for 2026-11-27:
        // Breakfast: 150 + 300 = 450 kcal | P: 20 + 6 = 26g | C: 8 + 45 = 53g | F: 4 + 10.5 = 14.5g | Fiber: 6g | Sodium: 70mg
        // Dinner: 300 + 88 = 388 kcal | P: 34g | C: 0g | F: 28g | Sodium: 90mg
        // Total: 838 kcal | P: 60.0g | C: 53.0g | F: 42.5g | Fiber: 6.0g | Sodium: 160.0mg
        #expect(md.hasPrefix("---\ndate: 2026-11-27\ntype: food-diary\nsource: nomnom\n"))
        #expect(md.contains("meals_logged: 2\n"))
        #expect(md.contains("calories_kcal: 838\n"))
        #expect(md.contains("protein_g: 60.0\n"))
        #expect(md.contains("carbs_g: 53.0\n"))
        #expect(md.contains("fat_g: 42.5\n"))
        #expect(md.contains("fiber_g: 6.0\n"))
        #expect(md.contains("sodium_mg: 160.0\n"))

        // Headings and content
        #expect(md.contains("# Food Diary — 2026-11-27"))
        #expect(md.contains("**Daily Total:** 838 kcal · P: 60.0g · C: 53.0g · F: 42.5g"))
        #expect(md.contains("## Dinner — Teriyaki Salmon Bowl"))
        #expect(md.contains("## Breakfast — Greek Yogurt, Berries & \"Crunchy\" Granola"))
        #expect(md.contains("- **Honey Granola** (1/2 cup · 1.5x) — 300 kcal"))
        #expect(md.contains("- **Notes:** Great start, added cinnamon"))

        // Collapsible sauces/oils Obsidian callout with included vs excluded markers
        #expect(md.contains("> [!note]- Sauces, Oils & Seasonings"))
        #expect(md.contains("> - [x] Olive oil (~10g) — 88 kcal (P 0.0g · C 0.0g · F 10.0g)"))
        #expect(md.contains("> - [ ] Teriyaki glaze (~15g) — 30 kcal (P 0.5g · C 7.0g · F 0.0g) *(excluded)*"))

        // Excludes other dates and deleted meals
        #expect(!md.contains("Yesterday Lunch"))
        #expect(!md.contains("Deleted Snack"))
    }

    @Test("obsidianDailyMarkdown handles days with no meals cleanly")
    func obsidianEmptyDay() {
        let md = PortableExporter.obsidianDailyMarkdown(date: "2026-11-28", meals: sampleMeals())
        #expect(md.contains("meals_logged: 0"))
        #expect(md.contains("calories_kcal: 0"))
        #expect(md.contains("_No meals logged._"))
    }
}
