#!/bin/sh
# scripts/dist.sh — Build reproducible release tarballs into build/dist/.
#
# Usage:
#   ./scripts/dist.sh src    Build reproducible source archive: build/dist/tree-sitter-zoril-<ver>.tar.xz
#   ./scripts/dist.sh bin    Build reproducible binary archive: build/dist/tree-sitter-zoril-<ver>-<os>-<arch>.tar.xz
#   ./scripts/dist.sh all    Build both source and binary archives
#   ./scripts/dist.sh check  Build both twice, verify bit-for-bit reproducibility (cmp -s), and smoke-test
set -eu

case "$0" in */*) cd "${0%/*}/.." ;; *) cd .. ;; esac || exit 2
REPO_ROOT="$(pwd -P)"

PROJECT="tree-sitter-zoril"
VERSION="$(cat "$REPO_ROOT/VERSION" 2>/dev/null || echo "0.1.0-alpha")"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

MODE="${1:-all}"
case "$MODE" in
    src|bin|all|check) ;;
    *) echo "usage: scripts/dist.sh src|bin|all|check" >&2; exit 2 ;;
esac

for tool in bsdtar git xz sha256sum; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "dist: $tool not found on PATH" >&2
        exit 1
    fi
done

if [ -d "$REPO_ROOT/.git" ] && command -v git >/dev/null 2>&1; then
    if [ "${DIST_ALLOW_DIRTY:-0}" != 1 ] && ! git -C "$REPO_ROOT" diff --quiet HEAD -- 2>/dev/null; then
        echo "dist: the working tree has uncommitted changes to tracked files; commit them, or set DIST_ALLOW_DIRTY=1" >&2
        git -C "$REPO_ROOT" diff --stat HEAD -- >&2
        exit 1
    fi
fi

if [ -d "$REPO_ROOT/.git" ] && command -v git >/dev/null 2>&1; then
    EPOCH="$(git -C "$REPO_ROOT" log -1 --format=%ct HEAD)"
else
    EPOCH="$(date +%s)"
fi

OUT="${DIST_OUT:-$REPO_ROOT/build/dist}"
mkdir -p "$OUT"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tree_sitter_zoril_dist_XXXXXX")"
trap 'rm -rf "$WORK"' EXIT INT TERM

# Generate mtree manifest for reproducible archive
manifest() {
    _dir="$1"
    _name="$2"
    _attrs="uid=0 gid=0 uname=root gname=root time=$EPOCH.0"
    echo "#mtree"
    echo "$_name type=dir mode=0755 $_attrs"
    (cd "$_dir" && find . -mindepth 1 | LC_ALL=C sort) | while IFS= read -r _p; do
        _p="${_p#./}"
        case "$_p" in
            *[!A-Za-z0-9._/+-]*) echo "dist: unsupported character in path: $_p" >&2; return 1 ;;
        esac
        if [ -L "$_dir/$_p" ]; then
            echo "dist: symbolic links are not archived: $_p" >&2
            return 1
        elif [ -d "$_dir/$_p" ]; then
            echo "$_name/$_p type=dir mode=0755 $_attrs"
        elif [ -x "$_dir/$_p" ]; then
            echo "$_name/$_p type=file mode=0755 $_attrs contents=$_dir/$_p"
        else
            echo "$_name/$_p type=file mode=0644 $_attrs contents=$_dir/$_p"
        fi
    done
}

archive() {
    manifest "$1" "$2" > "$WORK/$2.mtree"
    bsdtar -c --format ustar -J --options xz:compression-level=9,xz:threads=1 \
        -f "$3.tmp" "@$WORK/$2.mtree"
    mv -f "$3.tmp" "$3"
}

build_src() {
    _target_out="${1:-$OUT}"
    _name="$PROJECT-$VERSION"
    _dir="$WORK/src/$_name"
    rm -rf "$WORK/src"
    mkdir -p "$_dir"
    if [ -d "$REPO_ROOT/.git" ] && command -v git >/dev/null 2>&1; then
        git -C "$REPO_ROOT" archive HEAD | bsdtar -x -f - -C "$_dir"
    else
        bsdtar -c --exclude="./build" --exclude="./.git" -C "$REPO_ROOT" . | bsdtar -x -f - -C "$_dir"
    fi
    printf "%s\n" "$VERSION" > "$_dir/VERSION"
    archive "$_dir" "$_name" "$_target_out/$_name.tar.xz"
    echo "$_target_out/$_name.tar.xz"
}

smoke_test_bin() {
    _archive="$1"
    _name="$2"
    _x="$(mktemp -d "${TMPDIR:-/tmp}/tsz_smoke_bin_XXXXXX")"
    bsdtar -x -f "$_archive" -C "$_x"
    _dl_flags="-ldl"
    [ "$(uname -s)" = "Darwin" ] && _dl_flags=""
    ${CC:-gcc} -O2 -I "$REPO_ROOT/src" "$REPO_ROOT/test/check_abi.c" $_dl_flags -o "$_x/check_abi" >/dev/null 2>&1 || {
        echo "dist: smoke test ABI runner compilation failed" >&2
        rm -rf "$_x"
        return 1
    }
    _so_path="$_x/$_name/lib/zoril.so"
    for test_kind in dlopen name abi symbols scanner; do
        "$_x/check_abi" "$_so_path" "$test_kind" >/dev/null 2>&1 || {
            echo "dist: binary smoke test failed on $test_kind" >&2
            rm -rf "$_x"
            return 1
        }
    done
    rm -rf "$_x"
}

build_bin() {
    _target_out="${1:-$OUT}"
    _name="$PROJECT-$VERSION-$OS-$ARCH"
    _dir="$WORK/bin/$_name"
    rm -rf "$WORK/bin"
    mkdir -p "$_dir/lib" "$_dir/queries" "$_dir/config" "$_dir/scripts"
    ${MAKE:-make} -C "$REPO_ROOT" --no-print-directory build >/dev/null
    cp "$REPO_ROOT/build/parser.so" "$_dir/lib/zoril.so"
    cp "$REPO_ROOT/queries/"*.scm "$_dir/queries/"
    cp -r "$REPO_ROOT/config"/* "$_dir/config/"
    cp "$REPO_ROOT/scripts/install-helix.sh" "$REPO_ROOT/scripts/install-neovim.sh" "$_dir/scripts/"
    cp "$REPO_ROOT/README.md" "$REPO_ROOT/LICENSE" "$REPO_ROOT/VERSION" "$_dir/"
    archive "$_dir" "$_name" "$_target_out/$_name.tar.xz"
    smoke_test_bin "$_target_out/$_name.tar.xz" "$_name"
    echo "$_target_out/$_name.tar.xz"
}

write_sums() {
    (cd "$OUT" && sha256sum -- "$PROJECT"-*.tar.xz > "$OUT/SHA256SUMS.tmp")
    mv -f "$OUT/SHA256SUMS.tmp" "$OUT/SHA256SUMS"
}

write_build_info() {
    _commit="${BUILD_COMMIT:-}"
    _tree="${BUILD_TREE:-}"
    if [ -d "$REPO_ROOT/.git" ] && command -v git >/dev/null 2>&1; then
        _commit="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")"
        if ! git -C "$REPO_ROOT" diff --quiet HEAD -- 2>/dev/null; then
            _commit="$_commit-dirty"
        fi
        _tree="$(git -C "$REPO_ROOT" rev-parse 'HEAD^{tree}' 2>/dev/null || echo "unknown")"
    fi
    _host="unknown"
    [ -r /etc/os-release ] && _host="$(sed -n 's/^PRETTY_NAME=//p' /etc/os-release | head -n1 | tr -d '"')"
    _cc_ver="$(${CC:-gcc} --version 2>/dev/null | head -n1 || echo "unknown")"

    {
        echo "version: $VERSION"
        echo "commit: ${_commit:-unknown}"
        echo "tree: ${_tree:-unknown}"
        echo "target: $ARCH-$OS"
        echo "host_os: ${_host:-unknown}"
        echo "cc: $_cc_ver"
        while read -r _h _f; do
            echo "archive_sha256: $_h $_f"
        done < "$OUT/SHA256SUMS"
    } > "$OUT/build-info.txt.tmp"
    mv -f "$OUT/build-info.txt.tmp" "$OUT/build-info.txt"
    (cd "$OUT" && sha256sum build-info.txt) >> "$OUT/SHA256SUMS"
}

smoke_user_src() {
    _tar="$1"
    _work="$(mktemp -d "${TMPDIR:-/tmp}/tsz_smoke_src_XXXXXX")"
    bsdtar -x -f "$_tar" -C "$_work"
    _pkg_dir="$(ls -d "$_work/$PROJECT-"* | head -n1)"
    [ ! -e "$_pkg_dir/.git" ] || {
        echo "dist: source archive carries .git" >&2
        rm -rf "$_work"
        return 1
    }
    # Run make test with git removed from PATH
    _path_no_git="$(echo "$PATH" | tr ':' '\n' | grep -v git | tr '\n' ':')"
    (cd "$_pkg_dir" && env PATH="$_path_no_git" make test >/dev/null 2>&1) || {
        echo "dist: make test failed in extracted source archive with no git on PATH" >&2
        rm -rf "$_work"
        return 1
    }
    rm -rf "$_work"
}

smoke_user_enclosed() {
    _tar="$1"
    _work="$(mktemp -d "${TMPDIR:-/tmp}/tsz_smoke_enc_XXXXXX")"
    git init "$_work" >/dev/null 2>&1
    bsdtar -x -f "$_tar" -C "$_work"
    _pkg_dir="$(ls -d "$_work/$PROJECT-"* | head -n1)"
    (cd "$_pkg_dir" && make test >/dev/null 2>&1) || {
        echo "dist: make test failed in source archive unpacked inside enclosing git repository" >&2
        rm -rf "$_work"
        return 1
    }
    rm -rf "$_work"
}

case "$MODE" in
    src)
        build_src "$OUT" >/dev/null
        write_sums
        write_build_info
        echo "    [PASS] dist: source archive $OUT/$PROJECT-$VERSION.tar.xz"
        ;;
    bin)
        build_bin "$OUT" >/dev/null
        write_sums
        write_build_info
        echo "    [PASS] dist: binary archive $OUT/$PROJECT-$VERSION-$OS-$ARCH.tar.xz"
        ;;
    all)
        build_src "$OUT" >/dev/null
        build_bin "$OUT" >/dev/null
        write_sums
        write_build_info
        echo "    [PASS] dist: source archive $OUT/$PROJECT-$VERSION.tar.xz"
        echo "    [PASS] dist: binary archive $OUT/$PROJECT-$VERSION-$OS-$ARCH.tar.xz"
        ;;
    check)
        mkdir -p "$WORK/a" "$WORK/b"
        for kind in src bin; do
            first="$("build_$kind" "$WORK/a")"
            second="$("build_$kind" "$WORK/b")"
            if ! cmp -s "$first" "$second"; then
                echo "[FAIL] dist: two builds of $(basename "$first") differ" >&2
                exit 1
            fi
            echo "[PASS] dist: $(basename "$first") is reproducible ($(wc -c < "$first" | tr -d ' ') bytes)"
            eval "first_$kind=\$first"
        done
        smoke_user_src "$first_src"
        echo "[PASS] dist: source archive builds and tests with no git on PATH"
        smoke_user_enclosed "$first_src"
        echo "[PASS] dist: source archive builds and tests inside enclosing git repository"
        smoke_test_bin "$first_bin" "$(basename "$first_bin" .tar.xz)"
        echo "[PASS] dist: binary archive smoke test passed"
        ;;
esac
