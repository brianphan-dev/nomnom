import Foundation
import Testing
@testable import NomNomShared

@Suite("MyFitnessPalParser & RFC4180CSVParser")
struct MyFitnessPalParserTests {
    @Test("RFC-4180 parser handles quoted commas, escaped quotes, CRLF, LF, BOM, and embedded newlines")
    func rfc4180EdgeCases() throws {
        let csv = "\u{FEFF}Col1,Col2,Col3\r\n"
            + "\"Hello, world\",\"He said \"\"yum\"\"\",\"Line 1\r\nLine 2\"\r\n"
            + "plain,,trailing\n"

        let rows = try RFC4180CSVParser.parse(csv)
        #expect(rows.count == 3)
        #expect(rows[0] == ["Col1", "Col2", "Col3"])
        #expect(rows[1] == ["Hello, world", "He said \"yum\"", "Line 1\r\nLine 2"])
        #expect(rows[2] == ["plain", "", "trailing"])
    }

    @Test("RFC-4180 parser rejects unterminated quoted field")
    func rfc4180UnterminatedQuote() {
        #expect(throws: CSVParseError.unterminatedQuotedField(row: 2)) {
            _ = try RFC4180CSVParser.parse("a,b\n\"unclosed,val")
        }
    }

    @Test("Parses full MyFitnessPal Nutrition-Summary CSV with quoted commas and notes")
    func parsesRealMFPFormat() throws {
        let csv = [
            "Date,Meal,Calories,Fat (g),Saturated Fat,Polyunsaturated Fat,Monounsaturated Fat,Trans Fat,Cholesterol,Sodium (mg),Potassium,Carbohydrates (g),Fiber,Sugar,Protein (g),Vitamin A,Vitamin C,Calcium,Iron,Note",
            "2026-11-20,Breakfast,485.5,14.2,3.5,2.1,5.0,0.0,185.0,420.0,310.0,52.0,7.5,12.0,36.8,10.0,15.0,20.0,12.0,\"Oats, berries, and \"\"extra\"\" whey\"",
            "2026-11-20,Snacks,\"1,020.0\",40.0,10.0,5.0,15.0,0.0,50.0,610.0,400.0,110.0,9.0,35.0,55.0,0.0,0.0,0.0,0.0,\"Post-run refueling\nwith trail mix\"",
            "2026-11-21,Post-Workout,310,4.5,1.0,0,0,0,0,180,250,38,2,18,30,0,0,0,0,",
        ].joined(separator: "\r\n")

        let result = try MyFitnessPalParser.parse(csv: csv)
        #expect(result.warnings.isEmpty)
        #expect(result.rows.count == 3)

        let breakfast = result.rows[0]
        #expect(breakfast.localDate == "2026-11-20")
        #expect(breakfast.rawMealName == "Breakfast")
        #expect(breakfast.mealType == .breakfast)
        #expect(breakfast.nutrition.caloriesKcal == 485.5)
        #expect(breakfast.nutrition.fatG == 14.2)
        #expect(breakfast.nutrition.carbsG == 52.0)
        #expect(breakfast.nutrition.proteinG == 36.8)
        #expect(breakfast.nutrition.fiberG == 7.5)
        #expect(breakfast.nutrition.sugarG == 12.0)
        #expect(breakfast.nutrition.sodiumMg == 420.0)
        #expect(breakfast.note == "Oats, berries, and \"extra\" whey")

        // Deterministic fingerprint check
        let expectedHash = PureSHA256.hex("mfp|2026-11-20|breakfast|485.5|36.8|52.0|14.2")
        #expect(breakfast.fingerprint == expectedHash)

        // Comma-formatted calorie number + Snacks -> .snack + multiline note
        let snacks = result.rows[1]
        #expect(snacks.mealType == .snack)
        #expect(snacks.nutrition.caloriesKcal == 1020.0)
        #expect(snacks.note == "Post-run refueling\nwith trail mix")

        // Custom MFP meal slot maps to .snack while keeping original title
        let customSlot = result.rows[2]
        #expect(customSlot.mealType == .snack)
        #expect(customSlot.rawMealName == "Post-Workout")
        #expect(customSlot.note == nil)
    }

    @Test("Parses minimal CSV missing all optional columns")
    func missingOptionalColumns() throws {
        let csv = """
        Date,Meal,Calories,Fat (g),Carbohydrates (g),Protein (g)
        2026-11-22,Lunch,650,20,70,45
        2026-11-22,Dinner,720.4,24.5,68.2,54.1
        """

        let result = try MyFitnessPalParser.parse(csv: csv)
        #expect(result.warnings.isEmpty)
        #expect(result.rows.count == 2)
        #expect(result.rows[0].nutrition.fiberG == nil)
        #expect(result.rows[0].nutrition.sugarG == nil)
        #expect(result.rows[0].nutrition.sodiumMg == nil)
        #expect(result.rows[0].note == nil)
        #expect(result.rows[1].mealType == .dinner)
    }

    @Test("Throws structured error when required headers are missing")
    func missingRequiredHeaders() {
        let csv = """
        Date,Meal,Calories,Protein (g)
        2026-11-22,Lunch,500,40
        """

        #expect(throws: MyFitnessPalImportError.missingRequiredColumns(["Fat (g)", "Carbohydrates (g)"])) {
            _ = try MyFitnessPalParser.parse(csv: csv)
        }
    }

    @Test("Empty CSV and malformed syntax throw structured import errors")
    func emptyAndSyntaxErrorCSV() {
        #expect(throws: MyFitnessPalImportError.emptyCSV) {
            _ = try MyFitnessPalParser.parse(csv: "   \r\n  ")
        }
        #expect(throws: MyFitnessPalImportError.csvSyntaxError(.unterminatedQuotedField(row: 2))) {
            _ = try MyFitnessPalParser.parse(csv: "Date,Meal\n\"2026-11-22,Lunch")
        }
    }

    @Test("Invalid rows generate warnings without failing valid rows")
    func malformedRowsProduceWarnings() throws {
        let csv = """
        Date,Meal,Calories,Fat (g),Carbohydrates (g),Protein (g)
        2026-02-30,Breakfast,400,10,50,30
        2026-11-22,Lunch,N/A,20,70,45
        2026-11-22,Dinner,700,25,65,50
        """

        let result = try MyFitnessPalParser.parse(csv: csv)
        #expect(result.rows.count == 1)
        #expect(result.rows[0].mealType == .dinner)
        #expect(result.warnings.count == 2)
    }

    @Test("DuplicatePolicy reconciliation handles skip, keepBoth, and replaceDate deterministically")
    func duplicatePolicyReconciliation() throws {
        let csv = """
        Date,Meal,Calories,Fat (g),Carbohydrates (g),Protein (g),Note
        2026-11-20,Breakfast,500,15,55,35,Morning oats
        2026-11-20,Lunch,700,22,72,50,Chicken bowl
        2026-11-20,Lunch,700,22,72,50,Duplicate row inside same CSV
        2026-11-21,Dinner,620,18,60,48,Salmon
        """

        let parsed = try MyFitnessPalParser.parse(csv: csv)
        #expect(parsed.rows.count == 4)

        let now = NomNomJSON.parseISO8601("2026-11-27T12:00:00.000Z")!

        // Existing meals:
        // 1. Matches 2026-11-20 Breakfast (without stored fingerprint — matched by computed nutrition!)
        let existingBreakfast = Meal(
            localDate: "2026-11-20",
            eatenAt: now,
            mealType: .breakfast,
            title: "Breakfast",
            captureMethod: .manualDB,
            items: [
                MealEntryItem(
                    displayName: "Oats",
                    servingLabel: "1 bowl",
                    nutrition: NutritionSnapshot(caloriesKcal: 500, proteinG: 35, carbsG: 55, fatG: 15)
                ),
            ],
            createdAt: now,
            updatedAt: now
        )
        // 2. Unrelated existing meal on 2026-11-20 (different dinner)
        let existingSameDayOtherMeal = Meal(
            localDate: "2026-11-20",
            eatenAt: now,
            mealType: .dinner,
            title: "Tacos",
            captureMethod: .photoAI,
            items: [
                MealEntryItem(
                    displayName: "Tacos",
                    servingLabel: "3 tacos",
                    nutrition: NutritionSnapshot(caloriesKcal: 800, proteinG: 40, carbsG: 80, fatG: 35)
                ),
            ],
            createdAt: now,
            updatedAt: now
        )
        // 3. Existing meal on another unaffected date (2026-11-19)
        let existingOtherDate = Meal(
            localDate: "2026-11-19",
            eatenAt: now,
            mealType: .lunch,
            title: "Salad",
            captureMethod: .photoAI,
            createdAt: now,
            updatedAt: now
        )
        // 4. Soft-deleted matching Dinner on 2026-11-21 (should NOT block re-import!)
        let deletedDinner = Meal(
            localDate: "2026-11-21",
            eatenAt: now,
            mealType: .dinner,
            title: "Salmon",
            captureMethod: .importedMFP,
            dedupeFingerprint: parsed.rows[3].fingerprint,
            createdAt: now,
            updatedAt: now,
            deletedAt: now
        )

        let existing = [existingBreakfast, existingSameDayOtherMeal, existingOtherDate, deletedDinner]

        // Policy: .skip
        let skipResult = MyFitnessPalParser.reconcile(
            importedRows: parsed.rows,
            existingMeals: existing,
            policy: .skip,
            timezoneId: "America/Los_Angeles",
            now: now
        )
        // Row 0 (Breakfast) skipped due to existingBreakfast; Row 2 (duplicate Lunch) skipped within CSV.
        // Row 1 (Lunch) + Row 3 (2026-11-21 Dinner, since existing one was soft-deleted) imported.
        #expect(skipResult.importedCount == 2)
        #expect(skipResult.skippedCount == 2)
        #expect(skipResult.replacedCount == 0)
        #expect(skipResult.mealsToInsert.map(\.mealType) == [.lunch, .dinner])
        #expect(skipResult.mealsToInsert.allSatisfy { $0.captureMethod == .importedMFP })

        // Policy: .keepBoth
        let keepBothResult = MyFitnessPalParser.reconcile(
            importedRows: parsed.rows,
            existingMeals: existing,
            policy: .keepBoth,
            now: now
        )
        #expect(keepBothResult.importedCount == 4)
        #expect(keepBothResult.skippedCount == 0)
        #expect(keepBothResult.replacedCount == 0)

        // Policy: .replaceDate
        let replaceResult = MyFitnessPalParser.reconcile(
            importedRows: parsed.rows,
            existingMeals: existing,
            policy: .replaceDate,
            now: now
        )
        #expect(replaceResult.importedCount == 4)
        #expect(replaceResult.skippedCount == 0)
        // Replaces both active meals on 2026-11-20, leaves 2026-11-19 untouched, ignores already-deleted 2026-11-21 meal.
        #expect(Set(replaceResult.mealIdsToDelete) == Set([existingBreakfast.id, existingSameDayOtherMeal.id]))
    }
}
