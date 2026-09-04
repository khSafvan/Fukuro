# Fukurō (フクロウ)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%2012%2B%20(API%2031%2B)-brightgreen.svg)](https://developer.android.com/about/versions/12)
[![Language](https://img.shields.io/badge/Language-Kotlin%20100%25-orange.svg)](https://kotlinlang.org/)
[![UI Framework](https://img.shields.io/badge/UI-Jetpack%20Compose-4285F4.svg)](https://developer.android.com/jetpack/compose)
[![PRD Status](https://img.shields.io/badge/PRD-Draft%20v1.0-purple.svg)](DEVELOPMENT.md#2-prd-implementation-blueprint)

> **A high-performance, privacy-respecting manga & manhwa reader for Android — forked from TachiyomiSY, stripped of bloat, and rebuilt for speed.**

---

## 1. Vision & Identity

**Fukurō** (フクロウ, Japanese for "owl") is a native Android manga and manhwa reader forked from **TachiyomiSY** (itself based on Tachiyomi and Mihon). The project's mission is to take a proven, community-trusted reading engine and rebuild its performance-critical paths — rendering, storage, sync, and networking — from the ground up, while aggressively shedding years of accumulated technical debt and site-specific bloat.

Our owl mascot embodies the product’s identity: **quiet, sharp-eyed, and built to see clearly in the dark corners of the web** that Cloudflare and ISP-level DPI censorship attempt to obscure.

```
       /\_/\
      ((@v@))   FUKURŌ — Seeing clearly where others can't.
      ():::()
       VV-VV
```

---

## 2. Why Fukurō? (Problems We Solve)

Popular Tachiyomi / Mihon forks are feature-rich but burdened by years of backwards-compatibility shims and legacy architectural bottlenecks:

| Problem Area | Legacy Mihon / TachiyomiSY Behavior | The Fukurō Solution |
|---|---|---|
| **Webtoon Rendering** | `subsampling-scale-image-view` causes GC pauses, memory spikes, and stutter on 15,000px+ long-strips. | **Hardware-accelerated Jetpack Compose Canvas**, bitmap pooling, dynamic texture slicing (>4000px), and proactive ahead-of-scroll prefetching. |
| **Storage Traversal** | Android Storage Access Framework (`UniFile`) causes heavy I/O lag on libraries with 5,000+ chapters. | Direct `java.io.File` traversal with `MANAGE_EXTERNAL_STORAGE` and native **Requery SQLite** with `WAL` journal mode (<16ms perceived response). |
| **Cloud Sync** | Fragile full-database JSON dumps to Google Drive corrupt easily on network drops, causing permanent sync lockouts. | **Git-backed, event-sourced append-only JSON journal** synced to user-owned private Git repositories (via JGit), with secondary cloud adapters. |
| **Network Censorship** | Users must manually solve Cloudflare loops in WebViews or run separate VPNs to bypass ISP SNI/DPI filtering. | **Silent headless Cloudflare challenge solver** (`cf_clearance` injection), TLS fingerprint normalization, and **ClientHello fragmentation** for DPI bypass without a VPN. |
| **Extension Installs** | Every extension update forces users through Android's disruptive "Install unknown apps" OS prompts. | **In-app dynamic extension loader** via runtime `DexClassLoader`, loading APK packages directly from sandboxed storage. |
| **Bloat & Complexity** | Hardcoded E-Hentai/ExHentai database tables, custom login managers, and legacy UI layers add weight and complexity. | **The Great SY Purge**: complete removal of non-core site subsystems, shrinking APK footprint and maximizing maintainability. |
| **Legacy OS Tax** | Supporting Android 8+ forces compatibility shims, blocking modern Android 12+ capabilities. | **Android 12 (API 31+) hard floor**: native Vulkan, Material You dynamic color, and SplashScreen API. |

---

## 3. Core Architectural Pillars

### 🚀 1. Hardware-Accelerated Rendering Engine
- Replaces `SubsamplingScaleImageView` with a hardware-accelerated Compose Canvas.
- **Texture Slicing**: Automatically chunks ultra-tall manhwa panels (>4000px) before GPU dispatch to prevent OpenGL texture dimension overflows.
- **Bitmap Pooling**: Zero-allocation recycled bitmap memory pools eliminate garbage collection pauses during fast scrolling.
- **Ahead-of-Scroll Prefetcher**: Background I/O threads decode 3–5 upcoming pages ahead of user scroll velocity.
- **Modern Codec Support**: Native JNI decoders for AVIF and JPEG XL formats.

### ⚡ 2. High-Throughput Direct Storage & Requery SQLite
- Uses `MANAGE_EXTERNAL_STORAGE` to bypass the slow Android DocumentFile/UniFile abstraction layer.
- Upgrades Android's default SQLite driver to native **Requery SQLite bindings**.
- Configures `PRAGMA journal_mode=WAL` and `PRAGMA synchronous=NORMAL` for concurrent, non-blocking reads during background downloads.

### 🔒 3. Git-Backed, Event-Sourced Sync Engine
- **Zero Full-DB Dumps**: Every action (mark chapter read, add manga, update category) is recorded as a lightweight JSON delta event.
- **User Data Ownership**: Synchronizes against a user's private Git repository (GitHub, GitLab, Gitea, or self-hosted) via pure-Java JGit.
- **Conflict-Free**: Offline-first event replaying guarantees zero data loss or database corruption even across interrupted networks.

### 🛡️ 4. Native Anti-Blocking & Censorship Circumvention
- **Headless Cloudflare Solver**: Silently solves JavaScript Turnstile/Cloudflare challenges in a background headless WebView and injects `cf_clearance` into OkHttp cookies.
- **DPI/SNI Splitting**: Custom `SocketFactory` fragments the TLS `ClientHello` packet across TCP segments, defeating deep-packet-inspection censorship without routing traffic through a third-party VPN.
- **Built-in DoH**: DNS-over-HTTPS fallback resolvers bypass ISP-level DNS poisoning.

### 📦 5. Frictionless Dynamic Extensions
- Downloads and stores extension APKs within internal application storage.
- Loads extension bytecode at runtime via `DexClassLoader`, resolving host API interfaces seamlessly.
- Never prompts the user with OS-level package installer dialogs.

---

## 4. Development Roadmap

Development follows the 7-phase build architecture established in the [Product Requirements Document](DEVELOPMENT.md#2-prd-implementation-blueprint):

| Phase | Milestone | Focus Area | Status |
|:---:|:---|:---|:---:|
| **1** | **Architecture & Scaffolding** | Set `minSdk=31`, remove legacy OS shims, enable Compose `StrongSkippingMode`, configure modern build tooling | 🟡 In Progress |
| **2** | **Storage & Database Overhaul** | Direct `java.io.File` traversal, Requery SQLite bindings, WAL mode | 📋 Planned |
| **3** | **Rendering Engine** | Compose hardware canvas, texture slicing, bitmap pooling, prefetch pipeline | 📋 Planned |
| **4** | **Dynamic Extension Engine** | `DexClassLoader` runtime APK loading, isolation sandbox | 📋 Planned |
| **5** | **Git-Backed Sync** | Event-sourced delta journal, JGit private repo synchronization | 📋 Planned |
| **6** | **Access & Anti-Blocking** | Silent Cloudflare challenge solving, TLS normalization, DPI `ClientHello` fragmentation | 📋 Planned |
| **7** | **The "Great SY Purge" & Polish** | Strip legacy E-Hentai subsystem, Baseline Profiles, Material You theming | 📋 Planned |
| **★** | **AI Upscaling (Stretch)** | On-device NCNN / Vulkan GPU page super-resolution (Waifu2x / Real-CUGAN) | 🔮 Stretch |

---

## 5. Product Principles & Non-Goals

### Product Principles
1. **Native First**: 100% Kotlin & Jetpack Compose. Cross-platform frameworks (e.g. React Native) introduce bridge overhead and memory latency during continuous high-res bitmap scrolling.
2. **Own Your Data**: Data synchronizes exclusively to user-controlled endpoints (private Git repositories or personal cloud drives). No proprietary backend, no accounts, no tracking.
3. **Cut, Don't Carry**: Non-essential features, legacy compatibility wrappers, and site-specific subsystems are purged rather than preserved.
4. **Modern OS, No Compromises**: Android 12+ only, unlocking modern platform APIs without polyfills.

### Non-Goals (v1)
- **No iOS Support in v1**: Any future iOS client would require a Kotlin Multiplatform core extraction or independent Swift client.
- **No Android < 12**: Devices running Android 11 or older will not be supported.
- **No E-Hentai Maintenance**: E-Hentai-specific metadata tables and UI will be removed.
- **No Hosted Cloud Service**: Fukuro will never operate a centralized user database or sync server.

---

## 6. Installation

### System Requirements
- **Operating System**: Android 12.0 (API Level 31) or higher.
- **Architecture**: `arm64-v8a`, `x86_64`, `armeabi-v7a`, or `universal`.

### Sideloading via ADB
Download the appropriate APK from the [Releases](https://github.com/khSafvan/Fukuro/releases) page and install:

```bash
# Install on connected device or running emulator
adb install -r app-universal-debug.apk
```

---

## 7. Developer Quickstart

### Prerequisites
- **Android Studio**: Ladybug (2024.2.1+) or newer.
- **JDK**: Java 17 or Java 21 (e.g. OpenJDK 21 / Eclipse Temurin).
- **Android SDK**: `compileSdk = 37`, `targetSdk = 36`, `minSdk = 31`.

### 🚀 One-Command Full Workflow
We provide an automated master pipeline script that validates code quality, executes unit tests, compiles the APK, launches the Android emulator (if not already running), installs the APK, and starts Fukurō:

```bash
./scripts/run.sh
```

### Developer Automation Scripts
Located in [`scripts/`](scripts/):

| Script | Command | Purpose |
|---|---|---|
| **Master Runner** | `./scripts/run.sh` | Full lifecycle: quality check → unit tests → APK build → boot emulator → install → launch |
| **Fast Iteration** | `./scripts/run.sh --skip-test` | Skips unit tests for rapid UI testing and Live Edit iteration |
| **Targeted AVD** | `./scripts/run.sh --avd Pixel_10a` | Starts a specific Android Virtual Device |
| **Code Checker** | `./scripts/check.sh` | Validates shell syntax and runs Spotless code formatting checks |
| **Auto-Format** | `./scripts/check.sh --apply` | Automatically fixes all Spotless Kotlin/XML formatting violations |
| **Build Helper** | `./scripts/build.sh [debug\|release]` | Builds APKs, detects architecture splits, and outputs package sizes |
| **Deep Clean** | `./scripts/clean.sh --all` | Cleans module `build/` directories, `.cxx`, native cache, and `.gradle` |

### Manual Build Commands
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

## 8. Live Edit & Android Studio Development

Fukurō is optimized for **Android Studio Live Edit** (hot-reload of Compose UI without rebuilding APKs):

1. In Android Studio, go to **Settings → Editor → Live Edit**.
2. Select **Push edits automatically (Immediate)**.
3. Ensure **Live Edit of Composables** is checked.
4. Run `./scripts/run.sh` to launch your emulator, then edit Composables in real-time.

For detailed architecture rules (State Hoisting, `@Immutable` models, and `@PreviewLightDark` micro-components), see [DEVELOPMENT.md](DEVELOPMENT.md).

---

## 9. Attribution & License

### Upstream Heritage
Fukurō is built upon the foundational work of the open-source manga reader community:
- [Tachiyomi](https://github.com/tachiyomiorg/tachiyomi) / [Mihon](https://github.com/mihonapp/mihon) by Javier Tomás and contributors.
- [TachiyomiSY](https://github.com/jobobby04/tachiyomisy) by jobobby04.
- [TachiyomiAZ](https://github.com/AZ-forks/TachiyomiAZ) by Az.
- [TachiyomiJ2K](https://github.com/Jays2Kings/tachiyomiJ2K) by Jays2Kings.
- [Neko](https://github.com/CarlosEsco/Neko) by CarlosEsco.

### License
This project is licensed under the **Apache License, Version 2.0**. See the [LICENSE](LICENSE) file for details.
