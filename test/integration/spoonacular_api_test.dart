import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:makanan/utils/indonesian_food_matcher.dart';

void main() {
  const String baseUrl = 'https://api.spoonacular.com/recipes';
  String? apiKey;

  // Load API key from .env file if available
  setUpAll(() async {
    try {
      await dotenv.load(fileName: '.env', isOptional: true);
      apiKey = dotenv.env['SPOONACULAR_API_KEY'];
    } catch (_) {
      // Fallback: try reading from environment variable
      apiKey = Platform.environment['SPOONACULAR_API_KEY'];
    }

    if (apiKey == null || apiKey!.isEmpty) {
      // Try direct read
      try {
        final file = File('.env');
        if (await file.exists()) {
          final content = await file.readAsString();
          for (final line in content.split('\n')) {
            if (line.startsWith('SPOONACULAR_API_KEY=')) {
              apiKey = line.split('=')[1].trim();
              break;
            }
          }
        }
      } catch (_) {}
    }
  });

  group('Spoonacular API - Makanan Indonesia', () {
    test('API Key tersedia', () {
      expect(apiKey, isNotNull, reason: 'SPOONACULAR_API_KEY harus ada di .env');
      expect(apiKey!.isEmpty, isFalse, reason: 'API Key tidak boleh kosong');
      print('🔑 API Key: ${apiKey!.substring(0, 8)}...');
    });

    test('search "nasi goreng" dengan cuisine=Indonesian', () async {
      final uri = Uri.parse('$baseUrl/complexSearch').replace(queryParameters: {
        'apiKey': apiKey!,
        'query': 'nasi goreng',
        'number': '5',
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
        'instructionsRequired': 'true',
        'cuisine': 'Indonesian',
      });

      final response = await http.get(uri);
      expect(response.statusCode, equals(200),
          reason: 'API harus merespon dengan 200 OK. Status: ${response.statusCode}');

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];
      final totalResults = decoded['totalResults'] ?? 0;

      print('📊 Total hasil dari API: $totalResults');
      print('📋 Hasil yang dikembalikan: ${results.length}');

      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          final r = results[i] as Map<String, dynamic>;
          print('  ${i + 1}. ${r['title']} - ${r['image'] ?? 'no image'}');
        }
      } else {
        print('⚠️ API tidak mengembalikan hasil untuk "nasi goreng"!');
      }

      // Cek apakah hasilnya mengandung makanan Indonesia
      final hasIndonesianFood = results.any((r) {
        final title = (r as Map<String, dynamic>)['title']?.toString() ?? '';
        return IndonesianFoodMatcher.isIndonesianFood(title);
      });

      print('🔍 Apakah ada makanan Indonesia? $hasIndonesianFood');
      print('💡 Catatan: API mungkin tidak mengembalikan makanan Indonesia yang akurat.');
      print('    Oleh karena itu, database lokal digunakan sebagai PRIORITAS UTAMA.');
    });

    test('search "rendang" dengan cuisine=Indonesian', () async {
      final uri = Uri.parse('$baseUrl/complexSearch').replace(queryParameters: {
        'apiKey': apiKey!,
        'query': 'rendang',
        'number': '5',
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
        'instructionsRequired': 'true',
        'cuisine': 'Indonesian',
      });

      final response = await http.get(uri);
      expect(response.statusCode, equals(200));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];

      print('\n📊 Total hasil rendang: ${decoded['totalResults'] ?? 0}');
      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          final r = results[i] as Map<String, dynamic>;
          print('  ${i + 1}. ${r['title']}');
        }
      } else {
        print('⚠️ API tidak mengembalikan hasil untuk "rendang"!');
      }
    });

    test('search "soto" dengan cuisine=Indonesian', () async {
      final uri = Uri.parse('$baseUrl/complexSearch').replace(queryParameters: {
        'apiKey': apiKey!,
        'query': 'soto',
        'number': '5',
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
        'instructionsRequired': 'true',
        'cuisine': 'Indonesian',
      });

      final response = await http.get(uri);
      expect(response.statusCode, equals(200));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];

      print('\n📊 Total hasil soto: ${decoded['totalResults'] ?? 0}');
      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          final r = results[i] as Map<String, dynamic>;
          print('  ${i + 1}. ${r['title']}');
        }
      } else {
        print('⚠️ API tidak mengembalikan hasil untuk "soto"!');
      }
    });

    test('search "bakso" dengan cuisine=Indonesian', () async {
      final uri = Uri.parse('$baseUrl/complexSearch').replace(queryParameters: {
        'apiKey': apiKey!,
        'query': 'bakso',
        'number': '5',
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
        'instructionsRequired': 'true',
        'cuisine': 'Indonesian',
      });

      final response = await http.get(uri);
      expect(response.statusCode, equals(200));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];

      print('\n📊 Total hasil bakso: ${decoded['totalResults'] ?? 0}');
      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          final r = results[i] as Map<String, dynamic>;
          print('  ${i + 1}. ${r['title']}');
        }
      } else {
        print('⚠️ API tidak mengembalikan hasil untuk "bakso"!');
      }
    });

    test('search tanpa cuisine filter (default behavior)', () async {
      final uri = Uri.parse('$baseUrl/complexSearch').replace(queryParameters: {
        'apiKey': apiKey!,
        'query': 'nasi goreng',
        'number': '5',
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
        'instructionsRequired': 'true',
      });

      final response = await http.get(uri);
      expect(response.statusCode, equals(200));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];

      print('\n📊 Tanpa filter cuisine - Total: ${decoded['totalResults'] ?? 0}');
      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          final r = results[i] as Map<String, dynamic>;
          print('  ${i + 1}. ${r['title']}');
        }

        // Cek apakah makanan non-Indonesia muncul (masalah yang dikeluhkan user)
        final nonIndonesianCount = results.where((r) {
          final title = (r as Map<String, dynamic>)['title']?.toString() ?? '';
          return !IndonesianFoodMatcher.isIndonesianFood(title);
        }).length;

        print('⚠️ Makanan non-Indonesia: $nonIndonesianCount dari ${results.length}');
        if (nonIndonesianCount > 0) {
          print('❌ INI MASALAHNYA! Tanpa filter, API menampilkan makanan non-Indonesia.');
          print('✅ SOLUSI: Database lokal sudah mengatasi ini dengan prioritas lebih tinggi.');
        }
      }
    });
  });

  group('Spoonacular API - Gambar Makanan', () {
    test('periksa apakah gambar dari CDN Spoonacular bisa diakses', () async {
      final uri = Uri.parse('$baseUrl/complexSearch').replace(queryParameters: {
        'apiKey': apiKey!,
        'query': 'chicken',
        'number': '2',
        'addRecipeInformation': 'true',
      });

      final response = await http.get(uri);
      expect(response.statusCode, equals(200));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];

      if (results.isNotEmpty) {
        final firstImage = (results[0] as Map<String, dynamic>)['image']?.toString() ?? '';
        print('\n📸 Contoh gambar dari API: $firstImage');

        if (firstImage.contains('img.spoonacular.com')) {
          print('⚠️ Gambar dari img.spoonacular.com - TIDAK punya CORS header!');
          print('❌ Ini masalah untuk Flutter Web CanvasKit.');
          print('✅ SOLUSI: RecipeService sudah mengganti dengan gambar Unsplash.');
        } else if (firstImage.isNotEmpty) {
          print('✅ Gambar dari sumber lain.');
        }
      }
    });
  });
}
