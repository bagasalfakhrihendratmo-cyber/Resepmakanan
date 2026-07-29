import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/recipe_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _cuisine = 'any';
  String _diet = 'any';
  String _intolerance = 'any';
  int? _maxReadyTime;

  // Indonesia placed FIRST as the prominent default recommendation
  final List<Map<String, String>> _cuisines = [
    {'value': 'indonesian', 'label': 'Indonesia'},
    {'value': 'any', 'label': 'Semua'},
    {'value': 'chinese', 'label': 'China'},
    {'value': 'japanese', 'label': 'Jepang'},
    {'value': 'italian', 'label': 'Italia'},
    {'value': 'mexican', 'label': 'Meksiko'},
    {'value': 'indian', 'label': 'India'},
    {'value': 'thai', 'label': 'Thailand'},
    {'value': 'korean', 'label': 'Korea'},
    {'value': 'american', 'label': 'Amerika'},
    {'value': 'middle eastern', 'label': 'Timur Tengah'},
    {'value': 'french', 'label': 'Prancis'},
  ];

  final List<Map<String, String>> _diets = [
    {'value': 'any', 'label': 'Semua'},
    {'value': 'vegetarian', 'label': 'Vegetarian'},
    {'value': 'vegan', 'label': 'Vegan'},
    {'value': 'gluten free', 'label': 'Bebas Gluten'},
    {'value': 'dairy free', 'label': 'Bebas Susu'},
    {'value': 'ketogenic', 'label': 'Ketogenik'},
    {'value': 'paleo', 'label': 'Paleo'},
    {'value': 'low carb', 'label': 'Rendah Karbohidrat'},
  ];

  final List<Map<String, String>> _intolerances = [
    {'value': 'any', 'label': 'Semua'},
    {'value': 'dairy', 'label': 'Susu'},
    {'value': 'egg', 'label': 'Telur'},
    {'value': 'gluten', 'label': 'Gluten'},
    {'value': 'peanut', 'label': 'Kacang'},
    {'value': 'seafood', 'label': 'Makanan Laut'},
    {'value': 'soy', 'label': 'Kedelai'},
    {'value': 'wheat', 'label': 'Gandum'},
  ];

  final List<int> _timeOptions = [0, 15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    final provider = context.read<RecipeProvider>();
    _cuisine = provider.cuisineFilter ?? 'any';
    _diet = provider.dietFilter ?? 'any';
    _intolerance = provider.intoleranceFilter ?? 'any';
    _maxReadyTime = provider.maxReadyTime;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.filter_list_rounded,
                      color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Filter Pencarian',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _cuisine = 'any';
                      _diet = 'any';
                      _intolerance = 'any';
                      _maxReadyTime = null;
                    });
                    // Default 'any' = semua jenis masakan (API punya lebih banyak variasi)
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.poppins(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── CUISINE ──────────────────────────────────────────────────
            _buildSectionLabel('Jenis Masakan'),
            const SizedBox(height: 8),
            _buildCuisineSection(colorScheme),
            const SizedBox(height: 16),

            // Diet
            _buildSectionLabel('Diet'),
            const SizedBox(height: 8),
            _buildWrapChips(_diets, _diet, (val) {
              setState(() => _diet = val);
            }, colorScheme),
            const SizedBox(height: 16),

            // Intolerance
            _buildSectionLabel('Intoleransi Bahan'),
            const SizedBox(height: 8),
            _buildWrapChips(_intolerances, _intolerance, (val) {
              setState(() => _intolerance = val);
            }, colorScheme),
            const SizedBox(height: 16),

            // Max Ready Time
            _buildSectionLabel('Maksimal Waktu Masak'),
            const SizedBox(height: 8),
            _buildTimeChips(colorScheme),
            const SizedBox(height: 24),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<RecipeProvider>().setAdvancedFilters(
                        cuisine: _cuisine == 'any' ? null : _cuisine,
                        diet: _diet == 'any' ? null : _diet,
                        intolerance: _intolerance == 'any' ? null : _intolerance,
                        maxReadyTime: _maxReadyTime,
                      );
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Terapkan Filter',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PROMINENT CUISINE SECTION ──────────────────────────────────────────
  // Indonesia ditampilkan pertama dengan badge rekomendasi + divider
  Widget _buildCuisineSection(ColorScheme colorScheme) {
    // Pisahkan Indonesia dari list utama
    final otherCuisines = _cuisines
        .where((c) => c['value'] != 'indonesian')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔥 Indonesia chip — prominent with badge
        _buildIndonesiaChip(colorScheme),
        const SizedBox(height: 10),
        // Subtle divider
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.3),
                colorScheme.primary.withValues(alpha: 0.05),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Other cuisines (including 'Semua')
        _buildWrapChips(otherCuisines, _cuisine, (val) {
          setState(() => _cuisine = val);
        }, colorScheme, chipFontSize: 11.5),
      ],
    );
  }

  // ─── INDONESIA SPECIAL CHIP ──────────────────────────────────────────────
  Widget _buildIndonesiaChip(ColorScheme colorScheme) {
    final isSelected = _cuisine == 'indonesian';
    return GestureDetector(
      onTap: () => setState(() => _cuisine = 'indonesian'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flag / icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '🇮🇩',
                  style: TextStyle(fontSize: isSelected ? 18 : 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Indonesia',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            // Badge rekomendasi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '⭐ Rekomendasi',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildWrapChips(
    List<Map<String, String>> items,
    String selected,
    Function(String) onSelected,
    ColorScheme colorScheme, {
    double chipFontSize = 12,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items.map((item) {
        final value = item['value']!;
        final label = item['label']!;
        final isSelected = selected == value;
        return ChoiceChip(
          label: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: chipFontSize,
              color: isSelected ? Colors.white : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onSelected(value),
          selectedColor: colorScheme.primary,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildTimeChips(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _timeOptions.map((time) {
        final label = time == 0 ? 'Berapapun' : '$time menit';
        final isSelected =
            _maxReadyTime == time || (time == 0 && _maxReadyTime == null);
        return ChoiceChip(
          label: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isSelected ? Colors.white : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _maxReadyTime = time == 0 ? null : time;
            });
          },
          selectedColor: colorScheme.primary,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}
