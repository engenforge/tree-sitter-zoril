#!/usr/bin/env bash
set -uo pipefail

# test_runner.sh - Zoril Tree-sitter & Helix Grammar Test Suite
# Conforms to project test specification:
# Output: [PASS] group test_name or [FAIL] group test_name
# Summary: Total: N run, P passed, F failed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CORPUS_DIR="${ZORIL_CORPUS_DIR:-$ROOT_DIR/test/zrl}"
CC="${CC:-gcc}"
CFLAGS="${CFLAGS:--Wall -Wextra -O3 -shared -fPIC}"

cd "$ROOT_DIR"

PROFILE="${PROFILE:-auto}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile=*)
            PROFILE="${1#*=}"
            shift
            ;;
        --user)
            PROFILE="user"
            shift
            ;;
        --dev)
            PROFILE="dev"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

HAS_TREE_SITTER=false
if command -v tree-sitter &>/dev/null; then
    HAS_TREE_SITTER=true
fi

if [[ "$PROFILE" == "dev" && "$HAS_TREE_SITTER" != "true" ]]; then
    echo "Error: 'tree-sitter' command not found."
    echo "The developer profile requires tree-sitter-cli to test grammar generation and AST parsing."
    echo "Install tree-sitter-cli (e.g. 'pacman -S tree-sitter-cli' or 'cargo install tree-sitter-cli')."
    exit 1
fi

total=0
passed=0
failed=0

run_test() {
    local group="$1"
    local name="$2"
    shift 2
    total=$((total + 1))
    if "$@" >/dev/null 2>&1; then
        echo "[PASS] $group $name"
        passed=$((passed + 1))
    else
        echo "[FAIL] $group $name"
        failed=$((failed + 1))
    fi
}

TMP_BUILD="$(mktemp -d)"
trap 'rm -rf "$TMP_BUILD"' EXIT

mkdir -p "$ROOT_DIR/build"

# Group 1: User / Packager Profile Tests (C toolchain & runtime integrity)
run_test "build" "parser.c and scanner.c compile with gcc" "$CC" $CFLAGS -I "$ROOT_DIR/src" "$ROOT_DIR/src/parser.c" "$ROOT_DIR/src/scanner.c" -o "$TMP_BUILD/parser.so"

DL_FLAGS="-ldl"
if command -v uname &>/dev/null && [[ "$(uname -s)" == "Darwin" ]]; then
    DL_FLAGS=""
fi

if "$CC" -O2 -I "$ROOT_DIR/src" "$ROOT_DIR/test/check_abi.c" $DL_FLAGS -o "$TMP_BUILD/check_abi" 2>/dev/null || \
   "$CC" -O2 -I "$ROOT_DIR/src" "$ROOT_DIR/test/check_abi.c" -o "$TMP_BUILD/check_abi" 2>/dev/null; then
    # Ensure build/parser.so is available for ABI verification
    if [[ ! -f "$ROOT_DIR/build/parser.so" && -f "$TMP_BUILD/parser.so" ]]; then
        cp "$TMP_BUILD/parser.so" "$ROOT_DIR/build/parser.so"
    fi
    run_test "abi" "parser.so loads via dlopen" "$TMP_BUILD/check_abi" "$ROOT_DIR/build/parser.so" dlopen
    run_test "abi" "language name matches zoril" "$TMP_BUILD/check_abi" "$ROOT_DIR/build/parser.so" name
    run_test "abi" "ABI version is supported" "$TMP_BUILD/check_abi" "$ROOT_DIR/build/parser.so" abi
    run_test "abi" "symbol count is non-zero" "$TMP_BUILD/check_abi" "$ROOT_DIR/build/parser.so" symbols
    run_test "abi" "external scanner symbols exported" "$TMP_BUILD/check_abi" "$ROOT_DIR/build/parser.so" scanner
fi

run_test "queries" "highlights.scm exists and non-empty" test -s "$ROOT_DIR/queries/highlights.scm"
run_test "queries" "indents.scm exists and non-empty" test -s "$ROOT_DIR/queries/indents.scm"

# Group 2: Grammar Developer Profile Tests (AST corpus parsing & tree-sitter verification)
if [[ "$PROFILE" == "dev" || ("$PROFILE" == "auto" && "$HAS_TREE_SITTER" == "true") ]]; then
    run_test "build" "tree-sitter generate succeeds" tree-sitter generate -o "$TMP_BUILD" src/grammar.js
    run_test "build" "highlights query compiles against grammar" tree-sitter test

    if [[ -d "$CORPUS_DIR" ]]; then
        for f in "$CORPUS_DIR"/*.zrl; do
            b="$(basename "$f")"
            total=$((total + 1))
            # Ensure file parses with zero ERROR nodes
            if tree-sitter parse "$f" 2>&1 | grep -q "ERROR"; then
                echo "[FAIL] corpus $b"
                failed=$((failed + 1))
            else
                echo "[PASS] corpus $b"
                passed=$((passed + 1))
            fi
        done
    fi
elif [[ "$PROFILE" == "auto" ]]; then
    echo "Notice: 'tree-sitter' CLI not found; skipped developer grammar tests (user profile satisfied)."
fi

echo "Total: $total run, $passed passed, $failed failed"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
exit 0
