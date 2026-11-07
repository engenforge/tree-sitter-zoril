#!/usr/bin/env bash
set -euo pipefail

# install-neovim.sh - Install Zoril syntax support into user's Neovim configuration
# Usage: ./scripts/install-neovim.sh [TARGET_DATA_DIR] [TARGET_CONFIG_DIR]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DATA_DIR="${1:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site}"
CONFIG_DIR="${2:-${XDG_CONFIG_HOME:-$HOME/.config}/nvim}"

PARSER_DIR="$DATA_DIR/parser"
QUERIES_DIR="$DATA_DIR/queries/zoril"
FTDETECT_DIR="$CONFIG_DIR/ftdetect"

echo "==> Installing Zoril language support for Neovim"
echo "    Neovim data dir:   $DATA_DIR"
echo "    Neovim config dir: $CONFIG_DIR"

mkdir -p "$PARSER_DIR"
mkdir -p "$QUERIES_DIR"
mkdir -p "$FTDETECT_DIR"

# 1. Copy query files
cp "$ROOT_DIR/queries/highlights.scm" "$QUERIES_DIR/highlights.scm"
cp "$ROOT_DIR/queries/indents.scm" "$QUERIES_DIR/indents.scm"
echo "    [OK] Installed queries to $QUERIES_DIR"

# 2. Compile or copy tree-sitter parser shared library
DYLIB_EXT="so"
if [[ "$(uname -s)" == "Darwin" ]]; then
    DYLIB_EXT="so" # Note: Neovim on macOS expects parser/*.so for treesitter parsers
fi

CC="${CC:-gcc}"
if ! command -v "$CC" &>/dev/null; then
    CC="clang"
fi

if [[ -f "$ROOT_DIR/lib/zoril.so" ]]; then
    echo "    Using pre-built $ROOT_DIR/lib/zoril.so..."
    cp "$ROOT_DIR/lib/zoril.so" "$PARSER_DIR/zoril.so"
    echo "    [OK] Installed grammar to $PARSER_DIR/zoril.so"
elif [[ -f "$ROOT_DIR/build/parser.so" ]]; then
    echo "    Using pre-built $ROOT_DIR/build/parser.so..."
    cp "$ROOT_DIR/build/parser.so" "$PARSER_DIR/zoril.so"
    echo "    [OK] Installed grammar to $PARSER_DIR/zoril.so"
elif command -v "$CC" &>/dev/null; then
    echo "    Compiling Zoril tree-sitter parser with $CC..."
    mkdir -p "$ROOT_DIR/build"
    "$CC" -O3 -shared -fPIC \
        -I "$ROOT_DIR/src" \
        "$ROOT_DIR/src/parser.c" \
        "$ROOT_DIR/src/scanner.c" \
        -o "$PARSER_DIR/zoril.so"
    echo "    [OK] Compiled grammar to $PARSER_DIR/zoril.so"
else
    echo "    [WARN] No C compiler found (gcc/clang). Please compile build/parser.so first."
fi

# 3. Configure filetype detection
FTDETECT_FILE="$FTDETECT_DIR/zoril.lua"
if [[ -f "$FTDETECT_FILE" ]]; then
    if grep -q "zrl" "$FTDETECT_FILE"; then
        echo "    [OK] Filetype detection already configured in $FTDETECT_FILE"
    else
        printf "\nvim.filetype.add({ extension = { zrl = 'zoril' } })\n" >> "$FTDETECT_FILE"
        echo "    [OK] Appended filetype detection to $FTDETECT_FILE"
    fi
else
    cat << 'EOF' > "$FTDETECT_FILE"
-- Zoril filetype detection
vim.filetype.add({
  extension = {
    zrl = 'zoril',
  },
})
EOF
    echo "    [OK] Created $FTDETECT_FILE"
fi

echo ""
echo "==> Installation complete! Open any .zrl file with 'nvim' to test."
