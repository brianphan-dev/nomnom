// Sample content for the nomnom UI kits. All values are illustrative.
window.NN_DATA = {
  today: 'Friday, 27 November',
  targets: { kcal: 2100, protein: 120, carbs: 240, fat: 70 },
  micros: [
    { label: 'Fiber', value: '14 g' }, { label: 'Sugar', value: '31 g' }, { label: 'Sodium', value: '1,280 mg' },
    { label: 'Sat. fat', value: '11 g' }, { label: 'Potassium', value: '1,950 mg' }, { label: 'Iron', value: '9 mg' },
  ],
  meals: [
    { id: 'm3', title: 'Salmon rice bowl', mealType: 'Lunch', time: '12:40', kcal: 642, protein: 38, carbs: 58, fat: 27, method: 'photo_ai', items: [
      { name: 'Salmon fillet', serving: '1 fillet (~150g)', kcal: 280 }, { name: 'Sushi rice', serving: '1 cup (~160g)', kcal: 210 },
      { name: 'Avocado', serving: '¼ (~35g)', kcal: 56 }, { name: 'Edamame', serving: '¼ cup', kcal: 47 }, { name: 'Sesame oil', serving: '1 tsp', kcal: 40 }, { name: 'Soy sauce', serving: '1 tbsp', kcal: 9 } ] },
    { id: 'm2', title: 'Flat white', mealType: 'Snack', time: '10:10', kcal: 120, protein: 6, carbs: 9, fat: 6, method: 'barcode', items: [
      { name: 'Flat white, whole milk', serving: '8 fl oz', kcal: 120 } ] },
    { id: 'm1', title: 'Overnight oats with berries', mealType: 'Breakfast', time: '7:45', kcal: 363, protein: 14, carbs: 55, fat: 10, method: 'manual', items: [
      { name: 'Rolled oats', serving: '½ cup (40g)', kcal: 150 }, { name: 'Milk, 2%', serving: '¾ cup', kcal: 92 }, { name: 'Chia seeds', serving: '1 tbsp', kcal: 58 },
      { name: 'Mixed berries', serving: '½ cup', kcal: 42 }, { name: 'Honey', serving: '1 tsp', kcal: 21 } ] },
  ],
  detectedTitle: 'Chicken thigh plate',
  detected: [
    { id: 'd1', name: 'Chicken thigh, grilled', serving: '2 thighs (~180g)', kcal: 330, p: 38, c: 0, f: 19, confidence: 0.92 },
    { id: 'd2', name: 'Jasmine rice', serving: '1 cup (~160g)', kcal: 205, p: 4, c: 45, f: 0, confidence: 0.88 },
    { id: 'd3', name: 'Broccolini', serving: '1 cup (~90g)', kcal: 40, p: 3, c: 6, f: 1, confidence: 0.71 },
  ],
  extras: [
    { id: 'e1', name: 'Olive oil', serving: '2 tsp', kcal: 80, p: 0, c: 0, f: 9, on: true },
    { id: 'e2', name: 'Soy glaze', serving: '1 tbsp', kcal: 25, p: 1, c: 5, f: 0, on: true },
    { id: 'e3', name: 'Sesame seeds', serving: '1 tsp', kcal: 17, p: 1, c: 1, f: 1, on: true },
  ],
  recents: [
    { name: 'Greek yogurt, plain', brand: '2% fat', source: 'USDA', per100: { kcal: 73, p: 9.9, c: 3.9, f: 2 }, servings: [{ label: '1 cup', g: 170 }, { label: '100g', g: 100 }, { label: '1 tub', g: 500 }] },
    { name: 'Scrambled eggs', brand: 'Cooked in butter', source: 'USDA', per100: { kcal: 148, p: 10, c: 1.6, f: 11 }, servings: [{ label: '2 eggs', g: 122 }, { label: '1 egg', g: 61 }, { label: '100g', g: 100 }] },
    { name: 'Sourdough toast', brand: 'Bakery', source: 'USDA', per100: { kcal: 272, p: 9, c: 52, f: 2 }, servings: [{ label: '1 slice', g: 50 }, { label: '100g', g: 100 }] },
    { name: 'Banana', brand: 'Raw', source: 'USDA', per100: { kcal: 89, p: 1.1, c: 22.8, f: 0.3 }, servings: [{ label: '1 medium', g: 118 }, { label: '100g', g: 100 }] },
    { name: 'Almonds', brand: 'Dry roasted', source: 'USDA', per100: { kcal: 579, p: 21, c: 22, f: 50 }, servings: [{ label: '1 handful', g: 28 }, { label: '100g', g: 100 }] },
  ],
  product: { name: 'Dark chocolate almond bar', brand: 'Good Grain Co.', source: 'Open Food Facts', per100: { kcal: 500, p: 15, c: 40, f: 35 }, servings: [{ label: '1 bar', g: 40 }, { label: '100g', g: 100 }] },
  week: { range: '21 – 27 November', days: ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'], kcal: [1840, 2050, 1920, 2210, 1760, 2080, 1125], avg: { protein: 104, carbs: 212, fat: 66 } },
  importRows: [
    ['24 Nov', 'Breakfast', 412, 22, 48, 14], ['24 Nov', 'Lunch', 688, 41, 62, 28], ['24 Nov', 'Dinner', 734, 46, 70, 27], ['24 Nov', 'Snacks', 190, 6, 24, 8],
  ],
};
