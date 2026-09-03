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

- **Build Debug APK**:
  ```bash
  ./gradlew assembleDebug
  ```
  Output: `app/build/outputs/apk/debug/app-debug.apk`

- **Build Release APKs**:
  ```bash
  ./gradlew assembleRelease
  ```
  Output: `app/build/outputs/apk/release/`

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
  ./scripts/build.sh             # Builds debug APK (or ./scripts/build.sh release)
  ./scripts/clean.sh --all       # Safely cleans module build directories and .gradle cache
  ```

### Running & Debugging with Android Studio

Android Studio is the recommended environment for developing, running, and debugging Fukurō.

#### 1. Run / Debug from Android Studio
- Open the project in Android Studio.
- Select the **app** run configuration and **debug** build variant from the **Build Variants** tool window.
- Select your target Android Virtual Device (AVD) or connected physical device (API 26+).
- Click **Run** (`Shift+F10`) or **Debug** (`Shift+F9`).

#### 2. Fast UI Iteration (Live Edit & Previews)
The UI is built with **Jetpack Compose**:
- **Live Edit**: Configure in **Settings → Editor → Live Edit** to push Composable code changes directly to the running device without full rebuilds.
- **Compose Previews**: View interactive `@PreviewLightDark` components directly in the editor split pane.
- See [DEVELOPMENT.md](DEVELOPMENT.md) for full Live Edit conventions and architectural guidelines.

#### 3. Command Line & ADB Testing
To install and inspect debug builds directly via ADB:

```bash
# Install debug build onto active device/emulator
adb install -r app/build/outputs/apk/debug/app-debug.apk

# Launch the debug application
adb shell am start -n eu.kanade.tachiyomi.fukuro.debug/eu.kanade.tachiyomi.ui.main.MainActivity

# View logcat output filtered to Fukurō
adb logcat -s "Fukuro" "logcat"
```

#### 4. Fallback Testing: Physical Android Phone via USB Debugging
If you do not have hardware virtualization for an AVD emulator, or need a lightweight on-device test setup:

1. **Enable Developer Options**: On your Android phone, go to **Settings → About Phone** and tap **Build Number** 7 times.
2. **Enable USB Debugging**: In **Settings → System → Developer Options**, toggle on **USB Debugging** (and **Install via USB** if prompted).
3. **Connect Device**: Plug your phone into your development machine with a USB cable and tap **Allow** on the computer authorization dialog on your phone screen.
4. **Verify ADB Detection**:
   ```bash
   adb devices
   ```
   *Your device should be listed as `device` (not `unauthorized` or `offline`).*
5. **Run & Hot Reload**:
   - In Android Studio's top toolbar, choose your phone from the device target dropdown.
   - Click **Run** (`Shift+F10`) or use Live Edit directly — Live Edit pushes changes over USB to any device on Android 10+ (API 29+).

### Secrets & Configuration
- **`local.properties`**: Android Studio automatically manages `sdk.dir`.
- **Optional API Secrets**: Release builds configure optional client credentials (`app/google-services.json` and `app/src/main/assets/client_secrets.json`). These files are ignored by git and are omitted by default in local debug builds.
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
