# Fukuro Development & Compose Live Edit Guide

This document outlines local development setup, performance flags, and Jetpack Compose best practices to ensure fast iterative development and full compatibility with Android Studio's **Live Edit (hot reload)**.

---

## 1. Android Studio Live Edit IDE Setup

Live Edit is an IDE-level preference that cannot be enabled via project source files. Each contributor should configure this once in Android Studio:

1. Open **Settings** (or **Preferences** on macOS).
2. Navigate to **Editor → Live Edit**.
3. Select your preferred reload mode:
   - **Push edits automatically (Immediate)**: Automatically pushes UI code edits to the running emulator/device on every pause. Recommended for rapid styling and layout iterations.
   - **Push edits manually (Ctrl+S / Cmd+S)**: Pushes edits only when you explicitly save. Useful when writing larger multi-line logic changes.
4. Ensure **Live Edit of Composables** is enabled.

> [!NOTE]
> Live Edit requires a device or emulator running Android 10 (API level 29) or higher, with Compose compiler and Compose runtime 1.3+.

> [!TIP]
> **Physical Phone Fallback**: If an AVD emulator cannot run or lacks hardware virtualization on your host, attach a physical phone via USB with **USB Debugging** enabled. Live Edit pushes incremental code changes seamlessly over USB with near-zero overhead.

---

## 2. Gradle Build Flags

The following build flags are configured in [gradle.properties](gradle.properties):

```properties
android.enableR8.fullMode=false
org.gradle.caching=true
org.gradle.parallel=true
org.gradle.configureondemand=true
```

### Why These Flags?
- **`android.enableR8.fullMode=false`**: Disables R8 full-mode aggressive whole-program restructuring and repackaging during incremental compilation. Debug builds do not minify (`isMinifyEnabled = false`), while release builds continue to minify and optimize safely using standard R8 rules.
- **`org.gradle.caching=true`**: Reuses compilation outputs across branches and builds.
- **`org.gradle.parallel=true`**: Compiles independent modules simultaneously.
- **`org.gradle.configureondemand=true`**: Configures only modules relevant to the requested task.

---

## 3. Live Edit Architecture & Compose Conventions

To ensure Live Edit can re-inject composable functions without losing user state or forcing full activity recreation, follow these four core principles:

### A. State Hoisting (Unidirectional Data Flow)
- **Do not** declare `remember { mutableStateOf(...) }` inside leaf items, list cells, or nested sub-components (e.g. dropdown menu state inside a list item).
- **Hoist state** to the screen's `ViewModel` / `ScreenModel` (as `StateFlow`) or to the nearest screen-level parent composable.
- Pass state down as parameters and user actions up as event lambdas (`onClick`, `onToggle`).

### B. Predictable Parameters & Stability Inference
- Domain models and UI data classes passed to composables should be annotated with `@Immutable` (e.g., `Chapter`, `Category`, `LibraryManga`, `LibraryItem`).
- **Never** inject services (e.g., `Injekt.get<SourceManager>()`) as default constructor properties of UI data classes. Resolve services at call sites or in ScreenModels to prevent invalidating stability.
- Annotate UI interfaces (such as `Tab`) with `@Stable` so the Compose compiler can safely skip recompositions.

### C. Zero Top-Level Side Effects
- **Never** perform database queries, SharedPreferences disk reads, or repository calls directly inside a composable function body (e.g. `Injekt.get<...>().get()` or `.await()`).
- Wrap one-time preference instances in `remember { Injekt.get<Preferences>() }`.
- Observe dynamic settings using `.collectAsState()` or within `LaunchedEffect(key)`.

### D. Modular UI Chunks
- Avoid giant monolithic composables (e.g., 200+ lines defining an entire screen).
- Break screens into single-responsibility sub-containers (e.g., `TopBarContainer`, `NavigatorOverlay`, `BottomBarContainer`).
- When a developer edits a styling attribute in a small sub-composable, Live Edit re-renders only that node without invalidating the whole screen hierarchy.

---

## 4. Interactive `@Preview` Micro-Components

Develop style-heavy, frequently modified micro-components in isolation using `@PreviewLightDark`:

- **Library Grid Items**: `MangaCompactGridItem` and `MangaComfortableGridItem` in [CommonMangaItem.kt](app/src/main/java/eu/kanade/presentation/library/components/CommonMangaItem.kt).
- **Reader Overlays**: `ReaderTopBar` and `ReaderBottomBar` in [ReaderTopBar.kt](app/src/main/java/eu/kanade/presentation/reader/appbars/ReaderTopBar.kt) and [ReaderBottomBar.kt](app/src/main/java/eu/kanade/presentation/reader/appbars/ReaderBottomBar.kt).
- Always wrap preview instances in `TachiyomiPreviewTheme` to test both light and dark themes simultaneously in Android Studio's design pane.
