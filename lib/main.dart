import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'models/recipe.dart';
import 'providers/recipe_provider.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
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

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  final List<String> _filters = ['all', 'quick', 'simple'];
  final Map<String, String> _filterLabels = {
    'all': 'Semua',
    'quick': 'Cepat',
    'simple': 'Sederhana',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resep Masakan'),
        actions: [
          IconButton(
            onPressed: () {
              _searchController.clear();
              provider.searchRecipes('');
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildSearchTab(context, provider),
          _buildFavoritesTab(context, provider),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Cari'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorit'),
        ],
      ),
    );
  }

  Widget _buildSearchTab(BuildContext context, RecipeProvider provider) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temukan resep favorit',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari resep atau bahan...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () async {
                      await provider.searchRecipes(
                        _searchController.text,
                        filter: provider.activeFilter,
                      );
                    },
                    icon: const Icon(Icons.send),
                  ),
                ),
                onSubmitted: (_) async {
                  await provider.searchRecipes(
                    _searchController.text,
                    filter: provider.activeFilter,
                  );
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _filters.map((filter) {
                  final isActive = provider.activeFilter == filter;
                  return ChoiceChip(
                    label: Text(_filterLabels[filter] ?? filter),
                    selected: isActive,
                    onSelected: (_) async {
                      await provider.searchRecipes(
                        _searchController.text,
                        filter: filter,
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        if (provider.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else if (provider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(provider.errorMessage!),
          )
        else
          Expanded(
            child: ListView.builder(
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
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                  onFavoriteToggle: () async {
                    await provider.toggleFavorite(recipe);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFavoritesTab(BuildContext context, RecipeProvider provider) {
    if (provider.favorites.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada resep favorit. Tambahkan beberapa resep untuk melihat koleksi Anda di sini.',
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.favorites.length,
      itemBuilder: (context, index) {
        final recipe = provider.favorites[index];
        return RecipeCard(
          recipe: recipe,
          isFavorite: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipe: recipe),
              ),
            );
          },
          onFavoriteToggle: () async {
            await provider.toggleFavorite(recipe);
          },
        );
      },
    );
  }
}

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final isFavorite = provider.isFavorite(recipe.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        actions: [
          IconButton(
            onPressed: () async {
              await provider.toggleFavorite(recipe);
            },
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            color: isFavorite ? Colors.red : Colors.grey,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                recipe.image,
                fit: BoxFit.cover,
                height: 240,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              recipe.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Waktu: ${recipe.readyInMinutes ?? '--'} menit | Porsi: ${recipe.servings ?? '--'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bahan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...recipe.ingredients.map(
              (ingredient) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('- $ingredient'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Langkah Memasak',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...recipe.instructions.map(
              (instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(instruction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
