# Fukurō — Engineering & Contributor Guide

Welcome to the **Fukurō** (フクロウ) engineering and contributor guide. This document is the comprehensive, deep-technical reference for setting up the development environment, understanding the application architecture and dependency graph, adhering to Compose and Live Edit conventions, running Linux and emulator testing workflows, and contributing code to the project.

---

## 1. Core Engineering Principles

Every architectural and implementation decision in Fukurō adheres to four foundational engineering rules:

1. **Native First (100% Kotlin & Jetpack Compose)**: No cross-platform abstraction bridges (e.g. React Native, Flutter). Continuous high-resolution bitmap decoding, memory-mapped I/O, and GPU texture uploading require direct JVM and native C++ control.
2. **Own Your Data**: Sync engines target user-controlled infrastructure (primarily private Git repositories via JGit). No centralized tracking, no proprietary databases, no mandatory accounts.
3. **Cut, Don't Carry**: We do not maintain legacy workarounds, dead code paths, or site-specific subsystems (such as E-Hentai/ExHentai tables). Code that does not directly serve high-performance manga and manhwa reading is removed.
4. **Modern OS Baseline (Android 12+ / API 31+)**: We reject pre-Android 12 compatibility shims. We leverage modern Android capabilities directly: Material You dynamic theming, Vulkan baseline, Splash Screen API, and high-performance background concurrency.

---

## 2. Architecture & Dependency Overview

### Module Structure

The project is organized into cohesive Gradle modules to enforce separation of concerns, improve compilation isolation, and maximize Gradle build caching:

```
Fukuro/
├── app/                  # Application entry point, navigation, DI wiring, background workers
├── baseline-profile/     # AOT Macrobenchmark compilation profiles for instant cold starts
├── core/
│   └── common/          # Low-level primitives, coroutine dispatchers, reactive extensions
├── core-metadata/        # Tracker schemas, rating metadata, and tag definitions
├── data/                 # SQLite database, DAOs, repositories, OkHttp network engine
├── domain/               # Pure Kotlin domain entities, business logic, interactor use cases
├── i18n/                 # Core multilingual translation strings
├── i18n-sy/              # Extended community translation sets
├── presentation-core/    # Design system, Compose theme tokens, icons, and base styling
├── presentation-widget/  # Home screen widgets and interactive Glance micro-components
├── scripts/              # Automated developer CLI utilities (run, check, build, clean)
├── source-api/           # Source interfaces, HTTP abstractions, and catalogue models
└── source-local/         # Local folder scanner and offline comic archive parser
```

#### Module Responsibilities

| Module | Purpose & Scope | Direct Dependencies |
|---|---|---|
| **`:domain`** | Core business models (`Manga`, `Chapter`, `Category`, `Track`) and use cases. Pure Kotlin with zero Android framework dependencies. | Pure Kotlin |
| **`:data`** | Implements domain repository interfaces. Handles SQLite database operations, migrations, preferences, and network dispatchers. | `:domain`, `:core:common` |
| **`:presentation-core`** | Houses the Jetpack Compose design system, color palettes, typography, and reusable UI elements. | `:core:common` |
| **`:presentation-widget`** | Glance-based Android home screen widgets and glanceable reading list components. | `:domain`, `:core:common` |
| **`:app`** | Ties modules together. Contains screen composables, `MainActivity`, `ReaderActivity`, Injekt/Koin DI graph, and application lifecycle. | All modules |
| **`:source-api`** | Public interfaces implemented by external manga and comic source extensions. | `:core:common` |
| **`:source-local`** | Scans local filesystem archives (`.cbz`, `.cbr`, `.zip`, `.epub`) and manages local chapter metadata. | `:source-api`, `:domain`, `:core:common` |
| **`:baseline-profile`** | Generates Android Baseline Profiles using AndroidX Benchmark to optimize AOT DEX compilation. | `:app` |

---

### Dependency Injection (DI) Graph

Fukurō uses **Injekt** (`uy.kohesive.injekt`) as its primary lightweight service locator and dependency injection container across the core architecture, supplemented by **Koin** (`io.insert-koin`) in specific SY modules.

- **Initialization**: Singletons and factories are registered during application startup inside `App.onCreate()`:
  - `AppModule`: Registers database instances, network helpers, caches (`ChapterCache`, `CoverCache`), download managers, and image savers.
  - `PreferenceModule`: Injects typed preferences (`SourcePreferences`, `ReaderPreferences`, `SecurityPreferences`, `UiPreferences`).
  - `DomainModule` & `SYDomainModule`: Injects interactor use cases (`GetManga`, `GetChaptersByMangaId`, `UpdateManga`).
- **Resolution**:
  - In non-UI classes, inject via `Injekt.get<T>()` or property delegate `by injectLazy()`.
  - In ViewModels / ScreenModels, inject dependencies through constructor parameters or resolve once upon initialization.
  - **Do not** pass Injekt singletons as default parameters into Composable functions, as this disrupts Compose compiler stability tracking.

---

### Core Migration Dependencies & Responsibilities

Four core low-level libraries power the modernized subsystems:

1. **Cronet**
   - **Role**: Chromium network stack integration.
   - **Responsibility**: Provides high-throughput HTTP/2 and HTTP/3 connection multiplexing, native QUIC protocol transport, robust DNS caching, and reduced handshake latency for downloading chapter pages across congested networks.
2. **JGit**
   - **Role**: Pure-Java Git implementation (`org.eclipse.jgit`).
   - **Responsibility**: Drives the event-sourced Git-backed synchronization engine. Connects directly to remote private Git repositories (GitHub, GitLab, self-hosted Gitea) over HTTPS using Personal Access Tokens (PATs) without requiring native command-line Git binaries on the device.
3. **Requery SQLite**
   - **Role**: High-performance native SQLite driver (`libsqlite3x`).
   - **Responsibility**: Replaces Android's stock framework SQLite bindings with modern SQLite C-libraries configured with Write-Ahead Logging (`PRAGMA journal_mode = WAL`), memory-mapped I/O (`PRAGMA mmap_size = 268435456`), and bundled query optimizations, guaranteeing sub-16ms query times for collections with thousands of chapters.
4. **NCNN**
   - **Role**: Tencent mobile neural network computing engine.
   - **Responsibility**: High-efficiency Vulkan GPU accelerated inference on mobile chipsets, enabling on-device super-resolution / upscaling models (Waifu2x / Real-CUGAN) for manga panels without cloud dependencies.

---

## 3. Development Environment & Build Setup

### Prerequisites

| Tool | Required Version | Notes |
|---|---|---|
| **Android Studio** | Ladybug (2024.2.1+) or newer | Essential for Compose Live Edit support. |
| **JDK** | Java 17 or Java 21 | OpenJDK 17/21 or Eclipse Temurin. |
| **Android SDK** | `compileSdk = 37`, `targetSdk = 36`, `minSdk = 31` | Android 12.0+ (API 31+) hard baseline. |
| **Gradle** | 8.13+ (via `./gradlew` wrapper) | Configured in `gradle/wrapper/gradle-wrapper.properties`. |
| **Virtualization** | `/dev/kvm` read/write access | Required for hardware-accelerated AVD emulation on Linux. |

### Environment Configuration

1. **`local.properties`**: Android Studio creates this file automatically, or you can create it manually at the repository root:
   ```properties
   sdk.dir=/home/username/Android/Sdk
   ```
2. **API Secrets (Optional)**:
   - **Google Drive Sync**: Place client credentials at `app/src/main/assets/client_secrets.json`. If omitted, local debug builds compile cleanly, and only Google Drive synchronization is disabled.
   - **Firebase**: Firebase configuration is optional. If `google-services.json` is not present, `FirebaseConfig` gracefully no-ops.
3. **Signing Configurations**:
   - **Debug builds**: Automatically signed with Android's built-in debug keystore (`~/.android/debug.keystore`).
   - **Release builds**: Configured in CI via environment secrets (`SIGNING_KEY`, `ALIAS`, `KEY_STORE_PASSWORD`, `KEY_PASSWORD`).

---

## 4. Single Unified Build Variant & Release Pipeline

Following flavor consolidation, the repository operates on a single unified build variant setup:

- **Build Types**:
  - `debug`: Development build with `.debug` package suffix (`eu.kanade.tachiyomi.fukuro.debug`), pseudo-locales enabled, and debugging tools attached.
  - `release`: Minified, obfuscated, and optimized build with R8/ProGuard enabled (`isMinifyEnabled = true`, `isShrinkResources = true`).
  - `benchmark`: Specialized build type inheriting from release for Baseline Profile generation.
- **ABI Splits**:
  Configured in `app/build.gradle.kts`:
  - `arm64-v8a`: Modern 64-bit ARM devices.
  - `armeabi-v7a`: Legacy 32-bit ARM devices.
  - `x86_64`: 64-bit emulators and Intel/AMD Chromebooks.
  - `x86`: 32-bit x86 environments.
  - `universal`: Combined APK containing all native ABIs.
- **Baseline Profiles**:
  The `:baseline-profile` module uses AndroidX Macrobenchmark to trace critical user journeys (cold startup, library scrolling, reader opening) and writes compiled DEX rules directly into `app/src/main/baselineProfiles/`.

### CI/CD Workflow

GitHub Actions automates continuous integration and releases:
- `.github/workflows/build_check.yml`: Triggered on pull requests. Runs Spotless checks, compiles the debug APK, and uploads the resulting build artifact.
- `.github/workflows/build_push.yml`: Triggered on pushes to the `release` branch. Assembles the release variant, executes unit tests, signs ABI-split APKs with production keys, and publishes release packages (`Fukuro.apk`, `Fukuro-arm64-v8a.apk`, etc.) to GitHub Releases.

---

## 5. Automated Developer CLI Suite

All developer automation scripts are located in [`scripts/`](scripts/) and feature error detection, colored terminal output, and non-zero exit codes on failure:

```bash
# ==============================================================================
# 1. Master Pipeline: Check -> Test -> Build -> Launch Emulator -> Install -> Run
# ==============================================================================
./scripts/run.sh

# Fast iterative UI testing (skips unit tests):
./scripts/run.sh --skip-test

# Target a specific Android Virtual Device:
./scripts/run.sh --avd Pixel_10a

# Clean build before assembling and running:
./scripts/run.sh --clean

# Stream app logcat output after launch:
./scripts/run.sh --logcat

# ==============================================================================
# 2. Code Quality & Spotless Formatting
# ==============================================================================
./scripts/check.sh             # Validates shell syntax and checks Kotlin formatting
./scripts/check.sh --apply     # Automatically fixes all formatting issues with spotlessApply
./scripts/check.sh --test      # Runs Spotless checks and unit tests together

# ==============================================================================
# 3. APK Assembling
# ==============================================================================
./scripts/build.sh debug       # Compiles debug APK and lists ABI outputs with file sizes
./scripts/build.sh release     # Compiles release build variant
./scripts/build.sh --clean     # Cleans before compiling

# ==============================================================================
# 4. Safe Cleaning
# ==============================================================================
./scripts/clean.sh             # Safely removes module build/ directories
./scripts/clean.sh --all       # Deep cleans build/, .cxx, native cache, and .gradle
```

### Manual Gradle Commands

```bash
# Build Debug APKs (produces universal + ABI split APKs)
./gradlew assembleDebug

# Build Release APKs
./gradlew assembleRelease

# Run Unit Tests
./gradlew test

# Verify & Apply Code Formatting
./gradlew spotlessCheck
./gradlew spotlessApply
```

---

## 6. Testing & Running Workflows

### A. Android Studio & Emulator

1. Open the project in Android Studio (Ladybug or newer).
2. Allow Gradle sync to finish.
3. Select the `debug` build variant in the **Build Variants** panel.
4. Select your target AVD (API 31+) or connected device.
5. Click **Run** (`Shift+F10`) or **Debug** (`Shift+F9`).

---

### B. Linux Testing via Waydroid

Fukurō is actively developed and tested on Linux using [Waydroid](https://waydro.id/), an LXC container-based Android runtime that runs Android without emulation overhead.

#### 1. Start Waydroid & Sideload APK
Ensure the Waydroid session is active, then install the built debug APK:
```bash
# Start Waydroid container session
waydroid session start

# Install universal debug APK
waydroid app install app/build/outputs/apk/debug/app-universal-debug.apk
```

#### 2. Launch Fukurō
Launch the application directly using its debug package name:
```bash
waydroid app launch eu.kanade.tachiyomi.fukuro.debug
```

#### 3. Waydroid Considerations
- **GApps vs. Vanilla Images**: The unified build runs cleanly on both vanilla and GApps Waydroid images; Firebase and Google Play Services calls gracefully no-op when absent.
- **Container Networking & DNS**: If manga source chapters time out or fail to load inside the Waydroid container, enable **DNS-over-HTTPS** in Fukurō (`More → Settings → Advanced → DNS-over-HTTPS → Cloudflare / Google`) to bypass container bridge DNS issues.
- **Shared Storage / Backups**: You can transfer `.tachibk` backups or local chapter archives directly into Waydroid through the host's shared media directory:
  ```bash
  cp -r ~/Downloads/MyManga ~/.local/share/waydroid/data/media/0/Download/
  ```
- **ADB Integration**: When Waydroid is active, it automatically binds to `localhost:5555` or registers in `adb devices`, allowing standard ADB commands and Live Edit pushes to work seamlessly.

---

### C. Physical Android Phone via USB Debugging

If your development host lacks hardware virtualization for an AVD emulator:

1. **Enable Developer Options**: On your Android 12+ device, open **Settings → About Phone** and tap **Build Number** 7 times.
2. **Enable USB Debugging**: In **Settings → System → Developer Options**, toggle on **USB Debugging**.
3. **Connect Device**: Connect your phone to your host machine via USB. Tap **Allow** on the USB debugging authorization prompt.
4. **Verify ADB Connection**:
   ```bash
   adb devices
   # Output should list your device as 'device'
   ```
5. **Install & Stream Logs**:
   ```bash
   adb install -r app/build/outputs/apk/debug/app-universal-debug.apk
   adb shell am start -n eu.kanade.tachiyomi.fukuro.debug/eu.kanade.tachiyomi.ui.main.MainActivity
   adb logcat -s "Fukuro" "logcat"
   ```

---

## 7. Android Studio Live Edit & Jetpack Compose Conventions

Fukurō is optimized for **Android Studio Live Edit** (hot-reloading composables directly on running emulators, physical phones, or Waydroid). To ensure Live Edit can re-inject composable functions without resetting state or restarting activities, follow these four architectural conventions:

### A. State Hoisting (Unidirectional Data Flow)
- **Never** declare `remember { mutableStateOf(...) }` inside list cells, grid items, or nested sub-components.
- **Hoist state** to the screen's `ScreenModel` / `ViewModel` (exposed as an immutable `StateFlow`) or to the top-level screen container.
- Pass state down as immutable arguments and user actions up as event lambdas (`onItemClick`, `onFavoriteToggle`).

### B. Predictable Parameters & Stability Inference
- Annotate domain and UI data classes passed to composables with `@Immutable` (e.g. `Manga`, `Chapter`, `Category`, `LibraryItem`).
- **Never** inject service singletons (such as `Injekt.get<SourceManager>()`) as default constructor parameters of UI data classes. Resolve services at call sites or in ScreenModels to prevent breaking compiler stability inference.
- Annotate UI interfaces with `@Stable` so the Compose runtime can safely skip unnecessary recompositions.

### C. Zero Top-Level Side Effects
- **Never** execute disk reads, database queries, or network calls directly inside a composable function body (e.g. `Injekt.get<Preferences>().get()` or `.await()`).
- Cache one-time preference references with `remember { Injekt.get<Preferences>() }`.
- Collect dynamic flows using `.collectAsState()` or within `LaunchedEffect(key)`.

### D. Modular UI Chunks
- Avoid giant monolithic composable functions (e.g. 200+ lines defining an entire screen).
- Deconstruct screens into single-responsibility sub-containers (e.g. `TopBarContainer`, `BottomBarContainer`, `GridContent`).
- When a styling attribute is modified in a small sub-composable, Live Edit re-renders only that specific node without recompiling the surrounding screen hierarchy.

### Interactive `@PreviewLightDark` Micro-Components
Develop style-heavy micro-components in isolation using `@PreviewLightDark`:
- **Library Grid Items**: `MangaCompactGridItem` and `MangaComfortableGridItem` in [CommonMangaItem.kt](file:///home/zack/Workshop/Fukuro/app/src/main/java/eu/kanade/presentation/library/components/CommonMangaItem.kt).
- **Reader Overlays**: `ReaderTopBar` and `ReaderBottomBar` in [ReaderTopBar.kt](file:///home/zack/Workshop/Fukuro/app/src/main/java/eu/kanade/presentation/reader/appbars/ReaderTopBar.kt) and [ReaderBottomBar.kt](file:///home/zack/Workshop/Fukuro/app/src/main/java/eu/kanade/presentation/reader/appbars/ReaderBottomBar.kt).
- Always wrap preview instances in `TachiyomiPreviewTheme` to verify light and dark Material You palettes concurrently.

---

## 8. Known Issues & Troubleshooting

| Symptom | Cause | Solution |
|---|---|---|
| **Emulator crashes or hangs on launch** | Corrupted AVD snapshot loading. | Start emulator with `./scripts/run.sh` (which includes `-no-snapshot-load`) or start emulator manually with `emulator -avd <name> -no-snapshot-load`. |
| **Manga images fail to load in Waydroid** | Container bridge network DNS failure. | Open Fukurō settings: **More → Settings → Advanced → DNS-over-HTTPS** and select **Cloudflare** or **Google**. |
| **Spotless check fails during build** | Kotlin or XML formatting does not match KtLint rules. | Run `./scripts/check.sh --apply` or `./gradlew spotlessApply` to automatically format all files. |
| **Out of memory during Gradle build** | Insufficient memory allocated to Gradle daemon. | Verify `org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m` in `gradle.properties`. |
| **Live Edit drops state on code change** | State declared in leaf composables instead of hoisted. | Hoist state to the parent screen container or ViewModel/ScreenModel using `StateFlow`. |
| **`/dev/kvm` permission denied** | Host user is not in the `kvm` user group. | Run `sudo usermod -aG kvm $USER` and log out/log back in. |

---

## 9. Contribution Standards & Pull Request Workflow

### Code Style & Spotless Formatting
All Kotlin, Gradle Kotlin DSL, and XML files must pass Spotless checks before being merged:
```bash
# Verify formatting
./scripts/check.sh

# Automatically apply formatting fixes
./scripts/check.sh --apply
```

### Commit Message Conventions
Commit messages must adhere to the [Conventional Commits](https://www.conventionalcommits.org/) specification:
- `feat(rendering): implement compose webtoon texture slicing`
- `perf(storage): replace UniFile traversal with java.io.File NIO channels`
- `refactor(sync): introduce append-only journal event schema`
- `fix(network): resolve cf_clearance cookie injection race condition`
- `docs(readme): synchronize PRD roadmap and developer scripts`

### Pull Request Verification Checklist
Before submitting a PR:
- [ ] `./scripts/check.sh` passes with zero formatting errors.
- [ ] `./gradlew test` passes all unit test suites.
- [ ] `./scripts/build.sh debug` compiles successfully.
- [ ] New UI components include interactive `@PreviewLightDark` functions where applicable.
- [ ] Commit history is clean and follows conventional commit semantics.

---

## 10. PRD Implementation Blueprint (The 7 Phases)

Contributors implementing roadmap features should follow this architectural plan:

### Phase 1 — Architecture & Scaffolding
- **Hard Baseline**: Set `minSdk = 31` across all modules.
- **Compatibility Cleanup**: Remove pre-Android 12 permission checks, legacy `Theme.AppCompat` wrappers, and old exact-alarm workarounds.
- **Compiler Optimization**: Enable Compose Compiler `StrongSkippingMode` in `gradle/build-logic` to eliminate unnecessary UI recompositions.
- **Dependency Integration**: Prepare DI wiring for Cronet, JGit, Requery SQLite, and NCNN.

### Phase 2 — Storage & Database Overhaul
- **Direct Filesystem Traversal**: Request `MANAGE_EXTERNAL_STORAGE` and replace all `UniFile` / DocumentFile traversals with standard `java.io.File` and NIO channels for downloading and indexing chapters.
- **Requery SQLite Driver**: Replace Android's stock SQLite bindings with Requery native SQLite bindings.
- **Concurrency PRAGMAs**:
  ```sql
  PRAGMA journal_mode = WAL;
  PRAGMA synchronous = NORMAL;
  PRAGMA temp_store = MEMORY;
  PRAGMA mmap_size = 268435456; -- 256MB memory-mapped I/O
  ```
- **Acceptance Criteria**: Instantaneous (<16ms perceived) library and category switching for collections exceeding 5,000 chapters.

### Phase 3 — High-Performance Rendering Engine
- **Hardware Compose Canvas**: Deprecate and remove `SubsamplingScaleImageView`. Build a dedicated hardware-accelerated Compose viewer.
- **Texture Slicing**: Manhwa webtoon panels exceeding 4,000px in height are automatically sliced into sub-bitmaps before rendering to avoid GPU texture limits and driver hangs.
- **Bitmap Recycling Pool**: Reusable memory buffers prevent frequent garbage collection churn during continuous rapid scrolling.
- **Ahead-of-Scroll Prefetcher**: Background I/O threads decode 3–5 pages ahead of current scroll position based on scroll velocity vectors.
- **Native Decoders**: JNI C++ integrations for next-gen image codecs: **AVIF** and **JPEG XL (JXL)**.
- **Acceptance Criteria**: Sustained 60fps (or 120Hz display refresh rate) through a 15,000px webtoon strip on mid-tier devices.

### Phase 4 — Dynamic Extension Engine
- **In-App APK Sandboxing**: Download extension `.apk` packages directly into secure internal storage (`context.noBackupFilesDir`).
- **Runtime Classloading**: Load and instantiate extension classes via `DexClassLoader` linked against host `:source-api` interfaces.
- **No Unknown App Prompts**: Users can install, update, and remove extensions entirely within Fukurō without encountering Android's disruptive OS-level package installer dialogs.

### Phase 5 — Git-Backed Sync Engine
- **Event-Sourced Architecture**: Replace all whole-database dumps with an append-only delta event journal (`journal.jsonl`). Each mutation (e.g. `CHAPTER_READ`, `MANGA_FAVORITED`, `CATEGORY_CHANGED`) is an immutable event with a timestamp and UUID.
- **Primary JGit Adapter**: Pure-Java Git integration connecting to any private Git repository (GitHub, GitLab, self-hosted Gitea) using a Personal Access Token (PAT).
- **Secondary Cloud Adapters**: Google Drive and OneDrive adapters storing the delta journal with ETag-based optimistic concurrency (`If-Match`).
- **Sync Protocol**:
  ```
  1. Pull remote journal commits
  2. Replay unseen events into local SQLite database
  3. Append local uncommitted journal events
  4. Push commit to remote repository
  ```
- **Acceptance Criteria**: Flawless sync between multiple devices with zero data loss or unrecoverable lockouts, even during abrupt network disconnects.

### Phase 6 — Access & Anti-Censorship
- **Silent Cloudflare Solver**: Upon receiving HTTP `403`/`503` Cloudflare Turnstile challenges, automatically launch an off-screen headless WebView, evaluate the challenge, extract `cf_clearance` and session cookies, and inject them into OkHttp's `CookieJar`.
- **DPI / SNI Bypass**: Custom `SocketFactory` implementing **TLS `ClientHello` Fragmentation** (splitting the SNI header across multiple TCP packets) to defeat ISP Deep Packet Inspection without requiring a VPN.
- **DoH Resolver**: Built-in DNS-over-HTTPS (Cloudflare / Google / Quad9) fallback to circumvent DNS poisoning.

### Phase 7 — The "Great SY Purge" & UI Polish
- **Subsystem Removal**: Completely delete `Ehentai.kt`, `Exhentai.kt`, custom tag namespace tables, watchlist synchronizers, and E-Hentai login management dialogs.
- **Dynamic Material You**: Full adoption of Android 12+ wallpaper-extracted dynamic colors (`dynamicLightColorScheme` / `dynamicDarkColorScheme`) as the primary design system.
- **Baseline Profiles**: Automated Macrobenchmark tests generate optimized Baseline Profiles for near-instant cold startup.

### Cross-Phase (Stretch) — On-Device AI Upscaling
- Integrate Tencent **NCNN** with Vulkan GPU acceleration.
- Implement lightweight Waifu2x / Real-CUGAN models to super-resolve low-bitrate manga scans on demand without stalling the prefetch pipeline.
