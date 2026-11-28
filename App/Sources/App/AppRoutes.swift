import Foundation
import SwiftUI
import UIKit
import NomNomShared
import NomNomCore
import NomNomDesignSystem

// MARK: - Capture & Navigation Routes

public enum CaptureMode: String, CaseIterable, Hashable, Sendable, Identifiable {
    case photo
    case barcode
    case manual

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .photo: "Photo AI"
        case .barcode: "Barcode"
        case .manual: "Manual"
        }
    }
}

public struct ServingSelectionContext: Identifiable, Sendable {
    public let id: UUID
    public let foodItem: FoodItem
    public let mealType: MealType
    public let captureMethod: CaptureMethod

    public init(
        id: UUID = UUID(),
        foodItem: FoodItem,
        mealType: MealType = .defaultForCurrentTime(),
        captureMethod: CaptureMethod = .manualDB
    ) {
        self.id = id
        self.foodItem = foodItem
        self.mealType = mealType
        self.captureMethod = captureMethod
    }
}

// MARK: - Review Draft Model

public struct ReviewItemDraft: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var displayName: String
    public var servingLabel: String
    public var gramWeight: Double?
    public var portionMultiplier: Double
    public var confidence: Double
    public var baseNutrition: NutritionSnapshot

    public init(
        id: UUID = UUID(),
        displayName: String,
        servingLabel: String,
        gramWeight: Double? = nil,
        portionMultiplier: Double = 1.0,
        confidence: Double = 0.85,
        baseNutrition: NutritionSnapshot
    ) {
        self.id = id
        self.displayName = displayName
        self.servingLabel = servingLabel
        self.gramWeight = gramWeight
        self.portionMultiplier = portionMultiplier
        self.confidence = confidence
        self.baseNutrition = baseNutrition
    }

    public var scaledNutrition: NutritionSnapshot {
        baseNutrition.scaled(by: portionMultiplier)
    }

    public var scaledGrams: Double? {
        gramWeight.map { $0 * portionMultiplier }
    }

    public var needsCheck: Bool {
        confidence < 0.76
    }

    public var portionSubtitle: String {
        if let grams = scaledGrams {
            return "\(servingLabel) · \(Int(grams.rounded())) g"
        }
        return servingLabel
    }
}

public struct ReviewSauceDraft: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var estimatedGrams: Double?
    public var nutrition: NutritionSnapshot
    public var isIncluded: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        estimatedGrams: Double? = nil,
        nutrition: NutritionSnapshot,
        isIncluded: Bool = true
    ) {
        self.id = id
        self.name = name
        self.estimatedGrams = estimatedGrams
        self.nutrition = nutrition
        self.isIncluded = isIncluded
    }
}

public struct ReviewDraft: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var mealType: MealType
    public var captureMethod: CaptureMethod
    public var photoJPEGData: Data?
    public var items: [ReviewItemDraft]
    public var sauces: [ReviewSauceDraft]
    public var warnings: [String]
    public var userHint: String?

    public init(
        id: UUID = UUID(),
        title: String,
        mealType: MealType = .defaultForCurrentTime(),
        captureMethod: CaptureMethod = .photoAI,
        photoJPEGData: Data? = nil,
        items: [ReviewItemDraft],
        sauces: [ReviewSauceDraft] = [],
        warnings: [String] = [],
        userHint: String? = nil
    ) {
        self.id = id
        self.title = title
        self.mealType = mealType
        self.captureMethod = captureMethod
        self.photoJPEGData = photoJPEGData
        self.items = items
        self.sauces = sauces
        self.warnings = warnings
        self.userHint = userHint
    }

    public var totalNutrition: NutritionSnapshot {
        let itemTotals = items.map(\.scaledNutrition)
        let sauceTotals = sauces.filter(\.isIncluded).map(\.nutrition)
        return NutritionSnapshot.sum(itemTotals + sauceTotals)
    }

    public var includedSauceCount: Int {
        sauces.filter(\.isIncluded).count
    }

    public var includedSauceKcal: Double {
        sauces.filter(\.isIncluded).reduce(0) { $0 + $1.nutrition.caloriesKcal }
    }

    public static func from(
        response: AnalyzeMealResponse,
        photoJPEGData: Data?,
        captureMethod: CaptureMethod,
        hint: String?
    ) -> ReviewDraft {
        var reviewItems: [ReviewItemDraft] = []
        var reviewSauces: [ReviewSauceDraft] = []

        for detected in response.items {
            reviewItems.append(
                ReviewItemDraft(
                    displayName: detected.displayName,
                    servingLabel: detected.servingLabel,
                    gramWeight: detected.gramWeight,
                    portionMultiplier: 1.0,
                    confidence: detected.confidence,
                    baseNutrition: detected.nutrition
                )
            )
            for ingredient in detected.ingredients where ingredient.isOptionalEstimate || ingredient.category == .sauce || ingredient.category == .oil || ingredient.category == .seasoning {
                reviewSauces.append(
                    ReviewSauceDraft(
                        id: ingredient.id,
                        name: ingredient.name,
                        estimatedGrams: ingredient.estimatedGrams,
                        nutrition: ingredient.nutrition,
                        isIncluded: ingredient.isIncluded
                    )
                )
            }
        }

        return ReviewDraft(
            title: response.suggestedTitle.isEmpty ? "Logged meal" : response.suggestedTitle,
            mealType: response.suggestedMealType ?? .defaultForCurrentTime(),
            captureMethod: captureMethod,
            photoJPEGData: photoJPEGData,
            items: reviewItems,
            sauces: reviewSauces,
            warnings: response.warnings,
            userHint: hint
        )
    }

    public func toMeal(localDate: String, eatenAt: Date = Date(), mealId: UUID = UUID()) -> Meal {
        var entryItems: [MealEntryItem] = items.enumerated().map { index, item in
            let attachedSauces: [IngredientEstimate] = (index == 0)
                ? sauces.map { sauce in
                    IngredientEstimate(
                        id: sauce.id,
                        name: sauce.name,
                        category: .sauce,
                        estimatedGrams: sauce.estimatedGrams,
                        nutrition: sauce.nutrition,
                        isOptionalEstimate: true,
                        isIncluded: sauce.isIncluded
                    )
                }
                : []

            return MealEntryItem(
                id: item.id,
                mealId: mealId,
                displayName: item.displayName,
                servingLabel: item.servingLabel,
                quantity: 1.0,
                gramWeight: item.gramWeight,
                portionMultiplier: item.portionMultiplier,
                confidence: item.confidence,
                nutrition: item.baseNutrition,
                ingredients: attachedSauces
            )
        }

        // If user removed all primary items but kept sauces, preserve sauces on a lightweight entry
        if entryItems.isEmpty, !sauces.filter(\.isIncluded).isEmpty {
            let sauceEstimates = sauces.map { sauce in
                IngredientEstimate(
                    id: sauce.id,
                    name: sauce.name,
                    category: .sauce,
                    estimatedGrams: sauce.estimatedGrams,
                    nutrition: sauce.nutrition,
                    isOptionalEstimate: true,
                    isIncluded: sauce.isIncluded
                )
            }
            entryItems.append(
                MealEntryItem(
                    mealId: mealId,
                    displayName: "Sauces and oils",
                    servingLabel: "1 serving",
                    nutrition: .zero,
                    ingredients: sauceEstimates
                )
            )
        }

        return Meal(
            id: mealId,
            localDate: localDate,
            eatenAt: eatenAt,
            timezoneId: TimeZone.current.identifier,
            mealType: mealType,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Logged meal" : title,
            notes: userHint,
            captureMethod: captureMethod,
            aiStatus: .analyzed,
            items: entryItems
        )
    }
}

// MARK: - Domain <-> Design System Mappers

public extension MealType {
    static func defaultForCurrentTime(_ date: Date = Date()) -> MealType {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<22: return .dinner
        default: return .snack
        }
    }
}

public extension CaptureMethod {
    var nnLoggingMethod: NNLoggingMethod {
        switch self {
        case .photoAI: .photoAI
        case .barcode: .barcode
        case .labelOCR: .labelOCR
        case .manualDB, .manualAI: .manual
        case .importedMFP, .importedHealthKit: .imported
        }
    }
}

@MainActor
public func mapSyncStatus(from store: NomNomAppStore) -> NNSyncStatus {
    if store.isOffline || store.syncStatus == .offline {
        return .offline(queued: store.queuedCount > 0 ? store.queuedCount : nil)
    }
    switch store.syncStatus {
    case .syncing:
        return .syncing
    case .offline:
        return .offline(queued: store.queuedCount > 0 ? store.queuedCount : nil)
    case .synced, .error:
        return store.queuedCount > 0 ? .offline(queued: store.queuedCount) : .synced
    }
}

// MARK: - Local Meal Photo Storage

public enum AppPhotoStorage {
    private static var photosDirectory: URL? {
        guard let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            return nil
        }
        let dir = appSupport
            .appendingPathComponent("NomNom", isDirectory: true)
            .appendingPathComponent("Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public static func savePhoto(_ jpegData: Data, forMealId mealId: UUID) {
        guard let url = photosDirectory?.appendingPathComponent("\(mealId.uuidString).jpg") else { return }
        try? jpegData.write(to: url, options: .atomic)
    }

    public static func loadUIImage(forMealId mealId: UUID) -> UIImage? {
        guard let url = photosDirectory?.appendingPathComponent("\(mealId.uuidString).jpg"),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return UIImage(data: data)
    }

    public static func deletePhoto(forMealId mealId: UUID) {
        guard let url = photosDirectory?.appendingPathComponent("\(mealId.uuidString).jpg") else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Generates a calm photographic-tone placeholder plate image for Simulator testing when hardware camera is unavailable.
    public static func makeSimulatorSamplePlateJPEG() -> Data {
        let size = CGSize(width: 768, height: 768)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            // Warm ceramic table
            UIColor(red: 0.90, green: 0.89, blue: 0.87, alpha: 1).setFill()
            cg.fill(CGRect(origin: .zero, size: size))
            // Ceramic bowl shadow
            UIColor(red: 0.78, green: 0.76, blue: 0.73, alpha: 1).setFill()
            cg.fillEllipse(in: CGRect(x: 96, y: 112, width: 576, height: 576))
            // Stone bowl
            UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1).setFill()
            cg.fillEllipse(in: CGRect(x: 96, y: 96, width: 576, height: 576))
            // Rice bed
            UIColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1).setFill()
            cg.fillEllipse(in: CGRect(x: 160, y: 160, width: 448, height: 448))
            // Grilled salmon fillet (persimmon-salmon tone)
            UIColor(red: 0.87, green: 0.44, blue: 0.25, alpha: 1).setFill()
            let salmon = UIBezierPath(roundedRect: CGRect(x: 210, y: 230, width: 220, height: 150), cornerRadius: 42)
            salmon.fill()
            // Avocado slices (matcha green)
            UIColor(red: 0.43, green: 0.61, blue: 0.34, alpha: 1).setFill()
            for i in 0..<4 {
                let slice = UIBezierPath(roundedRect: CGRect(x: 425 + CGFloat(i) * 18, y: 280 + CGFloat(i) * 32, width: 115, height: 42), cornerRadius: 21)
                slice.fill()
            }
            // Edamame + greens
            UIColor(red: 0.28, green: 0.49, blue: 0.26, alpha: 1).setFill()
            let greens = UIBezierPath(roundedRect: CGRect(x: 220, y: 420, width: 200, height: 120), cornerRadius: 48)
            greens.fill()
        }
        return image.jpegData(compressionQuality: 0.85) ?? Data()
    }
}
