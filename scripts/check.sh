#!/usr/bin/env bash
# ==============================================================================
# Script: check.sh
# Purpose: Performs code quality, style, and formatting checks for Fukurō.
# Usage: ./scripts/check.sh [--help]
# ==============================================================================

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

APPLY_FIX=false
RUN_TESTS=false

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Performs automated code checks and formatting verification for Fukurō.

Options:
    -f, --apply, --fix   Automatically format code using Spotless (spotlessApply)
    -t, --test           Run unit tests alongside code quality checks
    -h, --help           Display this help message and exit
EOF
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--apply|--fix)
            APPLY_FIX=true
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
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

echo -e "${BLUE}==> Starting repository code quality checks...${NC}"

# 1. Shell scripts validation
echo -e "${BLUE}--> Checking shell script syntax...${NC}"
for script in scripts/*.sh gradlew; do
    if [[ -f "$script" ]]; then
        if bash -n "$script"; then
            echo -e "${GREEN}  ✓ ${script} syntax valid${NC}"
        else
            echo -e "${RED}  ✗ Error: ${script} has syntax errors!${NC}"
            exit 1
        fi
    fi
done

# 2. Spotless Formatting Check or Fix
if command -v java >/dev/null 2>&1; then
    if [[ "$APPLY_FIX" == true ]]; then
        echo -e "${BLUE}--> Applying Spotless code formatting (spotlessApply)...${NC}"
        if ./gradlew spotlessApply; then
            echo -e "${GREEN}  ✓ Spotless formatting applied successfully${NC}"
        else
            echo -e "${RED}  ✗ Error: Spotless formatting application failed.${NC}"
            exit 1
        fi
    else
        echo -e "${BLUE}--> Running Spotless code formatting check (spotlessCheck)...${NC}"
        if ./gradlew spotlessCheck; then
            echo -e "${GREEN}  ✓ Spotless check passed${NC}"
        else
            echo -e "${RED}  ✗ Error: Spotless code formatting check failed!${NC}"
            echo -e "${YELLOW}  Tip: Run './scripts/check.sh --apply' or './gradlew spotlessApply' to format automatically.${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}--> Skipping Gradle Spotless check (JDK not detected in PATH).${NC}"
fi

# 3. Unit Tests (Optional)
if [[ "$RUN_TESTS" == true ]]; then
    if command -v java >/dev/null 2>&1; then
        echo -e "${BLUE}--> Running unit tests (./gradlew test)...${NC}"
        if ./gradlew test; then
            echo -e "${GREEN}  ✓ All unit tests passed${NC}"
        else
            echo -e "${RED}  ✗ Error: Unit tests failed! Check build/reports/tests/ for details.${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}--> Skipping unit tests (JDK not detected in PATH).${NC}"
    fi
fi

echo -e "${GREEN}==> All code quality checks completed successfully!${NC}"
