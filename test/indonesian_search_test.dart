import 'package:flutter_test/flutter_test.dart';
import 'package:makanan/services/recipe_service.dart';
import 'package:makanan/utils/indonesian_food_matcher.dart';
import 'package:makanan/utils/recipe_image_mapper.dart';

void main() {
  final recipeService = RecipeService();

  // ─────────────────────────────────────────────────────────────────────────
  // INDONESIAN FOOD MATCHER TESTS
  // ─────────────────────────────────────────────────────────────────────────
  group('IndonesianFoodMatcher', () {
    test('mendeteksi "nasi goreng" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('nasi goreng'), isTrue);
    });

    test('mendeteksi "rendang" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('rendang'), isTrue);
    });

    test('mendeteksi "soto ayam" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('soto ayam'), isTrue);
    });

    test('mendeteksi "bakso" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('bakso'), isTrue);
    });

    test('mendeteksi "sate" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('sate'), isTrue);
    });

    test('mendeteksi "gado-gado" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('gado-gado'), isTrue);
    });

    test('mendeteksi "ayam penyet" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('ayam penyet'), isTrue);
    });

    test('mendeteksi "mie ayam" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('mie ayam'), isTrue);
    });

    test('mendeteksi "ketoprak" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('ketoprak'), isTrue);
    });

    test('mendeteksi "lontong sayur" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('lontong sayur'), isTrue);
    });

    test('mendeteksi "opor ayam" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('opor ayam'), isTrue);
    });

    test('mendeteksi "pempek" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('pempek'), isTrue);
    });

    test('mendeteksi "rawon" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('rawon'), isTrue);
    });

    test('mendeteksi "gudeg" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('gudeg'), isTrue);
    });

    test('tidak mendeteksi "pasta" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('pasta'), isFalse);
    });

    test('tidak mendeteksi "burger" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('burger'), isFalse);
    });

    test('tidak mendeteksi "sushi" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('sushi'), isFalse);
    });

    test('tidak mendeteksi "salad" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('salad'), isFalse);
    });

    test('tidak mendeteksi "steak" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('steak'), isFalse);
    });

    test('tidak mendeteksi "pizza" sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood('pizza'), isFalse);
    });

    test('query kosong tidak terdeteksi sebagai makanan Indonesia', () {
      expect(IndonesianFoodMatcher.isIndonesianFood(''), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // INDONESIAN FOOD MATCHER - LOCAL RECIPE ID MAPPING
  // ─────────────────────────────────────────────────────────────────────────
  group('IndonesianFoodMatcher.getLocalRecipeId', () {
    test('mengembalikan ID untuk "nasi goreng"', () {
      expect(IndonesianFoodMatcher.getLocalRecipeId('nasi goreng'), equals(1));
    });

    test('mengembalikan ID untuk "rendang"', () {
      expect(IndonesianFoodMatcher.getLocalRecipeId('rendang'), equals(15));
    });

    test('mengembalikan ID untuk "soto ayam"', () {
      expect(IndonesianFoodMatcher.getLocalRecipeId('soto ayam'), equals(2));
    });

    test('mengembalikan ID untuk "ayam penyet"', () {
      expect(IndonesianFoodMatcher.getLocalRecipeId('ayam penyet'), equals(28));
    });

    test('mengembalikan ID untuk "bakso"', () {
      expect(IndonesianFoodMatcher.getLocalRecipeId('bakso'), equals(18));
    });

    test('mengembalikan null untuk query non-Indonesia', () {
      expect(IndonesianFoodMatcher.getLocalRecipeId('pasta'), isNull);
    });

    test('mengembalikan null untuk query kosong', () {
      expect(IndonesianFoodMatcher.getLocalRecipeId(''), isNull);
    });

    test('case insensitive - "Nasi Goreng" tetap terdeteksi', () {
      expect(IndonesianFoodMatcher.getLocalRecipeId('Nasi Goreng Kampung'), equals(1));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RECIPE SERVICE - DEMO RECIPE SEARCH (API KEY EMPTY → DEMO FALLBACK)
  // ─────────────────────────────────────────────────────────────────────────
  group('RecipeService demo search fallback', () {
    test('searchRecipes("nasi goreng") mengembalikan resep Indonesia (demo)', () async {
      final recipes = await recipeService.searchRecipes('nasi goreng');
      expect(recipes, isNotEmpty);
      expect(
        recipes.any((r) => r.title.toLowerCase().contains('nasi goreng')),
        isTrue,
      );
    });

    test('searchRecipes("rendang") mengembalikan resep Rendang Sapi', () async {
      final recipes = await recipeService.searchRecipes('rendang');
      expect(recipes, isNotEmpty);
      expect(
        recipes.any((r) => r.title.toLowerCase().contains('rendang')),
        isTrue,
      );
    });

    test('searchRecipes("soto") mengembalikan resep Soto Ayam', () async {
      final recipes = await recipeService.searchRecipes('soto');
      expect(recipes, isNotEmpty);
      expect(
        recipes.any((r) => r.title.toLowerCase().contains('soto')),
        isTrue,
      );
    });

    test('searchRecipes("bakso") mengembalikan resep Bakso', () async {
      final recipes = await recipeService.searchRecipes('bakso');
      expect(recipes, isNotEmpty);
      expect(
        recipes.any((r) => r.title.toLowerCase().contains('bakso')),
        isTrue,
      );
    });

    test('searchRecipes("sate") mengembalikan resep Sate', () async {
      final recipes = await recipeService.searchRecipes('sate');
      expect(recipes, isNotEmpty);
      expect(
        recipes.any((r) => r.title.toLowerCase().contains('sate')),
        isTrue,
      );
    });

    test('searchRecipes("gado") mengembalikan resep Gado-Gado', () async {
      final recipes = await recipeService.searchRecipes('gado');
      expect(recipes, isNotEmpty);
      expect(
        recipes.any((r) => r.title.toLowerCase().contains('gado')),
        isTrue,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE MATCHING VERIFICATION
  // ─────────────────────────────────────────────────────────────────────────
  group('Recipe images match recipe names', () {
    test('semua gambar berasal dari sumber dengan CORS (Wikimedia/Unsplash, bukan Spoonacular)', () async {
      final recipes = await recipeService.searchRecipes('nasi');
      for (final recipe in recipes) {
        expect(
          recipe.image.startsWith('https://upload.wikimedia.org/') ||
              recipe.image.startsWith('https://images.unsplash.com/'),
          isTrue,
          reason: 'Gambar ${recipe.title} harus dari Wikimedia/Unsplash (CORS ✅), '
              'bukan Spoonacular CDN. URL: ${recipe.image}',
        );
      }
    });

    test('gambar mapping dipakai untuk hidangan Indonesia yang dikenal', () async {
      final recipes = await recipeService.searchRecipes('nasi');
      for (final recipe in recipes) {
        final mapped = RecipeImageMapper.imageForTitle(recipe.title);
        if (mapped != null) {
          expect(
            recipe.image, equals(mapped),
            reason: '${recipe.title} harus memakai gambar mapping, bukan gambar acak. '
                'Gambar: ${recipe.image}',
          );
        }
      }
    });

    test('tidak ada gambar dari img.spoonacular.com', () async {
      final recipes = await recipeService.searchRecipes('ayam');
      for (final recipe in recipes) {
        expect(
          recipe.image.contains('img.spoonacular.com'),
          isFalse,
          reason: 'Gambar ${recipe.title} tidak boleh dari Spoonacular CDN (CORS error)',
        );
      }
    });

    test('setiap resep demo memiliki URL gambar yang valid', () async {
      final recipes = await recipeService.searchRecipes('mie');
      for (final recipe in recipes) {
        expect(
          recipe.image.isNotEmpty,
          isTrue,
          reason: '${recipe.title} harus memiliki gambar',
        );
        expect(
          recipe.image.startsWith('https://'),
          isTrue,
          reason: 'URL gambar ${recipe.title} harus HTTPS: ${recipe.image}',
        );
      }
    });

    test('Rawon Surabaya selalu menampilkan gambar rawon', () async {
      final recipes = await recipeService.searchRecipes('rawon');
      final rawon = recipes.firstWhere(
        (r) => r.title.toLowerCase().contains('rawon'),
      );
      expect(rawon.image, contains('Rawon_Setan'));
      expect(rawon.image, contains('upload.wikimedia.org'));
    });

    test('Coto Makassar selalu menampilkan gambar coto makassar', () async {
      final recipes = await recipeService.searchRecipes('coto');
      final coto = recipes.firstWhere(
        (r) => r.title.toLowerCase().contains('coto'),
      );
      expect(coto.image, contains('Coto_Makassar'));
    });

    test('Pempek Palembang selalu menampilkan gambar pempek', () async {
      final recipes = await recipeService.searchRecipes('pempek');
      final pempek = recipes.firstWhere(
        (r) => r.title.toLowerCase().contains('pempek'),
      );
      expect(pempek.image, contains('Pempek'));
    });

    test('Papeda selalu menampilkan gambar papeda', () async {
      final recipes = await recipeService.searchRecipes('papeda');
      final papeda = recipes.firstWhere(
        (r) => r.title.toLowerCase().contains('papeda'),
      );
      expect(papeda.image, contains('papeda'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RECIPE DATA INTEGRITY
  // ─────────────────────────────────────────────────────────────────────────
  group('Recipe data integrity', () {
    test('semua resep demo memiliki bahan dan langkah memasak', () async {
      final recipes = await recipeService.searchRecipes('nasi');
      for (final recipe in recipes) {
        expect(
          recipe.ingredients.isNotEmpty,
          isTrue,
          reason: '${recipe.title} harus memiliki bahan',
        );
        expect(
          recipe.instructions.isNotEmpty,
          isTrue,
          reason: '${recipe.title} harus memiliki langkah memasak',
        );
        // Pastikan tidak ada placeholder
        expect(
          recipe.ingredients.any((i) => i.contains('belum tersedia')),
          isFalse,
          reason: '${recipe.title} harus memiliki bahan asli, bukan placeholder',
        );
      }
    });

    test('judul atau bahan resep mengandung kata kunci yang dicari', () async {
      final recipes = await recipeService.searchRecipes('ayam');
      expect(recipes, isNotEmpty);
      for (final recipe in recipes) {
        // Cek apakah judul ATAU minimal salah satu bahan mengandung keyword
        final titleMatch = recipe.title.toLowerCase().contains('ayam');
        final ingredientMatch =
            recipe.ingredients.any((i) => i.toLowerCase().contains('ayam'));
        expect(
          titleMatch || ingredientMatch,
          isTrue,
          reason: "'${recipe.title}' harus mengandung 'ayam' di judul atau bahan",
        );
      }
    });

    test('jumlah bahan resep masuk akal (minimal 3 bahan)', () async {
      final recipes = await recipeService.searchRecipes('nasi');
      for (final recipe in recipes) {
        expect(
          recipe.ingredients.length >= 3,
          isTrue,
          reason: '${recipe.title} harus memiliki minimal 3 bahan, '
              'hanya memiliki ${recipe.ingredients.length}',
        );
      }
    });

    test('jumlah langkah memasak masuk akal (minimal 3 langkah)', () async {
      final recipes = await recipeService.searchRecipes('nasi');
      for (final recipe in recipes) {
        expect(
          recipe.instructions.length >= 3,
          isTrue,
          reason: '${recipe.title} harus memiliki minimal 3 langkah, '
              'hanya memiliki ${recipe.instructions.length}',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FILTER FUNCTIONALITY WITH INDONESIAN RECIPES
  // ─────────────────────────────────────────────────────────────────────────
  group('Filter functionality with Indonesian recipes', () {
    test('filter "quick" hanya mengembalikan resep ≤ 20 menit', () async {
      final recipes = await recipeService.searchRecipes('mie', filter: 'quick');
      expect(recipes, isNotEmpty);
      expect(
        recipes.every((r) => (r.readyInMinutes ?? 999) <= 20),
        isTrue,
      );
    });

    test('searchRecipes dengan query kosong mengembalikan daftar kosong', () async {
      final recipes = await recipeService.searchRecipes('');
      expect(recipes, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RECIPE DETAIL RETRIEVAL (regresi bug: detail != hasil pencarian)
  // ─────────────────────────────────────────────────────────────────────────
  group('Recipe detail retrieval', () {
    test('getRecipeDetail(1) mengembalikan Nasi Goreng Kampung', () async {
      final recipe = await recipeService.getRecipeDetail(1);
      expect(recipe, isNotNull);
      expect(recipe!.title, contains('Nasi Goreng'));
    });

    test('getRecipeDetail(15) mengembalikan Rendang Sapi', () async {
      final recipe = await recipeService.getRecipeDetail(15);
      expect(recipe, isNotNull);
      expect(recipe!.title.toLowerCase(), contains('rendang'));
    });

    test('REGRESI: getRecipeDetail(5) mengembalikan Nasi Goreng Jawa, BUKAN Fried Anchovies', () async {
      // Bug asli: user klik "Nasi Goreng Jawa" (ID lokal 5) tapi detail
      // menampilkan "Fried Anchovies with Sage" (ID 5 di Spoonacular).
      final recipe = await recipeService.getRecipeDetail(5);
      expect(recipe, isNotNull);
      expect(recipe!.title, contains('Nasi Goreng Jawa'));
      expect(recipe.title.toLowerCase(), isNot(contains('anchovies')));
      // Gambar harus dari sumber CORS ✅ dan sesuai judul (nasi goreng).
      expect(
        recipe.image.startsWith('https://upload.wikimedia.org/') ||
            recipe.image.startsWith('https://images.unsplash.com/'),
        isTrue,
      );
      expect(recipe.image.contains('img.spoonacular.com'), isFalse);
    });

    test('REGRESI: getRecipeDetail(5) tidak pernah memanggil API Spoonacular untuk ID lokal', () async {
      // ID 5 dikenali sebagai ID resep lokal → API tidak boleh dipanggil.
      expect(IndonesianFoodMatcher.isLocalRecipeId(5), isTrue);
      expect(IndonesianFoodMatcher.isLocalRecipeId(9999), isFalse);
    });

    test('getRecipeDetail dengan ID tidak dikenal mengembalikan null (bukan resep random)', () async {
      // User meminta: detail TIDAK boleh mengambil "first result / random recipe".
      final recipe = await recipeService.getRecipeDetail(9999);
      expect(recipe, isNull);
    });

    test('getRecipeDetail(24) ID lokal tanpa data demo → null, tidak ke API', () async {
      // ID 24 (Nasi Uduk) ada di matcher tetapi tidak di demo recipes.
      // Jika database tidak tersedia (web), harus null — JANGAN ke API.
      expect(IndonesianFoodMatcher.isLocalRecipeId(24), isTrue);
      final recipe = await recipeService.getRecipeDetail(24);
      expect(recipe, isNull);
    });

    test('isLocalRecipeId mendeteksi semua ID lokal dengan benar', () {
      // ID lokal dari matcher
      expect(IndonesianFoodMatcher.isLocalRecipeId(1), isTrue);
      expect(IndonesianFoodMatcher.isLocalRecipeId(15), isTrue);
      expect(IndonesianFoodMatcher.isLocalRecipeId(28), isTrue);
      expect(IndonesianFoodMatcher.isLocalRecipeId(76), isTrue);
      // ID Spoonacular asli (biasanya 6+ digit)
      expect(IndonesianFoodMatcher.isLocalRecipeId(634476), isFalse);
      expect(IndonesianFoodMatcher.isLocalRecipeId(100000), isFalse);
    });
  });
}
