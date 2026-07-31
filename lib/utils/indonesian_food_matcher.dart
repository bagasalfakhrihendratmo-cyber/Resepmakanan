/// Utility untuk mendeteksi apakah query pencarian adalah makanan Indonesia.
/// Juga menyediakan mapping keyword → lokal recipe ID.
class IndonesianFoodMatcher {
  IndonesianFoodMatcher._();

  /// Daftar keyword makanan Indonesia yang dikenali.
  /// Setiap keyword dipetakan ke ID resep lokal yang sesuai.
  static const Map<String, int> _keywordToLocalId = {
    // ═══ NASI ═══
    'nasi goreng': 1,
    'nasi goreng kampung': 1,
    'nasi goreng seafood': 4,
    'nasi goreng jawa': 5,
    'nasi goreng merah': 6,
    'nasi': 1,
    'nasi uduk': 24,
    'nasi kuning': 25,
    'nasi liwet': 26,
    'nasi padang': 15,
    'nasi timbel': 27,

    // ═══ AYAM ═══
    'ayam': 2,
    'ayam goreng': 7,
    'ayam goreng mentega': 7,
    'ayam bakar': 9,
    'ayam bakar taliwang': 9,
    'ayam penyet': 28,
    'ayam suwir': 10,
    'ayam suwir pedas': 10,
    'ayam pop': 29,
    'ayam rica': 30,
    'ayam rica rica': 30,
    'opor ayam': 8,
    'soto ayam': 2,
    'soto': 2,
    'kari ayam': 31,

    // ═══ SAPI / DAGING ═══
    'rendang': 15,
    'rendang sapi': 15,
    'sapi': 15,
    'rawon': 19,
    'rawon surabaya': 19,
    'sop buntut': 23,
    'sop buntut bakar': 23,
    'coto makassar': 20,
    'coto': 20,
    'semur': 32,
    'semur daging': 32,
    'empal gentong': 33,
    'tongseng': 34,
    'tongseng sapi': 34,
    'bakso': 18,
    'bakso sapi': 18,
    'bakso malang': 18,
    'sate': 16,
    'sate ayam': 16,
    'sate ayam madura': 16,
    'sate kambing': 35,
    'gulai': 36,
    'gulai sapi': 36,

    // ═══ MIE ═══
    'mie': 11,
    'mie goreng': 11,
    'mie goreng jawa': 11,
    'mie ayam': 12,
    'mie ayam bakso': 12,
    'mie rebus': 13,
    'mie rebus aceh': 13,
    'mie aceh': 13,
    'mie godog': 14,
    'mie godog kuah': 14,
    'mie celor': 37,
    'mie koclok': 38,
    'kwetiau': 39,
    'kwetiau goreng': 39,
    'bakmi': 12,

    // ═══ SAYUR & SALAD ═══
    'gado gado': 17,
    'gado-gado': 17,
    'gado2': 17,
    'sayur': 40,
    'sayur asem': 40,
    'sayur lodeh': 41,
    'sayur sop': 42,
    'karedok': 43,
    'pecel': 44,
    'pecel lele': 45,
    'urap': 46,
    'tumis kangkung': 47,
    'kangkung': 47,
    'capcay': 48,

    // ═══ IKAN & SEAFOOD ═══
    'ikan': 49,
    'ikan bakar': 49,
    'ikan goreng': 49,
    'ikan kuah kuning': 21,
    'papeda': 21,
    'pempek': 22,
    'pempek palembang': 22,
    'tekwan': 50,
    'otak otak': 51,
    'otak-otak': 51,
    'udang': 52,
    'udang goreng': 52,
    'cumi': 53,
    'cumi goreng': 53,
    'gurame': 54,
    'gurame bakar': 54,

    // ═══ TAHU & TEMPE ═══
    'tempe': 55,
    'tempe goreng': 55,
    'tempe mendoan': 56,
    'tahu': 57,
    'tahu goreng': 57,
    'tahu isi': 58,
    'tahu gejrot': 59,
    'perkedel': 60,
    'perkedel kentang': 60,

    // ═══ KUAT & TRADISIONAL ═══
    'ketoprak': 61,
    'lontong': 62,
    'lontong sayur': 62,
    'lontong balap': 63,
    'bubur': 64,
    'bubur ayam': 64,
    'surabi': 65,
    'serabi': 65,
    'martabak': 66,
    'martabak telur': 66,
    'martabak manis': 67,
    'terang bulan': 67,
    'pisang goreng': 68,
    'tahu bulat': 69,
    'cilok': 70,
    'cilor': 71,
    'cireng': 72,
    'batagor': 73,
    'siomay': 74,
    'sempol': 75,

    // ═══ GUDEG & JOGJA ═══
    'gudeg': 76,
    'gudeg jogja': 76,
    'yangko': 77,
    'bakpia': 78,
    'wedang ronde': 79,
    'wedang jahe': 80,

    // ═══ MASAKAN PADANG ═══
    'rendang': 15,
    'gulai': 36,
    'dendeng balado': 81,
    'dendeng': 81,
    'paru': 82,
    'paru goreng': 82,
    'sambal ijo': 83,
    'sambal lado': 83,
    'telur balado': 84,
    'teri balado': 85,

    // ═══ MINUMAN ═══
    'es teh': 86,
    'es jeruk': 87,
    'es campur': 88,
    'es teler': 89,
    'es dawet': 90,
    'cendol': 90,
    'es cendol': 90,
    'es podeng': 91,
    'es buah': 92,
    'bir pletok': 93,
    'kopi': 94,
    'kopi tubruk': 94,
    'kopi susu': 95,
    'bandrek': 96,
    'sekoteng': 97,
    'rujak': 98,
    'rujak buah': 98,
    'asinan': 99,
    'asinan buah': 99,
  };

  /// Daftar keyword umum makanan Indonesia (tanpa mapping spesifik).
  /// Digunakan untuk deteksi apakah query adalah makanan Indonesia.
  static const Set<String> _indonesianFoodSet = {
    ..._keywordToLocalId.keys,
    // Tambahan keyword umum tanpa ID spesifik
    'masakan indonesia',
    'makanan indonesia',
    'resep indonesia',
    'indonesia',
    'nusantara',
    'makanan tradisional',
    'masakan rumahan',
    'masakan nusantara',
    'jajanan pasar',
    'jajanan',
    'kue tradisional',
    'kue basah',
    'kue kering',
    'lauk',
    'lauk pauk',
    'sambal',
    'sambal goreng',
  };

  /// Cek apakah query mengandung keyword makanan Indonesia.
  static bool isIndonesianFood(String query) {
    if (query.trim().isEmpty) return false;
    final lowerQuery = query.trim().toLowerCase();

    // Cek exact match dulu
    if (_indonesianFoodSet.contains(lowerQuery)) return true;

    // Cek partial match
    for (final keyword in _indonesianFoodSet) {
      if (lowerQuery.contains(keyword) || keyword.contains(lowerQuery)) {
        return true;
      }
    }

    return false;
  }

  /// Mendapatkan ID resep lokal yang paling cocok untuk query.
  /// Mengembalikan null jika tidak ada mapping.
  static int? getLocalRecipeId(String query) {
    final lowerQuery = query.trim().toLowerCase();

    // Cari exact match dulu
    if (_keywordToLocalId.containsKey(lowerQuery)) {
      return _keywordToLocalId[lowerQuery];
    }

    // Cari partial match (prefix)
    for (final entry in _keywordToLocalId.entries) {
      if (lowerQuery.contains(entry.key) ||
          entry.key.startsWith(lowerQuery)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Mendapatkan semua keyword Indonesia yang cocok dengan query.
  /// Berguna untuk mencari lebih banyak hasil terkait.
  static List<String> getMatchingKeywords(String query) {
    final lowerQuery = query.trim().toLowerCase();
    final matches = <String>[];

    for (final keyword in _keywordToLocalId.keys) {
      if (keyword.contains(lowerQuery) || lowerQuery.contains(keyword)) {
        matches.add(keyword);
      }
    }

    return matches;
  }

  /// Daftar ID resep lokal yang direkomendasikan untuk ditampilkan saat
  /// aplikasi pertama kali dibuka (saran pencarian).
  static const List<int> suggestedRecipeIds = [
    1,  // Nasi Goreng Kampung
    2,  // Soto Ayam
    7,  // Ayam Goreng Mentega
    11, // Mie Goreng Jawa
    15, // Rendang Sapi
    16, // Sate Ayam Madura
    17, // Gado-Gado Jakarta
    18, // Bakso Sapi Rumahan
    19, // Rawon Surabaya
    22, // Pempek Palembang
  ];
}
