import Foundation

// MARK: - RFC-4180 CSV Parser

public enum CSVParseError: Error, Sendable, Equatable {
    case unterminatedQuotedField(row: Int)
    case unexpectedCharacterAfterClosingQuote(row: Int)
}

/// Strict RFC-4180 CSV parser supporting quoted fields, embedded commas,
/// escaped double quotes (`""`), embedded newlines, UTF-8 BOM, and CRLF/LF line endings.
public enum RFC4180CSVParser: Sendable {
    public static func parse(_ input: String) throws -> [[String]] {
        let scalars = Array(input.unicodeScalars)
        guard !scalars.isEmpty else { return [] }

        var index = 0
        // Strip leading UTF-8 BOM if present.
        if scalars[0] == "\u{FEFF}" {
            index = 1
        }
        guard index < scalars.count else { return [] }

        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField: [UnicodeScalar] = []
        var inQuotes = false
        var fieldStarted = false

        while index < scalars.count {
            let scalar = scalars[index]

            if inQuotes {
                if scalar == "\"" {
                    if index + 1 < scalars.count, scalars[index + 1] == "\"" {
                        currentField.append("\"")
                        index += 2
                    } else {
                        inQuotes = false
                        index += 1
                        if index < scalars.count {
                            let next = scalars[index]
                            if next != "," && next != "\r" && next != "\n" {
                                throw CSVParseError.unexpectedCharacterAfterClosingQuote(row: rows.count + 1)
                            }
                        }
                    }
                } else {
                    currentField.append(scalar)
                    index += 1
                }
            } else {
                if scalar == "\"" && !fieldStarted {
                    inQuotes = true
                    fieldStarted = true
                    index += 1
                } else if scalar == "," {
                    currentRow.append(String(String.UnicodeScalarView(currentField)))
                    currentField.removeAll(keepingCapacity: true)
                    fieldStarted = false
                    index += 1
                } else if scalar == "\r" || scalar == "\n" {
                    currentRow.append(String(String.UnicodeScalarView(currentField)))
                    rows.append(currentRow)
                    currentField.removeAll(keepingCapacity: true)
                    currentRow.removeAll(keepingCapacity: true)
                    fieldStarted = false
                    if scalar == "\r", index + 1 < scalars.count, scalars[index + 1] == "\n" {
                        index += 2
                    } else {
                        index += 1
                    }
                } else {
                    fieldStarted = true
                    currentField.append(scalar)
                    index += 1
                }
            }
        }

        if inQuotes {
            throw CSVParseError.unterminatedQuotedField(row: rows.count + 1)
        }

        if fieldStarted || !currentRow.isEmpty {
            currentRow.append(String(String.UnicodeScalarView(currentField)))
            rows.append(currentRow)
        }

        return rows
    }
}

// MARK: - MyFitnessPal Importer

public enum MyFitnessPalImportError: Error, Sendable, Equatable {
    case emptyCSV
    case missingRequiredColumns([String])
    case csvSyntaxError(CSVParseError)
}

public enum DuplicatePolicy: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case skip = "skip"
    case keepBoth = "keep_both"
    case replaceDate = "replace_date"
}

/// A parsed meal-level summary row from a MyFitnessPal `Nutrition-Summary-*.csv` export.
public struct ParsedMyFitnessPalRow: Codable, Sendable, Equatable, Hashable {
    public var rowNumber: Int
    public var localDate: String
    public var rawMealName: String
    public var mealType: MealType
    public var nutrition: NutritionSnapshot
    public var note: String?
    public var fingerprint: String

    public init(
        rowNumber: Int,
        localDate: String,
        rawMealName: String,
        mealType: MealType,
        nutrition: NutritionSnapshot,
        note: String? = nil,
        fingerprint: String
    ) {
        self.rowNumber = rowNumber
        self.localDate = localDate
        self.rawMealName = rawMealName
        self.mealType = mealType
        self.nutrition = nutrition
        self.note = note
        self.fingerprint = fingerprint
    }

    private enum CodingKeys: String, CodingKey {
        case rowNumber = "row_number"
        case localDate = "local_date"
        case rawMealName = "raw_meal_name"
        case mealType = "meal_type"
        case nutrition
        case note
        case fingerprint
    }

    /// Converts this imported MFP summary row into a domain `Meal` with a single rolled-up item.
    public func toMeal(
        id: UUID = UUID(),
        itemId: UUID = UUID(),
        timezoneId: String = "UTC",
        now: Date = Date()
    ) -> Meal {
        let eatenAt = MyFitnessPalParser.defaultEatenAt(
            localDate: localDate,
            mealType: mealType,
            timezoneId: timezoneId
        ) ?? now

        let item = MealEntryItem(
            id: itemId,
            mealId: id,
            displayName: "\(rawMealName) (MyFitnessPal Summary)",
            servingLabel: "1 meal summary",
            quantity: 1.0,
            portionMultiplier: 1.0,
            nutrition: nutrition
        )

        return Meal(
            id: id,
            localDate: localDate,
            eatenAt: eatenAt,
            timezoneId: timezoneId,
            mealType: mealType,
            title: rawMealName,
            notes: note,
            captureMethod: .importedMFP,
            aiStatus: .none,
            dedupeFingerprint: fingerprint,
            items: [item],
            photoIds: [],
            createdAt: now,
            updatedAt: now
        )
    }
}

public struct MyFitnessPalParseResult: Sendable, Equatable {
    public var headers: [String]
    public var rows: [ParsedMyFitnessPalRow]
    public var warnings: [String]

    public init(headers: [String], rows: [ParsedMyFitnessPalRow], warnings: [String]) {
        self.headers = headers
        self.rows = rows
        self.warnings = warnings
    }
}

public struct MyFitnessPalReconcileResult: Sendable, Equatable {
    public var mealsToInsert: [Meal]
    public var mealIdsToDelete: [UUID]
    public var skippedRows: [ParsedMyFitnessPalRow]

    public var importedCount: Int { mealsToInsert.count }
    public var skippedCount: Int { skippedRows.count }
    public var replacedCount: Int { mealIdsToDelete.count }

    public init(
        mealsToInsert: [Meal],
        mealIdsToDelete: [UUID],
        skippedRows: [ParsedMyFitnessPalRow]
    ) {
        self.mealsToInsert = mealsToInsert
        self.mealIdsToDelete = mealIdsToDelete
        self.skippedRows = skippedRows
    }
}

/// Parser and duplicate-reconciliation engine for MyFitnessPal `Nutrition-Summary-*.csv` files.
public enum MyFitnessPalParser: Sendable {
    private struct ColumnMap {
        let date: Int
        let meal: Int
        let calories: Int
        let fat: Int
        let carbs: Int
        let protein: Int
        let fiber: Int?
        let sugar: Int?
        let saturatedFat: Int?
        let sodium: Int?
        let potassium: Int?
        let calcium: Int?
        let iron: Int?
        let vitaminC: Int?
        let vitaminD: Int?
        let note: Int?
    }

    /// Parses a MyFitnessPal `Nutrition-Summary-*.csv` text payload into structured meal rows.
    public static func parse(csv: String) throws -> MyFitnessPalParseResult {
        let rawRows: [[String]]
        do {
            rawRows = try RFC4180CSVParser.parse(csv)
        } catch let error as CSVParseError {
            throw MyFitnessPalImportError.csvSyntaxError(error)
        }

        // Drop completely blank rows before identifying headers.
        guard let headerRowIndex = rawRows.firstIndex(where: { row in
            row.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }) else {
            throw MyFitnessPalImportError.emptyCSV
        }

        let headers = rawRows[headerRowIndex].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let columnMap = try buildColumnMap(from: headers)

        var parsedRows: [ParsedMyFitnessPalRow] = []
        var warnings: [String] = []

        for idx in (headerRowIndex + 1)..<rawRows.count {
            let row = rawRows[idx]
            let rowNumber = idx + 1 // 1-based line/row index including header

            // Ignore blank spacer lines.
            if row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }

            let rawDate = cell(row, at: columnMap.date)
            guard isValidLocalDate(rawDate) else {
                warnings.append("Row \(rowNumber): skipped invalid date '\(rawDate)'.")
                continue
            }

            let rawMeal = cell(row, at: columnMap.meal)
            guard !rawMeal.isEmpty else {
                warnings.append("Row \(rowNumber): skipped empty meal name.")
                continue
            }

            guard
                let calories = parseRequiredDouble(cell(row, at: columnMap.calories)),
                let fat = parseRequiredDouble(cell(row, at: columnMap.fat)),
                let carbs = parseRequiredDouble(cell(row, at: columnMap.carbs)),
                let protein = parseRequiredDouble(cell(row, at: columnMap.protein))
            else {
                warnings.append("Row \(rowNumber): skipped due to non-numeric required macro values.")
                continue
            }

            let nutrition = NutritionSnapshot(
                caloriesKcal: calories,
                proteinG: protein,
                carbsG: carbs,
                fatG: fat,
                fiberG: parseOptionalDouble(row, at: columnMap.fiber),
                sugarG: parseOptionalDouble(row, at: columnMap.sugar),
                saturatedFatG: parseOptionalDouble(row, at: columnMap.saturatedFat),
                sodiumMg: parseOptionalDouble(row, at: columnMap.sodium),
                potassiumMg: parseOptionalDouble(row, at: columnMap.potassium),
                calciumMg: parseOptionalDouble(row, at: columnMap.calcium),
                ironMg: parseOptionalDouble(row, at: columnMap.iron),
                vitaminCMg: parseOptionalDouble(row, at: columnMap.vitaminC),
                vitaminDMcg: parseOptionalDouble(row, at: columnMap.vitaminD)
            )

            let rawNote = columnMap.note.map { cell(row, at: $0) }
            let normalizedNote: String? = rawNote.flatMap { $0.isEmpty ? nil : $0 }
            let mealType = mapMealType(rawMeal)
            let dedupeHash = fingerprint(
                localDate: rawDate,
                mealType: mealType,
                nutrition: nutrition
            )

            parsedRows.append(
                ParsedMyFitnessPalRow(
                    rowNumber: rowNumber,
                    localDate: rawDate,
                    rawMealName: rawMeal,
                    mealType: mealType,
                    nutrition: nutrition,
                    note: normalizedNote,
                    fingerprint: dedupeHash
                )
            )
        }

        return MyFitnessPalParseResult(
            headers: headers,
            rows: parsedRows,
            warnings: warnings
        )
    }

    /// Computes deterministic SHA-256 deduplication fingerprint:
    /// `PureSHA256.hex("mfp|\(date)|\(mealType)|\(kcal)|\(p)|\(c)|\(f)")`
    public static func fingerprint(
        localDate: String,
        mealType: MealType,
        caloriesKcal: Double,
        proteinG: Double,
        carbsG: Double,
        fatG: Double
    ) -> String {
        let kcal = CanonicalNumberFormatter.fixed1(caloriesKcal)
        let p = CanonicalNumberFormatter.fixed1(proteinG)
        let c = CanonicalNumberFormatter.fixed1(carbsG)
        let f = CanonicalNumberFormatter.fixed1(fatG)
        return PureSHA256.hex("mfp|\(localDate)|\(mealType.rawValue)|\(kcal)|\(p)|\(c)|\(f)")
    }

    public static func fingerprint(
        localDate: String,
        mealType: MealType,
        nutrition: NutritionSnapshot
    ) -> String {
        fingerprint(
            localDate: localDate,
            mealType: mealType,
            caloriesKcal: nutrition.caloriesKcal,
            proteinG: nutrition.proteinG,
            carbsG: nutrition.carbsG,
            fatG: nutrition.fatG
        )
    }

    /// Reconciles parsed MFP rows against existing diary meals under the requested `DuplicatePolicy`.
    public static func reconcile(
        importedRows: [ParsedMyFitnessPalRow],
        existingMeals: [Meal],
        policy: DuplicatePolicy,
        timezoneId: String = "UTC",
        now: Date = Date()
    ) -> MyFitnessPalReconcileResult {
        let activeExisting = existingMeals.filter { !$0.isDeleted }

        switch policy {
        case .skip:
            var seenFingerprints = Set<String>()
            for meal in activeExisting {
                if let stored = meal.dedupeFingerprint {
                    seenFingerprints.insert(stored)
                }
                seenFingerprints.insert(
                    fingerprint(
                        localDate: meal.localDate,
                        mealType: meal.mealType,
                        nutrition: meal.totalNutrition
                    )
                )
            }

            var toInsert: [Meal] = []
            var skipped: [ParsedMyFitnessPalRow] = []
            for row in importedRows {
                if seenFingerprints.contains(row.fingerprint) {
                    skipped.append(row)
                } else {
                    seenFingerprints.insert(row.fingerprint)
                    toInsert.append(row.toMeal(timezoneId: timezoneId, now: now))
                }
            }
            return MyFitnessPalReconcileResult(
                mealsToInsert: toInsert,
                mealIdsToDelete: [],
                skippedRows: skipped
            )

        case .keepBoth:
            let toInsert = importedRows.map { $0.toMeal(timezoneId: timezoneId, now: now) }
            return MyFitnessPalReconcileResult(
                mealsToInsert: toInsert,
                mealIdsToDelete: [],
                skippedRows: []
            )

        case .replaceDate:
            let importedDates = Set(importedRows.map(\.localDate))
            let idsToDelete = activeExisting
                .filter { importedDates.contains($0.localDate) }
                .map(\.id)
            let toInsert = importedRows.map { $0.toMeal(timezoneId: timezoneId, now: now) }
            return MyFitnessPalReconcileResult(
                mealsToInsert: toInsert,
                mealIdsToDelete: idsToDelete,
                skippedRows: []
            )
        }
    }

    // MARK: - Helpers

    public static func mapMealType(_ rawMealName: String) -> MealType {
        switch rawMealName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "breakfast":
            return .breakfast
        case "lunch":
            return .lunch
        case "dinner":
            return .dinner
        case "snack", "snacks":
            return .snack
        default:
            return .snack
        }
    }

    internal static func defaultEatenAt(
        localDate: String,
        mealType: MealType,
        timezoneId: String
    ) -> Date? {
        let parts = localDate.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else {
            return nil
        }

        let (hour, minute): (Int, Int) = switch mealType {
        case .breakfast: (8, 0)
        case .lunch: (12, 30)
        case .dinner: (18, 30)
        case .snack: (15, 0)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezoneId) ?? TimeZone(secondsFromGMT: 0)!
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)
    }

    private static func buildColumnMap(from headers: [String]) throws -> ColumnMap {
        var lookup: [String: Int] = [:]
        for (idx, header) in headers.enumerated() {
            let normalized = header
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if lookup[normalized] == nil {
                lookup[normalized] = idx
            }
        }

        func find(_ aliases: [String]) -> Int? {
            for alias in aliases {
                if let index = lookup[alias] {
                    return index
                }
            }
            return nil
        }

        let dateIdx = find(["date"])
        let mealIdx = find(["meal"])
        let caloriesIdx = find(["calories", "calories (kcal)", "energy (kcal)"])
        let fatIdx = find(["fat (g)", "fat"])
        let carbsIdx = find(["carbohydrates (g)", "carbohydrates", "carbs (g)", "carbs"])
        let proteinIdx = find(["protein (g)", "protein"])

        var missing: [String] = []
        if dateIdx == nil { missing.append("Date") }
        if mealIdx == nil { missing.append("Meal") }
        if caloriesIdx == nil { missing.append("Calories") }
        if fatIdx == nil { missing.append("Fat (g)") }
        if carbsIdx == nil { missing.append("Carbohydrates (g)") }
        if proteinIdx == nil { missing.append("Protein (g)") }

        guard missing.isEmpty,
              let date = dateIdx,
              let meal = mealIdx,
              let calories = caloriesIdx,
              let fat = fatIdx,
              let carbs = carbsIdx,
              let protein = proteinIdx
        else {
            throw MyFitnessPalImportError.missingRequiredColumns(missing)
        }

        return ColumnMap(
            date: date,
            meal: meal,
            calories: calories,
            fat: fat,
            carbs: carbs,
            protein: protein,
            fiber: find(["fiber (g)", "fiber"]),
            sugar: find(["sugar (g)", "sugar", "sugars (g)", "sugars"]),
            saturatedFat: find(["saturated fat (g)", "saturated fat"]),
            sodium: find(["sodium (mg)", "sodium"]),
            potassium: find(["potassium (mg)", "potassium"]),
            calcium: find(["calcium (mg)", "calcium"]),
            iron: find(["iron (mg)", "iron"]),
            vitaminC: find(["vitamin c (mg)", "vitamin c"]),
            vitaminD: find(["vitamin d (mcg)", "vitamin d"]),
            note: find(["note", "notes"])
        )
    }

    private static func cell(_ row: [String], at index: Int) -> String {
        guard index >= 0 && index < row.count else { return "" }
        return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseRequiredDouble(_ raw: String) -> Double? {
        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
        guard !cleaned.isEmpty, let value = Double(cleaned), value.isFinite else {
            return nil
        }
        return value
    }

    private static func parseOptionalDouble(_ row: [String], at index: Int?) -> Double? {
        guard let index else { return nil }
        let raw = cell(row, at: index)
        guard !raw.isEmpty else { return nil }
        return parseRequiredDouble(raw)
    }

    private static func isValidLocalDate(_ value: String) -> Bool {
        let bytes = Array(value.utf8)
        guard bytes.count == 10, bytes[4] == 45, bytes[7] == 45 else { return false }
        let parts = value.split(separator: "-")
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]),
              (1...12).contains(month),
              (1...31).contains(day)
        else {
            return false
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let date = calendar.date(from: components) else { return false }
        let roundTrip = calendar.dateComponents([.year, .month, .day], from: date)
        return roundTrip.year == year && roundTrip.month == month && roundTrip.day == day
    }
}
