# Fukurō (フクロウ)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%2012%2B%20(API%2031%2B)-brightgreen.svg)](https://developer.android.com/about/versions/12)
[![Language](https://img.shields.io/badge/Language-Kotlin%20100%25-orange.svg)](https://kotlinlang.org/)
[![UI Framework](https://img.shields.io/badge/UI-Jetpack%20Compose-4285F4.svg)](https://developer.android.com/jetpack/compose)

> **A high-performance, privacy-respecting manga and manhwa reader for Android — forked from TachiyomiSY, stripped of legacy bloat, and rebuilt for speed.**

---

## What is Fukurō?

**Fukurō** (フクロウ, Japanese for "owl") is a native Android manga and comic reader built for readers who demand high-speed browsing and deep customization. Forked from **TachiyomiSY** (itself based on Tachiyomi and Mihon), Fukurō focuses on modern Android capabilities, removing legacy compatibility shims, eliminating bloat, and delivering an ultra-smooth reading experience.

Our owl mascot embodies the product's identity: quiet, sharp-eyed, and built to see clearly anywhere on the web.

```
       /\_/\
      ((@v@))   FUKURŌ — Seeing clearly where others can't.
      ():::()
       VV-VV
```

---

## Key Features

- **⚡ Modern Jetpack Compose UI**: Fast, responsive, fluid interface designed exclusively with 100% Kotlin and Jetpack Compose.
- **🎨 Material You Dynamic Theming**: Adapts automatically to your wallpaper palette with full dynamic light and dark themes on Android 12+.
- **📖 Versatile Reading Modes**: Continuous vertical webtoon strip, left-to-right, right-to-left, and double-page viewing with custom scaling and color filters.
- **📂 Local & Remote Library Support**: Read offline archives (`.cbz`, `.cbr`, `.zip`, `.epub`) or browse thousands of community sources.
- **🛡️ Built-in Privacy & Anti-Censorship**: Integrated DNS-over-HTTPS (DoH) resolvers and TLS fingerprinting protections keep your reading private.
- **🔄 Flexible Sync & Backups**: Automated tracking integration with AniList, MyAnimeList, Kitsu, Shikimori, Bangumi, and Komga, plus robust backup support.
- **🚫 Zero Ads, Zero Tracking**: Free and open source software with no telemetry, no tracking libraries, and no monetization.

---

## Installation

### System Requirements
- **Operating System**: Android 12.0 (API Level 31) or higher.
- **Supported Architectures**: `arm64-v8a` (most modern devices), `armeabi-v7a` (older 32-bit), `x86_64`, or `universal`.

### Download & Sideload
1. Visit the [Releases](https://github.com/khSafvan/Fukuro/releases) page.
2. Download the appropriate `.apk` for your device:
   - **`Fukuro-arm64-v8a.apk`**: Recommended for almost all modern Android phones and tablets.
   - **`Fukuro.apk`**: Universal package containing all device architectures (choose this if unsure).
3. Open the downloaded file on your Android device and confirm installation when prompted.

---

## Development & Technical Documentation

See [DOCUMENT.md](DOCUMENT.md) for development setup and technical documentation.

---

## Attribution & License

### Upstream Heritage
Fukurō is built upon the foundational work of the open-source manga reader community:
- [Tachiyomi](https://github.com/tachiyomiorg/tachiyomi) / [Mihon](https://github.com/mihonapp/mihon) by Javier Tomás and contributors.
- [TachiyomiSY](https://github.com/jobobby04/tachiyomisy) by jobobby04.
- [TachiyomiAZ](https://github.com/AZ-forks/TachiyomiAZ) by Az.
- [TachiyomiJ2K](https://github.com/Jays2Kings/tachiyomiJ2K) by Jays2Kings.
- [Neko](https://github.com/CarlosEsco/Neko) by CarlosEsco.

### License
This project is licensed under the **Apache License, Version 2.0**. See the [LICENSE](LICENSE) file for details.
