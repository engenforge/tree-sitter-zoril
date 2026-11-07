# Tree-sitter Zoril (`tree-sitter-zoril`)

This repository provides the official **Tree-sitter** grammar and editor syntax highlighting support (Helix, Neovim, and other Tree-sitter editors) for the [Zoril systems programming language](https://git.engenforge.com/zoril).

## Features

- **Full Language Coverage**: Supports all Zoril surface syntax (v0.1.0-alpha), including:
  - 31 keywords and 9 reserved words
  - Built-in annotations (`@likely`, `@unlikely`, `@syscall`, `@slice`, `@ptr_cast`, `@drop`, etc.)
  - Attributes (`#[must_use]`, `#[derive(Clone)]`, `#[borrows]`, `#[stores]`, `#[fresh]`, etc.)
  - Expression-oriented constructs: `match`, `if/else`, closures (`|x| x * 2`), turbofish (`::<T>`)
  - Slices (`[T]`, `[mut T]`) and fixed-size arrays (`[T; N]`)
  - Linear resource types (`fd<r>`, `fd<w>`, `fd<rw>`, `async_context`)
  - Nested block comments (`/* /* nested */ */`)
  - Wrapping arithmetic operators (`+%=`, `-%=`, `*%=`, `+%`, `-%`, `*%`)
- **Zero-Dependency Parser**: Ships pre-generated C parser sources (`src/parser.c` and `src/scanner.c`). A Node.js environment or Tree-sitter CLI is not required to compile and use the grammar.
- **Universal Editor Support**: Supports **Helix**, **Neovim**, and any editor with Tree-sitter integration.
- **Tested Against Zoril Corpus**: 100% parse pass rate verified against all 42 official Zoril language corpus programs.

---

## Helix Editor Setup

### Option A: One-Command Installation (Local)

Run the included install script (or use `make install-helix`):

```bash
make install-helix
# or run directly:
./scripts/install-helix.sh
```

This will automatically:
1. Install syntax highlight and indent queries to `~/.config/helix/runtime/queries/zoril/`
2. Compile `zoril.so` into `~/.config/helix/runtime/grammars/` using your system C compiler (`gcc` or `clang`)
3. Register `.zrl` files and the grammar in `~/.config/helix/languages.toml`

### Option B: Using Git in Helix `languages.toml`

Add the following (also available in [`config/helix/languages.toml`](config/helix/languages.toml)) to your Helix language configuration (`~/.config/helix/languages.toml`):

```toml
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
```

Copy the queries from `queries/` to `~/.config/helix/runtime/queries/zoril/`, then run:

```bash
hx --grammar fetch
hx --grammar build
```

---

## Neovim Setup

### Option A: One-Command Installation (Local)

Run the included Neovim install script (or use `make install-neovim`):

```bash
make install-neovim
# or run directly:
./scripts/install-neovim.sh
```

This will automatically:
1. Install syntax queries to `~/.local/share/nvim/site/queries/zoril/`
2. Compile or copy `zoril.so` into `~/.local/share/nvim/site/parser/zoril.so`
3. Configure `.zrl` filetype detection in `~/.config/nvim/ftdetect/zoril.lua`

### Option B: Using `nvim-treesitter`

Add the parser definition (also available in [`config/neovim/zoril.lua`](config/neovim/zoril.lua)) to your Neovim configuration:

```lua
-- Filetype detection
vim.filetype.add({
  extension = {
    zrl = "zoril",
  },
})

-- Register parser with nvim-treesitter
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.zoril = {
  install_info = {
    url = "https://git.engenforge.com/tree-sitter-zoril.git",
    files = {"src/parser.c", "src/scanner.c"},
    branch = "main",
    generate_requires_npm = false,
    requires_generate_from_grammar = false,
  },
  filetype = "zrl",
}
```

Then in Neovim run:
```vim
:TSInstall zoril
```

---

## Testing & Development

Ensure you have `tree-sitter-cli` (v0.22+) and a C compiler installed.

```bash
# Build parser into build/parser.so
make build

# Regenerate parser sources from src/grammar.js
make generate

# Run test suite against Zoril corpus
make test

# Install to Helix
make install-helix

# Install to Neovim
make install-neovim

# Build source & binary distribution tarballs
make dist

# View all available make targets
make help
```

---

## Releases & Distribution

Distribution packages are built into `build/dist/` using:

```bash
# Build reproducible source tarball
make dist

# Build pre-compiled binary tarball
make dist-bin

# Verify bit-for-bit reproducibility and smoke-test paths
make dist-check
```

This generates:
- `build/dist/tree-sitter-zoril-<version>.tar.xz`: Reproducible source code tarball.
- `build/dist/tree-sitter-zoril-<version>-linux-x86_64.tar.xz`: Pre-compiled binary tarball containing `zoril.so`, queries, headers, and install scripts.
- `build/dist/build-info.txt`: Build provenance metadata (compiler versions, toolchain hashes, target triple, host OS).
- `build/dist/SHA256SUMS`: SHA-256 checksums for the release tarballs and `build-info.txt`.

---

## Repository & Mirrors

- **Project Website**: [git.engenforge.com/tree-sitter-zoril](https://git.engenforge.com/tree-sitter-zoril)
- **Primary Repository**: `https://git.engenforge.com/tree-sitter-zoril.git`
- **Mirrors**:
  - `https://gitlab.com/engenforge/tree-sitter-zoril.git`
  - `https://github.com/engenforge/tree-sitter-zoril.git`
- **Release Downloads**:
  - Primary: `https://get.engenforge.com/tree-sitter-zoril/<version>/`
  - GitLab Mirror: `https://gitlab.com/engenforge/tree-sitter-zoril/-/releases/v<version>/downloads/`
  - GitHub Mirror: `https://github.com/engenforge/tree-sitter-zoril/releases/download/v<version>/`

---

## License

MIT License. See [LICENSE](LICENSE) for details.
