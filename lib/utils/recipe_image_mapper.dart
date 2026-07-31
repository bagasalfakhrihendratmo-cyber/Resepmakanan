/// Utility untuk memetakan nama resep Indonesia → gambar yang benar-benar
/// sesuai dengan hidangannya.
///
/// # Kenapa ini ada?
/// Spoonacular CDN (img.spoonacular.com) TIDAK mengirim header CORS, sehingga
/// gambarnya diblokir oleh Flutter Web (CanvasKit). Kode lama menggantinya
/// dengan foto Unsplash yang dipilih berdasarkan `recipeId % panjangLista` —
/// akibatnya gambar TIDAK ada hubungannya dengan nama resep (mis. Rawon
/// menampilkan foto nasi goreng).
///
/// Kelas ini menyelesaikan masalah tersebut dengan cara:
/// 1. Menormalkan nama resep (huruf kecil, tanpa tanda baca, spasi rapi).
/// 2. Mencocokkan nama dengan daftar hidangan Indonesia yang dikurasi.
/// 3. Mengembalikan URL gambar terverifikasi dari Wikimedia Commons
///    (memiliki header `access-control-allow-origin: *` ✅, aman untuk web).
/// 4. Jika tidak cocok → fallback ke gambar API (bila aman) atau gambar
///    generik yang deterministik (judul yang sama → gambar yang sama).
class RecipeImageMapper {
  RecipeImageMapper._();

  /// Menormalkan nama resep agar bisa dicocokkan dengan keyword hidangan.
  ///
  /// Contoh:
  /// - "Rawon Surabaya"   → "rawon surabaya"
  /// - "Gado-Gado Jakarta" → "gado gado jakarta"
  /// - "Papeda & Ikan Kuah Kuning" → "papeda ikan kuah kuning"
  static String normalize(String input) {
    var s = input.toLowerCase().trim();
    // Ganti semua karakter selain huruf/angka dengan spasi.
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    // Rapatkan spasi berlebih.
    return s.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Mapping keyword hidangan → URL gambar terverifikasi dari Wikimedia
  /// Commons. Semua URL memiliki header CORS, jadi aman dimuat di Flutter Web.
  static const Map<String, String> _dishImages = {
    // ═══ NASI ═══
    'nasi goreng':
        'https://upload.wikimedia.org/wikipedia/commons/3/3e/Nasi_goreng_indonesia.jpg',
    'nasi uduk':
        'https://upload.wikimedia.org/wikipedia/commons/a/a6/Nasi_uduk_netherlands.jpg',
    'nasi kuning':
        'https://upload.wikimedia.org/wikipedia/commons/9/96/Nasi_Kuning_dan_Ungkep_Ayam.jpg',
    'nasi':
        'https://upload.wikimedia.org/wikipedia/commons/3/3e/Nasi_goreng_indonesia.jpg',

    // ═══ AYAM ═══
    'soto ayam':
        'https://upload.wikimedia.org/wikipedia/commons/0/05/Soto_ayam.JPG',
    'soto':
        'https://upload.wikimedia.org/wikipedia/commons/0/05/Soto_ayam.JPG',
    'ayam bakar taliwang':
        'https://upload.wikimedia.org/wikipedia/commons/c/c5/Ayam_Bakar_Taliwang_Bang_Tangu.jpg',
    'ayam bakar':
        'https://upload.wikimedia.org/wikipedia/commons/7/78/Ayam_bakar.jpg',
    'ayam goreng':
        'https://upload.wikimedia.org/wikipedia/commons/9/9d/Ayam_goreng_kalasan.JPG',
    'ayam penyet':
        'https://upload.wikimedia.org/wikipedia/commons/5/57/Ayam_penyet.JPG',
    'ayam':
        'https://upload.wikimedia.org/wikipedia/commons/9/9d/Ayam_goreng_kalasan.JPG',
    'opor ayam':
        'https://upload.wikimedia.org/wikipedia/commons/c/cd/Opor_Ayam_Telur_Pindang.JPG',

    // ═══ MIE ═══
    'mie goreng':
        'https://upload.wikimedia.org/wikipedia/commons/f/f0/Mi_Goreng_GM.jpg',
    'mie ayam':
        'https://upload.wikimedia.org/wikipedia/commons/e/e6/Mie_Ayam_Ekstra_Telur_Bakso.jpg',
    'mie aceh':
        'https://upload.wikimedia.org/wikipedia/commons/f/f4/Mie_Aceh_with_beef.jpg',
    'mie':
        'https://upload.wikimedia.org/wikipedia/commons/f/f0/Mi_Goreng_GM.jpg',

    // ═══ DAGING ═══
    'rendang':
        'https://upload.wikimedia.org/wikipedia/commons/5/50/Beef_Rendang..JPG',
    'rawon':
        'https://upload.wikimedia.org/wikipedia/commons/7/7e/Rawon_Setan.jpg',
    'coto makassar':
        'https://upload.wikimedia.org/wikipedia/commons/c/c1/Coto_Makassar_dish.JPG',
    'coto':
        'https://upload.wikimedia.org/wikipedia/commons/c/c1/Coto_Makassar_dish.JPG',
    'sop buntut':
        'https://upload.wikimedia.org/wikipedia/commons/e/e6/Sop_Buntut_Oxtail_soup.jpg',
    'gulai':
        'https://upload.wikimedia.org/wikipedia/commons/a/a7/Gulai_tunjang.JPG',
    'bakso':
        'https://upload.wikimedia.org/wikipedia/commons/5/55/Bakso_khas_Solo.jpg',
    'sate ayam':
        'https://upload.wikimedia.org/wikipedia/commons/0/0a/Sate_ayam_Ragusa_Jl_Veteran.JPG',
    'sate kambing':
        'https://upload.wikimedia.org/wikipedia/commons/2/25/Sate_kambing_dan_nasi.jpg',
    'sate':
        'https://upload.wikimedia.org/wikipedia/commons/0/0a/Sate_ayam_Ragusa_Jl_Veteran.JPG',

    // ═══ SAYUR & LAUK ═══
    'gado gado':
        'https://upload.wikimedia.org/wikipedia/commons/3/30/Gado-gado_in_Jakarta.JPG',
    'sayur asem':
        'https://upload.wikimedia.org/wikipedia/commons/5/58/Sayur_asem_vegetable_soup.jpg',
    'sayur':
        'https://upload.wikimedia.org/wikipedia/commons/5/58/Sayur_asem_vegetable_soup.jpg',
    'karedok':
        'https://upload.wikimedia.org/wikipedia/commons/9/9c/Karedok.JPG',
    'lontong sayur':
        'https://upload.wikimedia.org/wikipedia/commons/e/e1/Lontong_sayur_without_spoon.JPG',
    'ketoprak':
        'https://upload.wikimedia.org/wikipedia/commons/2/2e/Ketoprak_Boplo.JPG',
    'tempe mendoan':
        'https://upload.wikimedia.org/wikipedia/commons/7/7e/Tempe_mendoan_sambal_kecap.jpg',

    // ═══ IKAN & SEAFOOD ═══
    'papeda':
        'https://upload.wikimedia.org/wikipedia/commons/d/db/Hidangan_papeda.jpg',
    'pempek':
        'https://upload.wikimedia.org/wikipedia/commons/c/c2/Pempek_campur.JPG',

    // ═══ MASAKAN KHAS ═══
    'gudeg':
        'https://upload.wikimedia.org/wikipedia/commons/3/31/Nasi_Gudeg.jpg',
  };

  /// Foto makanan generik (Unsplash, CORS ✅) sebagai fallback terakhir.
  static const List<String> _genericImages = [
    'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1603366445781-2fedc492e0a4?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1559847844-5315695dadae?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?auto=format&fit=crop&w=800&q=80',
  ];

  /// Menentukan URL gambar yang paling cocok untuk sebuah judul resep.
  ///
  /// Mengembalikan `null` jika judul tidak dikenali sebagai hidangan yang
  /// punya gambar khusus.
  static String? imageForTitle(String title) {
    final normalized = normalize(title);
    if (normalized.isEmpty) return null;

    // Prioritaskan keyword terpanjang (paling spesifik) terlebih dahulu,
    // agar "ayam bakar taliwang" tidak tertimpa oleh "ayam bakar".
    final keywords = _dishImages.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final keyword in keywords) {
      if (normalized.contains(keyword)) return _dishImages[keyword];
    }
    return null;
  }

  /// Cek apakah URL berasal dari CDN Spoonacular (tidak punya header CORS,
  /// jadi tidak bisa dimuat di Flutter Web CanvasKit).
  static bool isSpoonacularCdn(String url) {
    return url.contains('img.spoonacular.com');
  }

  /// Menyelesaikan gambar final untuk sebuah resep dengan urutan prioritas:
  ///
  /// 1. Gambar mapping khusus hidangan Indonesia (jika nama cocok).
  /// 2. Gambar `fallback` jika aman (bukan CDN Spoonacular, tidak kosong).
  /// 3. Gambar generik yang deterministik — judul yang sama selalu
  ///    menghasilkan gambar yang sama (bukan acak seperti bug lama).
  static String resolveImage({
    required String title,
    required String fallback,
  }) {
    final mapped = imageForTitle(title);
    if (mapped != null) return mapped;

    if (fallback.isNotEmpty && !isSpoonacularCdn(fallback)) {
      return fallback;
    }

    // Hindari modulo negatif/overflow dengan abs.
    final hash = title.hashCode.abs() & 0x7fffffff;
    return _genericImages[hash % _genericImages.length];
  }
}
