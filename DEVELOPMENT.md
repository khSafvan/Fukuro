# Fukurō Engineering & Contributor Guide

Welcome to the **Fukurō** (フクロウ) contributor and architecture guide. This document serves as the technical companion to the [Product Requirements Document (PRD)](README.md#4-development-roadmap), outlining our module structure, implementation blueprint, development environment, Jetpack Compose conventions, and automated tooling.

---

## 1. Core Engineering Principles

Every architectural and implementation decision in Fukurō adheres to four foundational rules:

1. **Native First (100% Kotlin & Jetpack Compose)**: No cross-platform abstraction bridges (e.g. React Native, Flutter). Continuous high-resolution bitmap decoding, memory-mapped I/O, and GPU texture uploading require direct JVM and native C++ control.
2. **Own Your Data**: Sync engines target user-controlled infrastructure (primarily private Git repositories via JGit). No centralized tracking, no proprietary databases, no mandatory accounts.
3. **Cut, Don't Carry**: We do not maintain legacy workarounds, dead code paths, or site-specific subsystems (such as E-Hentai/ExHentai tables). Code that does not directly serve high-performance manga and manhwa reading is removed.
4. **Modern OS Baseline (Android 12+ / API 31+)**: We reject pre-Android 12 compatibility shims. We leverage modern Android capabilities directly: Material You dynamic theming, Vulkan baseline, Splash Screen API, and high-performance background concurrency.

---

## 2. Repository & Multi-Module Architecture

The project is structured into cohesive Gradle modules to enforce clean separation of concerns and maximize build caching:

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
├── presentation-widget/  # Home screen widgets and interactive micro-components
├── scripts/              # Automated developer CLI utilities (run, check, build, clean)
├── source-api/           # Source interfaces, HTTP abstractions, and catalogue models
└── source-local/         # Local folder scanner and offline comic archive parser
```

### Module Responsibilities

| Module | Purpose & Scope | Dependencies |
|---|---|---|
| **`:domain`** | Contains core entities (`Manga`, `Chapter`, `Category`, `Track`) and use cases. Pure Kotlin; no Android framework dependencies. | None (pure Kotlin) |
| **`:data`** | Implements domain repository interfaces. Manages SQLite databases, migrations, preferences, and network clients. | `:domain`, `:core:common` |
| **`:presentation-core`** | Houses our Jetpack Compose design system, color palettes, typography, and reusable UI components. | `:core:common` |
| **`:app`** | Ties modules together. Contains screen composables, `MainActivity`, `ReaderActivity`, Injekt/Koin DI graph, and application lifecycle. | All modules |
| **`:source-api`** | Public interfaces implemented by external manga source extensions. | `:core:common` |
| **`:baseline-profile`** | Generates Android Baseline Profiles using AndroidX Benchmark to optimize AOT DEX compilation. | `:app` |

---

## 3. PRD Implementation Blueprint (The 7 Phases)

Contributors should reference this blueprint when implementing features against the [Product Requirements Document](README.md#4-development-roadmap).

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

---

## 4. Development Environment & Automated CLI Suite

### Prerequisites
- **JDK**: Java 17 or 21 (OpenJDK / Eclipse Temurin).
- **Android SDK**: `compileSdk = 37`, `targetSdk = 36`, `minSdk = 31`. Configured in `local.properties`:
  ```properties
  sdk.dir=/home/zack/Android/Sdk
  ```
- **Virtualization**: `/dev/kvm` accessible for hardware-accelerated emulator execution.

### Automated Developer CLI Suite
All scripts are located in [`scripts/`](scripts/) and feature rigorous error detection, colored diagnostics, and non-zero exit codes on failure:

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

---

## 5. Android Studio Live Edit & Jetpack Compose Conventions

Fukurō is architected for **Android Studio Live Edit** (hot-reloading composables directly on running emulators/devices). To ensure Live Edit can re-inject composable functions without dropping state or restarting activities, adhere to these four architectural rules:

### A. State Hoisting (Unidirectional Data Flow)
- **Never** declare `remember { mutableStateOf(...) }` inside leaf items, list cells, or nested sub-components.
- **Hoist state** to the screen’s `ScreenModel` / `ViewModel` (exposed as a `StateFlow`) or to the top-level screen container.
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
- **Library Grid Items**: `MangaCompactGridItem` and `MangaComfortableGridItem` in [CommonMangaItem.kt](app/src/main/java/eu/kanade/presentation/library/components/CommonMangaItem.kt).
- **Reader Overlays**: `ReaderTopBar` and `ReaderBottomBar` in [ReaderTopBar.kt](app/src/main/java/eu/kanade/presentation/reader/appbars/ReaderTopBar.kt) and [ReaderBottomBar.kt](app/src/main/java/eu/kanade/presentation/reader/appbars/ReaderBottomBar.kt).
- Always wrap preview instances in `TachiyomiPreviewTheme` to verify light and dark Material You palettes concurrently.

---

## 6. Code Style, Spotless & Git Contribution Standards

### Formatting Verification
All Kotlin and XML files must conform to the project's Spotless configuration. Before submitting any changes, verify and format your code:

```bash
# Verify formatting
./scripts/check.sh

# Automatically apply formatting fixes
./scripts/check.sh --apply
```

### Commit Message Conventions
Commit messages should follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat(rendering): implement compose webtoon texture slicing`
- `perf(storage): replace UniFile traversal with java.io.File NIO channels`
- `refactor(sync): introduce append-only journal event schema`
- `fix(network): resolve cf_clearance cookie injection race condition`
- `docs(readme): synchronize PRD roadmap and developer scripts`

### Pull Request Verification Checklist
Before opening a PR:
- [ ] `./scripts/check.sh` passes with zero formatting errors.
- [ ] `./gradlew test` passes all unit test suites.
- [ ] `./scripts/build.sh debug` compiles successfully.
- [ ] New UI components include interactive `@PreviewLightDark` functions.
- [ ] Commit history is clean and follows conventional commit semantics.
