import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/recipe.dart';
import '../models/user_rating.dart';

class IndonesianRecipe {
  final int id;
  final String namaResep;
  final String deskripsi;
  final String bahan;
  final String langkahMemasak;
  final String gambar;
  final String kategori;

  const IndonesianRecipe({
    required this.id,
    required this.namaResep,
    required this.deskripsi,
    required this.bahan,
    required this.langkahMemasak,
    required this.gambar,
    required this.kategori,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama_resep': namaResep,
        'deskripsi': deskripsi,
        'bahan': bahan,
        'langkah_memasak': langkahMemasak,
        'gambar': gambar,
        'kategori': kategori,
      };

  factory IndonesianRecipe.fromMap(Map<String, dynamic> map) => IndonesianRecipe(
        id: map['id'] as int,
        namaResep: map['nama_resep'] as String,
        deskripsi: map['deskripsi'] as String? ?? '',
        bahan: map['bahan'] as String,
        langkahMemasak: map['langkah_memasak'] as String,
        gambar: map['gambar'] as String,
        kategori: map['kategori'] as String? ?? 'Umum',
      );
}

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'makanan.db';
  static const String _tableFavorites = 'favorites';
  static const String _tableSearchHistory = 'search_history';
  static const String _tableCollections = 'collections';
  static const String _tableCollectionRecipes = 'collection_recipes';
  static const String _tableUserRatings = 'user_ratings';
  static const String _tableIndonesianRecipes = 'indonesian_recipes';
  static const String _webStorageKey = 'favorite_recipes';
  static const int _dbVersion = 4;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createNewTables(db);
        }
        if (oldVersion < 3) {
          await _createIndonesianRecipesTable(db);
          await _seedIndonesianRecipes(db);
        }
        if (oldVersion < 4) {
          await _seedIndonesianRecipes(db);
        }
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableFavorites (
        id INTEGER PRIMARY KEY,
        title TEXT,
        image TEXT,
        readyInMinutes INTEGER,
        servings INTEGER,
        ingredients TEXT,
        instructions TEXT,
        ingredient_data TEXT
      )
    ''');
    await _createNewTables(db);
  }

  Future<void> _createNewTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableSearchHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        image_url TEXT DEFAULT '',
        viewed_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableCollections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableCollectionRecipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        recipe_id INTEGER NOT NULL,
        UNIQUE(collection_id, recipe_id),
        FOREIGN KEY (collection_id) REFERENCES $_tableCollections(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableUserRatings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL UNIQUE,
        rating INTEGER NOT NULL,
        rated_at TEXT NOT NULL
      )
    ''');
    await _createIndonesianRecipesTable(db);
    await _seedIndonesianRecipes(db);
  }

  Future<void> _createIndonesianRecipesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableIndonesianRecipes (
        id INTEGER PRIMARY KEY,
        nama_resep TEXT NOT NULL,
        deskripsi TEXT DEFAULT '',
        bahan TEXT NOT NULL,
        langkah_memasak TEXT NOT NULL,
        gambar TEXT NOT NULL,
        kategori TEXT DEFAULT 'Umum'
      )
    ''');
  }

  // ─── INDONESIAN RECIPES ────────────────────────────────────────────────────

  /// Search the local indonesian_recipes table by keyword.
  /// Returns matching recipes as [Recipe] objects.
  /// Returns empty list on web (sqflite not available).
  Future<List<Recipe>> searchIndonesianRecipes(String query) async {
    if (kIsWeb) return [];

    try {
      final db = await database;
      final lowerQuery = query.toLowerCase();

      final maps = await db.query(
        _tableIndonesianRecipes,
        where: 'LOWER(nama_resep) LIKE ? OR LOWER(kategori) LIKE ? OR LOWER(deskripsi) LIKE ? OR LOWER(bahan) LIKE ?',
        whereArgs: ['%$lowerQuery%', '%$lowerQuery%', '%$lowerQuery%', '%$lowerQuery%'],
        orderBy: 'nama_resep ASC',
        limit: 20,
      );

      return maps
          .map((item) => _indonesianRecipeToRecipe(IndonesianRecipe.fromMap(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get an Indonesian recipe by its ID.
  /// Returns null on web or if not found.
  Future<Recipe?> getIndonesianRecipeById(int id) async {
    if (kIsWeb) return null;

    try {
      final db = await database;
      final maps = await db.query(
        _tableIndonesianRecipes,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _indonesianRecipeToRecipe(
        IndonesianRecipe.fromMap(maps.first),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all Indonesian recipes from local database.
  /// Returns empty list on web.
  Future<List<Recipe>> getAllIndonesianRecipes() async {
    if (kIsWeb) return [];

    try {
      final db = await database;
      final maps = await db.query(
        _tableIndonesianRecipes,
        orderBy: 'nama_resep ASC',
      );

      return maps
          .map((item) => _indonesianRecipeToRecipe(IndonesianRecipe.fromMap(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Convert [IndonesianRecipe] to [Recipe] for display.
  Recipe _indonesianRecipeToRecipe(IndonesianRecipe indo) {
    return Recipe(
      id: indo.id,
      title: indo.namaResep,
      image: indo.gambar,
      readyInMinutes: 30,
      servings: 3,
      ingredients: indo.bahan.split('||'),
      instructions: indo.langkahMemasak.split('||'),
    );
  }

  /// Seed the indonesian_recipes table with all curated Indonesian recipes.
  Future<void> _seedIndonesianRecipes(Database db) async {
    // Clear existing data and re-seed to ensure fresh data
    await db.delete(_tableIndonesianRecipes);

    final batch = db.batch();
    for (final recipe in _allIndonesianRecipes) {
      batch.insert(_tableIndonesianRecipes, recipe.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Master list of all curated Indonesian recipes with matching images.
  static const List<IndonesianRecipe> _allIndonesianRecipes = [
    // ═══ NASI GORENG (id: 1-6) ═══
    IndonesianRecipe(
      id: 1,
      namaResep: 'Nasi Goreng Kampung',
      deskripsi: 'Nasi goreng tradisional kampung dengan bumbu uleg dan kencur yang khas.',
      bahan: 'Nasi putih (3 piring)||Telur ayam (2 butir)||Bawang merah (5 siung)||Bawang putih (3 siung)||Cabai rawit merah (5 buah)||Kecap manis (3 sdm)||Garam (1 sdt)||Merica bubuk (1/2 sdt)||Minyak goreng (3 sdm)||Daun bawang (2 batang)',
      langkahMemasak: '1. Siapkan nasi putih yang sudah didinginkan (nasi kemarin lebih baik karena teksturnya lebih kering).||2. Haluskan bawang merah, bawang putih, dan cabai rawit menggunakan ulekan atau blender bumbu.||3. Panaskan minyak goreng di wajan dengan api sedang. Tumis bumbu halus hingga harum dan matang, sekitar 3-4 menit.||4. Dorong bumbu ke pinggir wajan, pecahkan telur di tengah wajan lalu orak-arik hingga matang.||5. Masukkan nasi putih ke dalam wajan. Aduk rata dengan bumbu dan telur hingga semua nasi terlapisi bumbu.||6. Tambahkan kecap manis, garam, dan merica bubuk. Aduk kembali hingga semua bumbu tercampur merata.||7. Koreksi rasa. Tambahkan garam atau kecap sesuai selera.||8. Masukkan irisan daun bawang, aduk sebentar hingga layu.||9. Angkat dan sajikan selagi hangat dengan pelengkap kerupuk dan acar mentimun.',
      gambar: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=800&q=80',
      kategori: 'Nasi',
    ),
    IndonesianRecipe(
      id: 4,
      namaResep: 'Nasi Goreng Seafood',
      deskripsi: 'Nasi goreng dengan campuran udang dan cumi-cumi segar.',
      bahan: 'Nasi putih (2 piring)||Udang kupas (150 gram)||Cumi-cumi (100 gram)||Telur (1 butir)||Bawang putih (4 siung)||Cabai keriting (3 buah)||Saus tiram (2 sdm)||Kecap ikan (1 sdm)||Margarin (2 sdm)||Daun bawang (2 batang)||Garam dan merica (secukupnya)',
      langkahMemasak: '1. Bersihkan udang, buang kulit dan ekornya. Cuci bersih cumi-cumi, potong berbentuk cincin.||2. Haluskan bawang putih dan cabai keriting. Iris tipis daun bawang.||3. Panaskan margarin di wajan dengan api besar. Tumis bumbu halus hingga mengeluarkan aroma harum.||4. Masukkan udang dan cumi-cumi. Tumis cepat selama 2-3 menit hingga seafood matang (jangan terlalu lama agar tidak alot).||5. Dorong seafood ke pinggir wajan. Masukkan telur dan orak-arik hingga matang.||6. Masukkan nasi putih, saus tiram, dan kecap ikan. Aduk rata dengan api besar selama 3-4 menit.||7. Bumbui dengan garam dan merica secukupnya. Aduk kembali hingga tercampur sempurna.||8. Taburkan irisan daun bawang, aduk sebentar, lalu angkat.||9. Sajikan nasi goreng seafood selagi hangat, beri perasan jeruk nipis jika suka.',
      gambar: 'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?auto=format&fit=crop&w=800&q=80',
      kategori: 'Nasi',
    ),
    IndonesianRecipe(
      id: 5,
      namaResep: 'Nasi Goreng Jawa',
      deskripsi: 'Nasi goreng khas Jawa dengan petai dan kencur yang harum.',
      bahan: 'Nasi putih (3 piring)||Tempe (100 gram)||Petai (1 papan)||Telur (1 butir)||Bawang merah (6 siung)||Bawang putih (3 siung)||Kencur (2 ruas jari)||Cabai merah besar (3 buah)||Kecap manis (4 sdm)||Gula jawa (1 sdm, sisir halus)||Garam dan kaldu bubuk (secukupnya)',
      langkahMemasak: '1. Potong tempe berbentuk dadu kecil. Goreng setengah matang, tiriskan.||2. Haluskan bawang merah, bawang putih, kencur, dan cabai merah besar.||3. Kupas petai, belah menjadi dua bagian. Sisihkan.||4. Panaskan minyak di wajan. Tumis bumbu halus hingga harum dan berubah warna, sekitar 5 menit.||5. Masukkan petai, tumis sebentar hingga layu.||6. Masukkan nasi putih, kecap manis, dan gula jawa. Aduk rata dengan api sedang.||7. Tambahkan tempe goreng. Aduk kembali hingga semua bahan tercampur sempurna.||8. Bumbui dengan garam dan kaldu bubuk. Koreksi rasa.||9. Angkat dan sajikan hangat dengan taburan bawang goreng dan kerupuk udang.',
      gambar: 'https://images.unsplash.com/photo-1505253758473-96b7015fcd40?auto=format&fit=crop&w=800&q=80',
      kategori: 'Nasi',
    ),
    IndonesianRecipe(
      id: 6,
      namaResep: 'Nasi Goreng Merah',
      deskripsi: 'Nasi goreng dengan sambal bawang merah dan terasi yang pedas.',
      bahan: 'Nasi putih (2 piring)||Sambal bawang merah (3 sdm)||Bawang merah (4 siung, iris)||Terasi bakar (1 sdt)||Tomat merah (1 buah, potong)||Telur (1 butir)||Minyak goreng (3 sdm)||Garam dan gula (secukupnya)||Timun segar (untuk pelengkap)',
      langkahMemasak: '1. Siapkan nasi putih yang sudah didinginkan. Iris tipis bawang merah dan potong tomat.||2. Panaskan minyak di wajan. Tumis bawang merah iris hingga harum dan sedikit kecoklatan.||3. Masukkan sambal bawang merah dan terasi bakar. Aduk rata hingga terasi tercampur sempurna.||4. Masukkan potongan tomat, masak hingga tomat layu dan mengeluarkan sari merahnya.||5. Dorong bumbu ke pinggir wajan. Masukkan telur dan buat orak-arik.||6. Masukkan nasi putih. Aduk rata dengan bumbu merah hingga semua nasi berwarna merah merata.||7. Tambahkan garam dan gula secukupnya. Aduk kembali dengan api sedang.||8. Koreksi rasa. Pastikan rasa pedas, asin, dan manis seimbang.||9. Sajikan selagi hangat dengan irisan timun segar dan kerupuk.',
      gambar: 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=800&q=80',
      kategori: 'Nasi',
    ),

    // ═══ AYAM (id: 2, 7-10) ═══
    IndonesianRecipe(
      id: 2,
      namaResep: 'Soto Ayam Hangat',
      deskripsi: 'Soto ayam kuah kuning dengan suwiran ayam dan telur rebus.',
      bahan: 'Ayam kampung (1 ekor, potong 4)||Bawang merah (6 siung)||Bawang putih (4 siung)||Kunyit (2 ruas jari, bakar)||Jahe (2 ruas jari)||Sereh (3 batang, memarkan)||Daun jeruk (5 lembar)||Daun bawang (3 batang, iris)||Soun (100 gram, rendam air hangat)||Telur rebus (4 butir)||Minyak goreng (3 sdm)||Garam, merica, dan kaldu bubuk (secukupnya)',
      langkahMemasak: '1. Rebus ayam dalam 1.5 liter air hingga mendidih. Buang busa yang muncul di permukaan.||2. Haluskan bawang merah, bawang putih, kunyit bakar, dan jahe.||3. Panaskan minyak di wajan. Tumis bumbu halus bersama sereh dan daun jeruk hingga harum dan matang, sekitar 7 menit.||4. Masukkan bumbu tumis ke dalam rebusan ayam. Aduk rata.||5. Masak dengan api sedang hingga ayam empuk dan bumbu meresap, sekitar 25 menit.||6. Angkat ayam dari kuah, goreng sebentar hingga kecoklatan, lalu suwir-suwir dagingnya.||7. Siapkan mangkuk saji: tata soun, suwiran ayam, telur rebus yang dibelah, dan irisan daun bawang.||8. Siram dengan kuah soto panas. Taburi bawang goreng di atasnya.||9. Sajikan dengan nasi putih hangat, sambal, dan perasan jeruk nipis.',
      gambar: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=800&q=80',
      kategori: 'Ayam',
    ),
    IndonesianRecipe(
      id: 7,
      namaResep: 'Ayam Goreng Mentega',
      deskripsi: 'Ayam goreng dengan saus mentega yang gurih dan manis.',
      bahan: 'Ayam (500 gram, potong kecil)||Mentega (3 sdm)||Bawang putih (4 siung, cincang)||Bawang bombai (1/2 buah, iris)||Kecap inggris (2 sdm)||Kecap manis (2 sdm)||Saus tiram (1 sdm)||Gula pasir (1 sdt)||Merica bubuk (1/2 sdt)||Daun bawang (2 batang, iris)||Minyak goreng (secukupnya)',
      langkahMemasak: '1. Lumuri potongan ayam dengan sedikit garam dan merica. Diamkan 15 menit.||2. Goreng ayam dalam minyak panas hingga matang dan kecoklatan. Angkat dan tiriskan.||3. Panaskan mentega di wajan bersih dengan api sedang.||4. Tumis bawang putih cincang hingga harum, lalu masukkan bawang bombai. Tumis hingga layu.||5. Masukkan kecap inggris, kecap manis, saus tiram, gula pasir, dan merica. Aduk rata.||6. Masak saus hingga mengental dan berbuih, sekitar 2 menit.||7. Masukkan ayam goreng ke dalam saus mentega. Aduk cepat hingga semua potongan ayam terlapisi saus.||8. Taburkan irisan daun bawang, aduk sebentar, lalu angkat.||9. Sajikan ayam goreng mentega selagi hangat dengan nasi putih.',
      gambar: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=800&q=80',
      kategori: 'Ayam',
    ),
    IndonesianRecipe(
      id: 8,
      namaResep: 'Opor Ayam',
      deskripsi: 'Ayam kuah santan kuning nan gurih, hidangan khas Lebaran.',
      bahan: 'Ayam (1 ekor, potong 8 bagian)||Santan kental (500 ml)||Santan encer (500 ml)||Bawang merah (8 siung)||Bawang putih (5 siung)||Kemiri (4 butir, sangrai)||Ketumbar bubuk (1 sdm)||Jahe (2 ruas jari)||Lengkuas (3 ruas jari, memarkan)||Daun salam (4 lembar)||Serai (3 batang, memarkan)||Gula merah (1 sdm)||Garam dan penyedap (secukupnya)',
      langkahMemasak: '1. Cuci bersih potongan ayam. Lumuri air jeruk nipis dan garam, diamkan 15 menit lalu bilas.||2. Haluskan bawang merah, bawang putih, kemiri sangrai, jahe, dan ketumbar.||3. Panaskan sedikit minyak. Tumis bumbu halus bersama lengkuas, daun salam, dan serai hingga harum dan matang.||4. Masukkan potongan ayam. Aduk rata hingga ayam berubah warna.||5. Tuangkan santan encer. Masak api sedang hingga ayam setengah matang, sekitar 15 menit.||6. Masukkan gula merah, garam, dan penyedap. Aduk rata.||7. Tuangkan santan kental. Aduk perlahan agar santan tidak pecah.||8. Masak api kecil hingga ayam empuk dan kuah mengental, 20-25 menit. Aduk sesekali.||9. Koreksi rasa, angkat. Sajikan opor ayam dengan ketupat atau nasi hangat dan taburan bawang goreng.',
      gambar: 'https://images.unsplash.com/photo-1603895544018-0e8f6af6c5dc?auto=format&fit=crop&w=800&q=80',
      kategori: 'Ayam',
    ),
    IndonesianRecipe(
      id: 9,
      namaResep: 'Ayam Bakar Taliwang',
      deskripsi: 'Ayam bakar pedas khas Lombok dengan bumbu cabai dan terasi.',
      bahan: 'Ayam kampung (1 ekor, belah tengah)||Cabai keriting merah (10 buah)||Cabai rawit (8 buah)||Bawang merah (8 siung)||Bawang putih (4 siung)||Tomat merah (2 buah)||Terasi bakar (1 sdt)||Gula merah (2 sdm)||Kecap manis (3 sdm)||Minyak goreng (4 sdm)||Garam (secukupnya)',
      langkahMemasak: '1. Bersihkan ayam, belah di bagian dada. Lumuri air jeruk nipis dan garam, diamkan 15 menit.||2. Rebus cabai keriting, cabai rawit, dan tomat hingga layu. Tiriskan.||3. Haluskan cabai, tomat, bawang merah, bawang putih, dan terasi bakar.||4. Panaskan minyak. Tumis bumbu halus hingga harum dan matang, sekitar 10 menit.||5. Masukkan gula merah, kecap manis, dan garam. Ambil sebagian bumbu untuk olesan.||6. Masukkan ayam ke dalam sisa bumbu. Lumuri merata, diamkan 20 menit.||7. Bakar ayam di atas bara atau grill pan sambil diolesi bumbu.||8. Lanjutkan membakar hingga ayam kecoklatan dan harum.||9. Sajikan dengan nasi hangat, sambal tomat segar, dan lalapan.',
      gambar: 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=800&q=80',
      kategori: 'Ayam',
    ),
    IndonesianRecipe(
      id: 10,
      namaResep: 'Ayam Suwir Pedas',
      deskripsi: 'Suwiran ayam dengan bumbu pedas dan aroma jeruk limau.',
      bahan: 'Dada ayam (300 gram)||Cabai rawit merah (6 buah)||Cabai keriting (4 buah)||Bawang merah (5 siung)||Bawang putih (3 siung)||Serai (2 batang)||Daun jeruk (4 lembar)||Kecap manis (2 sdm)||Gula merah (1 sdm)||Minyak kelapa (2 sdm)||Garam dan kaldu bubuk||Jeruk limau (1 buah)',
      langkahMemasak: '1. Rebus dada ayam hingga matang, tiriskan, lalu suwir-suwir.||2. Haluskan cabai, bawang merah, dan bawang putih.||3. Panaskan minyak kelapa, tumis bumbu halus, serai, dan daun jeruk hingga harum.||4. Masukkan ayam suwir, aduk rata.||5. Tambahkan kecap manis, gula merah, garam, dan kaldu bubuk.||6. Masak api kecil hingga bumbu meresap, 10-15 menit.||7. Peraskan jeruk limau, aduk sebentar lalu angkat.||8. Koreksi rasa.||9. Sajikan dengan nasi hangat dan lalapan segar.',
      gambar: 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?auto=format&fit=crop&w=800&q=80',
      kategori: 'Ayam',
    ),

    // ═══ MIE (id: 11-14) ═══
    IndonesianRecipe(
      id: 11,
      namaResep: 'Mie Goreng Jawa',
      deskripsi: 'Mie goreng khas Jawa dengan sayuran segar dan bumbu kecap.',
      bahan: 'Mie telur basah (250 gram)||Kol (100 gram)||Sawi hijau (2 batang)||Wortel (1 buah)||Telur (1 butir)||Bawang merah (4 siung)||Bawang putih (2 siung)||Kecap manis (3 sdm)||Saus sambal (1 sdm)||Merica bubuk||Minyak goreng||Bawang goreng',
      langkahMemasak: '1. Rebus mie telur hingga setengah matang, tiriskan, beri sedikit minyak.||2. Haluskan bawang merah dan bawang putih. Iris sayuran.||3. Panaskan minyak, tumis bumbu halus hingga harum.||4. Masukkan telur, orak-arik.||5. Masukkan sayuran, tumis hingga layu.||6. Masukkan mie, aduk rata.||7. Tambahkan kecap manis, saus sambal, merica. Aduk hingga terlapisi.||8. Koreksi rasa, masak 3-4 menit.||9. Sajikan hangat dengan taburan bawang goreng.',
      gambar: 'https://images.unsplash.com/photo-1555126634-323283e090fa?auto=format&fit=crop&w=800&q=80',
      kategori: 'Mie',
    ),
    IndonesianRecipe(
      id: 12,
      namaResep: 'Mie Ayam Bakso',
      deskripsi: 'Mie ayam lengkap dengan bakso sapi dan topping ayam cincang.',
      bahan: 'Mie kuning basah (300 gram)||Dada ayam (200 gram)||Bakso sapi (10 butir)||Sawi hijau (3 batang)||Bawang putih (5 siung)||Kecap manis (3 sdm)||Kecap asin (1 sdm)||Minyak wijen (1 sdm)||Daun bawang||Kaldu ayam bubuk||Merica bubuk',
      langkahMemasak: '1. Rebus bakso hingga matang dan mengapung. Sisihkan.||2. Cincang bawang putih, tumis dengan minyak goreng dan minyak wijen.||3. Masukkan ayam cincang, masak hingga matang.||4. Tambahkan kecap manis, kecap asin, kaldu, merica. Sisihkan.||5. Rebus mie kuning hingga matang. Rebus sawi sebentar.||6. Siapkan mangkuk: campur minyak bawang, kecap asin, merica.||7. Masukkan mie, aduk rata dengan bumbu dasar.||8. Beri topping ayam cincang, bakso, sawi, daun bawang.||9. Siram dengan kuah kaldu bakso panas. Sajikan dengan sambal.',
      gambar: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80',
      kategori: 'Mie',
    ),
    IndonesianRecipe(
      id: 13,
      namaResep: 'Mie Rebus Aceh',
      deskripsi: 'Mie rebus khas Aceh dengan kuah kari dan daging sapi.',
      bahan: 'Mie telur basah (250 gram)||Daging sapi (150 gram)||Bawang merah (6 siung)||Bawang putih (4 siung)||Cabai merah (5 buah)||Kepala udang kering (1 sdm)||Jinten||Kari bubuk (1 sdm)||Santan instan (100 ml)||Toge (100 gram)||Daun bawang||Garam dan gula',
      langkahMemasak: '1. Rebus mie hingga setengah matang, tiriskan.||2. Haluskan bawang merah, bawang putih, cabai, dan kepala udang.||3. Tumis bumbu halus dengan jinten dan kari hingga harum.||4. Masukkan daging sapi, masak hingga berubah warna.||5. Tuang santan, aduk rata.||6. Masukkan mie dan toge, aduk rata.||7. Bumbui garam dan gula. Koreksi rasa.||8. Masak hingga matang dan kuah meresap.||9. Sajikan hangat dengan taburan daun bawang dan bawang goreng.',
      gambar: 'https://images.unsplash.com/photo-1626804475359-6a4c2e8c3a6a?auto=format&fit=crop&w=800&q=80',
      kategori: 'Mie',
    ),

    // ═══ DAGING (id: 15-16, 19-20, 23, 32-36) ═══
    IndonesianRecipe(
      id: 15,
      namaResep: 'Rendang Sapi',
      deskripsi: 'Rendang daging sapi khas Padang yang empuk dan kaya rempah.',
      bahan: 'Daging sapi (1 kg)||Santan kental (1 liter)||Bawang merah (12 siung)||Bawang putih (6 siung)||Cabai merah besar (8 buah)||Cabai rawit (5 buah)||Lengkuas (5 ruas)||Sereh (4 batang)||Daun jeruk (6 lembar)||Daun kunyit (2 lembar)||Ketumbar bubuk (2 sdm)||Jinten bubuk (1 sdt)||Garam dan gula merah',
      langkahMemasak: '1. Potong daging sapi melawan serat 4x4 cm. Cuci bersih.||2. Haluskan bawang merah, bawang putih, dan cabai.||3. Campur bumbu halus dengan ketumbar dan jinten.||4. Tuang santan ke wajan besar. Masukkan bumbu, lengkuas, sereh, daun jeruk, daun kunyit.||5. Masak santan sambil diaduk hingga mendidih.||6. Masukkan daging. Kecilkan api.||7. Masak api kecil 1.5-2 jam sambil sesekali diaduk.||8. Tambahkan garam dan gula merah. Masak hingga kuah habis dan bumbu menyelimuti daging.||9. Koreksi rasa. Sajikan dengan nasi hangat.',
      gambar: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=800&q=80',
      kategori: 'Daging',
    ),
    IndonesianRecipe(
      id: 16,
      namaResep: 'Sate Ayam Madura',
      deskripsi: 'Sate ayam dengan bumbu kacang khas Madura.',
      bahan: 'Dada ayam (500 gram)||Tusuk sate (20 batang)||Kacang tanah (200 gram)||Bawang putih (4 siung)||Cabai merah (3 buah)||Kecap manis (5 sdm)||Gula merah (2 sdm)||Air asam jawa (2 sdm)||Daun jeruk (3 lembar)||Garam||Minyak goreng',
      langkahMemasak: '1. Potong ayam dadu 2x2 cm.||2. Marinasi ayam dengan 2 sdm kecap manis dan air asam. Diamkan 20 menit.||3. Haluskan kacang tanah goreng, bawang putih, dan cabai.||4. Tumis bumbu kacang dengan daun jeruk, gula merah, kecap, air asam, garam.||5. Beri sedikit air, masak hingga mengental. Sisihkan.||6. Tusuk ayam ke tusuk sate.||7. Bakar sate di atas bara atau grill, olesi bumbu kacang dan kecap.||8. Balik hingga matang merata, 8-10 menit.||9. Sajikan dengan siraman bumbu kacang, kecap, lontong, dan acar.',
      gambar: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
      kategori: 'Daging',
    ),
    IndonesianRecipe(
      id: 19,
      namaResep: 'Rawon Surabaya',
      deskripsi: 'Sup daging sapi hitam khas Surabaya dengan kluwek.',
      bahan: 'Daging sapi sandung lamur (500 gram)||Kluwek (5 butir)||Bawang merah (8 siung)||Bawang putih (5 siung)||Serai (3 batang)||Lengkuas (2 ruas)||Daun jeruk (5 lembar)||Daun salam (3 lembar)||Ketumbar||Kunyit (1 ruas)||Jahe (1 ruas)||Minyak goreng||Garam dan gula||Telur asin||Toge pendek||Sambal terasi',
      langkahMemasak: '1. Rebus daging sapi dalam 2 liter air hingga empuk, 45 menit. Buang busa.||2. Sangrai kluwek hingga hitam, haluskan bersama bawang, kunyit, jahe, ketumbar.||3. Tumis bumbu halus dengan serai, lengkuas, daun jeruk, daun salam.||4. Masukkan ke rebusan daging. Aduk rata.||5. Masak api kecil hingga kuah hitam pekat, 30-40 menit.||6. Bumbui garam dan gula. Koreksi rasa.||7. Potong daging kecil, masukkan kembali ke kuah.||8. Siapkan mangkuk, tuang rawon panas. Taburi bawang goreng.||9. Sajikan dengan nasi, telur asin, toge, sambal terasi, kerupuk.',
      gambar: 'https://images.unsplash.com/photo-1603899122634-f086ca5f5ddd?auto=format&fit=crop&w=800&q=80',
      kategori: 'Daging',
    ),

    // ═══ SAYUR & LAINNYA (id: 17-18, 21-23) ═══
    IndonesianRecipe(
      id: 17,
      namaResep: 'Gado-Gado Jakarta',
      deskripsi: 'Sayuran rebus dengan siraman bumbu kacang khas Betawi.',
      bahan: 'Tahu putih (3 buah)||Tempe (150 gram)||Kentang (3 buah)||Telur rebus (3 butir)||Sawi hijau||Toge (100 gram)||Kacang panjang||Kacang tanah goreng (200 gram)||Cabai rawit (3 buah)||Bawang putih (3 siung)||Terasi bakar||Gula merah (2 sdm)||Air asam jawa||Kerupuk',
      langkahMemasak: '1. Rebus kentang hingga empuk, potong dadu.||2. Goreng tahu dan tempe, potong dadu.||3. Rebus sawi dan kacang panjang. Siram toge air panas.||4. Tata sayuran di piring.||5. Haluskan kacang tanah, cabai, bawang putih, terasi.||6. Tambahkan gula merah, air asam, air hangat. Aduk rata.||7. Bumbui garam. Koreksi rasa.||8. Siram bumbu kacang di atas sayuran.||9. Beri telur rebus, taburi bawang goreng, sajikan dengan kerupuk.',
      gambar: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      kategori: 'Sayur',
    ),
    IndonesianRecipe(
      id: 18,
      namaResep: 'Bakso Sapi Rumahan',
      deskripsi: 'Bakso sapi homemade dengan kuah kaldu gurih.',
      bahan: 'Daging sapi giling (500 gram)||Tepung tapioka (100 gram)||Bawang putih (6 siung)||Putih telur (2 butir)||Es batu (100 gram)||Garam (2 sdt)||Merica||Kaldu sapi bubuk||Baking powder||Mie kuning (300 gram)||Sawi hijau||Daun bawang||Bawang goreng',
      langkahMemasak: '1. Campur daging sapi giling, bawang putih, putih telur, es batu dalam food processor.||2. Giling hingga membentuk pasta lengket, 10 menit.||3. Tambahkan tapioka, garam, merica, kaldu, baking powder.||4. Giling hingga kalis. Istirahatkan 15 menit.||5. Didihkan air, kecilkan api.||6. Bentuk bakso bulat, masukkan ke air hangat.||7. Setelah mengapung, rebus 5 menit. Angkat.||8. Siapkan mangkuk: mie, sawi, bakso. Siram kuah kaldu panas.||9. Taburi daun bawang, bawang goreng. Sajikan dengan sambal dan kecap.',
      gambar: 'https://images.unsplash.com/photo-1559847844-5315695dadae?auto=format&fit=crop&w=800&q=80',
      kategori: 'Mie',
    ),
    IndonesianRecipe(
      id: 21,
      namaResep: 'Papeda & Ikan Kuah Kuning',
      deskripsi: 'Papeda sagu dengan ikan kuah kuning khas Papua.',
      bahan: 'Tepung sagu (250 gram)||Air panas (750 ml)||Garam||Ikan kakap (600 gram)||Jeruk nipis||Bawang merah (6 siung)||Bawang putih (4 siung)||Cabai merah besar (5 buah)||Kunyit||Jahe||Serai||Daun jeruk||Daun kemangi||Tomat hijau||Minyak goreng||Garam dan gula',
      langkahMemasak: '1. Larutkan sagu dengan 250 ml air dingin.||2. Didihkan 500 ml air, tuang larutan sagu sambil diaduk cepat.||3. Aduk hingga mengental dan bening. Sisihkan.||4. Lumuri ikan dengan air jeruk nipis dan garam. Diamkan.||5. Haluskan bawang, cabai, kunyit.||6. Tumis bumbu halus dengan jahe, serai, daun jeruk.||7. Tuang 500 ml air, masak hingga mendidih.||8. Masukkan ikan, masak 10-15 menit.||9. Bumbui, masukkan tomat dan kemangi. Sajikan dengan papeda.',
      gambar: 'https://images.unsplash.com/photo-1553621046-fd5f4c64e2ba?auto=format&fit=crop&w=800&q=80',
      kategori: 'Ikan',
    ),
    IndonesianRecipe(
      id: 22,
      namaResep: 'Pempek Palembang',
      deskripsi: 'Pempek ikan tenggiri khas Palembang dengan cuko.',
      bahan: 'Ikan tenggiri giling (500 gram)||Tepung sagu (250 gram)||Tepung terigu (50 gram)||Telur (2 butir)||Air es (200 ml)||Garam, gula, kaldu bubuk||Minyak goreng||Timun||Mie kuning||Gula merah (250 gram)||Cabai rawit||Bawang putih||Ebi kering||Cuka',
      langkahMemasak: '1. Campur ikan tenggiri dengan garam, gula, kaldu. Aduk hingga mengembang.||2. Masukkan telur dan air es, uleni hingga kalis.||3. Campur sagu dan terigu ke adonan. Aduk rata.||4. Bentuk adonan: kapal selam, lenjer, adaan.||5. Rebus pempek hingga mengapung. Tiriskan.||6. Buat cuko: rebus gula merah dengan air, saring. Tambahkan cabai, bawang, ebi, garam, cuka.||7. Goreng pempek hingga kecoklatan.||8. Potong pempek di piring.||9. Siram cuko, tambahkan mie, timun, ebi goreng.',
      gambar: 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?auto=format&fit=crop&w=800&q=80',
      kategori: 'Ikan',
    ),
    IndonesianRecipe(
      id: 23,
      namaResep: 'Sop Buntut Bakar',
      deskripsi: 'Sop buntut sapi dengan buntut bakar yang wangi.',
      bahan: 'Buntut sapi (1 kg)||Air (2.5 liter)||Bawang merah||Bawang putih||Bawang bombai||Cengkeh||Kapulaga||Kembang lawang||Kayu manis||Pala||Jahe||Lengkuas||Daun bawang||Seledri||Tomat||Wortel||Kentang||Garam, merica, kaldu||Jeruk nipis||Kecap manis',
      langkahMemasak: '1. Cuci buntut, rebus 10 menit, buang airnya.||2. Rebus lagi dengan air baru, jahe, bawang putih hingga empuk. Sisihkan buntut.||3. Saring kaldu.||4. Tumis bawang merah, bawang putih, bombai.||5. Masukkan cengkeh, kapulaga, kembang lawang, kayu manis, pala.||6. Tuang kaldu, masukkan lengkuas, seledri, garam, merica, kaldu.||7. Masukkan wortel, kentang. Masak hingga empuk.||8. Lumuri buntut dengan kecap, bakar hingga kecoklatan.||9. Sajikan buntut bakar di atas kuah sop. Taburi daun bawang, tomat, bawang goreng.',
      gambar: 'https://images.unsplash.com/photo-1603048588665-791ca8aea617?auto=format&fit=crop&w=800&q=80',
      kategori: 'Daging',
    ),

    // ═══ ADDITIONAL POPULAR RECIPES ═══
    IndonesianRecipe(
      id: 24,
      namaResep: 'Nasi Uduk',
      deskripsi: 'Nasi gurih khas Betawi yang dimasak dengan santan dan rempah.',
      bahan: 'Beras (500 gram)||Santan (500 ml)||Serai (3 batang)||Daun salam (4 lembar)||Daun pandan (2 lembar)||Lengkuas (3 ruas)||Bawang merah (6 siung, iris)||Garam (1 sdm)||Minyak goreng',
      langkahMemasak: '1. Cuci bersih beras, tiriskan.||2. Campur santan dengan serai, daun salam, daun pandan, lengkuas, bawang merah iris, garam.||3. Masukkan beras ke dalam campuran santan.||4. Masak hingga santan terserap, aduk sesekali.||5. Kukus nasi hingga matang sempurna, 30 menit.||6. Sajikan nasi uduk hangat dengan lauk pelengkap: ayam goreng, telur balado, sambal goreng kentang.||7. Taburi bawang goreng di atas nasi.||8. Sajikan dengan emping dan acar timun.||9. Nikmati selagi hangat.',
      gambar: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=800&q=80',
      kategori: 'Nasi',
    ),
    IndonesianRecipe(
      id: 25,
      namaResep: 'Nasi Kuning',
      deskripsi: 'Nasi kuning khas Indonesia dengan kunyit dan santan.',
      bahan: 'Beras (500 gram)||Santan (400 ml)||Kunyit (3 ruas, parut)||Serai (3 batang)||Daun salam (3 lembar)||Daun pandan (2 lembar)||Garam (1 sdm)||Bawang merah (5 siung)||Bawang putih (3 siung)',
      langkahMemasak: '1. Cuci bersih beras.||2. Campur santan dengan parutan kunyit, serai, daun salam, daun pandan, garam.||3. Tumis bawang merah dan bawang putih hingga harum, masukkan ke campuran santan.||4. Masukkan beras ke dalam campuran santan.||5. Masak hingga santan meresap.||6. Kukus nasi selama 30-40 menit hingga matang.||7. Aduk nasi agar warna kuning merata.||8. Sajikan dengan lauk pelengkap: ayam goreng, sambal, dan urap.||9. Taburi bawang goreng di atasnya.',
      gambar: 'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?auto=format&fit=crop&w=800&q=80',
      kategori: 'Nasi',
    ),
    IndonesianRecipe(
      id: 28,
      namaResep: 'Ayam Penyet',
      deskripsi: 'Ayam goreng yang dipenyet dengan sambal terasi pedas.',
      bahan: 'Ayam kampung (1 ekor)||Bawang putih (5 siung)||Kunyit (2 ruas)||Ketumbar (1 sdm)||Garam||Cabai rawit merah (15 buah)||Cabai merah besar (3 buah)||Terasi bakar (1 sdt)||Tomat (1 buah)||Gula merah (1 sdm)||Minyak goreng||Timun||Daun kemangi',
      langkahMemasak: '1. Rebus ayam dengan bumbu halus (bawang putih, kunyit, ketumbar, garam) hingga empuk.||2. Goreng ayam hingga kecoklatan dan renyah. Angkat.||3. Buat sambal: goreng cabai, tomat, dan terasi.||4. Haluskan cabai, tomat, terasi, gula merah, garam.||5. Taruh ayam goreng di atas sambal.||6. Penyet ayam dengan ulekan hingga hancur dan tercampur sambal.||7. Tambahkan perasan jeruk nipis.||8. Sajikan dengan nasi hangat.||9. Beri pelengkap timun, kemangi, dan tahu/tempe goreng.',
      gambar: 'https://images.unsplash.com/photo-1603366445781-2fedc492e0a4?auto=format&fit=crop&w=800&q=80',
      kategori: 'Ayam',
    ),
    IndonesianRecipe(
      id: 29,
      namaResep: 'Ayam Pop',
      deskripsi: 'Ayam goreng khas Padang yang direbus dengan air kelapa.',
      bahan: 'Ayam (1 ekor)||Air kelapa (500 ml)||Bawang putih (6 siung)||Jahe (3 ruas)||Lengkuas (3 ruas)||Daun salam (3 lembar)||Serai (2 batang)||Garam (1 sdm)||Minyak goreng',
      langkahMemasak: '1. Cuci bersih ayam, potong 4 bagian.||2. Haluskan bawang putih, jahe, lengkuas.||3. Rebus ayam dengan air kelapa, bumbu halus, daun salam, serai dan garam.||4. Masak hingga ayam empuk dan air menyusut.||5. Angkat ayam, tiriskan.||6. Goreng ayam sebentar dalam minyak panas hingga sedikit kecoklatan (jangan terlalu kering).||7. Sajikan ayam pop dengan nasi hangat dan sambal ijo.||8. Beri lalapan mentimun dan daun kemangi.||9. Siram sisa kuah rebusan di atas nasi jika suka.',
      gambar: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=800&q=80',
      kategori: 'Ayam',
    ),
    IndonesianRecipe(
      id: 30,
      namaResep: 'Ayam Rica-Rica',
      deskripsi: 'Ayam pedas khas Manado dengan cabai dan daun kemangi.',
      bahan: 'Ayam (1 ekor, potong 8)||Cabai rawit (15 buah)||Cabai keriting (10 buah)||Bawang merah (8 siung)||Bawang putih (5 siung)||Jahe (3 ruas)||Kunyit (2 ruas)||Tomato (2 buah)||Daun kemangi (2 ikat)||Serai (3 batang)||Daun jeruk (6 lembar)||Garam, gula, kaldu bubuk||Minyak goreng',
      langkahMemasak: '1. Cuci bersih ayam, lumuri dengan jeruk nipis dan garam.||2. Haluskan cabai, bawang merah, bawang putih, jahe, kunyit, tomat.||3. Panaskan minyak, tumis bumbu halus hingga harum.||4. Masukkan serai dan daun jeruk, aduk rata.||5. Masukkan potongan ayam, aduk hingga berubah warna.||6. Tambahkan sedikit air, masak hingga ayam empuk.||7. Bumbui dengan garam, gula, kaldu bubuk.||8. Masukkan daun kemangi, aduk sebentar hingga layu.||9. Angkat dan sajikan dengan nasi hangat.',
      gambar: 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=800&q=80',
      kategori: 'Ayam',
    ),

    // ═══ DAGING BARU (id: 32-36) ═══
    IndonesianRecipe(
      id: 32,
      namaResep: 'Semur Daging',
      deskripsi: 'Daging sapi rebus dengan kecap manis dan rempah, manis gurih.',
      bahan: 'Daging sapi (500 gram)||Kecap manis (5 sdm)||Bawang merah (8 siung)||Bawang putih (5 siung)||Bawang bombai (1 buah)||Jahe (3 ruas)||Pala bubuk (1/2 sdt)||Cengkeh (4 butir)||Kayu manis (5 cm)||Tomat (2 buah)||Garam, merica, kaldu bubuk||Minyak goreng||Air (500 ml)',
      langkahMemasak: '1. Potong daging sapi 3x3 cm. Rebus hingga setengah empuk.||2. Haluskan bawang merah, bawang putih, jahe.||3. Panaskan minyak, tumis bumbu halus dan bawang bombai hingga harum.||4. Masukkan pala, cengkeh, kayu manis. Aduk rata.||5. Masukkan daging, aduk hingga berubah warna.||6. Tuang air dan kecap manis. Masak api kecil.||7. Masukkan tomat, garam, merica, kaldu bubuk.||8. Masak hingga daging empuk dan kuah mengental, 45 menit.||9. Sajikan semur dengan nasi hangat dan taburan bawang goreng.',
      gambar: 'https://images.unsplash.com/photo-1603048588665-791ca8aea617?auto=format&fit=crop&w=800&q=80',
      kategori: 'Daging',
    ),
    IndonesianRecipe(
      id: 34,
      namaResep: 'Tongseng Sapi',
      deskripsi: 'Tumis daging sapi dengan kol dan kuah kecap pedas.',
      bahan: 'Daging sapi (400 gram)||Kol (200 gram, iris)||Tomat (2 buah, potong)||Daun bawang (3 batang)||Kecap manis (4 sdm)||Bawang merah (6 siung)||Bawang putih (4 siung)||Cabai rawit (10 buah)||Cabai merah (5 buah)||Serai (2 batang)||Daun jeruk (3 lembar)||Garam, merica, kaldu bubuk||Minyak goreng||Air (300 ml)',
      langkahMemasak: '1. Potong daging sapi tipis-tipis melawan serat.||2. Haluskan bawang merah, bawang putih, cabai.||3. Panaskan minyak, tumis bumbu halus, serai, dan daun jeruk hingga harum.||4. Masukkan daging, aduk hingga berubah warna.||5. Tuang air dan kecap manis. Masak hingga daging empuk.||6. Masukkan kol, tomat, aduk rata.||7. Bumbui garam, merica, kaldu bubuk.||8. Masukkan irisan daun bawang, aduk sebentar.||9. Sajikan tongseng panas dengan nasi putih.',
      gambar: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
      kategori: 'Daging',
    ),
    IndonesianRecipe(
      id: 35,
      namaResep: 'Sate Kambing',
      deskripsi: 'Sate kambing muda dengan bumbu kecap dan irisan cabai.',
      bahan: 'Daging kambing (500 gram)||Tusuk sate (20 batang)||Kecap manis (5 sdm)||Bawang merah (8 siung, iris)||Cabai rawit (10 buah, iris)||Tomat (3 buah, potong)||Jahe (3 ruas)||Ketumbar (1 sdm)||Garam||Minyak goreng||Jeruk nipis',
      langkahMemasak: '1. Potong daging kambing dadu 2x2 cm.||2. Haluskan jahe, ketumbar, garam, lumuri ke daging.||3. Tusuk daging ke tusuk sate.||4. Campur kecap manis dengan sedikit minyak untuk olesan.||5. Bakar sate di atas bara api sambil dioles kecap.||6. Balik hingga matang merata, 10-12 menit.||7. Sajikan sate dengan irisan bawang merah, cabai rawit, tomat.||8. Siram dengan kecap manis tambahan.||9. Beri perasan jeruk nipis dan sajikan dengan lontong.',
      gambar: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      kategori: 'Daging',
    ),
    IndonesianRecipe(
      id: 36,
      namaResep: 'Gulai Sapi',
      deskripsi: 'Gulai daging sapi khas Padang dengan kuah santan kuning.',
      bahan: 'Daging sapi (500 gram)||Santan (500 ml)||Bawang merah (8 siung)||Bawang putih (5 siung)||Cabai merah (8 buah)||Kunyit (2 ruas)||Jahe (3 ruas)||Lengkuas (3 ruas, memarkan)||Serai (3 batang)||Daun jeruk (4 lembar)||Daun salam (3 lembar)||Ketumbar (1 sdm)||Garam, gula||Minyak goreng',
      langkahMemasak: '1. Potong daging sapi 3x3 cm.||2. Haluskan bawang merah, bawang putih, cabai, kunyit, jahe, ketumbar.||3. Panaskan minyak, tumis bumbu halus bersama lengkuas, serai, daun jeruk, daun salam.||4. Masukkan daging, aduk hingga berubah warna.||5. Tuang santan encer, masak api kecil.||6. Masak hingga daging empuk, 40-50 menit.||7. Tuang santan kental, aduk perlahan.||8. Bumbui garam dan gula. Koreksi rasa.||9. Sajikan gulai dengan nasi hangat atau ketupat.',
      gambar: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=800&q=80',
      kategori: 'Daging',
    ),
    IndonesianRecipe(
      id: 39,
      namaResep: 'Kwetiau Goreng',
      deskripsi: 'Kwetiau goreng khas Pontianak dengan seafood.',
      bahan: 'Kwetiau basah (400 gram)||Udang (150 gram)||Bakso ikan (10 butir)||Telur (2 butir)||Kol (100 gram, iris)||Bawang putih (5 siung, cincang)||Kecap asin (2 sdm)||Kecap manis (2 sdm)||Saus tiram (1 sdm)||Merica||Minyak goreng||Daun bawang (3 batang)',
      langkahMemasak: '1. Siram kwetiau dengan air panas, tiriskan.||2. Panaskan minyak, tumis bawang putih hingga harum.||3. Masukkan telur, orak-arik.||4. Masukkan udang dan bakso, masak hingga matang.||5. Masukkan kol, aduk hingga layu.||6. Masukkan kwetiau, aduk rata.||7. Tambahkan kecap asin, kecap manis, saus tiram, merica.||8. Aduk hingga semua terlapisi bumbu, 3 menit.||9. Sajikan dengan taburan daun bawang dan bawang goreng.',
      gambar: 'https://images.unsplash.com/photo-1555126634-323283e090fa?auto=format&fit=crop&w=800&q=80',
      kategori: 'Mie',
    ),

    // ═══ SAYUR, LAUK & JAJANAN (id: 40-68) ═══
    IndonesianRecipe(
      id: 40,
      namaResep: 'Sayur Asem',
      deskripsi: 'Sayur asam segar dengan berbagai macam sayuran.',
      bahan: 'Kacang tanah||Kacang panjang||Melinjo||Jagung manis||Daun melinjo||Labu siam||Asam jawa||Bawang merah||Bawang putih||Cabai merah||Garam||Gula merah||Kaldu bubuk||Air',
      langkahMemasak: '1. Didihkan air, masukkan bawang merah, bawang putih, cabai yang sudah diiris.||2. Masukkan kacang tanah dan jagung, rebus hingga empuk.||3. Masukkan kacang panjang dan labu siam.||4. Masukkan melinjo dan daun melinjo.||5. Larutkan asam jawa dengan air, saring, masukkan ke sayur.||6. Bumbui garam, gula merah, kaldu bubuk.||7. Koreksi rasa asam-manis-gurih.||8. Masak hingga semua sayuran matang.||9. Sajikan hangat dengan nasi, sambal, dan lauk goreng.',
      gambar: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=800&q=80',
      kategori: 'Sayur',
    ),
    IndonesianRecipe(
      id: 43,
      namaResep: 'Karedok',
      deskripsi: 'Sayuran mentah dengan bumbu kacang khas Sunda.',
      bahan: 'Kacang panjang (5 batang)||Toge (100 gram)||Kol (100 gram)||Ketimun (1 buah)||Daun kemangi (1 ikat)||Terong (1 buah)||Kacang tanah goreng (200 gram)||Cabai rawit (5 buah)||Bawang putih (3 siung)||Kencur (2 ruas)||Gula merah (2 sdm)||Asam jawa||Garam',
      langkahMemasak: '1. Potong kecil-kecil kacang panjang, kol, ketimun, terong.||2. Seduh toge dengan air panas, tiriskan.||3. Petiki daun kemangi.||4. Haluskan kacang tanah, cabai, bawang putih, kencur, gula merah, asam jawa, garam.||5. Tambahkan sedikit air hangat, aduk hingga kekentalan yang diinginkan.||6. Campur bumbu kacang dengan semua sayuran mentah.||7. Aduk rata hingga semua sayuran terlapisi bumbu.||8. Sajikan karedok dengan taburan bawang goreng.||9. Tambahkan kerupuk sebagai pelengkap.',
      gambar: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      kategori: 'Sayur',
    ),
    IndonesianRecipe(
      id: 56,
      namaResep: 'Tempe Mendoan',
      deskripsi: 'Tempe goreng tepung setengah matang khas Banyumas.',
      bahan: 'Tempe (1 papan, iris tipis)||Tepung terigu (200 gram)||Tepung beras (50 gram)||Daun bawang (3 batang, iris)||Bawang putih (4 siung, haluskan)||Ketumbar (1 sdt)||Kunyit bubuk (1/2 sdt)||Garam, kaldu bubuk||Air (300 ml)||Minyak goreng||Cabai rawit (untuk sambal)',
      langkahMemasak: '1. Iris tempe tipis-tipis melebar.||2. Campur tepung terigu, tepung beras, daun bawang, bawang putih, ketumbar, kunyit, garam, kaldu.||3. Tuang air sedikit demi sedikit, aduk hingga adonan kental.||4. Panaskan minyak goreng.||5. Celupkan irisan tempe ke adonan tepung.||6. Goreng dalam minyak panas hingga setengah matang (tidak terlalu kering).||7. Angkat, tiriskan.||8. Sajikan selagi hangat dengan sambal kecap.||9. Nikmati dicocol sambal kecap pedas.',
      gambar: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=800&q=80',
      kategori: 'Lauk',
    ),
    IndonesianRecipe(
      id: 61,
      namaResep: 'Ketoprak',
      deskripsi: 'Ketoprak Jakarta dengan lontong, tahu, dan bumbu kacang.',
      bahan: 'Lontong (2 buah)||Tahu goreng (4 buah)||Toge (100 gram)||Mie kuning (200 gram)||Kacang tanah goreng (150 gram)||Bawang putih (3 siung)||Cabai rawit (4 buah)||Kecap manis (3 sdm)||Gula merah (1 sdm)||Air asam jawa||Garam||Kerupuk||Daun seledri||Bawang goreng',
      langkahMemasak: '1. Potong lontong dan tahu goreng sesuai selera.||2. Seduh toge dengan air panas, tiriskan.||3. Rebus mie kuning hingga matang, tiriskan.||4. Haluskan kacang tanah, bawang putih, cabai rawit, gula merah, garam.||5. Tambahkan air asam jawa dan sedikit air hangat. Aduk rata.||6. Tata lontong, tahu, mie, dan toge di piring.||7. Siram dengan bumbu kacang.||8. Beri kecap manis secukupnya.||9. Taburi seledri, bawang goreng, dan kerupuk.',
      gambar: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      kategori: 'Lauk',
    ),
    IndonesianRecipe(
      id: 62,
      namaResep: 'Lontong Sayur',
      deskripsi: 'Lontong dengan sayur labu siam kuah santan pedas.',
      bahan: 'Lontong atau ketupat||Labu siam (2 buah)||Santan (500 ml)||Bawang merah||Bawang putih||Cabai merah besar||Cabai rawit||Udang rebon||Daun salam||Serai||Lengkuas||Garam||Gula||Telur rebus||Kerupuk',
      langkahMemasak: '1. Potong labu siam seperti korek api, remas dengan garam, cuci bersih.||2. Haluskan bawang merah, bawang putih, cabai.||3. Tumis bumbu halus dengan udang rebon, daun salam, serai, lengkuas.||4. Masukkan labu siam, aduk rata.||5. Tuang santan, aduk agar tidak pecah.||6. Masak dengan api kecil hingga labu empuk.||7. Bumbui garam dan gula. Koreksi rasa.||8. Potong lontong, tata di piring.||9. Siram sayur santan, beri telur rebus dan kerupuk.',
      gambar: 'https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?auto=format&fit=crop&w=800&q=80',
      kategori: 'Sayur',
    ),
    IndonesianRecipe(
      id: 64,
      namaResep: 'Bubur Ayam',
      deskripsi: 'Bubur ayam hangat dengan topping ayam suwir dan telur.',
      bahan: 'Beras (200 gram)||Air (1.5 liter)||Dada ayam (200 gram)||Bawang putih (4 siung)||Jahe (3 ruas)||Daun salam (3 lembar)||Garam, merica, kaldu ayam||Kecap manis||Daun bawang (iris)||Bawang goreng||Telur rebus||Kerupuk||Cakwe||Sambal',
      langkahMemasak: '1. Cuci beras, rendam 30 menit.||2. Rebus ayam dengan bawang putih dan jahe hingga empuk.||3. Angkat ayam, suwir-suwir dagingnya.||4. Masukkan beras ke dalam kaldu ayam.||5. Tambahkan daun salam, garam, merica.||6. Masak dengan api kecil sambil diaduk hingga menjadi bubur.||7. Masak hingga bubur mengental dan matang, 30-40 menit.||8. Sajikan bubur di mangkuk, beri topping ayam suwir.||9. Tambahkan telur rebus, daun bawang, bawang goreng, cakwe, kerupuk, kecap, dan sambal.',
      gambar: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=800&q=80',
      kategori: 'Lauk',
    ),
    IndonesianRecipe(
      id: 68,
      namaResep: 'Pisang Goreng',
      deskripsi: 'Pisang goreng crispy, jajanan pasar favorit Indonesia.',
      bahan: 'Pisang kepok (10 buah)||Tepung terigu (200 gram)||Tepung beras (50 gram)||Gula pasir (3 sdm)||Vanili (1 sdt)||Garam (1/2 sdt)||Air (200 ml)||Minyak goreng||Gula halus (taburan)||Meises coklat (opsional)',
      langkahMemasak: '1. Kupas pisang, belah menjadi 2 bagian memanjang.||2. Campur tepung terigu, tepung beras, gula, vanili, garam.||3. Tuang air sedikit demi sedikit, aduk hingga adonan kental.||4. Panaskan minyak goreng.||5. Celupkan pisang ke adonan tepung hingga terlapisi rata.||6. Goreng dalam minyak panas hingga kuning kecoklatan.||7. Angkat, tiriskan.||8. Sajikan hangat dengan taburan gula halus atau meises.||9. Nikmati sebagai camilan atau teman minum teh.',
      gambar: 'https://images.unsplash.com/photo-1505253758473-96b7015fcd40?auto=format&fit=crop&w=800&q=80',
      kategori: 'Lauk',
    ),
    IndonesianRecipe(
      id: 73,
      namaResep: 'Batagor',
      deskripsi: 'Baso tahu goreng khas Bandung dengan bumbu kacang.',
      bahan: 'Tahu putih (10 buah)||Ikan tenggiri giling (250 gram)||Tepung tapioka (100 gram)||Telur (1 butir)||Bawang putih (4 siung)||Daun bawang (2 batang)||Garam, merica, kaldu bubuk||Minyak goreng||Kacang tanah goreng (150 gram)||Cabai rawit||Gula merah||Kecap manis||Jeruk limau',
      langkahMemasak: '1. Haluskan tahu putih.||2. Campur tahu dengan ikan tenggiri, tapioka, telur, bawang putih, daun bawang, garam, merica, kaldu.||3. Aduk hingga rata.||4. Bentuk adonan sesuai selera (bulat atau lonjong).||5. Kukus batagor hingga matang, 20 menit.||6. Goreng batagor hingga kecoklatan.||7. Haluskan kacang tanah, cabai, gula merah untuk bumbu.||8. Tambahkan air hangat, kecap manis, perasan jeruk limau.||9. Sajikan batagor dengan siraman bumbu kacang.',
      gambar: 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?auto=format&fit=crop&w=800&q=80',
      kategori: 'Lauk',
    ),
    IndonesianRecipe(
      id: 76,
      namaResep: 'Gudeg Jogja',
      deskripsi: 'Nangka muda manis khas Yogyakarta yang dimasak dengan santan.',
      bahan: 'Nangka muda (500 gram)||Santan (1 liter)||Gula merah (250 gram)||Bawang merah (8 siung)||Bawang putih (5 siung)||Ketumbar (1 sdm)||Lengkuas (4 ruas)||Daun salam (5 lembar)||Serai (3 batang)||Garam (1 sdm)||Minyak goreng||Telur rebus (pelengkap)||Ayam kampung (pelengkap)||Sambal goreng krecek',
      langkahMemasak: '1. Potong nangka muda kecil-kecil, rebus hingga empuk, buang airnya.||2. Haluskan bawang merah, bawang putih, ketumbar.||3. Panaskan minyak, tumis bumbu halus, lengkuas, daun salam, serai hingga harum.||4. Masukkan nangka muda, aduk rata.||5. Tuang santan dan masukkan gula merah, garam.||6. Masak dengan api kecil selama 3-4 jam hingga nangka empuk dan kuah mengental.||7. Aduk sesekali agar tidak gosong.||8. Koreksi rasa manis dan gurih.||9. Sajikan gudeg dengan nasi hangat, ayam kampung, telur rebus, sambal krecek.',
      gambar: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=800&q=80',
      kategori: 'Sayur',
    ),
    IndonesianRecipe(
      id: 89,
      namaResep: 'Es Teler',
      deskripsi: 'Es campur khas dengan alpukat, kelapa muda, dan nangka.',
      bahan: 'Alpukat (2 buah)||Kelapa muda (1 buah)||Nangka (5 buah)||Santan (200 ml)||Susu kental manis (3 sdm)||Sirup gula merah (100 ml)||Es batu serut||Daun pandan (2 lembar)',
      langkahMemasak: '1. Keruk daging alpukat dengan sendok.||2. Keruk daging kelapa muda.||3. Potong nangka kecil-kecil.||4. Rebus santan dengan daun pandan dan sedikit garam.||5. Dinginkan santan.||6. Siapkan gelas saji: masukkan es batu serut.||7. Tata alpukat, kelapa muda, dan nangka di atas es.||8. Siram dengan sirup gula merah, santan, dan susu kental manis.||9. Sajikan segera selagi dingin.',
      gambar: 'https://images.unsplash.com/photo-1553621046-fd5f4c64e2ba?auto=format&fit=crop&w=800&q=80',
      kategori: 'Minuman',
    ),
  ];

  // ─── FAVORITES ──────────────────────────────────────────────────────────────

  Future<List<Recipe>> getFavorites() async {
    if (kIsWeb) {
      return _getFavoritesFromWeb();
    }

    final db = await database;
    final maps = await db.query(_tableFavorites, orderBy: 'title ASC');
    return maps
        .map(
          (item) => Recipe.fromDbMap({
            'id': item['id'] as int,
            'title': item['title'] as String,
            'image': item['image'] as String,
            'readyInMinutes': item['readyInMinutes'] as int?,
            'servings': item['servings'] as int?,
            'ingredients': item['ingredients'] as String,
            'instructions': item['instructions'] as String,
            'ingredient_data': item['ingredient_data'] as String?,
          }),
        )
        .toList();
  }

  Future<void> saveFavorite(Recipe recipe) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await _getFavoritesFromWeb();
      final existingIndex = favorites.indexWhere(
        (item) => item.id == recipe.id,
      );
      if (existingIndex >= 0) {
        favorites[existingIndex] = recipe;
      } else {
        favorites.add(recipe);
      }
      await prefs.setString(
        _webStorageKey,
        jsonEncode(favorites.map((item) => item.toDbMap()).toList()),
      );
      return;
    }

    final db = await database;
    await db.insert(
      _tableFavorites,
      recipe.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(int id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await _getFavoritesFromWeb();
      favorites.removeWhere((item) => item.id == id);
      await prefs.setString(
        _webStorageKey,
        jsonEncode(favorites.map((item) => item.toDbMap()).toList()),
      );
      return;
    }

    final db = await database;
    await db.delete(_tableFavorites, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isFavorite(int id) async {
    if (kIsWeb) {
      final favorites = await _getFavoritesFromWeb();
      return favorites.any((item) => item.id == id);
    }

    final db = await database;
    final result = await db.query(
      _tableFavorites,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<Recipe>> _getFavoritesFromWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webStorageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) {
      final map = item as Map<String, dynamic>;
      return Recipe.fromDbMap({
        'id': map['id'] as int,
        'title': map['title'] as String,
        'image': map['image'] as String,
        'readyInMinutes': map['readyInMinutes'] as int?,
        'servings': map['servings'] as int?,
        'ingredients': map['ingredients'] as String,
        'instructions': map['instructions'] as String,
        'ingredient_data': map['ingredient_data'] as String?,
      });
    }).toList();
  }

  // ─── SEARCH HISTORY ─────────────────────────────────────────────────────────

  Future<List<SearchHistory>> getSearchHistory() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('search_history');
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => SearchHistory.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    final db = await database;
    final maps =
        await db.query(_tableSearchHistory, orderBy: 'viewed_at DESC', limit: 100);
    return maps.map((item) => SearchHistory.fromMap(item)).toList();
  }

  Future<void> addSearchHistory(SearchHistory entry) async {
    if (kIsWeb) {
      final history = await getSearchHistory();
      history.removeWhere((h) => h.recipeId == entry.recipeId);
      history.insert(0, entry);
      if (history.length > 100) history.removeLast();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'search_history',
        jsonEncode(history.map((h) => h.toMap()).toList()),
      );
      return;
    }

    final db = await database;
    // Remove duplicate entry if exists
    await db.delete(_tableSearchHistory, where: 'recipe_id = ?', whereArgs: [entry.recipeId]);
    await db.insert(_tableSearchHistory, entry.toMap());
  }

  Future<void> deleteSearchHistoryItem(int id) async {
    if (kIsWeb) {
      final history = await getSearchHistory();
      history.removeWhere((h) => h.id == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'search_history',
        jsonEncode(history.map((h) => h.toMap()).toList()),
      );
      return;
    }

    final db = await database;
    await db.delete(_tableSearchHistory, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearSearchHistory() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
      return;
    }

    final db = await database;
    await db.delete(_tableSearchHistory);
  }

  // ─── COLLECTIONS ───────────────────────────────────────────────────────────

  Future<List<Collection>> getCollections() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('collections');
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Collection.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    final db = await database;
    final maps = await db.query(_tableCollections, orderBy: 'created_at DESC');
    return maps.map((item) => Collection.fromMap(item)).toList();
  }

  Future<void> createCollection(String name) async {
    final collection = Collection(
      name: name,
      createdAt: DateTime.now(),
    );

    if (kIsWeb) {
      final collections = await getCollections();
      final newCollection = Collection(
        id: collections.isEmpty ? 1 : collections.map((c) => c.id ?? 0).reduce((a, b) => a > b ? a : b) + 1,
        name: name,
        createdAt: DateTime.now(),
      );
      collections.insert(0, newCollection);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'collections',
        jsonEncode(collections.map((c) => c.toMap()).toList()),
      );
      return;
    }

    final db = await database;
    await db.insert(_tableCollections, collection.toMap());
  }

  Future<void> deleteCollection(int id) async {
    if (kIsWeb) {
      final collections = await getCollections();
      collections.removeWhere((c) => c.id == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'collections',
        jsonEncode(collections.map((c) => c.toMap()).toList()),
      );
      // Also delete collection_recipes
      final recipeIds = await getCollectionRecipeIds(id);
      for (final recipeId in recipeIds) {
        await removeRecipeFromCollection(id, recipeId);
      }
      return;
    }

    final db = await database;
    await db.delete(_tableCollectionRecipes,
        where: 'collection_id = ?', whereArgs: [id]);
    await db.delete(_tableCollections, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<int>> getCollectionRecipeIds(int collectionId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('collection_recipes_$collectionId');
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => e as int).toList();
    }

    final db = await database;
    final maps = await db.query(_tableCollectionRecipes,
        where: 'collection_id = ?', whereArgs: [collectionId]);
    return maps.map((m) => m['recipe_id'] as int).toList();
  }

  Future<void> addRecipeToCollection(int collectionId, int recipeId) async {
    if (kIsWeb) {
      final ids = await getCollectionRecipeIds(collectionId);
      if (!ids.contains(recipeId)) {
        ids.add(recipeId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'collection_recipes_$collectionId',
          jsonEncode(ids),
        );
      }
      return;
    }

    final db = await database;
    try {
      await db.insert(_tableCollectionRecipes, {
        'collection_id': collectionId,
        'recipe_id': recipeId,
      });
    } catch (_) {
      // Ignore duplicate
    }
  }

  Future<void> removeRecipeFromCollection(int collectionId, int recipeId) async {
    if (kIsWeb) {
      final ids = await getCollectionRecipeIds(collectionId);
      ids.remove(recipeId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'collection_recipes_$collectionId',
        jsonEncode(ids),
      );
      return;
    }

    final db = await database;
    await db.delete(_tableCollectionRecipes,
        where: 'collection_id = ? AND recipe_id = ?',
        whereArgs: [collectionId, recipeId]);
  }

  Future<Map<int, List<int>>> getAllCollectionRecipeIds() async {
    if (kIsWeb) {
      final collections = await getCollections();
      final result = <int, List<int>>{};
      for (final c in collections) {
        result[c.id!] = await getCollectionRecipeIds(c.id!);
      }
      return result;
    }

    final db = await database;
    final maps = await db.query(_tableCollectionRecipes);
    final result = <int, List<int>>{};
    for (final m in maps) {
      final colId = m['collection_id'] as int;
      final recId = m['recipe_id'] as int;
      result.putIfAbsent(colId, () => []);
      result[colId]!.add(recId);
    }
    return result;
  }

  // ─── USER RATINGS ──────────────────────────────────────────────────────────

  Future<UserRating?> getUserRating(int recipeId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_ratings');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as List<dynamic>;
      final match = decoded.firstWhere(
        (item) => (item as Map<String, dynamic>)['recipe_id'] == recipeId,
        orElse: () => null,
      );
      if (match == null) return null;
      return UserRating.fromMap(match as Map<String, dynamic>);
    }

    final db = await database;
    final maps = await db.query(_tableUserRatings,
        where: 'recipe_id = ?', whereArgs: [recipeId], limit: 1);
    if (maps.isEmpty) return null;
    return UserRating.fromMap(maps.first);
  }

  Future<void> saveUserRating(int recipeId, int rating) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_ratings');
      var ratings = <Map<String, dynamic>>[];
      if (raw != null && raw.isNotEmpty) {
        ratings = (jsonDecode(raw) as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
      ratings.removeWhere((r) => r['recipe_id'] == recipeId);
      ratings.add({
        'recipe_id': recipeId,
        'rating': rating,
        'rated_at': DateTime.now().toIso8601String(),
      });
      await prefs.setString('user_ratings', jsonEncode(ratings));
      return;
    }

    final db = await database;
    await db.insert(
      _tableUserRatings,
      UserRating(
        recipeId: recipeId,
        rating: rating,
        ratedAt: DateTime.now(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── COLLECTION RECIPES DATA ───────────────────────────────────────────────

  Future<List<Recipe>> getRecipesByIds(List<int> ids, {List<Recipe>? allRecipes}) async {
    if (allRecipes != null) {
      return allRecipes.where((r) => ids.contains(r.id)).toList();
    }
    // Fallback: get from favorites
    final favorites = await getFavorites();
    return favorites.where((r) => ids.contains(r.id)).toList();
  }
}
