# ✨ Lumina — Personal Management App (iOS)

<div align="center">

![iOS 16+](https://img.shields.io/badge/iOS-16.0%2B-blue?style=for-the-badge&logo=apple)
![SwiftUI](https://img.shields.io/badge/SwiftUI-FF5A00?style=for-the-badge&logo=swift&logoColor=white)
![Go](https://img.shields.io/badge/Go_Core-00ADD8?style=for-the-badge&logo=go&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite_WAL-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![OWASP](https://img.shields.io/badge/OWASP-MASVS_Compliant-success?style=for-the-badge&logo=owasp)
![Offline-First](https://img.shields.io/badge/Storage-100%25_Offline-purple?style=for-the-badge)

<p align="center">
  <strong>Aplikasi All-in-One Pengelola Hidup Pribadi: Keuangan, Tabungan, Target, Kalender & Catatan Harian.</strong><br>
  100% Offline-First • Bebas Iklan • Tanpa Server Luar • Tanpa Langganan Berbayar • Standar Keamanan OWASP.
</p>

</div>

---

## 📱 Daftar Isi
- [Tentang Lumina](#-tentang-lumina)
- [Arsitektur Sistem (SwiftUI + Go Core)](#-arsitektur-sistem)
- [Fitur Utama](#-fitur-utama)
- [Standar Keamanan OWASP MASVS](#-standar-keamanan-owasp-masvs)
- [Struktur Direktori Proyek](#-struktur-direktori-proyek)
- [Cara Menjalankan Preview di Windows (VS Code)](#-cara-menjalankan-preview-di-windows-vs-code)
- [Panduan Instalasi ke iPhone Fisik (100% Gratis)](#-panduan-instalasi-ke-iphone-fisik-100-gratis)
  - [Opsi 1: Dari Komputer Windows (GitHub Actions + Sideloadly)](#opsi-1-dari-komputer-windows-github-actions--sideloadly)
  - [Opsi 2: Dari Komputer Mac (Xcode Standar)](#opsi-2-dari-komputer-mac-xcode-standar)
- [Pengujian Unit Test (Go Core)](#-pengujian-unit-test-go-core)
- [Lisensi](#-lisensi)

---

## 🌟 Tentang Lumina

**Lumina** dirancang untuk memberi Anda ketenangan dalam mengelola kehidupan sehari-hari tanpa mengorbankan privasi. Semua catatan transaksi, tabungan, agenda, dan jurnal rahasia Anda disimpan **eksklusif di memori lokal iPhone Anda** (`Application Support/lumina_v1.db`).

Dibangun dengan arsitektur hibrida modern:
- **Frontend**: SwiftUI (iOS 16+) dengan estetika *glassmorphism*, tipografi **SF Pro Rounded**, **Swift Charts**, haptics *Taptic Engine*, dan dukungan *Dark Mode* elegan.
- **Backend/Core**: Go (1.22+) dengan Clean Architecture (*Domain, Usecase, Repository, Bridge*) yang dikompilasi menjadi iOS Framework via `gomobile bind`.
- **Database**: Pure Go SQLite (`modernc.org/sqlite`) berkecepatan tinggi dengan mode **WAL (Write-Ahead Logging)** dan **FTS5 (Full-Text Search)**.

---

## 🏗 Arsitektur Sistem

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SwiftUI Frontend Layer                          │
│   (DashboardView, FinanceView, SavingsView, GoalsView, CalendarView)   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ @Published State Binding
┌───────────────────────────────────▼────────────────────────────────────┐
│                  SwiftUI ViewModels (@MainActor)                       │
│    DashboardVM, FinanceVM, SavingsVM, GoalsVM, NotesVM, AuthVM         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ async/await (Background Thread)
┌───────────────────────────────────▼────────────────────────────────────┐
│                    GoBridgeService (Swift Actor)                       │
│    • RPC Envelope: {"action": "...", "payload": "{...}"}               │
│    • Inisialisasi DB di Sandbox iPhone (Application Support)           │
│    • Mock Fallback Engine untuk Canvas Preview                         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Gomobile C-ABI Bridge
┌───────────────────────────────────▼────────────────────────────────────┐
│                       Go Bridge Layer (/core/bridge)                   │
│         Dispatch Handler & Serialisasi Envelope JSON                   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Typed Go Structs
┌───────────────────────────────────▼────────────────────────────────────┐
│                      Usecase Layer (/core/usecase)                     │
│   • FinanceUsecase (Safe-to-Spend™, Round-Up™, Anggaran, Neraca)       │
│   • SavingsUsecase (Proyeksi Target, Rekomendasi Tabungan H/M/B)       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Repository Interfaces
┌───────────────────────────────────▼────────────────────────────────────┐
│                    Repository Layer (/core/repository)                 │
│      FinanceRepo, SavingsRepo, GoalsRepo, CalendarNotesRepo            │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Pure Go SQLite Driver
┌───────────────────────────────────▼────────────────────────────────────┐
│               SQLite Local Database (WAL Mode + FTS5)                  │
│       File: /var/mobile/Containers/Data/.../lumina_v1.db              │
└────────────────────────────────────────────────────────────────────────┘
```

---

## ⚡ Fitur Utama

### 1. 🏠 Beranda (Dashboard) & Sapaan Dinamis
- Sapaan cerdas sesuai waktu (*Pagi, Siang, Sore, Malam*).
- Kartu total saldo keseluruhan, ringkasan pemasukan vs pengeluaran bulan ini.
- Kartu progres celengan teratas, checklist habit hari ini, agenda acara terdekat, dan cuplikan catatan harian.
- Tombol mengambang (**Floating Action Button `+`**) di tengah tab bar untuk aksi cepat mencatat transaksi, agenda, atau catatan.

### 2. 💳 Keuangan Cerdas & Multi-Dompet
- **Multi-Dompet**: Kelola Uang Tunai, Rekening Bank (BCA, Mandiri, dll.), dan E-Wallet (GoPay, OVO) dengan saldo masing-masing.
- **Kalkulator Safe-to-Spend™**: Menghitung secara dinamis uang belanja harian yang aman dihabiskan berdasarkan sisa hari bulan ini dan batas anggaran agar tidak mengalami defisit.
- **Otomatisasi Celengan Round-Up™**: Pembulatan nominal belanja (mis. belanja Rp 32.500 dibulatkan ke Rp 35.000, selisih **Rp 2.500** otomatis masuk ke celengan target Anda).
- **Anggaran Kategori**: Pengaturan limit belanja per kategori dengan slider ambang batas peringatan (*warning threshold*).
- **Swift Charts**: Visualisasi diagram batang mutasi mingguan dan diagram lingkaran pengeluaran.

### 3. 🎁 Tabungan & Celengan Impian
- Banyak celengan dengan nominal target, deadline waktu, ikon, dan palet warna.
- Lembar setor & tarik dana terhubung atomik ke dompet sumber.
- Cincin progres animasi (*Progress Ring*) dan proyeksi cerdas rekomendasi setoran rutin per hari, minggu, atau bulan.

### 4. 🎯 Target Hidup & Pelacak Kebiasaan (Habit Tracker)
- **Target Hidup**: Sub-task/milestone dengan checklist interaktif dan persentase otomatis.
- **Habit Tracker**: Pelacak streak harian (mis. *Minum Air 2L*, *Membaca Buku*) dengan efek animasi partikel **Confetti** saat kebiasaan berhasil dicentang.

### 5. 📅 Kalender & Agenda Harian
- Kalender grafikal interaktif untuk memilih tanggal.
- Pengingat acara lokal (*UserNotifications*) otomatis sebelum jadwal dimulai (5–60 menit).
- Filter riwayat agenda dan mutasi yang terjadi pada tanggal tertentu.

### 6. 📝 Catatan Harian, Jurnal & Pencarian Cepat FTS5
- Editor catatan ringan dengan mood tracker emoji (😊, 😌, 🚀, 💡, dll.).
- Label tag dan sematan catatan penting di atas (*Pin*).
- **Pencarian Full-Text Search (SQLite FTS5)** super cepat untuk menemukan kata kunci di seluruh isi catatan.

### 7. 📲 WidgetKit Suite (Home Screen & Lock Screen Widgets)
- **Saldo & Safe-to-Spend Widget** (`systemSmall`, `systemMedium`, `accessoryRectangular`, `accessoryCircular`).
- **Interactive Habit Tracker Widget** (`systemMedium`, `systemLarge`) berbasis **iOS 17+ AppIntent** — pengguna dapat mencentang habit langsung dari layar depan tanpa membuka aplikasi.
- **Celengan Widget** (`systemSmall`) dengan cincin progres persentase.

---

## 🛡 Standar Keamanan OWASP MASVS

Lumina menerapkan pedoman **OWASP Mobile Application Security Verification Standard (MASVS)**:

| Kategori OWASP | Implementasi di Lumina |
|---|---|
| **MASVS-STORAGE** | Hash kunci master dan kredensial sensitif disimpan eksklusif di **iOS Keychain Services** dengan level `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. |
| **MASVS-AUTH** | Pendaftaran Akun Lokal & Login menggunakan **PIN 6-Digit** yang di-hash dengan **Salted SHA-256** (garam kriptografi 32-byte acak via `SecRandomCopyBytes`). |
| **MASVS-THROTTLING** | Proteksi anti brute-force: Setelah 5 kali percobaan PIN salah, brankas otomatis mengaktifkan penalti **Lockout 30 Detik**. |
| **MASVS-PRIVACY** | **Privacy Shield**: Saat aplikasi masuk ke *App Switcher* (multitasking), layar otomatis diburamkan (*security mask*) agar saldo tidak terekam dalam snapshot screenshot iOS. |
| **MASVS-RESILIENCE** | Deteksi *jailbreak* otomatis untuk memastikan aplikasi berjalan di lingkungan sandbox yang aman. |

---

## 📂 Struktur Direktori Proyek

```
financial-ios-project/
├── .github/
│   └── workflows/
│       └── build-ios.yml             # CI/CD otomatis kompilasi IPA di macOS runner
├── core/                             # Backend / Core Logic Engine (Go 1.22+)
│   ├── bridge/
│   │   └── bridge.go                 # Gomobile C-ABI single envelope RPC
│   ├── domain/
│   │   └── models.go                 # Entitas relasional & DTO
│   ├── migrations/
│   │   └── migration.go              # Skema 18 tabel, FTS5 triggers, & initial seed
│   ├── repository/                   # CRUD SQLite (Finance, Savings, Goals, Notes)
│   ├── usecase/                      # Safe-to-Spend, Round-Up, Neraca, Proyeksi
│   └── tests/
│       └── finance_test.go           # Unit test menyeluruh (100% PASS)
├── ios/                              # Frontend SwiftUI (iOS 16+)
│   ├── App/
│   │   └── LuminaApp.swift           # Inisialisasi, Splash Loading, & Security Gate
│   ├── DesignSystem/
│   │   ├── Theme.swift               # Token warna, gradien, & haptic manager
│   │   ├── Typography.swift          # SF Pro Rounded font scaling
│   │   └── Components/               # Card, Button, ProgressRing, Confetti, Skeleton
│   ├── Features/
│   │   ├── Auth/                     # RegisterView, LoginView, AuthViewModel
│   │   ├── Dashboard/                # DashboardView & ViewModel
│   │   ├── Finance/                  # Multi-dompet, Mutasi, SafeToSpendCard
│   │   ├── Savings/                  # Celengan & Lembar Setor/Tarik
│   │   ├── Goals/                    # Target hidup & Habit tracker
│   │   ├── Calendar/                 # Kalender grafikal & Pengingat
│   │   ├── Notes/                    # Catatan harian & FTS5 search
│   │   └── Settings/                 # Kunci Face ID, Tema, Ekspor JSON/CSV
│   ├── Navigation/                   # LuminaTabBar & LuminaRootView
│   ├── Security/                     # Keychain, SecurityManager, ScreenShield
│   ├── Services/                     # GoBridgeService, Notification, Biometric
│   ├── Widgets/                      # WidgetKit suite & ToggleHabitIntent
│   └── Resources/                    # Info.plist, Localizable.strings (id/en)
├── preview/
│   └── index.html                    # 60 FPS Interactive iOS Simulator (Web Preview)
├── Makefile                          # Skrip otomasi 'make core' gomobile bind
├── preview.bat                       # Launcher 1-klik untuk web preview di Windows
└── README.md
```

---

## 💻 Cara Menjalankan Preview di Windows (VS Code)

Jika Anda sedang bekerja di komputer Windows dan ingin melihat antarmuka serta mencoba seluruh alurnya:

### Cara 1: Menggunakan Script Launcher (1 Detik)
Buka Terminal di folder proyek, jalankan:
```powershell
.\preview.bat
```
Browser laptop Anda akan langsung menampilkan **Interactive iPhone 16 Pro Simulator** dengan alur:
`Splash Loading -> Login PIN Keypad (Default: 123456 / Face ID) -> Beranda Interaktif`.

### Cara 2: Menjalankan Server Lokal Ringan
```powershell
python -m http.server 3000 --directory preview
```
Buka browser di alamat: `http://localhost:3000`.

---

## 📲 Panduan Instalasi ke iPhone Fisik (100% Gratis)

### Opsi 1: Dari Komputer Windows (GitHub Actions + Sideloadly)
*Metode ini tidak memerlukan komputer Mac sama sekali.*

1. **Jalankan Cloud Build di GitHub**:
   - Buka tab **Actions** pada repository ini: [Actions Lumina](https://github.com/zrahmatullah/ios-app-management/actions).
   - Tunggu workflow **"Build Lumina iOS App"** selesai (3–4 menit).
   - Di bagian bawah halaman build (**Artifacts**), unduh file **`Lumina-iOS-IPA`** (di dalamnya terdapat file `Lumina.ipa`).
2. **Sideload ke iPhone via Sideloadly**:
   - Unduh software gratis **[Sideloadly](https://sideloadly.io/)** di Windows.
   - Sambungkan iPhone ke laptop Windows via kabel USB (pilih *"Trust this computer"*).
   - Buka Sideloadly, tarik file `Lumina.ipa` ke dalamnya, masukkan Apple ID biasa Anda, lalu klik **Start**.
3. **Izinkan Aplikasi di iPhone (Sekali Saja)**:
   - Buka di iPhone: **Pengaturan > Umum > Manajemen VPN & Perangkat** -> ketuk nama Apple ID Anda lalu pilih **Percayai (Trust)**.
   - Buka: **Pengaturan > Privasi & Keamanan > Mode Pengembang (Developer Mode)** -> aktifkan toggle.
   - Selesai! Aplikasi Lumina siap digunakan.

---

### Opsi 2: Dari Komputer Mac (Xcode Standar)
1. Salin folder proyek ini ke komputer Mac.
2. Di Terminal Mac, buat framework Go Core:
   ```bash
   make core
   ```
3. Buka file `ios/Lumina.xcodeproj` di Xcode.
4. Sambungkan iPhone dengan kabel USB, pilih Apple ID Anda di tab **Signing & Capabilities** (*Personal Team* gratis).
5. Pilih iPhone Anda di toolbar atas, lalu tekan **Run (Cmd + R)**.

---

## 🧪 Pengujian Unit Test (Go Core)

Seluruh logika bisnis neraca, transfer saldo, proyeksi celengan, habit streak, Safe-to-Spend™, dan aturan Round-Up telah teruji dengan unit test otomatis:

```bash
cd core
go test -v ./tests/...
```

Output:
```text
=== RUN   TestAccountAndTransactionBalance
--- PASS: TestAccountAndTransactionBalance (0.13s)
=== RUN   TestTransferBetweenAccounts
--- PASS: TestTransferBetweenAccounts (0.13s)
=== RUN   TestSavingsProjectionAndDeposit
--- PASS: TestSavingsProjectionAndDeposit (0.14s)
=== RUN   TestGoalsAndHabitStreaks
--- PASS: TestGoalsAndHabitStreaks (0.18s)
=== RUN   TestSafeToSpendAndRoundUp
--- PASS: TestSafeToSpendAndRoundUp (0.10s)
PASS
ok      lumina/core/tests       4.394s
```

---

## 📄 Lisensi

Proyek ini dirilis di bawah lisensi [MIT License](LICENSE). Bebas digunakan, dimodifikasi, dan didistribusikan untuk keperluan pribadi maupun komersial.
