# Volly Superstars  (com.sano.volsu)
Developer: Sano - Game voli 3D offline (Godot 4.2, GL Compatibility)

## Cara build APK lewat GitHub
1. Buat repo baru di GitHub, upload SEMUA isi folder ini (termasuk folder `.github`).
2. Buka tab **Actions** > **Build Android APK** > tunggu selesai (sekitar 5-10 menit).
3. Buka hasil run > bagian **Artifacts** > download **VollySuperstars-APK** > ekstrak > install `VollySuperstars.apk`.

Build otomatis jalan tiap push ke branch main/master, atau klik **Run workflow** manual.
APK yang dihasilkan adalah debug-signed (bisa langsung di-install).

## Isi
- 1000 pemain buatan (nama Indonesia/Jepang/Korea), 100 pemain bintang, 32 legend Haikyuu, 130 team
- Kartu pemain, transfer (Available/Search/Save), shop pack, misi, daily reward, upgrade stats
- Story 1-100, Tournament auto save, tutorial 20 langkah, musik + efek suara
- `tools/gen_assets.py` = pembuat icon dan audio (opsional, aset sudah ada)

## Update v2
- Kamera dari atas (lapangan horizontal), penonton, wasit, maskot, pemain 3D dengan animasi halus
- Bar timing + cincin penanda bola, tombol aksi selalu tampil
- Tutorial: sentuh di mana saja berfungsi + pengaman anti-nyangkut
- Menu utama dengan background animasi dan maskot

## Update v3
- Tutorial berdiri sendiri (layar terpisah, 20 langkah sentuh)
- 1.132 portrait pemain detail di folder `faces/`, tekstur lapangan di `tex/`, maskot berlayer di `mascot/`
- Musik: taruh `menu.mp3` dan `match.mp3` di `/sdcard/Download/VollyMusic/`, tools Termux ikut mengunggahnya
  (atau taruh manual sebagai `audio/bgm_menu.mp3` dan `audio/bgm_match.mp3` di repo)
