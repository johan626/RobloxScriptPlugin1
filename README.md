# GUIConvert Plugin

## 🇮🇩 Plugin untuk Mengonversi Hierarki GUI menjadi Skrip Lua di Roblox Studio

GUIConvert adalah sebuah plugin canggih untuk Roblox Studio yang dirancang untuk mempercepat alur kerja pengembangan antarmuka pengguna (UI). Plugin ini memungkinkan developer untuk secara visual merancang UI mereka di Explorer, lalu secara otomatis mengubah hierarki `GuiObject` tersebut menjadi skrip Luau (`ModuleScript` atau `LocalScript`) yang bersih, terorganisir, dan siap pakai.

---

## ✨ Fitur Utama

- **Konversi Massal (*Bulk Conversion*):** Pilih beberapa `GuiObject` di Explorer dan konversikan semuanya sekaligus, masing-masing ke dalam skripnya sendiri.
- **Konversi Sekali Klik:** Ubah `ScreenGui` atau `GuiObject` apa pun menjadi skrip Luau dengan satu klik.
- **Dua Pilihan Tipe Skrip:**
  - **`ModuleScript`**: Hasilkan modul yang dapat digunakan kembali yang mengembalikan sebuah fungsi `create()` untuk membangun UI. Ideal untuk diintegrasikan ke dalam kerangka kerja (framework) UI Anda.
  - **`LocalScript`**: Hasilkan skrip yang akan secara otomatis membuat UI di bawah `PlayerGui` saat permainan dimulai.
- **Sinkronisasi Langsung (`Live Sync`) Berkinerja Tinggi:**
  - **Sangat Dioptimalkan:** Sistem `Live Sync` telah direkayasa ulang untuk kinerja maksimum, bahkan pada hierarki GUI dengan ribuan elemen.
  - **Manajemen Sumber Daya Cerdas:** Koneksi peristiwa dikelola secara dinamis untuk mencegah `memory leak` dan memastikan dampak minimal pada performa Studio.
  - **Umpan Balik Informatif:** UI memberikan stempel waktu yang jelas untuk sinkronisasi terakhir, sehingga Anda selalu tahu statusnya.
- **UI Modern & Profesional:** Antarmuka plugin telah didesain ulang sepenuhnya untuk estetika modern dan pengalaman pengguna yang lebih baik.
  - **Bantuan Kontekstual:** Arahkan kursor ke pengaturan atau tombol apa pun untuk mendapatkan *tooltip* informatif yang menjelaskan fungsinya.
  - **Sakelar Geser Kustom:** Opsi pengaturan sekarang menggunakan sakelar geser (toggle switches) yang jelas dan animasi.
  - **Hierarki Visual yang Jelas:** Tombol aksi utama didesain untuk menonjol, memandu pengguna melalui alur kerja.
  - **Desain Kohesif:** Semua elemen interaktif berbagi bahasa desain yang konsisten.
  - **Manajemen Daftar Hitam yang Ditingkatkan:**
    - **Profil Daftar Hitam:** Simpan dan muat konfigurasi daftar hitam yang berbeda sebagai "profil". Ini memungkinkan Anda untuk dengan cepat beralih di antara set properti yang diabaikan untuk berbagai jenis UI tanpa harus mencentangnya secara manual setiap saat.
    - **Grup yang Dapat Diciutkan:** Properti dalam daftar hitam sekarang dikelompokkan berdasarkan kelas (`Common`, `UIStroke`, `UIGradient`, dll.) dalam kategori yang dapat diciutkan, membuat navigasi menjadi jauh lebih mudah.
    - **Daftar Hitam Otomatis Cerdas:** Saat Anda memilih `UIListLayout` atau `UIGridLayout`, plugin secara otomatis memasukkan properti `Position` dan `Size` ke dalam daftar hitam untuk Anda.
    - **Interaktivitas Tinggi:** Baris properti memberikan umpan balik visual dengan menjadi lebih terang saat kursor diarahkan ke atasnya.
    - **Seleksi Massal:** Gunakan tombol "Tambah Semua" dan "Hapus Semua" untuk mengelola daftar hitam dengan cepat.
- **Dukungan Properti yang Luas:**
  - Plugin sekarang mendukung lebih banyak properti modern dari sebelumnya, memastikan konversi yang lebih akurat. Properti yang baru didukung meliputi:
    - **Teks Lanjutan:** `RichText`, `FontFace`, `LineHeight`, `TextDirection`, `TextTruncate`.
    - **Gambar Lanjutan:** `ResampleMode`, `TileSize`.
    - **Batas & Garis:** `BorderMode`, `BorderColor3`, dan properti `UIStroke` tambahan seperti `BorderOffset`, `BorderStrokePosition`, `StrokeSizingMode`, dan `ZIndex`.
    - **Tata Letak Fleksibel:** Properti `HorizontalFlex` dan `VerticalFlex` untuk `UIListLayout`.
- **Pratinjau Kode Langsung (`Live Code Preview`):**
  - **Umpan Balik Instan:** Lihat kode Luau yang akan dihasilkan secara *real-time* langsung di UI plugin.
  - **Pembaruan Dinamis:** Pratinjau secara otomatis diperbarui setiap kali Anda mengubah objek yang dipilih atau menyesuaikan pengaturan konversi apa pun.
  - **Salin dengan Mudah:** Kode ditampilkan dalam `TextBox` yang dapat dipilih, memungkinkan Anda untuk dengan cepat menyalin cuplikan (atau seluruh skrip) menggunakan `Ctrl+C`.
- **Deteksi Template Cerdas:**
  - **Kode Efisien:** Secara otomatis mendeteksi grup elemen yang berulang di dalam `UIListLayout` atau `UIGridLayout`.
  - **Output Ringkas:** Alih-alih menghasilkan kode yang repetitif, plugin akan membuat satu "template", tabel `variations` untuk properti yang berbeda, dan sebuah `for loop` untuk meng-kloning template tersebut. Ini secara drastis mengurangi ukuran skrip dan meningkatkan keterbacaan.
- **Output Kode Hierarkis:**
  - **Struktur Visual:** Kode yang dihasilkan memiliki indentasi yang secara visual mencerminkan hierarki induk-anak dari GUI asli di Explorer.
  - **Keterbacaan Tinggi:** Membuatnya sangat mudah untuk memahami struktur UI langsung dari skrip.
- **Pelestarian Kode Kustom:** Timpa skrip yang ada tanpa kehilangan kode kustom Anda. Logika yang Anda tulis di antara penanda `--// USER_CODE_START` dan `--// USER_CODE_END` akan tetap utuh.
- **Kode yang Sangat Dioptimalkan & Mudah Dibaca:**
  - **Performa Instansiasi Cepat:** Menggunakan teknik *deferred parenting* (menetapkan induk di akhir) untuk memastikan bahwa UI dimuat secepat mungkin saat skrip dieksekusi, bahkan untuk hierarki yang sangat besar.
  - **Serialisasi Standar:** Menggunakan `Color3.fromRGB()` untuk representasi warna yang jelas dan `UDim2.new()` untuk properti posisi/ukuran.
  - **Pengelompokan Properti Logis:** Properti secara otomatis dikelompokkan berdasarkan fungsi (misalnya, `Layout`, `Visual`, `Text`), membuatnya lebih mudah untuk dibaca dan dipahami.
  - **Minimalis:** Plugin secara otomatis mengabaikan properti yang memiliki nilai default, menghasilkan output yang paling bersih.
- **Fitur Tambahan:**
  - **Abaikan Objek dengan Mudah:** Abaikan `GuiObject` apa pun (dan semua turunannya) dari konversi dengan memilihnya di Explorer dan mencentang kotak "Abaikan Objek & Turunannya" di UI plugin.
  - **Pembuat Kode Contoh:** Secara otomatis menghasilkan skrip contoh untuk menunjukkan cara memuat dan menggunakan `ModuleScript` yang Anda buat.
- **Serialisasi Atribut:** Secara otomatis mengonversi semua atribut kustom (`:SetAttribute()`) pada `GuiObject` Anda, memastikan tidak ada data atau konfigurasi yang hilang.

---

## 🚀 Panduan Penggunaan

1.  **Instalasi:**
    - (Petunjuk instalasi akan ditambahkan di sini, biasanya melalui Roblox Plugin Marketplace).
2.  **Membuka Plugin:**
    - Buka Roblox Studio.
    - Di tab **PLUGINS**, Anda akan menemukan tombol toolbar baru bernama "GUI Tools".
    - Klik tombol **"Convert GUI to LocalScript"** untuk membuka jendela konfigurasi GUIConvert.
3.  **Proses Konversi:**
    - Di jendela **Explorer**, pilih `ScreenGui` atau `GuiObject` root yang ingin Anda konversi.
    - Jendela plugin akan menampilkan objek yang Anda pilih.
    - **Konfigurasikan Opsi Anda:**
      - **Output Script Type:** Pilih `ModuleScript` atau `LocalScript`.
      - **Trace Comments:** Aktifkan untuk menambahkan komentar yang menunjukkan path asli setiap objek.
      - **Overwrite Existing:** Aktifkan untuk menimpa skrip dengan nama yang sama. Kode kustom Anda akan dilestarikan.
      - **Live Sync:** Aktifkan untuk pembaruan skrip secara real-time saat Anda mengedit GUI.
      - **Auto Open:** Saat `Live Sync` aktif, aktifkan ini agar editor skrip secara otomatis membuka dan menampilkan perubahan. Ini dapat mengganggu jika Anda sedang mengerjakan skrip lain.
      - **Property Blacklist:** Centang properti yang ingin Anda abaikan.
    - Tekan tombol **"Convert"**.
4.  **Menemukan Skrip Anda:**
    - `ModuleScript` yang dihasilkan akan ditempatkan di dalam `ReplicatedStorage` > `GeneratedGuis`.
    - `LocalScript` yang dihasilkan akan ditempatkan di dalam `StarterPlayer` > `StarterPlayerScripts` > `GeneratedLocalGuis`.

---
## 🤝 Kontribusi

Saat ini, proyek ini tidak terbuka untuk kontribusi publik. Namun, saran dan laporan bug sangat kami hargai.
