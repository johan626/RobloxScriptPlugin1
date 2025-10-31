# GUIConvert Plugin

## 🇮🇩 Plugin untuk Mengonversi Hierarki GUI menjadi Skrip Lua di Roblox Studio

GUIConvert adalah sebuah plugin canggih untuk Roblox Studio yang dirancang untuk mempercepat alur kerja pengembangan antarmuka pengguna (UI). Plugin ini memungkinkan developer untuk secara visual merancang UI mereka di Explorer, lalu secara otomatis mengubah hierarki `GuiObject` tersebut menjadi skrip Luau (`ModuleScript` atau `LocalScript`) yang bersih, terorganisir, dan siap pakai.

---

## ✨ Fitur Utama

- **Konversi Sekali Klik:** Ubah `ScreenGui` atau `GuiObject` apa pun menjadi skrip Luau dengan satu klik.
- **Dua Pilihan Tipe Skrip:**
  - **`ModuleScript`**: Hasilkan modul yang dapat digunakan kembali yang mengembalikan sebuah fungsi `create()` untuk membangun UI. Ideal untuk diintegrasikan ke dalam kerangka kerja (framework) UI Anda.
  - **`LocalScript`**: Hasilkan skrip yang akan secara otomatis membuat UI di bawah `PlayerGui` saat permainan dimulai.
- **Sinkronisasi Langsung (`Live Sync`):** Secara otomatis memperbarui skrip yang terhubung setiap kali Anda membuat perubahan pada GUI sumber di Explorer. Fitur ini sangat mempercepat proses iterasi desain.
- **UI yang Intuitif:** Atur semua opsi konversi melalui jendela plugin yang mudah digunakan.
  - **Daftar Hitam Properti (`Property Blacklist`):**
    - **Pencarian Cepat:** Filter daftar properti secara dinamis menggunakan bar pencarian.
    - **Seleksi Massal:** Gunakan tombol "Pilih Semua" dan "Batal Pilih Semua" untuk mengelola properti yang terlihat dengan cepat.
    - **Manajemen Mudah:** Pilih properti mana yang ingin Anda abaikan selama proses konversi, sangat berguna saat menggunakan `UILayout` di mana `Position` dan `Size` diatur secara otomatis.
  - **Tombol Toggle Berkode Warna:** Pengaturan seperti *Live Sync*, *Overwrite Existing*, dan *Trace Comments* memiliki tombol yang jelas untuk status 'On' (Hijau) dan 'Off' (Merah).
- **Deteksi Template Cerdas:**
  - **Kode Efisien:** Secara otomatis mendeteksi grup elemen yang berulang di dalam `UIListLayout` atau `UIGridLayout`.
  - **Output Ringkas:** Alih-alih menghasilkan kode yang repetitif, plugin akan membuat satu "template", tabel `variations` untuk properti yang berbeda, dan sebuah `for loop` untuk meng-kloning template tersebut. Ini secara drastis mengurangi ukuran skrip dan meningkatkan keterbacaan.
- **Output Kode Hierarkis:**
  - **Struktur Visual:** Kode yang dihasilkan memiliki indentasi yang secara visual mencerminkan hierarki induk-anak dari GUI asli di Explorer.
  - **Keterbacaan Tinggi:** Membuatnya sangat mudah untuk memahami struktur UI langsung dari skrip.
- **Pelestarian Kode Kustom:** Timpa skrip yang ada tanpa kehilangan kode kustom Anda. Logika yang Anda tulis di antara penanda `--// USER_CODE_START` dan `--// USER_CODE_END` akan tetap utuh.
- **Kode yang Dioptimalkan:** Plugin secara otomatis mengabaikan properti yang memiliki nilai default, menghasilkan output yang lebih bersih dan efisien.
- **Fitur Tambahan:**
  - **Abaikan Objek dengan Mudah:** Abaikan `GuiObject` apa pun (dan semua turunannya) dari konversi dengan memilihnya di Explorer dan mencentang kotak "Abaikan Objek & Turunannya" di UI plugin.
  - **Pembuat Kode Contoh:** Secara otomatis menghasilkan skrip contoh untuk menunjukkan cara memuat dan menggunakan `ModuleScript` yang Anda buat.

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
      - **Property Blacklist:** Centang properti yang ingin Anda abaikan.
    - Tekan tombol **"Convert"**.
4.  **Menemukan Skrip Anda:**
    - Skrip yang baru dibuat akan ditempatkan di dalam `StarterPlayer` > `StarterPlayerScripts`.
    - `ModuleScript` akan berada di folder `GeneratedGuis`.
    - `LocalScript` akan berada di folder `GeneratedLocalGuis`.

---
## 🤝 Kontribusi

Saat ini, proyek ini tidak terbuka untuk kontribusi publik. Namun, saran dan laporan bug sangat kami hargai.
