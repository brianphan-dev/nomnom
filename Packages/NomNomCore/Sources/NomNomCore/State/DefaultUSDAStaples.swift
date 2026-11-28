import Foundation
import NomNomShared

/// Curated offline USDA staple foods seeded on first launch so manual search
/// and the serving calculator work instantaneously without network access.
public enum DefaultUSDAStaples: Sendable {
    public static func catalog(now: Date = Date()) -> [FoodItem] {
        [
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000101")!,
                name: "Chicken Breast, Grilled",
                source: .usda,
                externalId: "fdc:171477",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 165,
                    proteinG: 31.0,
                    carbsG: 0.0,
                    fatG: 3.6,
                    fiberG: 0.0,
                    sugarG: 0.0,
                    saturatedFatG: 1.0,
                    sodiumMg: 74
                ),
                servingOptions: [
                    ServingOption(label: "1 breast (172g)", gramWeight: 172, isDefault: true),
                    ServingOption(label: "4 oz cooked (113g)", gramWeight: 113),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                isFavorite: true,
                lastUsedAt: now,
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000102")!,
                name: "Atlantic Salmon, Baked",
                source: .usda,
                externalId: "fdc:175168",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 206,
                    proteinG: 22.1,
                    carbsG: 0.0,
                    fatG: 12.4,
                    saturatedFatG: 2.5,
                    sodiumMg: 61,
                    potassiumMg: 384,
                    vitaminDMcg: 13.1
                ),
                servingOptions: [
                    ServingOption(label: "1 fillet (154g)", gramWeight: 154, isDefault: true),
                    ServingOption(label: "4 oz (113g)", gramWeight: 113),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                isFavorite: true,
                lastUsedAt: now,
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000103")!,
                name: "White Rice, Cooked",
                source: .usda,
                externalId: "fdc:169757",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 130,
                    proteinG: 2.7,
                    carbsG: 28.2,
                    fatG: 0.3,
                    fiberG: 0.4,
                    sugarG: 0.1,
                    sodiumMg: 1
                ),
                servingOptions: [
                    ServingOption(label: "1 cup cooked (158g)", gramWeight: 158, isDefault: true),
                    ServingOption(label: "1/2 cup cooked (79g)", gramWeight: 79),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                isFavorite: true,
                lastUsedAt: now,
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000104")!,
                name: "Brown Rice, Cooked",
                source: .usda,
                externalId: "fdc:169704",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 123,
                    proteinG: 2.7,
                    carbsG: 25.6,
                    fatG: 1.0,
                    fiberG: 1.6,
                    sugarG: 0.2,
                    sodiumMg: 4
                ),
                servingOptions: [
                    ServingOption(label: "1 cup cooked (195g)", gramWeight: 195, isDefault: true),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000105")!,
                name: "Whole Egg, Large",
                source: .usda,
                externalId: "fdc:748967",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 143,
                    proteinG: 12.6,
                    carbsG: 0.7,
                    fatG: 9.5,
                    saturatedFatG: 3.1,
                    sodiumMg: 142,
                    vitaminDMcg: 2.0
                ),
                servingOptions: [
                    ServingOption(label: "1 large egg (50g)", gramWeight: 50, isDefault: true),
                    ServingOption(label: "2 large eggs (100g)", gramWeight: 100),
                ],
                isFavorite: true,
                lastUsedAt: now,
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000106")!,
                name: "Greek Yogurt, Plain Nonfat",
                source: .usda,
                externalId: "fdc:170903",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 59,
                    proteinG: 10.2,
                    carbsG: 3.6,
                    fatG: 0.4,
                    fiberG: 0.0,
                    sugarG: 3.2,
                    sodiumMg: 36,
                    calciumMg: 110
                ),
                servingOptions: [
                    ServingOption(label: "1 cup (170g)", gramWeight: 170, isDefault: true),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                isFavorite: true,
                lastUsedAt: now,
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000107")!,
                name: "Rolled Oats, Dry",
                source: .usda,
                externalId: "fdc:173904",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 379,
                    proteinG: 13.2,
                    carbsG: 67.7,
                    fatG: 6.5,
                    fiberG: 10.1,
                    sugarG: 1.0,
                    sodiumMg: 6,
                    ironMg: 4.3
                ),
                servingOptions: [
                    ServingOption(label: "1/2 cup dry (40g)", gramWeight: 40, isDefault: true),
                    ServingOption(label: "1 cup dry (81g)", gramWeight: 81),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000108")!,
                name: "Avocado, Raw",
                source: .usda,
                externalId: "fdc:171705",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 160,
                    proteinG: 2.0,
                    carbsG: 8.5,
                    fatG: 14.7,
                    fiberG: 6.7,
                    sugarG: 0.7,
                    saturatedFatG: 2.1,
                    sodiumMg: 7,
                    potassiumMg: 485
                ),
                servingOptions: [
                    ServingOption(label: "1/2 medium avocado (75g)", gramWeight: 75, isDefault: true),
                    ServingOption(label: "1 medium avocado (150g)", gramWeight: 150),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000109")!,
                name: "Banana, Raw",
                source: .usda,
                externalId: "fdc:173944",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 89,
                    proteinG: 1.1,
                    carbsG: 22.8,
                    fatG: 0.3,
                    fiberG: 2.6,
                    sugarG: 12.2,
                    sodiumMg: 1,
                    potassiumMg: 358
                ),
                servingOptions: [
                    ServingOption(label: "1 medium banana (118g)", gramWeight: 118, isDefault: true),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000110")!,
                name: "Broccoli, Steamed",
                source: .usda,
                externalId: "fdc:169967",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 35,
                    proteinG: 2.4,
                    carbsG: 7.2,
                    fatG: 0.4,
                    fiberG: 3.3,
                    sugarG: 1.4,
                    sodiumMg: 41,
                    vitaminCMg: 64.9
                ),
                servingOptions: [
                    ServingOption(label: "1 cup chopped (156g)", gramWeight: 156, isDefault: true),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000111")!,
                name: "Sweet Potato, Baked",
                source: .usda,
                externalId: "fdc:168483",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 90,
                    proteinG: 2.0,
                    carbsG: 20.7,
                    fatG: 0.2,
                    fiberG: 3.3,
                    sugarG: 6.5,
                    sodiumMg: 36,
                    potassiumMg: 475
                ),
                servingOptions: [
                    ServingOption(label: "1 medium potato (114g)", gramWeight: 114, isDefault: true),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000112")!,
                name: "Extra Virgin Olive Oil",
                source: .usda,
                externalId: "fdc:171413",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 884,
                    proteinG: 0.0,
                    carbsG: 0.0,
                    fatG: 100.0,
                    saturatedFatG: 13.8,
                    sodiumMg: 2
                ),
                servingOptions: [
                    ServingOption(label: "1 tbsp (13.5g)", gramWeight: 13.5, isDefault: true),
                    ServingOption(label: "1 tsp (4.5g)", gramWeight: 4.5),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000113")!,
                name: "Almonds, Raw",
                source: .usda,
                externalId: "fdc:170567",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 579,
                    proteinG: 21.2,
                    carbsG: 21.6,
                    fatG: 49.9,
                    fiberG: 12.5,
                    sugarG: 4.4,
                    saturatedFatG: 3.8,
                    sodiumMg: 1,
                    calciumMg: 269
                ),
                servingOptions: [
                    ServingOption(label: "1 oz / ~23 almonds (28g)", gramWeight: 28, isDefault: true),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000114")!,
                name: "Peanut Butter, Smooth Natural",
                source: .usda,
                externalId: "fdc:172470",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 598,
                    proteinG: 22.2,
                    carbsG: 22.3,
                    fatG: 51.4,
                    fiberG: 5.0,
                    sugarG: 10.5,
                    saturatedFatG: 10.0,
                    sodiumMg: 426
                ),
                servingOptions: [
                    ServingOption(label: "2 tbsp (32g)", gramWeight: 32, isDefault: true),
                    ServingOption(label: "1 tbsp (16g)", gramWeight: 16),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000115")!,
                name: "Sourdough Bread",
                source: .usda,
                externalId: "fdc:172686",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 272,
                    proteinG: 10.8,
                    carbsG: 51.9,
                    fatG: 2.4,
                    fiberG: 2.2,
                    sugarG: 4.6,
                    sodiumMg: 602
                ),
                servingOptions: [
                    ServingOption(label: "1 medium slice (50g)", gramWeight: 50, isDefault: true),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000116")!,
                name: "Tofu, Firm",
                source: .usda,
                externalId: "fdc:172475",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 144,
                    proteinG: 17.3,
                    carbsG: 2.8,
                    fatG: 8.7,
                    fiberG: 2.3,
                    sugarG: 0.6,
                    sodiumMg: 14,
                    calciumMg: 683
                ),
                servingOptions: [
                    ServingOption(label: "1/2 cup cubed (126g)", gramWeight: 126, isDefault: true),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000117")!,
                name: "Black Beans, Cooked",
                source: .usda,
                externalId: "fdc:173735",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 132,
                    proteinG: 8.9,
                    carbsG: 23.7,
                    fatG: 0.5,
                    fiberG: 8.7,
                    sugarG: 0.3,
                    sodiumMg: 1
                ),
                servingOptions: [
                    ServingOption(label: "1/2 cup cooked (86g)", gramWeight: 86, isDefault: true),
                    ServingOption(label: "1 cup cooked (172g)", gramWeight: 172),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
            FoodItem(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000118")!,
                name: "Whey Protein Isolate, Unflavored",
                source: .usda,
                externalId: "fdc:173177",
                nutritionPer100g: NutritionSnapshot(
                    caloriesKcal: 370,
                    proteinG: 86.0,
                    carbsG: 3.3,
                    fatG: 1.5,
                    sugarG: 1.5,
                    sodiumMg: 210,
                    calciumMg: 420
                ),
                servingOptions: [
                    ServingOption(label: "1 scoop (30g)", gramWeight: 30, isDefault: true),
                    ServingOption(label: "100g", gramWeight: 100),
                ],
                createdAt: now,
                updatedAt: now
            ),
        ]
    }
}
