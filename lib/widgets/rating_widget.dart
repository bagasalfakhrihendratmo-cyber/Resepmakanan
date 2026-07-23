import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingWidget extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onRatingChanged;
  final double starSize;
  final bool readOnly;

  const RatingWidget({
    super.key,
    this.rating = 0,
    this.onRatingChanged,
    this.starSize = 32,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isFilled = starNumber <= rating;

        return GestureDetector(
          onTap: readOnly ? null : () => onRatingChanged?.call(starNumber),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: starSize,
              color: isFilled ? const Color(0xFFF39C12) : Colors.grey[300],
            ),
          ),
        );
      }),
    );
  }
}

class RatingSection extends StatelessWidget {
  final int currentRating;
  final ValueChanged<int>? onRatingChanged;

  const RatingSection({
    super.key,
    required this.currentRating,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFFF39C12).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rounded,
                    color: Color(0xFFF39C12), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                '⭐ Rating Pribadi',
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
            children: [
              RatingWidget(
                rating: currentRating,
                onRatingChanged: onRatingChanged,
                starSize: 36,
              ),
              const SizedBox(width: 12),
              Text(
                currentRating > 0 ? '$currentRating/5' : 'Belum dinilai',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: currentRating > 0
                      ? const Color(0xFFF39C12)
                      : Colors.grey[500],
                ),
              ),
            ],
          ),
          if (currentRating > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _getRatingLabel(currentRating),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Tidak suka';
      case 2:
        return 'Biasa saja';
      case 3:
        return 'Cukup enak';
      case 4:
        return 'Enak!';
      case 5:
        return 'Sangat enak! ⭐';
      default:
        return '';
    }
  }
}
