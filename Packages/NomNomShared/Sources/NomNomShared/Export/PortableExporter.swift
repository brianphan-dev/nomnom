import Foundation

// MARK: - Portable Archive Models

/// Metadata header written to `manifest.json` in a portable nomnom export archive.
public struct ExportManifest: Codable, Sendable, Equatable {
    public static let currentSchemaVersion = "1.0"

    public var schemaVersion: String
    public var exportedAt: Date
    public var appVersion: String
    public var mealCount: Int
    public var foodItemCount: Int
    public var photoCount: Int

    public init(
        schemaVersion: String = ExportManifest.currentSchemaVersion,
        exportedAt: Date = Date(),
        appVersion: String,
        mealCount: Int = 0,
        foodItemCount: Int = 0,
        photoCount: Int = 0
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.mealCount = mealCount
        self.foodItemCount = foodItemCount
        self.photoCount = photoCount
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case exportedAt = "exported_at"
        case appVersion = "app_version"
        case mealCount = "meal_count"
        case foodItemCount = "food_item_count"
        case photoCount = "photo_count"
    }
}

/// Complete portable JSON representation of a user's food diary (`diary.json`).
public struct DiaryExport: Codable, Sendable, Equatable {
    public var manifest: ExportManifest
    public var meals: [Meal]
    public var foodItems: [FoodItem]
    public var photoAssets: [PhotoAsset]

    public init(
        manifest: ExportManifest,
        meals: [Meal],
        foodItems: [FoodItem] = [],
        photoAssets: [PhotoAsset] = []
    ) {
        self.manifest = manifest
        self.meals = meals
        self.foodItems = foodItems
        self.photoAssets = photoAssets
    }

    private enum CodingKeys: String, CodingKey {
        case manifest
        case meals
        case foodItems = "food_items"
        case photoAssets = "photo_assets"
    }
}

// MARK: - Portable Exporter

/// Generates lossless JSON archives, RFC-4180 CSV tables, and Obsidian daily Markdown notes.
public enum PortableExporter: Sendable {
    /// Builds a `DiaryExport` with manifest counts populated automatically.
    public static func makeDiaryExport(
        meals: [Meal],
        foodItems: [FoodItem] = [],
        photoAssets: [PhotoAsset] = [],
        appVersion: String,
        exportedAt: Date = Date(),
        includeDeleted: Bool = false
    ) -> DiaryExport {
        let filteredMeals = includeDeleted ? meals : meals.filter { !$0.isDeleted }
        let filteredFoods = includeDeleted ? foodItems : foodItems.filter { $0.deletedAt == nil }
        let filteredPhotos = includeDeleted ? photoAssets : photoAssets.filter { $0.deletedAt == nil }

        let manifest = ExportManifest(
            schemaVersion: ExportManifest.currentSchemaVersion,
            exportedAt: exportedAt,
            appVersion: appVersion,
            mealCount: filteredMeals.count,
            foodItemCount: filteredFoods.count,
            photoCount: filteredPhotos.count
        )

        return DiaryExport(
            manifest: manifest,
            meals: filteredMeals,
            foodItems: filteredFoods,
            photoAssets: filteredPhotos
        )
    }

    /// Encodes a `DiaryExport` using canonical `NomNomJSON` encoding.
    public static func encodeJSON(
        _ export: DiaryExport,
        prettyPrinted: Bool = true
    ) throws -> Data {
        let encoder = NomNomJSON.makeEncoder(prettyPrinted: prettyPrinted, sortedKeys: true)
        return try encoder.encode(export)
    }

    /// Decodes a `DiaryExport` JSON payload.
    public static func decodeJSON(_ data: Data) throws -> DiaryExport {
        try NomNomJSON.makeDecoder().decode(DiaryExport.self, from: data)
    }

    // MARK: - RFC-4180 CSV Serializers

    /// Escapes a single CSV field strictly per RFC-4180.
    public static func csvEscape(_ field: String) -> String {
        let needsQuoting = field.unicodeScalars.contains { scalar in
            scalar == "," || scalar == "\"" || scalar == "\r" || scalar == "\n"
        }
        guard needsQuoting else { return field }
        let doubledQuotes = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(doubledQuotes)\""
    }

    /// Serializes meal-level summary rows (`meals.csv`).
    public static func mealsCSV(
        meals: [Meal],
        includeDeleted: Bool = false
    ) -> String {
        let header = [
            "meal_id",
            "local_date",
            "eaten_at",
            "timezone_id",
            "meal_type",
            "title",
            "capture_method",
            "ai_status",
            "calories_kcal",
            "protein_g",
            "carbs_g",
            "fat_g",
            "fiber_g",
            "sugar_g",
            "saturated_fat_g",
            "sodium_mg",
            "item_count",
            "notes",
        ].joined(separator: ",")

        let sortedMeals = sortMeals(includeDeleted ? meals : meals.filter { !$0.isDeleted })
        var lines: [String] = [header]
        lines.reserveCapacity(sortedMeals.count + 1)

        for meal in sortedMeals {
            let totals = meal.totalNutrition
            let fields: [String] = [
                meal.id.uuidString,
                meal.localDate,
                NomNomJSON.formatISO8601(meal.eatenAt),
                meal.timezoneId,
                meal.mealType.rawValue,
                meal.title,
                meal.captureMethod.rawValue,
                meal.aiStatus.rawValue,
                CanonicalNumberFormatter.fixed1(totals.caloriesKcal),
                CanonicalNumberFormatter.fixed1(totals.proteinG),
                CanonicalNumberFormatter.fixed1(totals.carbsG),
                CanonicalNumberFormatter.fixed1(totals.fatG),
                totals.fiberG.map(CanonicalNumberFormatter.fixed1) ?? "",
                totals.sugarG.map(CanonicalNumberFormatter.fixed1) ?? "",
                totals.saturatedFatG.map(CanonicalNumberFormatter.fixed1) ?? "",
                totals.sodiumMg.map(CanonicalNumberFormatter.fixed1) ?? "",
                String(meal.items.count),
                meal.notes ?? "",
            ]
            lines.append(fields.map(csvEscape).joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    /// Serializes per-item rows using each item's effective nutrition (`meal_items.csv`).
    public static func mealItemsCSV(
        meals: [Meal],
        includeDeleted: Bool = false
    ) -> String {
        let header = [
            "meal_id",
            "local_date",
            "meal_type",
            "item_id",
            "display_name",
            "brand",
            "serving_label",
            "quantity",
            "gram_weight",
            "portion_multiplier",
            "confidence",
            "calories_kcal",
            "protein_g",
            "carbs_g",
            "fat_g",
            "fiber_g",
            "sugar_g",
            "sodium_mg",
            "included_optional_ingredients",
        ].joined(separator: ",")

        let sortedMeals = sortMeals(includeDeleted ? meals : meals.filter { !$0.isDeleted })
        var lines: [String] = [header]

        for meal in sortedMeals {
            for item in meal.items {
                let effective = item.effectiveNutrition
                let includedOptionalNames = item.ingredients
                    .filter { $0.isOptionalEstimate && $0.isIncluded }
                    .map(\.name)
                    .joined(separator: "; ")

                let fields: [String] = [
                    meal.id.uuidString,
                    meal.localDate,
                    meal.mealType.rawValue,
                    item.id.uuidString,
                    item.displayName,
                    item.brand ?? "",
                    item.servingLabel,
                    CanonicalNumberFormatter.compact(item.quantity),
                    item.gramWeight.map(CanonicalNumberFormatter.fixed1) ?? "",
                    CanonicalNumberFormatter.compact(item.portionMultiplier),
                    item.confidence.map(CanonicalNumberFormatter.fixed2) ?? "",
                    CanonicalNumberFormatter.fixed1(effective.caloriesKcal),
                    CanonicalNumberFormatter.fixed1(effective.proteinG),
                    CanonicalNumberFormatter.fixed1(effective.carbsG),
                    CanonicalNumberFormatter.fixed1(effective.fatG),
                    effective.fiberG.map(CanonicalNumberFormatter.fixed1) ?? "",
                    effective.sugarG.map(CanonicalNumberFormatter.fixed1) ?? "",
                    effective.sodiumMg.map(CanonicalNumberFormatter.fixed1) ?? "",
                    includedOptionalNames,
                ]
                lines.append(fields.map(csvEscape).joined(separator: ","))
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Obsidian Daily Markdown

    /// Formats a single day's diary entries into an Obsidian Markdown note with
    /// YAML frontmatter, daily totals, per-meal headings, macro bullets, and a
    /// collapsible sauces/oils callout whenever applicable.
    public static func obsidianDailyMarkdown(date: String, meals: [Meal]) -> String {
        let dayMeals = sortMeals(
            meals.filter { !$0.isDeleted && $0.localDate == date }
        )
        let dailyTotal = NutritionSnapshot.sum(dayMeals.map(\.totalNutrition))

        var lines: [String] = []

        // YAML frontmatter
        lines.append("---")
        lines.append("date: \(date)")
        lines.append("type: food-diary")
        lines.append("source: nomnom")
        lines.append("meals_logged: \(dayMeals.count)")
        lines.append("calories_kcal: \(CanonicalNumberFormatter.integerRounded(dailyTotal.caloriesKcal))")
        lines.append("protein_g: \(CanonicalNumberFormatter.fixed1(dailyTotal.proteinG))")
        lines.append("carbs_g: \(CanonicalNumberFormatter.fixed1(dailyTotal.carbsG))")
        lines.append("fat_g: \(CanonicalNumberFormatter.fixed1(dailyTotal.fatG))")
        if let fiber = dailyTotal.fiberG {
            lines.append("fiber_g: \(CanonicalNumberFormatter.fixed1(fiber))")
        }
        if let sugar = dailyTotal.sugarG {
            lines.append("sugar_g: \(CanonicalNumberFormatter.fixed1(sugar))")
        }
        if let sodium = dailyTotal.sodiumMg {
            lines.append("sodium_mg: \(CanonicalNumberFormatter.fixed1(sodium))")
        }
        lines.append("---")
        lines.append("")

        // Document title & daily macro banner
        lines.append("# Food Diary — \(date)")
        lines.append("")
        lines.append(
            "**Daily Total:** \(CanonicalNumberFormatter.integerRounded(dailyTotal.caloriesKcal)) kcal · "
                + "P: \(CanonicalNumberFormatter.fixed1(dailyTotal.proteinG))g · "
                + "C: \(CanonicalNumberFormatter.fixed1(dailyTotal.carbsG))g · "
                + "F: \(CanonicalNumberFormatter.fixed1(dailyTotal.fatG))g"
        )

        if dayMeals.isEmpty {
            lines.append("")
            lines.append("_No meals logged._")
            return lines.joined(separator: "\n")
        }

        for meal in dayMeals {
            let mealTotal = meal.totalNutrition
            lines.append("")

            let mealHeading: String
            if meal.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                == meal.mealType.displayName.lowercased()
            {
                mealHeading = "## \(meal.mealType.displayName)"
            } else {
                mealHeading = "## \(meal.mealType.displayName) — \(meal.title)"
            }
            lines.append(mealHeading)
            lines.append("")

            lines.append("- **Calories:** \(CanonicalNumberFormatter.integerRounded(mealTotal.caloriesKcal)) kcal")
            lines.append(
                "- **Macros:** P \(CanonicalNumberFormatter.fixed1(mealTotal.proteinG))g · "
                    + "C \(CanonicalNumberFormatter.fixed1(mealTotal.carbsG))g · "
                    + "F \(CanonicalNumberFormatter.fixed1(mealTotal.fatG))g"
            )
            if let fiber = mealTotal.fiberG {
                lines.append("- **Fiber:** \(CanonicalNumberFormatter.fixed1(fiber))g")
            }
            if let sodium = mealTotal.sodiumMg {
                lines.append("- **Sodium:** \(CanonicalNumberFormatter.fixed1(sodium))mg")
            }
            lines.append("- **Capture:** `\(meal.captureMethod.rawValue)`")
            if let notes = meal.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let singleLineNote = notes
                    .replacingOccurrences(of: "\r\n", with: " ")
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\r", with: " ")
                lines.append("- **Notes:** \(singleLineNote)")
            }

            if !meal.items.isEmpty {
                lines.append("")
                lines.append("### Items")
                for item in meal.items {
                    let eff = item.effectiveNutrition
                    let portionSuffix = abs(item.portionMultiplier - 1.0) < 1e-6
                        ? ""
                        : " · \(CanonicalNumberFormatter.compact(item.portionMultiplier))x"
                    lines.append(
                        "- **\(item.displayName)** (\(item.servingLabel)\(portionSuffix)) — "
                            + "\(CanonicalNumberFormatter.integerRounded(eff.caloriesKcal)) kcal "
                            + "(P \(CanonicalNumberFormatter.fixed1(eff.proteinG))g · "
                            + "C \(CanonicalNumberFormatter.fixed1(eff.carbsG))g · "
                            + "F \(CanonicalNumberFormatter.fixed1(eff.fatG))g)"
                    )
                }
            }

            let sauceOilIngredients = meal.items.flatMap { item in
                item.ingredients.filter { ingredient in
                    ingredient.isOptionalEstimate
                        || ingredient.category == .sauce
                        || ingredient.category == .oil
                        || ingredient.category == .seasoning
                }
            }

            if !sauceOilIngredients.isEmpty {
                lines.append("")
                lines.append("> [!note]- Sauces, Oils & Seasonings")
                for ingredient in sauceOilIngredients {
                    let checkbox = ingredient.isIncluded ? "[x]" : "[ ]"
                    let gramsSuffix = ingredient.estimatedGrams.map {
                        " (~\(CanonicalNumberFormatter.compact($0))g)"
                    } ?? ""
                    let excludedSuffix = ingredient.isIncluded ? "" : " *(excluded)*"
                    let nut = ingredient.nutrition
                    lines.append(
                        "> - \(checkbox) \(ingredient.name)\(gramsSuffix) — "
                            + "\(CanonicalNumberFormatter.integerRounded(nut.caloriesKcal)) kcal "
                            + "(P \(CanonicalNumberFormatter.fixed1(nut.proteinG))g · "
                            + "C \(CanonicalNumberFormatter.fixed1(nut.carbsG))g · "
                            + "F \(CanonicalNumberFormatter.fixed1(nut.fatG))g)\(excludedSuffix)"
                    )
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func sortMeals(_ meals: [Meal]) -> [Meal] {
        meals.sorted { lhs, rhs in
            if lhs.localDate != rhs.localDate {
                return lhs.localDate < rhs.localDate
            }
            if lhs.eatenAt != rhs.eatenAt {
                return lhs.eatenAt < rhs.eatenAt
            }
            if lhs.mealType.sortOrder != rhs.mealType.sortOrder {
                return lhs.mealType.sortOrder < rhs.mealType.sortOrder
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}
