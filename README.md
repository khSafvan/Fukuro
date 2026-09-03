# Fukurō

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE)

**Fukurō** (フクロウ) is a free and open-source manga reader for Android 8.0 (API 26) and above. Forked from [Tachiyomi](https://github.com/tachiyomiorg/tachiyomi) / [Mihon](https://github.com/mihonapp/mihon) (based on TachiyomiSY / TachiyomiAZ), it enhances reader usability, metadata integration, and source management while maintaining full compatibility with the existing manga source extension ecosystem.

### Key Features
- **Dynamic & Custom Categories**: Organize library content dynamically with custom source categories and drag-and-drop sorting.
- **Enhanced Manga Reader**: Automatic webtoon detection, autoscroll, color-adaptive smart backgrounds, and custom page preloading.
- **Advanced Library Search & Filters**: Support for exclusion terms, exact-quote matching, tracker status filtering, and content visibility controls.
- **Source Migration & Batch Tools**: In-app migration between sources, batch source importation, and tag-based local/global search.
- **Rich Metadata & Recommendations**: Recommendations powered by MyAnimeList, AniList, and MangaDex, plus enhanced E-Hentai/ExHentai integration.

---

## Installation

Download the latest APK from your GitHub repository releases page.

Two build variants are available:
- **Standard**: Standard release containing Firebase crash reporting and Google Play Services integrations.
- **FOSS**: Fully open-source release without Google Play Services or non-free dependencies.

To sideload the APK onto a connected Android device via ADB:

```bash
adb install -r Fukuro-standard.apk
```

*Note: The app includes a built-in update checker under `More → About → Check for updates`.*

---

## Development / Build Setup

### Prerequisites
- **Android Studio**: Hedgehog (2023.1.1) or newer recommended.
- **JDK**: Java 17 (e.g. Eclipse Temurin 17).
- **Android SDK**:
  - `minSdk`: 26 (Android 8.0 Oreo)
  - `compileSdk`: 37
  - `targetSdk`: 36
  - `NDK`: 29.0.14206865

### Clone & Open
```bash
git clone https://github.com/fukuro/fukuro.git
cd fukuro
```
Open the project root directory directly in Android Studio to trigger the initial Gradle sync.

### Build Commands
Use the included Gradle wrapper (`./gradlew`) to build and test:

- **Build Standard Debug APK**:
  ```bash
  ./gradlew assembleStandardDebug
  ```
  Output: `app/build/outputs/apk/standard/debug/`

- **Build FOSS Debug APK**:
  ```bash
  ./gradlew assembleFossDebug
  ```
  Output: `app/build/outputs/apk/foss/debug/`

- **Run Unit Tests**:
  ```bash
  ./gradlew test
  ```

- **Verify & Apply Code Formatting**:
  ```bash
  ./gradlew spotlessCheck
  ./gradlew spotlessApply
  ```

- **Automated Developer Scripts**:
  ```bash
  ./scripts/check.sh             # Validates shell script syntax and Spotless rules
  ./scripts/build.sh standard    # Builds debug APK variant (standard or foss)
  ./scripts/clean.sh --all       # Safely cleans module build directories and .gradle cache
  ```

### Testing & Running on Linux (via Waydroid)

This project is actively tested and developed on Linux using [Waydroid](https://waydro.id/) (container-based Android runtime).

#### 1. Sideload into Waydroid
Ensure your Waydroid session is running (`waydroid session start`), then install the built debug APK:

```bash
# Standard Debug Variant
waydroid app install app/build/outputs/apk/standard/debug/app-standard-debug.apk

# Or FOSS Debug Variant
waydroid app install app/build/outputs/apk/foss/debug/app-foss-debug.apk
```

#### 2. Launch the App
Launch Fukurō directly inside your Waydroid container using its debug package name:

```bash
waydroid app launch eu.kanade.tachiyomi.fukuro.debug
```

#### 3. Waydroid-Specific Considerations
- **Image Type (GApps vs. Vanilla)**: If running a vanilla (non-GApps) Waydroid image, use the **FOSS** build (`./gradlew assembleFossDebug`) to avoid harmless Firebase initialization warnings on launch.
- **Container Networking & DNS**: If manga source chapters time out or fail to load inside Waydroid, enable **DNS-over-HTTPS** in Fukurō (`More → Settings → Advanced → DNS-over-HTTPS → Cloudflare / Google`) to bypass container bridge DNS issues.
- **Local Manga & Backup Files**: You can transfer `.tachibk` backups or local chapter folders directly into Waydroid via the shared media path on your host (`~/.local/share/waydroid/data/media/0/`).

#### 4. UI Fast Iteration (Live Edit)
The UI is built with **Jetpack Compose**. When developing in Android Studio:
- Use **Compose Preview** directly in editor panels for instant layout rendering.
- Use **Live Edit** / **Apply Code Changes** (`Ctrl+Alt+F10` / `Cmd+Option+R`) to hot-swap Compose composables without a full rebuild.

---

#### Alternative: Physical Device / Standard ADB Testing
For contributors testing on a physical Android device or standard AVD emulator, ADB can be used directly (Waydroid also registers with ADB when active):

```bash
# Install via ADB
adb install -r app/build/outputs/apk/standard/debug/app-standard-debug.apk

# View logcat output filtered to Fukurō
adb logcat -s "Fukuro" "logcat"
```

### Secrets & Configuration
- **`local.properties`**: Android Studio automatically manages `sdk.dir`.
- **Optional API Secrets**: Release builds configure optional client credentials (`app/google-services.json` and `app/src/main/assets/client_secrets.json`). These files are ignored by git and are omitted by default in debug and FOSS builds.
- **Signing**: Debug builds automatically sign with the default Android debug keystore. Release builds require release keystore properties configured in your environment or CI.

---

## License & Credits

### Upstream Attribution
Fukurō is an open-source fork based on:
- [Tachiyomi](https://github.com/tachiyomiorg/tachiyomi) / [Mihon](https://github.com/mihonapp/mihon) by Javier Tomás and community contributors.
- [TachiyomiAZ](https://github.com/AZ-forks/TachiyomiAZ) by Az.
- [TachiyomiSY](https://github.com/jobobby04/tachiyomisy) by jobobby04.
- Additional features and inspiration derived from [TachiyomiJ2K](https://github.com/Jays2Kings/tachiyomiJ2K) by Jays2Kings and [Neko](https://github.com/CarlosEsco/Neko) by CarlosEsco.

Special thanks to all upstream contributors who contributed patches and features, including Az, jobobby04, She11Shocked, Carlos, and Goldbattle.

### License
This project is licensed under the **Apache License, Version 2.0**.
You may obtain a copy of the License in the [LICENSE](./LICENSE) file or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
