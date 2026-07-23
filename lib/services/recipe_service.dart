import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/nutrition_info.dart';
import '../models/recipe.dart';

class RecipeService {
  static const String _baseUrl = 'https://api.spoonacular.com/recipes';

  Future<List<Recipe>> searchRecipes(
    String query, {
    String filter = 'all',
    String? cuisine,
    String? diet,
    String? intolerance,
    int? maxReadyTime,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return [];
    }

    final apiKey = _apiKey;
    if (apiKey.isEmpty || apiKey == 'demo_key') {
      return _searchDemoRecipes(normalizedQuery, filter);
    }

    // Build query parameters
    final params = <String, String>{
      'apiKey': apiKey,
      'query': normalizedQuery,
      'number': '10',
      'addRecipeInformation': 'true',
    };

    if (cuisine != null && cuisine.isNotEmpty && cuisine != 'any') {
      params['cuisine'] = cuisine;
    }
    if (diet != null && diet.isNotEmpty && diet != 'any') {
      params['diet'] = diet;
    }
    if (intolerance != null && intolerance.isNotEmpty && intolerance != 'any') {
      params['intolerance'] = intolerance;
    }
    if (maxReadyTime != null && maxReadyTime > 0) {
      params['maxReadyTime'] = maxReadyTime.toString();
    }

    final uri = Uri.parse('$_baseUrl/complexSearch').replace(queryParameters: params);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];
        final recipes = results
            .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
            .toList();
        return _applyFilter(recipes, filter);
      }
    } catch (_) {
      // Fallback to demo data when the API cannot be reached.
    }

    return _searchDemoRecipes(normalizedQuery, filter);
  }

  Future<NutritionInfo?> getNutritionInfo(int recipeId) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty || apiKey == 'demo_key') {
      return null;
    }

    final uri = Uri.parse(
      '$_baseUrl/$recipeId/nutritionWidget.json?apiKey=$apiKey',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return NutritionInfo.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Return null if nutrition info cannot be fetched
    }

    return null;
  }

  List<Recipe> _applyFilter(List<Recipe> recipes, String filter) {
    switch (filter) {
      case 'quick':
        return recipes
            .where((recipe) => (recipe.readyInMinutes ?? 999) <= 20)
            .toList();
      case 'simple':
        return recipes
            .where((recipe) => (recipe.ingredients.length <= 5))
            .toList();
      default:
        return recipes;
    }
  }

  Future<Recipe?> getRecipeDetail(int id) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty || apiKey == 'demo_key') {
      return _demoRecipes().firstWhere(
        (recipe) => recipe.id == id,
        orElse: () => _demoRecipes().first,
      );
    }

    final uri = Uri.parse('$_baseUrl/$id/information?apiKey=$apiKey');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return Recipe.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Fallback to demo data when the API cannot be reached.
    }

    return _demoRecipes().firstWhere(
      (recipe) => recipe.id == id,
      orElse: () => _demoRecipes().first,
    );
  }

  String get _apiKey {
    if (!dotenv.isInitialized) {
      return '';
    }

    return dotenv.env['SPOONACULAR_API_KEY'] ?? '';
  }

  List<Recipe> _searchDemoRecipes(String normalizedQuery, String filter) {
    final recipes = _demoRecipes()
        .where(
          (recipe) => recipe.title.toLowerCase().contains(
            normalizedQuery.toLowerCase(),
          ),
        )
        .toList();
    return _applyFilter(recipes, filter);
  }

  List<Recipe> _demoRecipes() {
    return [
      // ═══ NASI GORENG VARIANT (4 jenis) ═══
      const Recipe(
        id: 1,
        title: 'Nasi Goreng Kampung',
        image:
            'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 25,
        servings: 3,
        ingredients: [
          'Nasi putih (3 piring)',
          'Telur ayam (2 butir)',
          'Bawang merah (5 siung)',
          'Bawang putih (3 siung)',
          'Cabai rawit merah (5 buah)',
          'Kecap manis (3 sdm)',
          'Garam (1 sdt)',
          'Merica bubuk (1/2 sdt)',
          'Minyak goreng (3 sdm)',
          'Daun bawang (2 batang)',
        ],
        instructions: [
          '1. Siapkan nasi putih yang sudah didinginkan (nasi kemarin lebih baik karena teksturnya lebih kering).',
          '2. Haluskan bawang merah, bawang putih, dan cabai rawit menggunakan ulekan atau blender bumbu.',
          '3. Panaskan minyak goreng di wajan dengan api sedang. Tumis bumbu halus hingga harum dan matang, sekitar 3-4 menit.',
          '4. Dorong bumbu ke pinggir wajan, pecahkan telur di tengah wajan lalu orak-arik hingga matang.',
          '5. Masukkan nasi putih ke dalam wajan. Aduk rata dengan bumbu dan telur hingga semua nasi terlapisi bumbu.',
          '6. Tambahkan kecap manis, garam, dan merica bubuk. Aduk kembali hingga semua bumbu tercampur merata.',
          '7. Koreksi rasa. Tambahkan garam atau kecap sesuai selera.',
          '8. Masukkan irisan daun bawang, aduk sebentar hingga layu.',
          '9. Angkat dan sajikan selagi hangat dengan pelengkap kerupuk dan acar mentimun.',
        ],
      ),
      const Recipe(
        id: 4,
        title: 'Nasi Goreng Seafood',
        image:
            'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 30,
        servings: 2,
        ingredients: [
          'Nasi putih (2 piring)',
          'Udang kupas (150 gram)',
          'Cumi-cumi (100 gram)',
          'Telur (1 butir)',
          'Bawang putih (4 siung)',
          'Cabai keriting (3 buah)',
          'Saus tiram (2 sdm)',
          'Kecap ikan (1 sdm)',
          'Margarin (2 sdm)',
          'Daun bawang (2 batang)',
          'Garam dan merica (secukupnya)',
        ],
        instructions: [
          '1. Bersihkan udang, buang kulit dan ekornya. Cuci bersih cumi-cumi, potong berbentuk cincin.',
          '2. Haluskan bawang putih dan cabai keriting. Iris tipis daun bawang.',
          '3. Panaskan margarin di wajan dengan api besar. Tumis bumbu halus hingga mengeluarkan aroma harum.',
          '4. Masukkan udang dan cumi-cumi. Tumis cepat selama 2-3 menit hingga seafood matang (jangan terlalu lama agar tidak alot).',
          '5. Dorong seafood ke pinggir wajan. Masukkan telur dan orak-arik hingga matang.',
          '6. Masukkan nasi putih, saus tiram, dan kecap ikan. Aduk rata dengan api besar selama 3-4 menit.',
          '7. Bumbui dengan garam dan merica secukupnya. Aduk kembali hingga tercampur sempurna.',
          '8. Taburkan irisan daun bawang, aduk sebentar, lalu angkat.',
          '9. Sajikan nasi goreng seafood selagi hangat, beri perasan jeruk nipis jika suka.',
        ],
      ),
      const Recipe(
        id: 5,
        title: 'Nasi Goreng Jawa',
        image:
            'https://images.unsplash.com/photo-1603366445781-2fedc492e0a4?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 35,
        servings: 3,
        ingredients: [
          'Nasi putih (3 piring)',
          'Tempe (100 gram)',
          'Petai (1 papan)',
          'Telur (1 butir)',
          'Bawang merah (6 siung)',
          'Bawang putih (3 siung)',
          'Kencur (2 ruas jari)',
          'Cabai merah besar (3 buah)',
          'Kecap manis (4 sdm)',
          'Gula jawa (1 sdm, sisir halus)',
          'Garam dan kaldu bubuk (secukupnya)',
        ],
        instructions: [
          '1. Potong tempe berbentuk dadu kecil. Goreng setengah matang, tiriskan.',
          '2. Haluskan bawang merah, bawang putih, kencur, dan cabai merah besar menggunakan cobek.',
          '3. Kupas petai, belah menjadi dua bagian. Sisihkan.',
          '4. Panaskan minyak di wajan. Tumis bumbu halus hingga harum dan berubah warna, sekitar 5 menit.',
          '5. Masukkan petai, tumis sebentar hingga layu.',
          '6. Masukkan nasi putih, kecap manis, dan gula jawa yang sudah disisir. Aduk rata dengan api sedang.',
          '7. Tambahkan tempe goreng. Aduk kembali hingga semua bahan tercampur sempurna.',
          '8. Bumbui dengan garam dan kaldu bubuk. Koreksi rasa, tambahkan kecap jika kurang manis.',
          '9. Angkat dan sajikan hangat dengan taburan bawang goreng dan kerupuk udang.',
        ],
      ),
      const Recipe(
        id: 6,
        title: 'Nasi Goreng Merah',
        image:
            'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 25,
        servings: 2,
        ingredients: [
          'Nasi putih (2 piring)',
          'Sambal bawang merah (3 sdm)',
          'Bawang merah (4 siung, iris)',
          'Terasi bakar (1 sdt)',
          'Tomat merah (1 buah, potong)',
          'Telur (1 butir)',
          'Minyak goreng (3 sdm)',
          'Garam dan gula (secukupnya)',
          'Timun segar (untuk pelengkap)',
        ],
        instructions: [
          '1. Siapkan nasi putih yang sudah didinginkan. Iris tipis bawang merah dan potong tomat.',
          '2. Panaskan minyak di wajan. Tumis bawang merah iris hingga harum dan sedikit kecoklatan.',
          '3. Masukkan sambal bawang merah dan terasi bakar. Aduk rata hingga terasi tercampur sempurna.',
          '4. Masukkan potongan tomat, masak hingga tomat layu dan mengeluarkan sari merahnya.',
          '5. Dorong bumbu ke pinggir wajan. Masukkan telur dan buat orak-arik.',
          '6. Masukkan nasi putih. Aduk rata dengan bumbu merah hingga semua nasi berwarna merah merata.',
          '7. Tambahkan garam dan gula secukupnya. Aduk kembali dengan api sedang.',
          '8. Koreksi rasa. Pastikan rasa pedas, asin, dan manis seimbang.',
          '9. Sajikan selagi hangat dengan irisan timun segar dan kerupuk.',
        ],
      ),

      // ═══ AYAM VARIANT (5 jenis) ═══
      const Recipe(
        id: 2,
        title: 'Soto Ayam Hangat',
        image:
            'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 45,
        servings: 4,
        ingredients: [
          'Ayam kampung (1 ekor, potong 4)',
          'Bawang merah (6 siung)',
          'Bawang putih (4 siung)',
          'Kunyit (2 ruas jari, bakar)',
          'Jahe (2 ruas jari)',
          'Sereh (3 batang, memarkan)',
          'Daun jeruk (5 lembar)',
          'Daun bawang (3 batang, iris)',
          'Soun (100 gram, rendam air hangat)',
          'Telur rebus (4 butir)',
          'Minyak goreng (3 sdm)',
          'Garam, merica, dan kaldu bubuk (secukupnya)',
        ],
        instructions: [
          '1. Rebus ayam dalam 1.5 liter air hingga mendidih. Buang busa yang muncul di permukaan.',
          '2. Haluskan bawang merah, bawang putih, kunyit bakar, dan jahe menggunakan blender.',
          '3. Panaskan minyak di wajan. Tumis bumbu halus bersama sereh dan daun jeruk hingga harum dan matang, sekitar 7 menit.',
          '4. Masukkan bumbu tumis ke dalam rebusan ayam. Aduk rata.',
          '5. Masak dengan api sedang hingga ayam empuk dan bumbu meresap, sekitar 25 menit.',
          '6. Angkat ayam dari kuah, goreng sebentar hingga kecoklatan, lalu suwir-suwir dagingnya.',
          '7. Siapkan mangkuk saji: tata soun, suwiran ayam, telur rebus yang dibelah, dan irisan daun bawang.',
          '8. Siram dengan kuah soto panas. Taburi bawang goreng di atasnya.',
          '9. Sajikan dengan nasi putih hangat, sambal, dan perasan jeruk nipis.',
        ],
      ),
      const Recipe(
        id: 7,
        title: 'Ayam Goreng Mentega',
        image:
            'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 30,
        servings: 3,
        ingredients: [
          'Ayam (500 gram, potong kecil)',
          'Mentega (3 sdm)',
          'Bawang putih (4 siung, cincang)',
          'Bawang bombai (1/2 buah, iris)',
          'Kecap inggris (2 sdm)',
          'Kecap manis (2 sdm)',
          'Saus tiram (1 sdm)',
          'Gula pasir (1 sdt)',
          'Merica bubuk (1/2 sdt)',
          'Daun bawang (2 batang, iris)',
          'Minyak goreng (secukupnya)',
        ],
        instructions: [
          '1. Lumuri potongan ayam dengan sedikit garam dan merica. Diamkan 15 menit.',
          '2. Goreng ayam dalam minyak panas hingga matang dan kecoklatan. Angkat dan tiriskan.',
          '3. Panaskan mentega di wajan bersih dengan api sedang.',
          '4. Tumis bawang putih cincang hingga harum, lalu masukkan bawang bombai. Tumis hingga layu.',
          '5. Masukkan kecap inggris, kecap manis, saus tiram, gula pasir, dan merica. Aduk rata.',
          '6. Masak saus hingga mengental dan berbuih, sekitar 2 menit.',
          '7. Masukkan ayam goreng ke dalam saus mentega. Aduk cepat hingga semua potongan ayam terlapisi saus.',
          '8. Taburkan irisan daun bawang, aduk sebentar, lalu angkat.',
          '9. Sajikan ayam goreng mentega selagi hangat dengan nasi putih.',
        ],
      ),
      const Recipe(
        id: 8,
        title: 'Opor Ayam',
        image:
            'https://images.unsplash.com/photo-1603895544018-0e8f6af6c5dc?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 50,
        servings: 5,
        ingredients: [
          'Ayam (1 ekor, potong 8 bagian)',
          'Santan kental (500 ml dari 1 butir kelapa)',
          'Santan encer (500 ml)',
          'Bawang merah (8 siung)',
          'Bawang putih (5 siung)',
          'Kemiri (4 butir, sangrai)',
          'Ketumbar bubuk (1 sdm)',
          'Jahe (2 ruas jari)',
          'Lengkuas (3 ruas jari, memarkan)',
          'Daun salam (4 lembar)',
          'Serai (3 batang, memarkan)',
          'Gula merah (1 sdm, sisir)',
          'Garam dan penyedap (secukupnya)',
        ],
        instructions: [
          '1. Cuci bersih potongan ayam. Lumuri dengan air jeruk nipis dan garam, diamkan 15 menit lalu bilas.',
          '2. Haluskan bawang merah, bawang putih, kemiri sangrai, jahe, dan ketumbar menggunakan blender.',
          '3. Panaskan sedikit minyak di wajan besar. Tumis bumbu halus bersama lengkuas, daun salam, dan serai hingga harum dan matang.',
          '4. Masukkan potongan ayam ke dalam tumisan bumbu. Aduk rata hingga ayam berubah warna.',
          '5. Tuangkan santan encer. Masak dengan api sedang hingga ayam setengah matang, sekitar 15 menit.',
          '6. Masukkan gula merah, garam, dan penyedap. Aduk rata.',
          '7. Tuangkan santan kental. Aduk perlahan agar santan tidak pecah.',
          '8. Masak dengan api kecil hingga ayam empuk dan kuah mengental, sekitar 20-25 menit. Aduk sesekali.',
          '9. Koreksi rasa, angkat. Sajikan opor ayam dengan ketupat atau nasi hangat dan taburan bawang goreng.',
        ],
      ),
      const Recipe(
        id: 9,
        title: 'Ayam Bakar Taliwang',
        image:
            'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 55,
        servings: 4,
        ingredients: [
          'Ayam kampung (1 ekor, belah tengah)',
          'Cabai keriting merah (10 buah)',
          'Cabai rawit (8 buah)',
          'Bawang merah (8 siung)',
          'Bawang putih (4 siung)',
          'Tomat merah (2 buah)',
          'Terasi bakar (1 sdt)',
          'Gula merah (2 sdm, sisir)',
          'Kecap manis (3 sdm)',
          'Minyak goreng (4 sdm)',
          'Garam (secukupnya)',
        ],
        instructions: [
          '1. Bersihkan ayam, belah di bagian dada tanpa putus. Lumuri dengan air jeruk nipis dan garam, diamkan 15 menit.',
          '2. Rebus cabai keriting, cabai rawit, dan tomat hingga layu. Tiriskan.',
          '3. Haluskan cabai, tomat, bawang merah, bawang putih, dan terasi bakar menggunakan blender.',
          '4. Panaskan minyak. Tumis bumbu halus hingga harum dan matang, sekitar 10 menit.',
          '5. Masukkan gula merah, kecap manis, dan garam. Aduk rata. Ambil sebagian bumbu untuk olesan.',
          '6. Masukkan ayam ke dalam sisa bumbu. Lumuri merata, diamkan 20 menit agar bumbu meresap.',
          '7. Bakar ayam di atas bara api atau grill pan sambil diolesi bumbu olesan. Balik perlahan hingga kedua sisi matang.',
          '8. Lanjutkan membakar sambil dioles bumbu hingga ayam mengeluarkan aroma bakar yang harum dan berwarna kecoklatan.',
          '9. Sajikan ayam bakar Taliwang dengan nasi hangat, sambal tomat segar, dan lalapan mentimun.',
        ],
      ),
      const Recipe(
        id: 10,
        title: 'Ayam Suwir Pedas',
        image:
            'https://images.unsplash.com/photo-1587593810167-a84920ea0781?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 35,
        servings: 3,
        ingredients: [
          'Dada ayam (300 gram, rebus hingga matang)',
          'Cabai rawit merah (6 buah)',
          'Cabai keriting (4 buah)',
          'Bawang merah (5 siung)',
          'Bawang putih (3 siung)',
          'Serai (2 batang, memarkan)',
          'Daun jeruk (4 lembar)',
          'Kecap manis (2 sdm)',
          'Gula merah (1 sdm, sisir)',
          'Minyak kelapa (2 sdm)',
          'Garam dan kaldu bubuk (secukupnya)',
          'Jeruk limau (1 buah)',
        ],
        instructions: [
          '1. Rebus dada ayam hingga matang sempurna. Tiriskan, lalu suwir-suwir daging ayam menggunakan garpu.',
          '2. Haluskan cabai rawit, cabai keriting, bawang merah, dan bawang putih.',
          '3. Panaskan minyak kelapa di wajan. Tumis bumbu halus, serai, dan daun jeruk hingga harum.',
          '4. Masukkan ayam suwir ke dalam tumisan bumbu. Aduk rata.',
          '5. Tambahkan kecap manis, gula merah, garam, dan kaldu bubuk. Aduk kembali.',
          '6. Masak dengan api kecil hingga bumbu meresap ke dalam suwiran ayam, sekitar 10-15 menit.',
          '7. Peraskan jeruk limau di atasnya, aduk sebentar lalu angkat.',
          '8. Koreksi rasa, pastikan pedas-manis-asam seimbang.',
          '9. Sajikan ayam suwir pedas dengan nasi hangat dan lalapan segar.',
        ],
      ),

      // ═══ MIE VARIANT (4 jenis) ═══
      const Recipe(
        id: 11,
        title: 'Mie Goreng Jawa',
        image:
            'https://images.unsplash.com/photo-1555126634-323283e090fa?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 25,
        servings: 2,
        ingredients: [
          'Mie telur basah (250 gram)',
          'Kol (100 gram, iris halus)',
          'Sawi hijau (2 batang, potong)',
          'Wortel (1 buah, potong korek api)',
          'Telur (1 butir)',
          'Bawang merah (4 siung)',
          'Bawang putih (2 siung)',
          'Kecap manis (3 sdm)',
          'Saus sambal (1 sdm)',
          'Merica bubuk (1/2 sdt)',
          'Minyak goreng (3 sdm)',
          'Bawang goreng (untuk taburan)',
        ],
        instructions: [
          '1. Rebus mie telur hingga setengah matang (jangan terlalu lembek). Tiriskan dan beri sedikit minyak agar tidak lengket.',
          '2. Haluskan bawang merah dan bawang putih. Iris tipis kol, sawi, dan wortel.',
          '3. Panaskan minyak di wajan. Tumis bumbu halus hingga harum.',
          '4. Masukkan telur, orak-arik hingga setengah matang.',
          '5. Masukkan sayuran (kol, sawi, wortel). Tumis hingga layu namun masih renyah.',
          '6. Masukkan mie yang sudah direbus. Aduk rata dengan sayuran dan telur.',
          '7. Tambahkan kecap manis, saus sambal, dan merica bubuk. Aduk hingga semua mie terlapisi bumbu.',
          '8. Koreksi rasa. Masak hingga mie matang sempurna, sekitar 3-4 menit.',
          '9. Angkat, sajikan hangat dengan taburan bawang goreng dan acar timun.',
        ],
      ),
      const Recipe(
        id: 12,
        title: 'Mie Ayam Bakso',
        image:
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 40,
        servings: 3,
        ingredients: [
          'Mie kuning basah (300 gram)',
          'Dada ayam (200 gram, cincang)',
          'Bakso sapi (10 butir)',
          'Sawi hijau (3 batang)',
          'Bawang putih (5 siung)',
          'Kecap manis (3 sdm)',
          'Kecap asin (1 sdm)',
          'Minyak wijen (1 sdm)',
          'Daun bawang (2 batang, iris)',
          'Kaldu ayam bubuk (1 sdt)',
          'Merica bubuk (1/2 sdt)',
          'Minyak goreng (2 sdm)',
        ],
        instructions: [
          '1. Rebus bakso sapi hingga matang dan mengapung. Angkat, sisihkan. Air rebusan bakso bisa dipakai sebagai kuah kaldu.',
          '2. Cincang halus bawang putih, lalu tumis dengan minyak goreng dan minyak wijen hingga harum.',
          '3. Masukkan daging ayam cincang. Masak sapi diaduk hingga berubah warna dan matang.',
          '4. Tambahkan kecap manis, kecap asin, kaldu ayam bubuk, dan merica. Aduk rata. Sisihkan sebagai topping mie ayam.',
          '5. Rebus mie kuning hingga matang. Di air yang sama, rebus sebentar sawi hijau hingga layu.',
          '6. Siapkan mangkuk: campur 1 sdm minyak bawang, sedikit kecap asin, dan merica di dasar mangkuk.',
          '7. Masukkan mie yang sudah direbus ke dalam mangkuk. Aduk rata dengan bumbu dasar.',
          '8. Beri topping ayam cincang berbumbu, bakso, sawi rebus, dan taburan daun bawang.',
          '9. Siram dengan kuah kaldu bakso panas. Sajikan segera dengan sambal dan kecap tambahan.',
        ],
      ),
      const Recipe(
        id: 13,
        title: 'Mie Rebus Aceh',
        image:
            'https://images.unsplash.com/photo-1626804475359-6a4c2e8c3a6a?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 35,
        servings: 2,
        ingredients: [
          'Mie telur basah (250 gram)',
          'Daging sapi (150 gram, iris tipis)',
          'Bawang merah (6 siung)',
          'Bawang putih (4 siung)',
          'Cabai merah (5 buah)',
          'Kepala udang kering (1 sdm, haluskan)',
          'Jinten bubuk (1/2 sdt)',
          'Kari bubuk (1 sdm)',
          'Santan instan (100 ml)',
          'Toge (100 gram)',
          'Daun bawang (2 batang)',
          'Minyak goreng (3 sdm)',
          'Garam dan gula (secukupnya)',
        ],
        instructions: [
          '1. Rebus mie hingga setengah matang, tiriskan dan sisihkan.',
          '2. Haluskan bawang merah, bawang putih, cabai merah, dan kepala udang kering menggunakan blender.',
          '3. Panaskan minyak di wajan. Tumis bumbu halus bersama jinten bubuk dan kari bubuk hingga harum, sekitar 5 menit.',
          '4. Masukkan irisan daging sapi. Masak hingga daging berubah warna dan empuk.',
          '5. Tuangkan santan instan. Aduk rata dan masak hingga kuah sedikit mengental.',
          '6. Masukkan mie yang sudah direbus dan toge. Aduk rata dengan kuah kari.',
          '7. Bumbui dengan garam dan gula secukupnya. Koreksi rasa.',
          '8. Masak hingga mie matang sempurna dan kuah meresap, sekitar 5 menit.',
          '9. Angkat, sajikan hangat dengan taburan daun bawang dan bawang goreng. Tambahkan acar dan emping.',
        ],
      ),
      const Recipe(
        id: 14,
        title: 'Mie Godog Kuah',
        image:
            'https://images.unsplash.com/photo-1585032226651-759b368d7246?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 20,
        servings: 2,
        ingredients: [
          'Mie instan (2 bungkus)',
          'Telur (1 butir)',
          'Sawi hijau (2 batang)',
          'Bakso sapi (5 butir)',
          'Bawang putih (3 siung, cincang)',
          'Cabai rawit (3 buah, iris)',
          'Kecap manis (1 sdm)',
          'Saus sambal (1 sdm)',
          'Daun bawang (1 batang, iris)',
          'Air (500 ml)',
        ],
        instructions: [
          '1. Rebus air hingga mendidih. Masukkan bawang putih cincang dan cabai iris.',
          '2. Masukkan bakso sapi, masak hingga bakso mengapung.',
          '3. Masukkan mie instan beserta bumbunya. Aduk rata.',
          '4. Masukkan sawi hijau, masak hingga sawi layu sekitar 1 menit.',
          '5. Pecahkan telur ke dalam kuah. Aduk perlahan hingga telur matang dan berbentuk kerokan.',
          '6. Tambahkan kecap manis dan saus sambal. Aduk rata.',
          '7. Koreksi rasa, tambahkan garam atau saus sesuai selera.',
          '8. Angkat dan tuang ke mangkuk saji.',
          '9. Taburi irisan daun bawang dan bawang goreng. Sajikan selagi panas.',
        ],
      ),

      // ═══ ADDITIONAL POPULAR RECIPES (6 jenis) ═══
      const Recipe(
        id: 15,
        title: 'Rendang Sapi',
        image:
            'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 120,
        servings: 6,
        ingredients: [
          'Daging sapi (1 kg, potong besar)',
          'Santan kental (1 liter dari 2 butir kelapa)',
          'Bawang merah (12 siung)',
          'Bawang putih (6 siung)',
          'Cabai merah besar (8 buah)',
          'Cabai rawit (5 buah)',
          'Lengkuas (5 ruas jari, memarkan)',
          'Sereh (4 batang, memarkan)',
          'Daun jeruk (6 lembar)',
          'Daun kunyit (2 lembar, simpulkan)',
          'Ketumbar bubuk (2 sdm)',
          'Jinten bubuk (1 sdt)',
          'Garam dan gula merah (secukupnya)',
        ],
        instructions: [
          '1. Potong daging sapi melawan serat dengan ukuran 4x4 cm. Cuci bersih dan tiriskan.',
          '2. Haluskan bawang merah, bawang putih, cabai merah, cabai rawit menggunakan blender.',
          '3. Campur bumbu halus dengan ketumbar bubuk dan jinten bubuk. Aduk rata.',
          '4. Tuangkan santan ke dalam wajan besar (kuali tradisional lebih baik). Masukkan bumbu halus, lengkuas, sereh, daun jeruk, dan daun kunyit.',
          '5. Masak santan dengan api sedang sambil terus diaduk agar santan tidak pecah, hingga mendidih.',
          '6. Masukkan potongan daging sapi. Aduk rata. Kecilkan api.',
          '7. Masak dengan api kecil selama 1.5 - 2 jam sambil sesekali diaduk. Santan akan mengeluarkan minyak dan kuah mengental.',
          '8. Tambahkan garam dan gula merah. Aduk rata. Lanjutkan memasak hingga kuah habis dan bumbu menyelimuti daging.',
          '9. Koreksi rasa. Rendang siap disajikan dengan nasi hangat atau ketupat.',
        ],
      ),
      const Recipe(
        id: 16,
        title: 'Sate Ayam Madura',
        image:
            'https://images.unsplash.com/photo-1559847844-5315695dadae?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 40,
        servings: 4,
        ingredients: [
          'Dada ayam (500 gram, potong dadu)',
          'Tusuk sate (20 batang)',
          'Kacang tanah (200 gram, goreng)',
          'Bawang putih (4 siung)',
          'Cabai merah (3 buah)',
          'Kecap manis (5 sdm)',
          'Gula merah (2 sdm, sisir)',
          'Air asam jawa (2 sdm)',
          'Daun jeruk (3 lembar)',
          'Garam (secukupnya)',
          'Minyak goreng (2 sdm)',
        ],
        instructions: [
          '1. Potong dada ayam berbentuk dadu dengan ukuran seragam sekitar 2x2 cm.',
          '2. Marinasi ayam dengan 2 sdm kecap manis dan 1 sdm air asam jawa. Diamkan minimal 20 menit agar bumbu meresap.',
          '3. Sambil menunggu, buat bumbu kacang: haluskan kacang tanah goreng, bawang putih, dan cabai merah.',
          '4. Panaskan minyak, tumis bumbu kacang bersama daun jeruk, gula merah, sisa kecap manis, air asam jawa, dan garam.',
          '5. Tambahkan sedikit air, masak hingga bumbu mengental dan mengeluarkan minyak. Sisihkan.',
          '6. Tusukkan potongan ayam ke tusuk sate (3-4 potong per tusuk).',
          '7. Bakar sate di atas bara api atau grill pan. Olesi dengan sedikit bumbu kacang dan kecap selama membakar.',
          '8. Balik sate secara berkala hingga matang merata dan mengeluarkan aroma bakar, sekitar 8-10 menit.',
          '9. Sajikan sate hangat dengan siraman bumbu kacang, kecap manis tambahan, lontong, dan acar bawang.',
        ],
      ),
      const Recipe(
        id: 17,
        title: 'Gado-Gado Jakarta',
        image:
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 25,
        servings: 3,
        ingredients: [
          'Tahu putih (3 buah, goreng potong)',
          'Tempe (150 gram, goreng potong)',
          'Kentang (3 buah, rebus potong)',
          'Telur rebus (3 butir, belah)',
          'Sawi hijau (3 batang, rebus)',
          'Toge (100 gram, seduh air panas)',
          'Kacang panjang (5 batang, potong rebus)',
          'Kacang tanah goreng (200 gram)',
          'Cabai rawit (3 buah)',
          'Bawang putih (3 siung)',
          'Terasi bakar (1 sdt)',
          'Gula merah (2 sdm)',
          'Air asam jawa (2 sdm)',
          'Kerupuk (untuk pelengkap)',
        ],
        instructions: [
          '1. Rebus kentang hingga empuk. Angkat, tiriskan, potong dadu.',
          '2. Goreng tahu dan tempe hingga kecoklatan. Potong dadu.',
          '3. Rebus sawi hijau dan kacang panjang hingga layu. Siram toge dengan air panas.',
          '4. Potong-potong semua sayuran dan tata di piring saji.',
          '5. Buat bumbu kacang: haluskan kacang tanah goreng, cabai rawit, bawang putih, dan terasi bakar.',
          '6. Tambahkan gula merah, air asam jawa, dan sedikit air hangat. Aduk hingga kekentalan yang diinginkan.',
          '7. Bumbui dengan garam. Koreksi rasa manis, pedas, dan asam.',
          '8. Siram bumbu kacang di atas sayuran yang sudah ditata.',
          '9. Beri potongan telur rebus, taburi bawang goreng, dan sajikan dengan kerupuk.',
        ],
      ),
      const Recipe(
        id: 18,
        title: 'Bakso Sapi Rumahan',
        image:
            'https://images.unsplash.com/photo-1559847844-5315695dadae?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 60,
        servings: 6,
        ingredients: [
          'Daging sapi giling (500 gram)',
          'Tepung tapioka (100 gram)',
          'Bawang putih (6 siung, haluskan)',
          'Putih telur (2 butir)',
          'Es batu serut (100 gram)',
          'Garam (2 sdt)',
          'Merica bubuk (1 sdt)',
          'Kaldu sapi bubuk (1 sdm)',
          'Baking powder (1/2 sdt)',
          'Mie kuning (300 gram, rebus)',
          'Sawi hijau (3 batang)',
          'Daun bawang (2 batang, iris)',
          'Bawang goreng (untuk taburan)',
        ],
        instructions: [
          '1. Campurkan daging sapi giling, bawang putih halus, putih telur, dan es batu serut dalam food processor.',
          '2. Giling hingga semua bahan tercampur rata dan membentuk pasta yang lengket (sekitar 10 menit).',
          '3. Tambahkan tepung tapioka, garam, merica, kaldu sapi bubuk, dan baking powder ke dalam adonan.',
          '4. Lanjutkan giling hingga adonan kalis dan elastis. Istirahatkan adonan di kulkas selama 15 menit.',
          '5. Didihkan air dalam panci besar. Kecilkan api hingga air tidak mendidih (sekitar 80°C).',
          '6. Bentuk adonan bakso bulat-bulat menggunakan tangan dan sendok. Masukkan ke dalam air hangat.',
          '7. Setelah semua bakso mengapung, besarkan api dan rebus hingga matang sekitar 5 menit. Angkat.',
          '8. Siapkan mangkuk: tata mie kuning rebus, sawi rebus, dan bakso. Siram dengan kuah kaldu bakso panas.',
          '9. Taburi daun bawang dan bawang goreng. Sajikan dengan sambal, kecap, dan saus sambal.',
        ],
      ),
    ];
  }
}
