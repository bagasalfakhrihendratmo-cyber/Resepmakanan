import 'package:flutter/painting.dart';

class NutritionInfo {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double saturatedFat;

  const NutritionInfo({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.saturatedFat = 0,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    final nutrients = json['nutrients'] as List<dynamic>? ?? [];
    double getValue(String name) {
      final match = nutrients.firstWhere(
        (n) => (n as Map<String, dynamic>)['name']?.toString().toLowerCase() == name.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      return ((match as Map<String, dynamic>)['amount'] as num?)?.toDouble() ?? 0;
    }

    return NutritionInfo(
      calories: getValue('Calories'),
      protein: getValue('Protein'),
      carbs: getValue('Carbohydrates'),
      fat: getValue('Fat'),
      fiber: getValue('Fiber'),
      sugar: getValue('Sugar'),
      saturatedFat: getValue('Saturated Fat'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nutrients': [
        {'name': 'Calories', 'amount': calories, 'unit': 'kcal'},
        {'name': 'Protein', 'amount': protein, 'unit': 'g'},
        {'name': 'Carbohydrates', 'amount': carbs, 'unit': 'g'},
        {'name': 'Fat', 'amount': fat, 'unit': 'g'},
        {'name': 'Fiber', 'amount': fiber, 'unit': 'g'},
        {'name': 'Sugar', 'amount': sugar, 'unit': 'g'},
        {'name': 'Saturated Fat', 'amount': saturatedFat, 'unit': 'g'},
      ],
    };
  }

  NutritionInfo scale(double factor) {
    return NutritionInfo(
      calories: (calories * factor).roundToDouble(),
      protein: (protein * factor).roundToDouble(),
      carbs: (carbs * factor).roundToDouble(),
      fat: (fat * factor).roundToDouble(),
      fiber: (fiber * factor).roundToDouble(),
      sugar: (sugar * factor).roundToDouble(),
      saturatedFat: (saturatedFat * factor).roundToDouble(),
    );
  }
}

class NutritionItem {
  final String label;
  final double value;
  final String unit;
  final double maxValue;
  final Color color;

  const NutritionItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.maxValue,
    required this.color,
  });

  double get percentage => (value / maxValue).clamp(0, 1);
}
