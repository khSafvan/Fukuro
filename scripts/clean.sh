#!/usr/bin/env bash
# ==============================================================================
# Script: clean.sh
# Purpose: Idempotently cleans build caches, build output directories, and temporary files.
# Usage: ./scripts/clean.sh [--all] [--help]
# ==============================================================================

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

CLEAN_ALL=false

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Cleans project build output directories and caches safely.

Options:
    -a, --all       Clean .gradle cache and IDE temporary files as well
    -h, --help      Display this help message and exit
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)
            CLEAN_ALL=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

echo -e "${BLUE}==> Cleaning build outputs...${NC}"

# If Gradle wrapper and Java are available, run gradlew clean
if command -v java >/dev/null 2>&1 && [[ -x "./gradlew" ]]; then
    ./gradlew clean --quiet 2>/dev/null || true
fi

# Clean Gradle build directories idempotently
find . -name "build" -type d -exec rm -rf {} + 2>/dev/null || true
echo -e "${GREEN}  ✓ Removed module build directories${NC}"

if [[ "$CLEAN_ALL" == true ]]; then
    echo -e "${YELLOW}--> Deep cleaning caches (.gradle, .kotlin, native builds)...${NC}"
    rm -rf .gradle .kotlin .cxx .externalNativeBuild captures
    echo -e "${GREEN}  ✓ Removed .gradle, .kotlin, and native build cache directories${NC}"
fi

echo -e "${GREEN}==> Cleanup complete!${NC}"
