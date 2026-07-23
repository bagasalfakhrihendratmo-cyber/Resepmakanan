import 'package:cached_network_image/cached_network_image.dart';
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
    this.index = 0,
    this.onAddToCollection,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool isFavorite;
  final int index;
  final VoidCallback? onAddToCollection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: index % 3 == 2 ? 8 : 4,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: Colors.white,
              height: 130,
              child: Row(
                children: [
                  // Image section
                  SizedBox(
                    width: 130,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: recipe.image,
                            width: 130,
                            height: 130,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
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
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.primary.withValues(alpha: 0.08),
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: colorScheme.primary.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                          // Gradient overlay
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
                        ],
                      ),
                    ),
                  ),
                  // Content section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title
                          Text(
                            recipe.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C3E50),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Info badges
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
                          // Tags row
                          Row(
                            children: [
                              if ((recipe.readyInMinutes ?? 999) <= 20)
                                _buildTag('Cepat', Colors.orange, colorScheme),
                              if ((recipe.readyInMinutes ?? 999) <= 20 &&
                                  (recipe.ingredients.length <= 5))
                                const SizedBox(width: 6),
                              if (recipe.ingredients.length <= 5)
                                _buildTag('Sederhana', Colors.green, colorScheme),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Action buttons column
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
                              : Colors.grey[300],
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
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
                              color: Colors.grey[400],
                            ),
                            splashRadius: 16,
                            padding: EdgeInsets.zero,
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
