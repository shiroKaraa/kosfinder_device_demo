# KosFinder Device Demo

Aplikasi Flutter standalone untuk praktikum **Worksheet 10 — Advanced Mobile Features & Device Integration**.
Aplikasi ini mendemonstrasikan integrasi fitur perangkat (kamera, galeri, GPS, sensor) dan penyimpanan lokal,
dengan modul pengayaan Supabase Storage.

## Identitas

| | |
|---|---|
| **Nama** | I Kadek Dwi Bajaskara |
| **NIM** | 2415051068 |
| **Kelas** | PTI 5A |
| **Mata Kuliah** | Pemrograman Mobile |
| **Dosen** | Dr. Ir. I Ketut Resika Arthana, S.T., M.Kom. |
| **TA** | Made Yuda Sadewa, S.Pd. |

## Fitur

### Fitur Wajib

- **Kamera & Galeri** (`image_picker`): memilih foto JPG/JPEG/PNG maksimal 5 MB, lalu menyalinnya secara
  permanen ke Application Documents Directory.
- **GPS & Runtime Permission** (`geolocator`): tombol ambil koordinat dengan penanganan `denied`,
  `deniedForever`, GPS nonaktif, dan timeout. Izin diminta saat tombol ditekan, bukan otomatis saat
  aplikasi dibuka.
- **Draft Lokal** (`path_provider` + `shared_preferences`): metadata (nama, path foto, lat/lng)
  disimpan dalam format JSON dan otomatis dipulihkan saat aplikasi dibuka kembali.

### Fitur Pengayaan

- **Supabase Storage** (`supabase_flutter`): anonymous sign-in, upload ke bucket `kosfinder-demo`
  di dalam folder `{uid}/`, dengan RLS policy yang ketat.
- **Sensor Accelerometer** (`sensors_plus`): demo `userAccelerometerEventStream` dengan penanganan
  sensor tidak tersedia.

## Dependency Utama

| Package | Versi | Kegunaan |
|---------|-------|----------|
| `image_picker` | ^1.2.4 | Kamera & galeri |
| `geolocator` | ^14.1.2 | GPS & runtime permission |
| `path_provider` | ^2.1.6 | Application Documents Directory |
| `shared_preferences` | ^2.5.6 | Draft lokal (`SharedPreferencesAsync`) |
| `supabase_flutter` | ^2.18.3 | Auth anonymous + Storage upload |
| `sensors_plus` | ^7.1.1 | Accelerometer stream |

## Struktur Folder

```text
lib/
├── main.dart
├── cloud_config.dart
├── pages/
│   ├── device_demo_page.dart
│   └── sensor_demo_page.dart
└── services/
    ├── draft_repository.dart
    ├── device_location_service.dart
    └── photo_upload_service.dart
test/
└── widget_test.dart
```

## Cara Menjalankan

### Mode Lokal

```bash
flutter pub get
flutter run
```

Aplikasi berjalan tanpa backend. Tombol upload Supabase dalam keadaan nonaktif dan badge di header
menampilkan **"Mode lokal/offline"**.

### Mode Supabase (Pengayaan)

#### 1. Setup Supabase (sekali saja)

1. Buat project baru di [Supabase Dashboard](https://supabase.com/dashboard).
2. Buka **Authentication → Sign In / Providers**, lalu aktifkan **Anonymous Sign-Ins**.
3. Buka **Storage → New Bucket** dengan pengaturan berikut:
   - Nama: `kosfinder-demo`
   - Public: **ON**
   - Ukuran file maksimal: **5 MB**
   - MIME type yang diizinkan: `image/jpeg,image/png`
4. Buka **SQL Editor**, lalu jalankan policy berikut:

   ```sql
   drop policy if exists "ws10_demo_upload_own_folder" on storage.objects;

   create policy "ws10_demo_upload_own_folder"
   on storage.objects
   for insert
   to authenticated
   with check (
     bucket_id = 'kosfinder-demo'
     and (storage.foldername(name))[1] = (select auth.uid()::text)
   );
   ```

5. Buka **Project Settings → API**, lalu salin **Project URL** dan **Publishable key**.
   > ⚠️ Jangan gunakan `service_role` / secret key.

#### 2. Buat file `env.json`

Buat file `env.json` di root project (**jangan di-commit**):

```json
{
  "SUPABASE_URL": "https://xxxx.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_xxx"
}
```

Pastikan `.gitignore` memuat baris berikut:

```gitignore
# Environment variables (Supabase credentials)
env.json
.env
*.key
```

#### 3. Jalankan aplikasi

```bash
flutter run --dart-define-from-file=env.json
```

Badge header berubah menjadi **"Lokal + Supabase"** dan tombol upload aktif.

## Pengujian

```bash
flutter analyze
flutter test
```

## Keterbatasan Emulator

- **Kamera**: emulator default menyediakan kamera virtual dengan hasil simulasi (bukan foto nyata).
- **GPS**: gunakan *Extended Controls → Location* untuk mensimulasikan koordinat.
- **Accelerometer**: emulator default tidak mensimulasikan sensor, sehingga halaman Demo Sensor
  menampilkan pesan "sensor tidak tersedia" setelah 3 detik. Gunakan *Extended Controls → Virtual
  sensors* (jika emulator mendukung) atau HP fisik.

## Dokumentasi Screenshot

Seluruh screenshot disimpan di folder `docs/screenshots/`.

| # | File | Keterangan |
|---|------|------------|
| 1 | `01-mode-lokal.png` | Badge "Mode lokal/offline", tombol upload nonaktif |
| 2 | `02-foto-galeri.png` | Preview foto terpilih dari galeri |
| 3 | `03-gps-berhasil.png` | Koordinat Lat/Lng tampil |
| 4 | `04-draft-restore.png` | Setelah app ditutup-buka, nama + foto + koordinat terpulihkan |
| 5 | `05-negatif-deny.png` | Snackbar "Izin lokasi ditolak…" |
| 6 | `06-negatif-gps-off.png` | Snackbar "GPS/lokasi perangkat tidak aktif…" + tombol Settings |
| 7 | `07-negatif-file-besar.png` | Snackbar "Ukuran foto maksimal 5 MB" |
| 8 | `08-negatif-upload-offline.png` | Snackbar error upload + draft tetap ada |
| 9 | `09-supabase-upload.png` | `storagePath` + `publicUrl` tampil |
| 10 | `10-supabase-dashboard.png` | File di bucket `kosfinder-demo`, folder UID |
| 11 | `11-sensor-tidak-tersedia.png` | Card "sensor tidak tersedia" di emulator default |
| 12 | `12-sensor-hp.png` *(opsional)* | Nilai X/Y/Z berubah di HP fisik |

## Catatan Keamanan

- Bucket `kosfinder-demo` bersifat **Public**: siapa pun yang punya URL dapat melihat foto.
  Jangan unggah foto pribadi, gunakan foto demo nonprivat.
- `env.json` tidak boleh di-commit ke GitHub.
- Jangan gunakan `service_role` / secret key di aplikasi Flutter.

## Lisensi

Tugas akademik. Tidak untuk distribusi publik.