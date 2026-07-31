import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.isFavorite,
    this.onAddToCollection,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool isFavorite;
  final VoidCallback? onAddToCollection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: colorScheme.surface,
                height: 130,
                child: Row(
                  children: [
                    Hero(
                      tag: 'recipe_${recipe.id}',
                      child: SizedBox(
                        width: 130,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              Image.network(
                                recipe.displayImage,
                                width: 130,
                                height: 130,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: colorScheme.primary.withValues(alpha: 0.08),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: colorScheme.primary.withValues(alpha: 0.08),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('🍽️', style: TextStyle(fontSize: 32)),
                                        Text(
                                          'Gambar\ntidak tersedia',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            color: colorScheme.primary.withValues(alpha: 0.5),
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.5),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.timer_outlined, size: 10, color: Colors.white),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${recipe.readyInMinutes ?? "--"}m',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              recipe.title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildInfoBadge(
                                  Icons.timer_outlined,
                                  '${recipe.readyInMinutes ?? '--'} mnt',
                                  colorScheme.primary,
                                  colorScheme,
                                ),
                                const SizedBox(width: 8),
                                _buildInfoBadge(
                                  Icons.people_outline_rounded,
                                  '${recipe.servings ?? '--'} porsi',
                                  colorScheme.secondary,
                                  colorScheme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if ((recipe.readyInMinutes ?? 999) <= 20)
                                  _buildTag('⚡ Cepat', Colors.orange, colorScheme),
                                if ((recipe.readyInMinutes ?? 999) <= 20 &&
                                    (recipe.ingredients.length <= 5))
                                  const SizedBox(width: 6),
                                if (recipe.ingredients.length <= 5)
                                  _buildTag('✅ Sederhana', Colors.green, colorScheme),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: onFavoriteToggle,
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,
                              size: 24,
                            ),
                            color: isFavorite
                                ? const Color(0xFFE74C3C)
                                : (isDark ? Colors.grey[600] : Colors.grey[300]),
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            tooltip: isFavorite ? 'Hapus dari favorit' : 'Tambah ke favorit',
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                          if (onAddToCollection != null)
                            IconButton(
                              onPressed: onAddToCollection,
                              icon: Icon(
                                Icons.folder_outlined,
                                size: 18,
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                              ),
                              splashRadius: 16,
                              padding: EdgeInsets.zero,
                              tooltip: 'Tambah ke koleksi',
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(
    IconData icon,
    String text,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

}
