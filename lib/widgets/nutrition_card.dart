import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/nutrition_info.dart';

class NutritionCard extends StatelessWidget {
  final NutritionInfo nutrition;
  final String title;

  const NutritionCard({
    super.key,
    required this.nutrition,
    this.title = 'Informasi Gizi',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final items = [
      NutritionItem(
        label: 'Kalori',
        value: nutrition.calories,
        unit: 'kcal',
        maxValue: 500,
        color: const Color(0xFFE8733A),
      ),
      NutritionItem(
        label: 'Protein',
        value: nutrition.protein,
        unit: 'g',
        maxValue: 50,
        color: const Color(0xFF2ECC71),
      ),
      NutritionItem(
        label: 'Karbohidrat',
        value: nutrition.carbs,
        unit: 'g',
        maxValue: 100,
        color: const Color(0xFF3498DB),
      ),
      NutritionItem(
        label: 'Lemak',
        value: nutrition.fat,
        unit: 'g',
        maxValue: 50,
        color: const Color(0xFFE74C3C),
      ),
      if (nutrition.fiber > 0)
        NutritionItem(
          label: 'Serat',
          value: nutrition.fiber,
          unit: 'g',
          maxValue: 30,
          color: const Color(0xFF9B59B6),
        ),
      if (nutrition.sugar > 0)
        NutritionItem(
          label: 'Gula',
          value: nutrition.sugar,
          unit: 'g',
          maxValue: 50,
          color: const Color(0xFFF39C12),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.monitor_heart_outlined,
                    color: colorScheme.tertiary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                '🍎 $title',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => _buildNutritionBar(item)),
        ],
      ),
    );
  }

  Widget _buildNutritionBar(NutritionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF555555),
                ),
              ),
              Text(
                '${item.value.toStringAsFixed(item.value == item.value.roundToDouble() ? 0 : 1)} ${item.unit}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: item.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.percentage,
              backgroundColor: item.color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(item.color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
