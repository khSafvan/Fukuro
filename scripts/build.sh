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
    -h, --help      Display this help message and exit
EOF
}

BUILD_TYPE="debug"

while [[ $# -gt 0 ]]; do
    case "$1" in
        debug|release)
            BUILD_TYPE="$1"
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
    echo -e "${YELLOW}Warning: JAVA_HOME / java command not found in PATH.${NC}"
    echo -e "${YELLOW}Please set up JDK 17 or higher to run Gradle builds.${NC}"
    exit 1
fi

echo -e "${BLUE}==> Building Fukurō (${BUILD_TYPE})...${NC}"

if [[ "$BUILD_TYPE" == "release" ]]; then
    ./gradlew assembleRelease
else
    ./gradlew assembleDebug
fi

echo -e "${GREEN}==> Build completed successfully!${NC}"
