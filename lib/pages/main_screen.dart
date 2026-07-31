import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:makanan/models/recipe.dart';
import 'package:makanan/pages/collections_page.dart';
import 'package:makanan/pages/history_page.dart';
import 'package:makanan/pages/recipe_detail_page.dart';
import 'package:makanan/providers/recipe_provider.dart';
import 'package:makanan/providers/theme_provider.dart';
import 'package:makanan/widgets/filter_bottom_sheet.dart';
import 'package:makanan/widgets/recipe_card.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  Timer? _debounceTimer;
  Timer? _onboardingTimer;
  bool _showOnboardingHint = true;

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
  final Map<String, String> _filterTooltips = {
    'all': 'Tampilkan semua resep',
    'quick': 'Resep dengan waktu masak ≤ 20 menit',
    'simple': 'Resep dengan ≤ 5 bahan',
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

    // Hide onboarding hint after 5 seconds
    _onboardingTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showOnboardingHint = false);
      }
    });

    // Load search history after build (collections are already loaded
    // during the splash screen's initialization phase).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecipeProvider>();
      provider.loadSearchHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _debounceTimer?.cancel();
    _onboardingTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounceTimer?.cancel();
    final trimmed = value.trim();
    final provider = context.read<RecipeProvider>();
    if (trimmed.isEmpty) {
      provider.searchRecipes('');
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      await provider.searchRecipes(
        trimmed,
        filter: provider.activeFilter,
      );
    });
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
            switch (index) {
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CollectionsPage()),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              _buildHeader(context, provider, colorScheme, Theme.of(context).brightness),
              Flexible(
                flex: 0,
                child: _buildSearchSection(context, provider, colorScheme),
              ),
              if (provider.isLoading)
                _buildShimmerLoading()
              else if (provider.errorMessage != null)
                _buildErrorState(provider, colorScheme)
              else if (_searchController.text.isEmpty &&
                  provider.searchResults.isEmpty)
                _buildEmptyState(colorScheme, provider)
              else if (provider.searchResults.isEmpty &&
                  _searchController.text.trim().isNotEmpty)
                _buildNoResultsState(provider, colorScheme)
              else if (provider.searchResults.isNotEmpty)
                Expanded(child: _buildRecipeList(provider, context)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RecipeProvider provider, ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
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
                      'Resep Nusantara',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Temukan inspirasi masakan lezat',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🔍 cari & masak',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'by M.Bagas & Asqilah Yasmin',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'XII RPL 2',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_showOnboardingHint)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Coba cari resep!',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_showOnboardingHint)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dark mode toggle
                GestureDetector(
                  onTap: () => context.read<ThemeProvider>().toggleTheme(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 42,
                  height: 42,
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
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    tooltip: 'Reset pencarian',
                  ),
                ),
              ],
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
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: colorScheme.brightness == Brightness.dark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Cari Resep',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Ketik nama resep atau bahan, lalu pilih filter untuk hasil yang lebih spesifik',
                    child: Icon(Icons.info_outline_rounded, size: 16, color: colorScheme.outline),
                  ),
                  const Spacer(),
                  // Advanced filter button
                  GestureDetector(
                    onTap: () async {
                      _debounceTimer?.cancel();
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
                              : colorScheme.outlineVariant,
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
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Filter',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: provider.hasActiveAdvancedFilters
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
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
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _debounceTimer?.cancel();
                              _searchController.clear();
                              provider.searchRecipes('');
                            },
                            icon: Icon(Icons.close_rounded,
                                color: colorScheme.onSurfaceVariant, size: 20),
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: (value) async {
                    _debounceTimer?.cancel();
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
                      _debounceTimer?.cancel();
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
                        '🔄 Cari Ulang',
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
              // Filter pills with tooltips
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
                    return Tooltip(
                      message: _filterTooltips[filter] ?? '',
                      child: GestureDetector(
                        onTap: () {
                          _debounceTimer?.cancel();
                          final query = _searchController.text.trim();
                          if (query.isNotEmpty) {
                            provider.searchRecipes(
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
                                    : colorScheme.onSurfaceVariant,
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
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
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
    ),
  );
  }

  // ─── SHIMMER LOADING ──────────────────────────────────────────────────────
  Widget _buildShimmerLoading() {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: colorScheme.brightness == Brightness.dark ? 0.3 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.restaurant_rounded, size: 40, color: colorScheme.outlineVariant),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 180,
                              height: 14,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 100,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 50,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── ERROR STATE ──────────────────────────────────────────────────────────
  Widget _buildErrorState(RecipeProvider provider, ColorScheme colorScheme) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_off_rounded, size: 48, color: colorScheme.error),
              ),
              const SizedBox(height: 24),
              Text(
                'Gagal Memuat Data',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage ?? 'Terjadi kesalahan saat mencari resep',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _debounceTimer?.cancel();
                  final query = _searchController.text.trim();
                  if (query.isNotEmpty) {
                    provider.searchRecipes(query, filter: provider.activeFilter);
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'Coba Lagi',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── NO RESULTS STATE ─────────────────────────────────────────────────────
  Widget _buildNoResultsState(RecipeProvider provider, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
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
                  child: Text('🔍', style: TextStyle(fontSize: 56)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hmm, belum ketemu nih...',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Coba gunakan kata kunci yang berbeda atau cek ejaan kamu ya',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  provider.searchRecipes('');
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'Cari ulang',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: colorScheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Coba cari ini',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: colorScheme.outlineVariant)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(4),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: suggestions.map((s) {
                    final name = s.$1;
                    final emoji = s.$2;
                    return GestureDetector(
                      onTap: () {
                        _debounceTimer?.cancel();
                        _searchController.text = name;
                        provider.searchRecipes(name, filter: provider.activeFilter);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: isDark ? 0.2 : 0.03),
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
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(ColorScheme colorScheme, RecipeProvider provider) {
    final quickTips = [
      ('🍚', 'Nasi Goreng', 'Ketik "nasi goreng" untuk resep klasik'),
      ('🍗', 'Ayam', 'Cari resep olahan ayam favorit'),
      ('🥗', 'Sayur', 'Temukan resep sayur sehat'),
    ];

    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Text('🔍', style: TextStyle(fontSize: 80)),
              ),
              const SizedBox(height: 24),
              Text(
                'Cari Resep Favoritmu',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Masukkan nama masakan atau bahan\\nyang kamu miliki',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Coba cari',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...quickTips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          _debounceTimer?.cancel();
                          _searchController.text = tip.$2;
                          provider.searchRecipes(tip.$2, filter: provider.activeFilter);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Text(tip.$1, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tip.$2,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      tip.$3,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.outline),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    _buildFeatureHint(Icons.timer_outlined, 'Filter Cepat', 'Temukan resep yang bisa dibuat dalam 20 menit', colorScheme),
                    Divider(height: 20, color: colorScheme.outlineVariant),
                    _buildFeatureHint(Icons.eco_rounded, 'Filter Sederhana', 'Resep dengan bahan minimal (≤5 bahan)', colorScheme),
                    Divider(height: 20, color: colorScheme.outlineVariant),
                    _buildFeatureHint(Icons.folder_rounded, 'Koleksi', 'Simpan resep ke dalam folder koleksi', colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHint(IconData icon, String title, String desc, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeList(RecipeProvider provider, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (provider.searchResults.isEmpty) {
      return _buildNoResultsState(provider, colorScheme);
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
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.searchResults.length} resep',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                    final messenger = ScaffoldMessenger.of(context);
                    final title = recipe.title;
                    final newFavState = !provider.isFavorite(recipe.id);
                    await provider.toggleFavorite(recipe);
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            newFavState
                                ? '$title ❤️ ditambahkan ke favorit'
                                : '$title dihapus dari favorit',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(milliseconds: 2000),
                          backgroundColor: colorScheme.onSurface,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── FAVORITES TAB ────────────────────────────────────────────────────────
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
                  colorScheme.error.withValues(alpha: 0.08),
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
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Koleksi resep andalanmu',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
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
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Text('💝', style: TextStyle(fontSize: 100)),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Favorit',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Temukan resep lezat dan simpan\\nsebagai favorit untuk diakses kapan saja',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Klik ❤️ di resep untuk menyimpan',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
    final colorScheme = Theme.of(context).colorScheme;
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
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.favorites.length} resep',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                    final messenger = ScaffoldMessenger.of(context);
                    final title = recipe.title;
                    await provider.toggleFavorite(recipe);
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '$title dihapus dari favorit',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(milliseconds: 2000),
                          backgroundColor: colorScheme.onSurface,
                        ),
                      );
                    }
                  },
                  onAddToCollection: provider.collections.isNotEmpty
                      ? () => _showAddToCollectionSheet(context, provider, recipe)
                      : null,
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
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.folder_rounded,
                              color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Masukkan ke Koleksi',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pilih koleksi untuk "${recipe.title}"',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...provider.collections.map((collection) {
                      final isInCollection = provider.isRecipeInCollection(collection.id!, recipe.id);
                      return ListTile(
                        leading: Icon(
                          isInCollection
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isInCollection
                              ? Theme.of(context).colorScheme.primary
                              : colorScheme.outline,
                        ),
                        title: Text(
                          collection.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${provider.getRecipeCountInCollection(collection.id!)} resep',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () async {
                          if (isInCollection) {
                            await provider.removeRecipeFromCollection(collection.id!, recipe.id);
                          } else {
                            await provider.addRecipeToCollection(collection.id!, recipe.id);
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
                              color: colorScheme.onSurfaceVariant,
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
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
