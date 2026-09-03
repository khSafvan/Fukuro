#!/usr/bin/env bash
# ==============================================================================
# Script: check.sh
# Purpose: Performs code quality, style, and formatting checks for TachiyomiSY.
# Usage: ./scripts/check.sh [--help]
# ==============================================================================

set -euo pipefail

# Color definitions
RED='\030[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Performs automated code checks for TachiyomiSY repository.

Options:
    -h, --help      Display this help message and exit
EOF
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
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

echo -e "${BLUE}==> Starting repository code quality checks...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

# 1. Shell scripts validation
echo -e "${BLUE}--> Checking shell script syntax...${NC}"
for script in scripts/*.sh gradlew; do
    if [[ -f "$script" ]]; then
        bash -n "$script"
        echo -e "${GREEN}  ✓ ${script} syntax valid${NC}"
    fi
done

# 2. Gradle Spotless check (if java is available)
if command -v java >/dev/null 2>&1; then
    echo -e "${BLUE}--> Running Spotless code formatting check...${NC}"
    ./gradlew spotlessCheck
    echo -e "${GREEN}  ✓ Spotless check passed${NC}"
else
    echo -e "${BLUE}--> Skipping Gradle Spotless check (JDK not detected in PATH).${NC}"
fi

echo -e "${GREEN}==> All code quality checks completed successfully!${NC}"
