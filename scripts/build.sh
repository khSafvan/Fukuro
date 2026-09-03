#!/usr/bin/env bash
# ==============================================================================
# Script: build.sh
# Purpose: Build helper script for assembling TachiyomiSY APKs.
# Usage: ./scripts/build.sh [foss|standard] [--help]
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
Usage: $(basename "$0") [VARIANT] [OPTIONS]

Assembles TachiyomiSY Android application builds.

Variants:
    standard        Build standard debug variant (default)
    foss            Build FOSS debug variant

Options:
    -h, --help      Display this help message and exit
EOF
}

VARIANT="standard"

while [[ $# -gt 0 ]]; do
    case "$1" in
        standard|foss)
            VARIANT="$1"
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

echo -e "${BLUE}==> Building TachiyomiSY (${VARIANT} debug)...${NC}"

if [[ "$VARIANT" == "foss" ]]; then
    ./gradlew assembleFossDebug
else
    ./gradlew assembleStandardDebug
fi

echo -e "${GREEN}==> Build completed successfully!${NC}"
