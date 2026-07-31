import 'package:flutter_test/flutter_test.dart';
import 'package:makanan/models/recipe.dart';
import 'package:makanan/utils/recipe_image_mapper.dart';

void main() {
  group('RecipeImageMapper.normalize', () {
    test('huruf besar & kecil disamakan', () {
      expect(RecipeImageMapper.normalize('Rawon Surabaya'), 'rawon surabaya');
    });

    test('spasi berlebih dirapikan', () {
      expect(RecipeImageMapper.normalize('  Nasi   Goreng  Jawa '),
          'nasi goreng jawa');
    });

    test('tanda baca & simbol diganti spasi', () {
      expect(RecipeImageMapper.normalize('Gado-Gado Jakarta'),
          'gado gado jakarta');
      expect(RecipeImageMapper.normalize('Papeda & Ikan Kuah Kuning'),
          'papeda ikan kuah kuning');
      expect(RecipeImageMapper.normalize('Pempek (Palembang)'),
          'pempek palembang');
    });
  });

  group('RecipeImageMapper.imageForTitle', () {
    test('Rawon Surabaya → gambar rawon', () {
      final image = RecipeImageMapper.imageForTitle('Rawon Surabaya');
      expect(image, isNotNull);
      expect(image!, contains('Rawon_Setan'));
      expect(image, contains('upload.wikimedia.org'));
    });

    test('Coto Makassar → gambar coto makassar', () {
      expect(RecipeImageMapper.imageForTitle('Coto Makassar'),
          contains('Coto_Makassar'));
    });

    test('Pempek Palembang → gambar pempek', () {
      expect(RecipeImageMapper.imageForTitle('Pempek Palembang'),
          contains('Pempek'));
    });

    test('Papeda & Ikan Kuah Kuning → gambar papeda', () {
      expect(RecipeImageMapper.imageForTitle('Papeda & Ikan Kuah Kuning'),
          contains('papeda'));
    });

    test('Rendang Sapi → gambar rendang', () {
      expect(RecipeImageMapper.imageForTitle('Rendang Sapi'),
          contains('Rendang'));
    });

    test('Soto Ayam → gambar soto ayam', () {
      expect(RecipeImageMapper.imageForTitle('Soto Ayam Hangat'),
          contains('Soto_ayam'));
    });

    test('Nasi Goreng Jawa → gambar nasi goreng', () {
      expect(RecipeImageMapper.imageForTitle('Nasi Goreng Jawa'),
          contains('Nasi_goreng'));
    });

    test('variasi penulisan tetap cocok (huruf besar, spasi, tanda baca)', () {
      expect(RecipeImageMapper.imageForTitle('GADO-GADO JAKARTA'),
          contains('Gado-gado'));
      expect(RecipeImageMapper.imageForTitle('nasi goreng kampung'),
          contains('Nasi_goreng'));
    });

    test('keyword lebih spesifik menang (ayam bakar taliwang)', () {
      final taliwang = RecipeImageMapper.imageForTitle('Ayam Bakar Taliwang');
      expect(taliwang, contains('Taliwang'));
    });

    test('judul yang tidak dikenal → null', () {
      expect(RecipeImageMapper.imageForTitle('Spaghetti Carbonara'), isNull);
    });
  });

  group('RecipeImageMapper.isSpoonacularCdn', () {
    test('mendeteksi URL CDN Spoonacular', () {
      expect(
        RecipeImageMapper.isSpoonacularCdn(
            'https://img.spoonacular.com/recipes/123-556x370.jpg'),
        isTrue,
      );
    });

    test('URL normal bukan CDN Spoonacular', () {
      expect(
        RecipeImageMapper.isSpoonacularCdn(
            'https://upload.wikimedia.org/wikipedia/commons/a/a.jpg'),
        isFalse,
      );
    });
  });

  group('RecipeImageMapper.resolveImage', () {
    test('gambar mapping menang atas gambar API', () {
      final result = RecipeImageMapper.resolveImage(
        title: 'Rawon Surabaya',
        fallback: 'https://img.spoonacular.com/recipes/5-556x370.jpg',
      );
      expect(result, contains('Rawon_Setan'));
    });

    test('fallback API dipertahankan jika judul tidak dikenal', () {
      final result = RecipeImageMapper.resolveImage(
        title: 'Pasta Aglio Olio',
        fallback: 'https://cdn.example.com/pasta.jpg',
      );
      expect(result, 'https://cdn.example.com/pasta.jpg');
    });

    test('CDN Spoonacular diganti gambar generik (deterministik)', () {
      final a = RecipeImageMapper.resolveImage(
        title: 'Spaghetti Carbonara',
        fallback: 'https://img.spoonacular.com/recipes/999-556x370.jpg',
      );
      final b = RecipeImageMapper.resolveImage(
        title: 'Spaghetti Carbonara',
        fallback: 'https://img.spoonacular.com/recipes/999-556x370.jpg',
      );
      // Judul yang sama → gambar yang sama (tidak acak).
      expect(a, b);
      expect(RecipeImageMapper.isSpoonacularCdn(a), isFalse);
      expect(a.startsWith('https://'), isTrue);
    });

    test('judul sama selalu menghasilkan gambar sama', () {
      final a = RecipeImageMapper.resolveImage(
        title: 'Ayam Pop',
        fallback: '',
      );
      final b = RecipeImageMapper.resolveImage(
        title: 'Ayam Pop',
        fallback: '',
      );
      expect(a, b);
    });
  });

  group('Recipe.displayImage', () {
    test('kartu & detail memakai gambar yang sama untuk resep yang sama', () {
      const recipe = Recipe(
        id: 19,
        title: 'Rawon Surabaya',
        image: 'https://images.unsplash.com/photo-1603899122634-f086ca5f5ddd?auto=format&fit=crop&w=800&q=80',
        ingredients: ['Daging'],
        instructions: ['Masak'],
      );
      expect(recipe.displayImage, contains('Rawon_Setan'));
      // displayImage konsisten untuk object yang sama.
      expect(recipe.displayImage, recipe.displayImage);
    });

    test('copyWith(image:) mengubah gambar yang ditampilkan', () {
      const recipe = Recipe(
        id: 20,
        title: 'Coto Makassar',
        image: 'https://old.example.com/a.jpg',
        ingredients: ['Daging'],
        instructions: ['Masak'],
      );
      final mapped = recipe.copyWith(
        image: RecipeImageMapper.resolveImage(
          title: recipe.title,
          fallback: recipe.image,
        ),
      );
      expect(mapped.displayImage, contains('Coto_Makassar'));
    });
  });
}
