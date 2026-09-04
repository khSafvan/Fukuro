#!/usr/bin/env bash
# ==============================================================================
# Script: run.sh
# Purpose: Complete build, test, and run workflow for Fukurō on Android Emulator.
# Usage: ./scripts/run.sh [OPTIONS]
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Color definitions & UI output
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}==>${NC} ${BOLD}$*${NC}"
}

log_step() {
    echo -e "${CYAN}-->${NC} $*"
}

log_success() {
    echo -e "${GREEN}  ✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}  ⚠ Warning:${NC} $*"
}

log_error() {
    echo -e "${RED}  ✗ Error:${NC} $*" >&2
}

# ------------------------------------------------------------------------------
# Default settings
# ------------------------------------------------------------------------------
BUILD_TYPE="debug"
CLEAN_FIRST=false
SKIP_CHECK=false
SKIP_TEST=false
SKIP_BUILD=false
HEADLESS=false
FOLLOW_LOGCAT=false
TARGET_AVD=""
TARGET_DEVICE=""
BOOT_TIMEOUT=180

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Orchestrates the entire Fukurō development lifecycle:
1. Validates shell scripts and code formatting (Spotless)
2. Executes unit tests
3. Assembles the APK
4. Detects or launches an Android Emulator (AVD)
5. Installs the APK onto the emulator/device
6. Launches Fukurō MainActivity

Options:
    -c, --clean         Clean build outputs and caches before building
    --skip-check        Skip code formatting and shell script checks
    --skip-test         Skip unit tests for faster iteration
    --skip-build        Skip assembling APK (use existing build in app/build/outputs)
    -r, --release       Build and run release variant (default: debug)
    -a, --avd NAME      Specify AVD name to launch (auto-detected if omitted)
    -d, --device ID     Specify device serial if multiple devices are attached
    --headless          Launch emulator in headless mode (-no-window)
    -l, --logcat        Stream logcat logs filtered to Fukurō after launch
    -t, --timeout SEC   Max seconds to wait for emulator to boot (default: 180s)
    -h, --help          Display this help message and exit

Examples:
    ./scripts/run.sh                   # Full standard run: check, test, build, emulator, run
    ./scripts/run.sh --skip-test       # Fast iteration run without unit tests
    ./scripts/run.sh --avd Pixel_10a   # Run specifically on Pixel_10a AVD
    ./scripts/run.sh --clean           # Clean build before assembling and running
EOF
}

# ------------------------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--clean)
            CLEAN_FIRST=true
            shift
            ;;
        --skip-check)
            SKIP_CHECK=true
            shift
            ;;
        --skip-test)
            SKIP_TEST=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -r|--release)
            BUILD_TYPE="release"
            shift
            ;;
        -a|--avd)
            if [[ -z "${2:-}" ]]; then
                log_error "Missing argument for --avd"
                exit 1
            fi
            TARGET_AVD="$2"
            shift 2
            ;;
        -d|--device)
            if [[ -z "${2:-}" ]]; then
                log_error "Missing argument for --device"
                exit 1
            fi
            TARGET_DEVICE="$2"
            shift 2
            ;;
        --headless)
            HEADLESS=true
            shift
            ;;
        -l|--logcat)
            FOLLOW_LOGCAT=true
            shift
            ;;
        -t|--timeout)
            if [[ -z "${2:-}" || ! "$2" =~ ^[0-9]+$ ]]; then
                log_error "Invalid timeout value for --timeout: '${2:-}'"
                exit 1
            fi
            BOOT_TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Resolve repo root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

# ------------------------------------------------------------------------------
# Prerequisite: Java & Android SDK resolution
# ------------------------------------------------------------------------------
log_info "Step 1: Checking environment prerequisites..."

# 1. Java check
if ! command -v java >/dev/null 2>&1; then
    log_error "Java runtime (JDK 17+) not found in PATH."
    echo -e "${YELLOW}Please install OpenJDK 17 or higher (e.g. 'sudo pacman -S jdk17-openjdk' or 'sudo apt install openjdk-17-jdk').${NC}"
    exit 1
fi
JAVA_VER=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
log_success "Java detected: ${JAVA_VER}"

# 2. Android SDK resolution
ANDROID_SDK=""
if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME" ]]; then
    ANDROID_SDK="$ANDROID_HOME"
elif [[ -n "${ANDROID_SDK_ROOT:-}" && -d "$ANDROID_SDK_ROOT" ]]; then
    ANDROID_SDK="$ANDROID_SDK_ROOT"
elif [[ -f "local.properties" ]]; then
    SDK_PROP=$(grep -E "^sdk\.dir=" local.properties | cut -d'=' -f2- | tr -d '\r' || true)
    if [[ -n "$SDK_PROP" && -d "$SDK_PROP" ]]; then
        ANDROID_SDK="$SDK_PROP"
    fi
fi

if [[ -z "$ANDROID_SDK" ]]; then
    # Fallback to standard locations
    if [[ -d "$HOME/Android/Sdk" ]]; then
        ANDROID_SDK="$HOME/Android/Sdk"
    fi
fi

if [[ -z "$ANDROID_SDK" || ! -d "$ANDROID_SDK" ]]; then
    log_error "Android SDK not found. Neither ANDROID_HOME nor local.properties 'sdk.dir' is configured."
    echo -e "${YELLOW}Please configure 'sdk.dir=/path/to/Android/Sdk' in local.properties.${NC}"
    exit 1
fi

export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"
export PATH="${ANDROID_SDK}/platform-tools:${ANDROID_SDK}/emulator:${PATH}"
log_success "Android SDK located: ${ANDROID_SDK}"

# 3. ADB binary check
ADB_BIN=""
if command -v adb >/dev/null 2>&1; then
    ADB_BIN="$(command -v adb)"
elif [[ -x "${ANDROID_SDK}/platform-tools/adb" ]]; then
    ADB_BIN="${ANDROID_SDK}/platform-tools/adb"
fi

if [[ -z "$ADB_BIN" ]]; then
    log_error "ADB executable not found in PATH or ${ANDROID_SDK}/platform-tools/adb."
    exit 1
fi
log_success "ADB located: ${ADB_BIN}"

# 4. Emulator binary check
EMULATOR_BIN=""
if command -v emulator >/dev/null 2>&1; then
    EMULATOR_BIN="$(command -v emulator)"
elif [[ -x "${ANDROID_SDK}/emulator/emulator" ]]; then
    EMULATOR_BIN="${ANDROID_SDK}/emulator/emulator"
fi

# ------------------------------------------------------------------------------
# Optional Step: Repository Cleanup
# ------------------------------------------------------------------------------
if [[ "$CLEAN_FIRST" == true ]]; then
    log_info "Step 1b: Cleaning build outputs..."
    if [[ -x "./scripts/clean.sh" ]]; then
        ./scripts/clean.sh --all
    else
        ./gradlew clean
    fi
    log_success "Cleanup complete."
fi

# ------------------------------------------------------------------------------
# Step 2: Code Quality & Spotless Verification
# ------------------------------------------------------------------------------
if [[ "$SKIP_CHECK" == false ]]; then
    log_info "Step 2: Checking shell script syntax & code formatting..."
    if [[ -x "./scripts/check.sh" ]]; then
        if ! ./scripts/check.sh; then
            log_error "Code quality check failed."
            echo -e "${YELLOW}Tip: Run './scripts/check.sh --apply' or './gradlew spotlessApply' to format code.${NC}"
            exit 1
        fi
    else
        if ! ./gradlew spotlessCheck; then
            log_error "Spotless code formatting check failed."
            echo -e "${YELLOW}Tip: Run './gradlew spotlessApply' to auto-format code.${NC}"
            exit 1
        fi
    fi
    log_success "Code quality and formatting checks passed."
else
    log_step "Skipping code quality checks (--skip-check)."
fi

# ------------------------------------------------------------------------------
# Step 3: Run Unit Tests
# ------------------------------------------------------------------------------
if [[ "$SKIP_TEST" == false ]]; then
    log_info "Step 3: Running unit tests (./gradlew test)..."
    if ! ./gradlew test; then
        log_error "Unit tests failed!"
        echo -e "${YELLOW}Check the test report in: app/build/reports/tests/testDebugUnitTest/index.html${NC}"
        exit 1
    fi
    log_success "All unit tests passed."
else
    log_step "Skipping unit tests (--skip-test)."
fi

# ------------------------------------------------------------------------------
# Step 4: Assemble APK
# ------------------------------------------------------------------------------
if [[ "$BUILD_TYPE" == "release" ]]; then
    GRADLE_BUILD_TASK="assembleRelease"
    APK_DIR="app/build/outputs/apk/release"
    APP_PKG="eu.kanade.tachiyomi.fukuro"
else
    GRADLE_BUILD_TASK="assembleDebug"
    APK_DIR="app/build/outputs/apk/debug"
    APP_PKG="eu.kanade.tachiyomi.fukuro.debug"
fi
MAIN_ACTIVITY="eu.kanade.tachiyomi.ui.main.MainActivity"

if [[ "$SKIP_BUILD" == false ]]; then
    log_info "Step 4: Assembling Fukurō (${BUILD_TYPE})..."
    if ! ./gradlew "$GRADLE_BUILD_TASK"; then
        log_error "Gradle build failed for task '${GRADLE_BUILD_TASK}'."
        echo -e "${YELLOW}Tip: Run './gradlew ${GRADLE_BUILD_TASK} --stacktrace' for comprehensive diagnostic logs.${NC}"
        exit 1
    fi
    log_success "Build completed successfully."
else
    log_step "Skipping build (--skip-build)."
fi

# ------------------------------------------------------------------------------
# Step 5: Android Device / Emulator Setup & Verification
# ------------------------------------------------------------------------------
log_info "Step 5: Detecting connected devices or starting Android Emulator..."

# Check running devices
get_online_devices() {
    "$ADB_BIN" devices | grep -v "List of devices" | grep "device$" | awk '{print $1}' || true
}

ONLINE_DEVICES=($(get_online_devices))

if [[ -n "$TARGET_DEVICE" ]]; then
    # Verify the requested device is online
    if ! "$ADB_BIN" devices | grep -q "^${TARGET_DEVICE}[[:space:]]\+device"; then
        log_error "Requested device '${TARGET_DEVICE}' is not connected or unauthorized."
        "$ADB_BIN" devices
        exit 1
    fi
    SELECTED_DEVICE="$TARGET_DEVICE"
    log_success "Using explicitly specified device: ${SELECTED_DEVICE}"
elif [[ ${#ONLINE_DEVICES[@]} -gt 0 ]]; then
    SELECTED_DEVICE="${ONLINE_DEVICES[0]}"
    log_success "Found active device/emulator already running: ${SELECTED_DEVICE}"
else
    # No device online; we need to launch an emulator
    if [[ -z "$EMULATOR_BIN" || ! -x "$EMULATOR_BIN" ]]; then
        log_error "No active device found, and Android Emulator executable was not found."
        echo -e "${YELLOW}Please ensure Android Emulator is installed via Android Studio SDK Manager.${NC}"
        exit 1
    fi

    # Determine which AVD to start
    AVD_LIST=($("$EMULATOR_BIN" -list-avds || true))
    if [[ ${#AVD_LIST[@]} -eq 0 ]]; then
        log_error "No Android Virtual Devices (AVD) found."
        echo -e "${YELLOW}Please create a virtual device in Android Studio (Tools → Device Manager → Create Device).${NC}"
        exit 1
    fi

    if [[ -n "$TARGET_AVD" ]]; then
        # Check if specified AVD exists
        if ! printf '%s\n' "${AVD_LIST[@]}" | grep -qx "$TARGET_AVD"; then
            log_error "AVD '${TARGET_AVD}' does not exist."
            echo -e "${YELLOW}Available AVDs:${NC}"
            printf '    - %s\n' "${AVD_LIST[@]}"
            exit 1
        fi
        LAUNCH_AVD="$TARGET_AVD"
    else
        LAUNCH_AVD="${AVD_LIST[0]}"
        log_step "Auto-selected AVD: ${LAUNCH_AVD}"
    fi

    log_step "Launching Android Emulator with AVD: '${LAUNCH_AVD}'..."

    EMU_ARGS=("-avd" "$LAUNCH_AVD")
    if [[ "$HEADLESS" == true ]]; then
        EMU_ARGS+=("-no-window" "-no-audio")
    fi

    # Launch emulator in detached background session, redirecting output to a temporary log
    EMU_LOG="/tmp/fukuro_emulator.log"
    if command -v setsid >/dev/null 2>&1; then
        setsid "$EMULATOR_BIN" "${EMU_ARGS[@]}" </dev/null > "$EMU_LOG" 2>&1 &
    else
        nohup "$EMULATOR_BIN" "${EMU_ARGS[@]}" </dev/null > "$EMU_LOG" 2>&1 &
    fi
    EMU_PID=$!
    disown "$EMU_PID" 2>/dev/null || true

    log_step "Emulator started in detached session (PID: ${EMU_PID}). Log: ${EMU_LOG}"
    log_step "Waiting for emulator to connect to ADB and finish booting (timeout: ${BOOT_TIMEOUT}s)..."

    ELAPSED=0
    BOOT_COMPLETED=""
    SELECTED_DEVICE=""

    # Wait until adb registers the emulator device
    while [[ $ELAPSED -lt $BOOT_TIMEOUT ]]; do
        if ! kill -0 "$EMU_PID" 2>/dev/null; then
            log_error "Emulator process terminated unexpectedly!"
            if [[ -f "$EMU_LOG" ]]; then
                echo -e "${YELLOW}Last 20 lines of emulator log (${EMU_LOG}):${NC}"
                tail -n 20 "$EMU_LOG"
            fi
            exit 1
        fi

        ONLINE=($(get_online_devices))
        if [[ ${#ONLINE[@]} -gt 0 ]]; then
            # Find the emulator device
            for dev in "${ONLINE[@]}"; do
                if [[ "$dev" =~ ^emulator- ]]; then
                    SELECTED_DEVICE="$dev"
                    break
                fi
            done
            if [[ -n "$SELECTED_DEVICE" ]]; then
                # Check sys.boot_completed
                BOOT_COMPLETED=$("$ADB_BIN" -s "$SELECTED_DEVICE" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n' || true)
                if [[ "$BOOT_COMPLETED" == "1" ]]; then
                    break
                fi
            fi
        fi

        sleep 3
        ELAPSED=$((ELAPSED + 3))
        echo -ne "\r${CYAN}--> Waiting for boot completion... (${ELAPSED}s / ${BOOT_TIMEOUT}s)${NC}"
    done
    echo ""

    if [[ "$BOOT_COMPLETED" != "1" || -z "$SELECTED_DEVICE" ]]; then
        log_error "Emulator failed to boot within ${BOOT_TIMEOUT} seconds."
        echo -e "${YELLOW}Check ${EMU_LOG} for details.${NC}"
        exit 1
    fi

    log_success "Emulator '${LAUNCH_AVD}' (${SELECTED_DEVICE}) is fully booted and ready!"
fi

# ------------------------------------------------------------------------------
# Step 6: Select APK & Install onto Device
# ------------------------------------------------------------------------------
log_info "Step 6: Selecting appropriate APK and installing onto ${SELECTED_DEVICE}..."

# Query device ABI
DEV_ABI=$("$ADB_BIN" -s "$SELECTED_DEVICE" shell getprop ro.product.cpu.abi 2>/dev/null | tr -d '\r\n' || true)
log_step "Target device architecture: ${DEV_ABI:-unknown}"

# Locate APK matching ABI, or universal APK
TARGET_APK=""
if [[ -n "$DEV_ABI" && -f "${APK_DIR}/app-${DEV_ABI}-${BUILD_TYPE}.apk" ]]; then
    TARGET_APK="${APK_DIR}/app-${DEV_ABI}-${BUILD_TYPE}.apk"
elif [[ -f "${APK_DIR}/app-universal-${BUILD_TYPE}.apk" ]]; then
    TARGET_APK="${APK_DIR}/app-universal-${BUILD_TYPE}.apk"
else
    # First available APK in directory
    TARGET_APK=$(find "$APK_DIR" -maxdepth 1 -name "*.apk" | head -n 1 || true)
fi

if [[ -z "$TARGET_APK" || ! -f "$TARGET_APK" ]]; then
    log_error "No APK found in ${APK_DIR}."
    echo -e "${YELLOW}Please run './gradlew ${GRADLE_BUILD_TASK}' first.${NC}"
    exit 1
fi

log_step "Installing APK: $(basename "$TARGET_APK") ($(ls -lh "$TARGET_APK" | awk '{print $5}'))..."

if ! "$ADB_BIN" -s "$SELECTED_DEVICE" install -r "$TARGET_APK"; then
    log_error "Installation failed via ADB."
    echo -e "${YELLOW}If you have a conflicting signature or version downgrade, try uninstalling first:${NC}"
    echo -e "    ${ADB_BIN} -s ${SELECTED_DEVICE} uninstall ${APP_PKG}"
    exit 1
fi

log_success "Fukurō installed successfully!"

# ------------------------------------------------------------------------------
# Step 7: Launch Application
# ------------------------------------------------------------------------------
log_info "Step 7: Launching Fukurō on ${SELECTED_DEVICE}..."

COMPONENT="${APP_PKG}/${MAIN_ACTIVITY}"
START_OUTPUT=$("$ADB_BIN" -s "$SELECTED_DEVICE" shell am start -n "$COMPONENT" 2>&1)
echo "$START_OUTPUT"

if echo "$START_OUTPUT" | grep -qi "Error"; then
    log_error "Failed to launch ${COMPONENT}."
    exit 1
fi

# Wait a brief moment and verify the process is alive
sleep 2
APP_PID=$("$ADB_BIN" -s "$SELECTED_DEVICE" shell pidof "$APP_PKG" 2>/dev/null | tr -d '\r\n' || true)

if [[ -n "$APP_PID" ]]; then
    log_success "Fukurō is actively running on ${SELECTED_DEVICE}! (PID: ${APP_PID})"
else
    log_warn "Application started, but pidof did not return an active PID immediately. Check device screen."
fi

# ------------------------------------------------------------------------------
# Step 8: Optional Logcat Stream
# ------------------------------------------------------------------------------
if [[ "$FOLLOW_LOGCAT" == true ]]; then
    log_info "Streaming logcat logs for package '${APP_PKG}' (Ctrl+C to exit)..."
    "$ADB_BIN" -s "$SELECTED_DEVICE" logcat --pid="$APP_PID" 2>/dev/null || \
        "$ADB_BIN" -s "$SELECTED_DEVICE" logcat -s "Fukuro" "AndroidRuntime"
fi

log_info "Workflow completed successfully! 🎉"
