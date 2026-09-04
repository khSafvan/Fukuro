#!/usr/bin/env bash
# ==============================================================================
# Script: build.sh
# Purpose: Build helper script for assembling Fukurō APKs.
# Usage: ./scripts/build.sh [debug|release] [--help]
# ==============================================================================

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

show_help() {
    cat << EOF
Usage: $(basename "$0") [BUILD_TYPE] [OPTIONS]

Assembles Fukurō Android application builds.

Build Types:
    debug           Build debug APK (default)
    release         Build release APKs (full release with updater)

Options:
    -c, --clean     Clean build directories before assembling
    -t, --test      Run unit tests prior to assembling
    -h, --help      Display this help message and exit
EOF
}

BUILD_TYPE="debug"
CLEAN_FIRST=false
RUN_TESTS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        debug|release)
            BUILD_TYPE="$1"
            shift
            ;;
        -c|--clean)
            CLEAN_FIRST=true
            shift
            ;;
        -t|--test)
            RUN_TESTS=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

if ! command -v java >/dev/null 2>&1; then
    echo -e "${RED}Error: Java (JDK 17+) is required but not found in PATH.${NC}"
    echo -e "${YELLOW}Please set JAVA_HOME or install OpenJDK 17/21.${NC}"
    exit 1
fi

if [[ "$CLEAN_FIRST" == true ]]; then
    echo -e "${BLUE}==> Cleaning prior build outputs...${NC}"
    ./gradlew clean
fi

if [[ "$RUN_TESTS" == true ]]; then
    echo -e "${BLUE}==> Running unit tests prior to build...${NC}"
    if ! ./gradlew test; then
        echo -e "${RED}Error: Unit tests failed. Aborting build.${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}==> Building Fukurō (${BUILD_TYPE})...${NC}"

if [[ "$BUILD_TYPE" == "release" ]]; then
    TASK="assembleRelease"
    OUTPUT_DIR="app/build/outputs/apk/release"
else
    TASK="assembleDebug"
    OUTPUT_DIR="app/build/outputs/apk/debug"
fi

if ! ./gradlew "$TASK"; then
    echo -e "${RED}Error: Build failed for task '${TASK}'.${NC}"
    echo -e "${YELLOW}Tip: Check the Gradle logs above or run './gradlew ${TASK} --stacktrace' for detailed errors.${NC}"
    exit 1
fi

echo -e "${GREEN}==> Build completed successfully!${NC}"
echo -e "${BLUE}--> Generated APKs in ${OUTPUT_DIR}:${NC}"
if [[ -d "$OUTPUT_DIR" ]]; then
    find "$OUTPUT_DIR" -maxdepth 1 -name "*.apk" -exec ls -lh {} + 2>/dev/null | awk '{print "    " $9 " (" $5 ")"}'
    echo ""
    echo -e "${GREEN}To install onto a connected device or emulator:${NC}"
    echo -e "    adb install -r ${OUTPUT_DIR}/app-universal-${BUILD_TYPE}*.apk"
fi
