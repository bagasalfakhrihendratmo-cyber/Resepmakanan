1. Ringkasan Produk (Overview)
Aplikasi Resep Masakan adalah aplikasi mobile yang memungkinkan pengguna mencari resep masakan, melihat detail resep (bahan dan langkah memasak), serta menyimpan resep favorit untuk diakses kembali secara offline. Aplikasi ini dirancang untuk membantu pengguna menemukan inspirasi memasak dengan cepat dan menyimpan koleksi resep pribadi tanpa harus terhubung ke internet setiap saat.
1.1 Latar Belakang
Banyak pengguna kesulitan menemukan resep yang sesuai dengan bahan yang mereka miliki, dan seringkali kehilangan resep yang pernah mereka temukan karena tidak ada cara mudah untuk menyimpannya. Aplikasi ini menjawab kebutuhan tersebut dengan menghadirkan fitur pencarian resep yang terintegrasi dengan basis data resep global, dilengkapi kemampuan menyimpan resep favorit secara lokal di perangkat.
1.2 Tujuan Produk
•	Memudahkan pengguna mencari resep masakan berdasarkan kata kunci (nama masakan/bahan).
•	Menyediakan informasi detail resep yang jelas (bahan dan langkah-langkah memasak).
•	Memungkinkan pengguna menyimpan resep favorit agar dapat diakses kembali dengan cepat.
•	Memberikan pengalaman pengguna yang ringan dan optimal, termasuk saat koneksi internet terbatas.
1.3 Target Pengguna
•	Individu yang gemar memasak di rumah dan mencari inspirasi resep sehari-hari.
•	Pengguna yang ingin mengelola koleksi resep favorit pribadi.
•	Pengguna dengan koneksi internet yang tidak selalu stabil, sehingga membutuhkan akses offline ke resep favorit.
2. Ruang Lingkup (Scope)
2.1 Termasuk dalam Ruang Lingkup (In Scope)
•	Fitur pencarian resep berbasis kata kunci.
•	Halaman detail resep (bahan dan langkah memasak).
•	Fitur tombol favorit (tandai/batal tandai resep sebagai favorit).
•	Penyimpanan data favorit secara lokal di perangkat (offline).
•	Optimasi pemuatan dan caching gambar resep.
2.2 Di Luar Ruang Lingkup (Out of Scope) - Versi 1.0
•	Fitur akun pengguna / login / sinkronisasi favorit ke cloud.
•	Fitur berbagi resep ke media sosial.
•	Fitur ulasan/rating resep dari pengguna lain.
•	Fitur perencanaan menu (meal planning) dan daftar belanja.
•	Dukungan multi-bahasa (versi awal menggunakan Bahasa Indonesia/Inggris sesuai sumber data).
3. Fitur & Kebutuhan Fungsional (Functional Requirements)
3.1 Fitur Pencarian Resep
Deskripsi: Pengguna dapat mencari resep masakan dengan memasukkan kata kunci (misalnya nama masakan atau bahan utama) pada kolom pencarian.
Kebutuhan Fungsional:
1.	Sistem menyediakan kolom input pencarian pada halaman utama (home screen).
2.	Sistem mengirimkan query pencarian ke Spoonacular API dan menampilkan daftar resep yang relevan.
3.	Hasil pencarian ditampilkan dalam bentuk daftar (list/grid) berisi gambar thumbnail, nama resep, dan informasi ringkas (misal waktu memasak).
4.	Sistem menampilkan status loading saat proses pencarian berlangsung.
5.	Sistem menampilkan pesan yang informatif apabila resep tidak ditemukan atau terjadi kegagalan koneksi.
6.	Pengguna dapat mengetuk salah satu hasil pencarian untuk membuka halaman detail resep.
3.2 Fitur Detail Resep
Deskripsi: Menampilkan informasi lengkap suatu resep, mencakup daftar bahan dan langkah-langkah memasak.
Kebutuhan Fungsional:
7.	Sistem menampilkan gambar utama resep, judul, dan informasi umum (porsi, estimasi waktu memasak) jika tersedia dari Spoonacular API.
8.	Sistem menampilkan daftar bahan (ingredients) lengkap dengan takaran.
9.	Sistem menampilkan langkah-langkah memasak (instructions) secara berurutan.
10.	Sistem menyediakan tombol favorit pada halaman detail resep.
11.	Halaman detail dapat menampilkan data dari cache lokal apabila resep tersebut sudah pernah disimpan sebagai favorit dan sedang tidak ada koneksi internet.
3.3 Fitur Tombol Favorit
Deskripsi: Tombol untuk menandai atau membatalkan tanda resep sebagai favorit.
Kebutuhan Fungsional:
12.	Tombol favorit (ikon hati/bintang) tersedia pada kartu hasil pencarian dan halaman detail resep.
13.	Ketika ditekan, sistem menyimpan data resep terkait (ID, judul, gambar, bahan, langkah) ke basis data lokal (SQLite melalui sqflite).
14.	Ketika ditekan kembali (unfavorite), sistem menghapus data resep tersebut dari basis data lokal.
15.	Status tombol (aktif/tidak aktif) merefleksikan kondisi favorit resep secara real-time pada UI.
3.4 Fitur Penyimpanan Favorit Lokal
Deskripsi: Halaman yang menampilkan seluruh resep yang telah ditandai sebagai favorit oleh pengguna, tersimpan secara lokal di perangkat.
Kebutuhan Fungsional:
16.	Sistem menyediakan halaman/tab "Favorit" yang menampilkan seluruh resep favorit dari basis data SQLite lokal.
17.	Data pada halaman favorit tetap dapat diakses tanpa koneksi internet (mode offline).
18.	Pengguna dapat menghapus resep dari daftar favorit langsung melalui halaman ini.
19.	Halaman favorit menampilkan pesan/placeholder yang sesuai apabila belum ada resep yang disimpan.
4. Kebutuhan Non-Fungsional (Non-Functional Requirements)
•	Performa: Hasil pencarian resep tampil dalam waktu maksimal 2-3 detik pada koneksi internet normal.
•	Optimasi Gambar: Gambar resep menggunakan package cached_network_image agar gambar yang pernah dimuat tidak diunduh ulang, sehingga menghemat kuota dan mempercepat tampilan.
•	Offline Access: Resep yang sudah difavoritkan (data & gambar ter-cache) tetap dapat dibuka tanpa koneksi internet.
•	Keandalan: Aplikasi menampilkan pesan error yang jelas saat API tidak dapat diakses, tanpa membuat aplikasi crash.
•	Kompatibilitas: Aplikasi berjalan pada perangkat Android dan iOS dengan versi OS yang umum digunakan (sesuai kebijakan tim engineering).
•	Keamanan Data: API key Spoonacular disimpan secara aman (tidak di-hardcode secara terbuka pada source code publik, misalnya menggunakan file .env / flutter_dotenv).
•	Skalabilitas Data Lokal: Basis data SQLite (sqflite) mampu menyimpan minimal 200 resep favorit tanpa penurunan performa yang signifikan.
5. Arsitektur & Teknologi (Tech Stack)
Berikut adalah teknologi yang digunakan dalam pengembangan Aplikasi Resep Masakan:
5.1 Framework & Bahasa Pemrograman
•	Framework: Flutter - digunakan untuk membangun aplikasi mobile cross-platform (Android & iOS) dari satu basis kode yang sama, sehingga mempercepat proses development dan menjaga konsistensi tampilan (UI) di kedua platform.
•	Bahasa Pemrograman: Dart - bahasa pemrograman utama yang digunakan Flutter untuk membangun logika aplikasi maupun tampilan antarmuka (widget).
5.2 Sumber Data / API
•	Spoonacular API - digunakan sebagai sumber data resep eksternal, mencakup fitur pencarian resep serta pengambilan detail resep (bahan dan langkah memasak). Komunikasi dengan API ini dilakukan melalui HTTP request (misalnya menggunakan package http atau dio pada Flutter).
5.3 Penyimpanan Data Lokal (Local Storage)
•	Database: SQLite - basis data relasional lokal yang tersimpan langsung di perangkat pengguna, digunakan untuk menyimpan data resep yang ditandai sebagai favorit.
•	Package: sqflite - plugin Flutter yang digunakan untuk berkomunikasi dengan basis data SQLite (melakukan operasi create, read, update, delete/CRUD) pada data resep favorit.
5.4 Optimasi Gambar
•	Package: cached_network_image - digunakan untuk memuat gambar resep dari internet sekaligus menyimpan cache-nya di perangkat, sehingga gambar yang sama tidak perlu diunduh berulang kali. Hal ini membantu menghemat kuota data pengguna dan mempercepat waktu tampil gambar, termasuk untuk gambar resep favorit yang diakses secara offline.
5.5 Ringkasan Tech Stack
•	Frontend/Mobile Framework: Flutter
•	Bahasa Pemrograman: Dart
•	Sumber Data Resep: Spoonacular API
•	Database Lokal: SQLite (via package sqflite)
•	Optimasi & Caching Gambar: package cached_network_image
Catatan Teknis:
•	Diperlukan penanganan rate limit dari Spoonacular API (mengikuti kuota paket yang digunakan).
•	Perlu mekanisme mapping data respons Spoonacular API (format JSON) ke skema tabel SQLite melalui sqflite (khusus data yang disimpan sebagai favorit).
•	Perlu strategi cache-invalidation/pembersihan cache gambar dari cached_network_image agar penyimpanan perangkat tidak membengkak.
•	Struktur project Flutter disarankan mengikuti pola arsitektur yang jelas (misalnya MVVM/Provider/Bloc) agar mudah dikembangkan dan diuji ke depannya.
6. Alur Pengguna (User Flow)
6.1 Alur Pencarian Resep
20.	Pengguna membuka aplikasi dan berada di halaman utama.
21.	Pengguna mengetik kata kunci pada kolom pencarian.
22.	Aplikasi menampilkan daftar resep hasil pencarian dari Spoonacular API.
23.	Pengguna memilih salah satu resep untuk melihat detail.
6.2 Alur Menandai Favorit
24.	Pengguna berada di halaman detail resep atau kartu hasil pencarian.
25.	Pengguna menekan tombol favorit (ikon hati).
26.	Aplikasi menyimpan data resep ke basis data SQLite lokal melalui sqflite.
27.	Ikon favorit berubah status menjadi "tersimpan".
6.3 Alur Melihat Resep Favorit (Offline)
28.	Pengguna membuka tab/halaman "Favorit".
29.	Aplikasi menampilkan seluruh resep favorit dari basis data lokal, lengkap dengan gambar dari cache cached_network_image.
30.	Pengguna dapat membuka detail resep favorit meskipun tanpa koneksi internet.
7. Metrik Keberhasilan (Success Metrics)
•	Tingkat keberhasilan pencarian: persentase pencarian yang menghasilkan minimal satu resep relevan.
•	Rata-rata waktu muat (load time) halaman hasil pencarian dan halaman detail resep.
•	Jumlah rata-rata resep favorit yang disimpan per pengguna aktif.
•	Tingkat retensi pengguna yang kembali membuka halaman favorit dalam mode offline.
•	Crash rate aplikasi tetap di bawah ambang batas yang ditetapkan tim engineering.
8. Asumsi & Risiko
8.1 Asumsi
•	Ketersediaan dan kestabilan Spoonacular API terjaga sesuai SLA penyedia layanan.
•	Pengguna mengizinkan aplikasi mengakses penyimpanan lokal perangkat untuk basis data SQLite dan cache gambar.
8.2 Risiko
•	Ketergantungan penuh pada Spoonacular API - apabila terjadi gangguan layanan, fitur pencarian tidak dapat berfungsi.
•	Batasan kuota (rate limit/quota) API dapat membatasi jumlah pencarian yang dapat dilakukan pengguna.
•	Ukuran cache gambar dan basis data lokal yang terus bertambah dapat memengaruhi ruang penyimpanan perangkat pengguna.
9. Pertanyaan Terbuka (Open Questions)
•	Apakah dibutuhkan batas maksimal jumlah resep favorit yang dapat disimpan per pengguna?
•	Apakah fitur pencarian perlu dilengkapi filter tambahan (misalnya kategori, waktu memasak, diet) pada versi berikutnya?
•	Paket/tier Spoonacular API apa yang akan digunakan, dan bagaimana dampaknya terhadap kuota permintaan harian?
