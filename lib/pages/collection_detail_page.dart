import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user_rating.dart';
import '../providers/recipe_provider.dart';
import 'recipe_detail_page.dart';

class CollectionDetailPage extends StatefulWidget {
  final Collection collection;

  const CollectionDetailPage({super.key, required this.collection});

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  List? _recipeIds;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<RecipeProvider>();
    final ids = await provider.getCollectionRecipeIds(widget.collection.id!);
    setState(() {
      _recipeIds = ids;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collection.name),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<RecipeProvider>(
              builder: (context, provider, _) {
                if (_recipeIds == null || _recipeIds!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📂', style: TextStyle(fontSize: 80)),
                          const SizedBox(height: 24),
                          Text(
                            'Koleksi Kosong',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tambahkan resep favorit\nke koleksi ini',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[500],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Get recipes from favorites and search results
                final allRecipes = [
                  ...provider.favorites,
                  ...provider.searchResults,
                ];
                final recipes = allRecipes
                    .where((r) => _recipeIds!.contains(r.id))
                    .toList()
                  ..sort((a, b) => a.title.compareTo(b.title));

                if (recipes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🔍', style: TextStyle(fontSize: 80)),
                          const SizedBox(height: 24),
                          Text(
                            'Resep tidak ditemukan',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Resep di koleksi ini mungkin\nsudah dihapus dari favorit',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[500],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Header info
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.folder_rounded,
                                color: colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.collection.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2C3E50),
                                ),
                              ),
                              Text(
                                '${recipes.length} resep',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Remove collection button
                          IconButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Koleksi?'),
                                  content: const Text(
                                      'Resep di dalam koleksi tidak akan terhapus.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && mounted) {
                                await provider.deleteCollection(
                                    widget.collection.id!);
                                if (mounted) Navigator.pop(context);
                              }
                            },
                            icon: Icon(Icons.delete_outline_rounded,
                                color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    // Recipe list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 8, bottom: 16),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          // Build a simple card inline for collection display
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: CachedNetworkImage(
                                      imageUrl: recipe.image,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Container(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.08),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.08),
                                        child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 24,
                                            color: Colors.grey[400]),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  recipe.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2C3E50),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Row(
                                  children: [
                                    if (recipe.readyInMinutes != null) ...[
                                      Icon(Icons.timer_outlined,
                                          size: 12, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${recipe.readyInMinutes} mnt',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Icon(Icons.people_outline_rounded,
                                        size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${recipe.servings ?? '--'} porsi',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  onPressed: () async {
                                    await provider.removeRecipeFromCollection(
                                        widget.collection.id!, recipe.id);
                                    _loadData();
                                  },
                                  icon: Icon(Icons.remove_circle_outline_rounded,
                                      size: 20, color: Colors.red[300]),
                                  padding: EdgeInsets.zero,
                                ),
                                onTap: () {
                                  // Navigate to detail
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecipeDetailScreen(
                                          recipe: recipe),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
