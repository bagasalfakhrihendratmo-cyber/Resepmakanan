import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/recipe.dart';
import 'pages/collections_page.dart';
import 'pages/history_page.dart';
import 'pages/recipe_detail_page.dart';
import 'providers/recipe_provider.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/recipe_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  runApp(
    ChangeNotifierProvider(
      create: (_) => RecipeProvider(),
      child: const RecipeApp(),
    ),
  );
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resep Masakan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8733A),
          brightness: Brightness.light,
          primary: const Color(0xFFE8733A),
          secondary: const Color(0xFF2ECC71),
          tertiary: const Color(0xFFE74C3C),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F6F0),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFFF8F6F0),
          foregroundColor: const Color(0xFF2C3E50),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE8733A).withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE8733A),
              );
            }
            return GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFFE8733A));
            }
            return IconThemeData(color: Colors.grey[500]);
          }),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  final List<String> _filters = ['all', 'quick', 'simple'];
  final Map<String, String> _filterLabels = {
    'all': 'Semua',
    'quick': 'Cepat',
    'simple': 'Sederhana',
  };
  final Map<String, IconData> _filterIcons = {
    'all': Icons.explore,
    'quick': Icons.timer,
    'simple': Icons.eco,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    // Load async data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecipeProvider>();
      provider.loadSearchHistory();
      provider.loadCollections();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => FadeTransition(
          opacity: _fadeAnimation,
          child: child,
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildSearchTab(context, provider, colorScheme),
            _buildFavoritesTab(context, provider, colorScheme),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index >= 2) {
            // Navigate to full pages
            switch (index) {
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HistoryPage()),
                );
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CollectionsPage()),
                );
                break;
            }
            return;
          }
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Cari',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorit',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Koleksi',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab(
    BuildContext context,
    RecipeProvider provider,
    ColorScheme colorScheme,
  ) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, provider, colorScheme),
          _buildSearchSection(context, provider, colorScheme),
          if (provider.isLoading)
            _buildLoadingState(colorScheme)
          else if (provider.errorMessage != null)
            _buildNoResultsState(provider, colorScheme)
          else if (_searchController.text.isEmpty &&
              provider.searchResults.isEmpty)
            _buildEmptyState(colorScheme, provider)
          else
            Expanded(child: _buildRecipeList(provider, context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RecipeProvider provider, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.primary.withValues(alpha: 0.02),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🍳', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(
                      'Resep Masakan',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Temukan inspirasi masakan lezat untuk hari ini',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                _searchController.clear();
                provider.searchRecipes('');
              },
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 22),
              tooltip: 'Reset',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(
    BuildContext context,
    RecipeProvider provider,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Cari Resep',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const Spacer(),
                  // Advanced filter button
                  GestureDetector(
                    onTap: () async {
                      final result = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const FilterBottomSheet(),
                      );
                      if (result == true && mounted) {
                        final query = _searchController.text.trim();
                        if (query.isNotEmpty) {
                          await provider.searchRecipes(
                            query,
                            filter: provider.activeFilter,
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: provider.hasActiveAdvancedFilters
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: provider.hasActiveAdvancedFilters
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: provider.hasActiveAdvancedFilters
                                ? colorScheme.primary
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Filter',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: provider.hasActiveAdvancedFilters
                                  ? colorScheme.primary
                                  : Colors.grey[600],
                            ),
                          ),
                          if (provider.hasActiveAdvancedFilters) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari resep atau bahan...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.search_rounded,
                          color: colorScheme.primary, size: 22),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F6F0),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              provider.searchRecipes('');
                            },
                            icon: Icon(Icons.close_rounded,
                                color: Colors.grey[500], size: 20),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                  onSubmitted: (value) async {
                    if (value.trim().isNotEmpty) {
                      await provider.searchRecipes(
                        value,
                        filter: provider.activeFilter,
                      );
                    }
                  },
                ),
              ),
              if (_searchController.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await provider.searchRecipes(
                          _searchController.text,
                          filter: provider.activeFilter,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cari Resep',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              // Active advanced filters indicator
              if (provider.hasActiveAdvancedFilters)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt_rounded,
                            size: 14, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Filter aktif: ${[
                              if (provider.cuisineFilter != null)
                                '${provider.cuisineFilter}',
                              if (provider.dietFilter != null)
                                '${provider.dietFilter}',
                              if (provider.intoleranceFilter != null)
                                '${provider.intoleranceFilter}',
                              if (provider.maxReadyTime != null)
                                'max ${provider.maxReadyTime} mnt',
                            ].join(', ')}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            provider.clearAdvancedFilters();
                          },
                          child: Icon(Icons.close_rounded,
                              size: 16, color: colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              // Filter pills - minimal horizontal scroll
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isActive = provider.activeFilter == filter;
                    return GestureDetector(
                      onTap: () async {
                        final query = _searchController.text.trim();
                        if (query.isNotEmpty) {
                          await provider.searchRecipes(
                            query,
                            filter: filter,
                          );
                        } else {
                          provider.updateFilter(filter);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? colorScheme.primary
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _filterIcons[filter],
                              size: 14,
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _filterLabels[filter] ?? filter,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight:
                                    isActive ? FontWeight.w600 : FontWeight.w500,
                                color: isActive
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: colorScheme.primary,
                strokeCap: StrokeCap.round,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Mencari resep...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sebentar ya, kami sedang mencari resep terbaik',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(RecipeProvider provider, ColorScheme colorScheme) {
    final suggestions = [
      ('Nasi Goreng', '🍚'),
      ('Ayam', '🍗'),
      ('Mie', '🍜'),
      ('Sayur', '🥬'),
      ('Ikan', '🐟'),
      ('Telur', '🥚'),
    ];

    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Friendly illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.15),
                      colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '🔍',
                    style: TextStyle(fontSize: 56),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hmm, belum ketemu nih...',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  provider.errorMessage ??
                      'Coba gunakan kata kunci yang berbeda atau cek ejaan kamu ya',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Try searching button
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  provider.searchRecipes('');
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'Cari ulang',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Separator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Coba cari ini',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Suggestion grid
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: suggestions.map((s) {
                  final name = s.$1;
                  final emoji = s.$2;
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = name;
                      provider.searchRecipes(
                        name,
                        filter: provider.activeFilter,
                      );
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, RecipeProvider provider) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔍', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text(
                'Cari Resep Favoritmu',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Masukkan nama masakan atau bahan\\nyang kamu miliki',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSuggestionChip('Nasi Goreng', colorScheme, provider),
                  const SizedBox(width: 8),
                  _buildSuggestionChip('Ayam', colorScheme, provider),
                  const SizedBox(width: 8),
                  _buildSuggestionChip('Mie', colorScheme, provider),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, ColorScheme colorScheme, RecipeProvider provider) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        provider.searchRecipes(label, filter: provider.activeFilter);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeList(RecipeProvider provider, BuildContext context) {
    if (provider.searchResults.isEmpty) {
      return _buildNoResultsState(provider, Theme.of(context).colorScheme);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '🍽️ Hasil Pencarian',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.searchResults.length} resep',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 8, bottom: 16),
              itemCount: provider.searchResults.length,
              itemBuilder: (context, index) {
                final recipe = provider.searchResults[index];
                return RecipeCard(
                  recipe: recipe,
                  isFavorite: provider.isFavorite(recipe.id),
                  onTap: () {
                    provider.selectRecipe(recipe);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                RecipeDetailScreen(recipe: recipe),
                        transitionsBuilder: (context, animation,
                            secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                        transitionDuration:
                            const Duration(milliseconds: 350),
                      ),
                    );
                  },
                  onFavoriteToggle: () async {
                    await provider.toggleFavorite(recipe);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.isFavorite(recipe.id)
                                ? '${recipe.title} ditambahkan ke favorit'
                                : '${recipe.title} dihapus dari favorit',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(milliseconds: 2000),
                          backgroundColor: const Color(0xFF2C3E50),
                        ),
                      );
                    }
                  },
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(
    BuildContext context,
    RecipeProvider provider,
    ColorScheme colorScheme,
  ) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE74C3C).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                const Text('❤️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resep Favorit',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      'Koleksi resep andalanmu',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (provider.favorites.isEmpty)
            Expanded(child: _buildFavoritesEmptyState(colorScheme))
          else
            Expanded(child: _buildFavoritesList(provider, context)),
        ],
      ),
    );
  }

  Widget _buildFavoritesEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💝', style: TextStyle(fontSize: 100)),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Favorit',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Temukan resep lezat dan simpan\\nsebagai favorit untuk diakses kapan saja',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _selectedIndex = 0);
              },
              icon: const Icon(Icons.search_rounded, size: 20),
              label: Text(
                'Cari Resep',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(RecipeProvider provider, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '❤️ Koleksi Favorit',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.favorites.length} resep',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 8, bottom: 16),
              itemCount: provider.favorites.length,
              itemBuilder: (context, index) {
                final recipe = provider.favorites[index];
                return RecipeCard(
                  recipe: recipe,
                  isFavorite: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                RecipeDetailScreen(recipe: recipe),
                        transitionsBuilder: (context, animation,
                            secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                        transitionDuration:
                            const Duration(milliseconds: 350),
                      ),
                    );
                  },
                  onFavoriteToggle: () async {
                    await provider.toggleFavorite(recipe);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${recipe.title} dihapus dari favorit',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(milliseconds: 2000),
                          backgroundColor: const Color(0xFF2C3E50),
                        ),
                      );
                    }
                  },
                  onAddToCollection: provider.collections.isNotEmpty
                      ? () => _showAddToCollectionSheet(
                          context, provider, recipe)
                      : null,
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToCollectionSheet(
      BuildContext context, RecipeProvider provider, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                color: Colors.white,
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
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.folder_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Masukkan ke Koleksi',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pilih koleksi untuk "${recipe.title}"',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...provider.collections.map((collection) {
                      final isInCollection = provider.isRecipeInCollection(
                          collection.id!, recipe.id);
                      return ListTile(
                        leading: Icon(
                          isInCollection
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isInCollection
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[400],
                        ),
                        title: Text(
                          collection.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        subtitle: Text(
                          '${provider.getRecipeCountInCollection(collection.id!)} resep',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        onTap: () async {
                          if (isInCollection) {
                            await provider.removeRecipeFromCollection(
                                collection.id!, recipe.id);
                          } else {
                            await provider.addRecipeToCollection(
                                collection.id!, recipe.id);
                          }
                          setSheetState(() {});
                        },
                      );
                    }),
                    if (provider.collections.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Belum ada koleksi. Buat koleksi dulu ya!',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCreateCollectionDialog(context, provider);
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'Buat Koleksi Baru',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateCollectionDialog(
      BuildContext context, RecipeProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Buat Koleksi Baru',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nama koleksi',
            hintStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.createCollection(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }
}
