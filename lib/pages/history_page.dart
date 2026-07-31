import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user_rating.dart';
import '../providers/recipe_provider.dart';
import '../utils/recipe_image_mapper.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🕐', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('Riwayat'),
          ],
        ),
        actions: [
          Consumer<RecipeProvider>(
            builder: (context, provider, _) {
              if (provider.searchHistory.isEmpty) return const SizedBox();
              return IconButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus semua riwayat?'),
                      content: const Text(
                          'Semua riwayat resep yang dilihat akan dihapus.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Hapus Semua'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await provider.clearSearchHistory();
                  }
                },
                icon: Icon(Icons.delete_sweep_rounded,
                    color: colorScheme.onSurfaceVariant),
                tooltip: 'Hapus semua riwayat',
              );
            },
          ),
        ],
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          if (provider.historyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.searchHistory.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📖', style: TextStyle(fontSize: 100)),
                    const SizedBox(height: 24),
                    Text(
                      'Belum Ada Riwayat',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Resep yang kamu lihat akan\nmuncul di sini',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Group by date
          final grouped = <String, List<_HistoryWithIndex>>{};
          for (int i = 0; i < provider.searchHistory.length; i++) {
            final item = provider.searchHistory[i];
            final dateKey = _formatDateKey(item.viewedAt);
            grouped.putIfAbsent(dateKey, () => []);
            grouped[dateKey]!.add(_HistoryWithIndex(item, i));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              return _buildDateSection(
                  context, entry.key, entry.value, provider, colorScheme);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDateSection(
    BuildContext context,
    String dateKey,
    List<_HistoryWithIndex> items,
    RecipeProvider provider,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  dateKey,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) => _buildHistoryItem(
                context,
                item,
                provider,
                colorScheme,
              )),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    _HistoryWithIndex item,
    RecipeProvider provider,
    ColorScheme colorScheme,
  ) {
    final history = item.item;
    final isDark = colorScheme.brightness == Brightness.dark;
    // Selalu selesaikan gambar lewat mapper: cache lama (URL acak) otomatis
    // dikoreksi agar gambar riwayat SINKRON dengan kartu & halaman detail.
    final displayImage = RecipeImageMapper.resolveImage(
      title: history.title,
      fallback: history.imageUrl,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 48,
            height: 48,
            child: displayImage.isNotEmpty
                ? Image.network(
                    displayImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      child: Icon(Icons.restaurant_rounded,
                          size: 20, color: colorScheme.outline),
                    ),
                  )
                : Container(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    child: Icon(Icons.restaurant_rounded,
                        size: 20, color: Colors.grey[400]),
                  ),
          ),
        ),
        title: Text(
          history.title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatTimeAgo(history.viewedAt),
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          onPressed: () =>
              provider.deleteSearchHistoryItem(history.id!),
          icon: Icon(Icons.close_rounded,
              size: 18, color: colorScheme.outline),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 16,
        ),
        onTap: () {
          // Navigate to recipe detail
          provider.loadRecipeDetail(history.recipeId);
          // Find recipe from favorites or search results
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'Hari Ini';
    if (dateDay == yesterday) return 'Kemarin';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}

class _HistoryWithIndex {
  final SearchHistory item;
  final int index;

  _HistoryWithIndex(this.item, this.index);
}
