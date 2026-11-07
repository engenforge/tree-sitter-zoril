#!/usr/bin/env bash
set -euo pipefail

# install-helix.sh - Install Zoril syntax support into user's Helix configuration
# Usage: ./scripts/install-helix.sh [TARGET_CONFIG_DIR]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="${1:-${XDG_CONFIG_HOME:-$HOME/.config}/helix}"
RUNTIME_DIR="$CONFIG_DIR/runtime"
QUERIES_DIR="$RUNTIME_DIR/queries/zoril"
GRAMMARS_DIR="$RUNTIME_DIR/grammars"

echo "==> Installing Zoril language support for Helix"
echo "    Helix config dir: $CONFIG_DIR"

mkdir -p "$QUERIES_DIR"
mkdir -p "$GRAMMARS_DIR"

# 1. Copy query files
cp "$ROOT_DIR/queries/highlights.scm" "$QUERIES_DIR/highlights.scm"
cp "$ROOT_DIR/queries/indents.scm" "$QUERIES_DIR/indents.scm"
echo "    [OK] Installed queries to $QUERIES_DIR"

# 2. Compile or copy tree-sitter parser shared library
DYLIB_EXT="so"
if [[ "$(uname -s)" == "Darwin" ]]; then
    DYLIB_EXT="dylib"
fi

CC="${CC:-gcc}"
if ! command -v "$CC" &>/dev/null; then
    CC="clang"
fi

if [[ -f "$ROOT_DIR/lib/zoril.so" && "$DYLIB_EXT" == "so" ]]; then
    echo "    Using pre-built $ROOT_DIR/lib/zoril.so..."
    cp "$ROOT_DIR/lib/zoril.so" "$GRAMMARS_DIR/zoril.so"
    echo "    [OK] Installed grammar to $GRAMMARS_DIR/zoril.so"
elif [[ -f "$ROOT_DIR/build/parser.so" && "$DYLIB_EXT" == "so" ]]; then
    echo "    Using pre-built $ROOT_DIR/build/parser.so..."
    cp "$ROOT_DIR/build/parser.so" "$GRAMMARS_DIR/zoril.so"
    echo "    [OK] Installed grammar to $GRAMMARS_DIR/zoril.so"
elif command -v "$CC" &>/dev/null; then
    echo "    Compiling Zoril tree-sitter parser with $CC..."
    mkdir -p "$ROOT_DIR/build"
    "$CC" -O3 -shared -fPIC \
        -I "$ROOT_DIR/src" \
        "$ROOT_DIR/src/parser.c" \
        "$ROOT_DIR/src/scanner.c" \
        -o "$GRAMMARS_DIR/zoril.$DYLIB_EXT"
    echo "    [OK] Compiled grammar to $GRAMMARS_DIR/zoril.$DYLIB_EXT"
else
    echo "    [WARN] No C compiler found (gcc/clang). Relying on 'hx --grammar build'."
fi

# 3. Update languages.toml non-destructively if zoril is not already configured
LANGUAGES_TOML="$CONFIG_DIR/languages.toml"
if [[ -f "$LANGUAGES_TOML" ]]; then
    if grep -q 'name = "zoril"' "$LANGUAGES_TOML"; then
        echo "    [OK] Zoril language already registered in $LANGUAGES_TOML (leaving unchanged)"
    else
        cp "$LANGUAGES_TOML" "$LANGUAGES_TOML.bak"
        echo "    [OK] Backed up existing config to $LANGUAGES_TOML.bak"
        printf "\n" >> "$LANGUAGES_TOML"
        cat << 'EOF' >> "$LANGUAGES_TOML"

[[language]]
name = "zoril"
scope = "source.zoril"
injection-regex = "zoril|zrl"
file-types = ["zrl"]
comment-tokens = ["//"]
block-comment-tokens = [{ start = "/*", end = "*/" }]
indent = { tab-width = 4, unit = "    " }
grammar = "zoril"

[[grammar]]
name = "zoril"
source = { git = "https://git.engenforge.com/tree-sitter-zoril.git", rev = "v0.1.0-alpha" }
EOF
        echo "    [OK] Appended Zoril configuration to $LANGUAGES_TOML"
    fi
else
    cat << 'EOF' > "$LANGUAGES_TOML"
[[language]]
name = "zoril"
scope = "source.zoril"
injection-regex = "zoril|zrl"
file-types = ["zrl"]
comment-tokens = ["//"]
block-comment-tokens = [{ start = "/*", end = "*/" }]
indent = { tab-width = 4, unit = "    " }
grammar = "zoril"

[[grammar]]
name = "zoril"
source = { git = "https://git.engenforge.com/tree-sitter-zoril.git", rev = "v0.1.0-alpha" }
EOF
    echo "    [OK] Created $LANGUAGES_TOML with Zoril configuration"
fi

echo ""
echo "==> Installation complete! Open any .zrl file with 'hx' to test."
