import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/rating_widget.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final bool recordHistory;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.recordHistory = true,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late int _servings;
  bool _nutritionsLoading = false;
  bool _nutritionLoaded = false;
  int _userRating = 0;
  bool _ratingLoaded = false;

  @override
  void initState() {
    super.initState();
    _servings = widget.recipe.servings ?? 2;
    _recordHistory();
    _loadNutrition();
    _loadRating();
  }

  Future<void> _recordHistory() async {
    if (widget.recordHistory) {
      final provider = context.read<RecipeProvider>();
      await provider.addToSearchHistory(widget.recipe);
    }
  }

  Future<void> _loadNutrition() async {
    final provider = context.read<RecipeProvider>();
    if (provider.nutritionInfo == null && !_nutritionLoaded) {
      setState(() => _nutritionsLoading = true);
      await provider.loadNutritionInfo(widget.recipe.id);
      setState(() {
        _nutritionsLoading = false;
        _nutritionLoaded = true;
      });
    }
  }

  Future<void> _loadRating() async {
    final provider = context.read<RecipeProvider>();
    final rating = await provider.getUserRating(widget.recipe.id);
    if (mounted) {
      setState(() {
        _userRating = rating ?? 0;
        _ratingLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final isFavorite = provider.isFavorite(widget.recipe.id);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () async {
                await provider.toggleFavorite(widget.recipe);
              },
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                color: isFavorite ? Colors.red : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            _buildHeroImage(context, colorScheme),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Info Badges
                  _buildTitleSection(context, colorScheme),
                  const SizedBox(height: 20),

                  // Portion Calculator
                  _buildPortionCalculator(colorScheme),
                  const SizedBox(height: 20),

                  // Nutrition Info
                  if (_nutritionsLoading)
                    _buildNutritionLoading(colorScheme)
                  else if (provider.nutritionInfo != null) ...[
                    NutritionCard(
                      nutrition: provider.nutritionInfo!.scale(
                        _servings / (widget.recipe.servings ?? 1),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Rating Section
                  if (_ratingLoaded) ...[
                    RatingSection(
                      currentRating: _userRating,
                      onRatingChanged: (rating) async {
                        await provider.saveUserRating(
                            widget.recipe.id, rating);
                        setState(() => _userRating = rating);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Ingredients Section
                  _buildSectionHeader('📋 Bahan-Bahan', context),
                  const SizedBox(height: 12),
                  _buildIngredientsList(context, colorScheme),
                  const SizedBox(height: 24),

                  // Instructions Section
                  _buildSectionHeader('👨‍🍳 Langkah Memasak', context),
                  const SizedBox(height: 12),
                  _buildInstructionsList(context, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortionCalculator(ColorScheme colorScheme) {
    final baseServings = widget.recipe.servings ?? 1;
    final factor = _servings / baseServings;

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
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calculate_outlined,
                    color: colorScheme.secondary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                '🍽️ Kalkulator Porsi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minus button
              GestureDetector(
                onTap: () {
                  if (_servings > 1) {
                    setState(() => _servings--);
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _servings > 1
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    color: _servings > 1
                        ? colorScheme.primary
                        : Colors.grey[300],
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  Text(
                    _servings.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Porsi',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Plus button
              GestureDetector(
                onTap: () {
                  if (_servings < 50) {
                    setState(() => _servings++);
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Bahan disesuaikan untuk $_servings porsi',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (factor != 1.0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'x${factor.toStringAsFixed(1)} dari resep asli',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNutritionLoading(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Memuat informasi gizi...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ─── REUSED FROM ORIGINAL RecipeDetailScreen ─────────────────────────────

  Widget _buildHeroImage(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: Image.network(
              widget.recipe.image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 320,
              errorBuilder: (context, error, stackTrace) => Container(
                color: colorScheme.primary.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(Icons.image_not_supported_rounded,
                      size: 64, color: colorScheme.primary.withValues(alpha: 0.3)),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: colorScheme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: Row(
              children: [
                _buildImageBadge(
                  Icons.timer_outlined,
                  '${widget.recipe.readyInMinutes ?? '--'} menit',
                  Colors.white,
                ),
                const SizedBox(width: 10),
                _buildImageBadge(
                  Icons.people_outline_rounded,
                  '${widget.recipe.servings ?? '--'} porsi',
                  Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.recipe.title,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C3E50),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_rounded,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.recipe.readyInMinutes ?? '--'} menit',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_rounded,
                      size: 16, color: colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.recipe.servings ?? '--'} porsi',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList(
      BuildContext context, ColorScheme colorScheme) {
    final factor = _servings / (widget.recipe.servings ?? 1);

    return Column(
      children: widget.recipe.ingredients.asMap().entries.map((entry) {
        final ingredient = entry.value;

        // Parse and scale the ingredient
        String displayText = ingredient;
        if (factor != 1.0) {
          final parsed = Ingredient.fromDisplayString(ingredient);
          if (parsed.amount > 0) {
            final scaledAmount = parsed.amount * factor;
            final amountStr = scaledAmount == scaledAmount.roundToDouble()
                ? scaledAmount.toInt().toString()
                : scaledAmount.toStringAsFixed(1);
            final suffix = parsed.unit.isEmpty ? '' : ' ${parsed.unit}';
            displayText = '${parsed.name} ($amountStr$suffix)';
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  displayText,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF2C3E50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (factor != 1.0)
                Text(
                  'x${factor.toStringAsFixed(1)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: colorScheme.primary.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstructionsList(
      BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: widget.recipe.instructions.asMap().entries.map((entry) {
        final index = entry.key;
        final instruction = entry.value;
        final stepMatch = RegExp(r'^(\d+)\.\s*(.*)').firstMatch(instruction);
        final stepNumber = stepMatch?.group(1) ?? '${index + 1}';
        final stepText = stepMatch?.group(2) ?? instruction;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    stepText,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF555555),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
