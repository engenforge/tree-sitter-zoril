# Agent Instructions

Guidance for any AI agent working on `tree-sitter-zoril` (Tree-sitter grammar and editor integrations for Zoril).

## Project Scope & Boundaries

- **Purpose**: Provides Tree-sitter grammar specifications (`src/grammar.js`, `src/scanner.c`), pre-generated C parser sources (`src/parser.c`, `src/tree_sitter/parser.h`), highlight/indent queries (`queries/`), and editor configurations (Helix, Neovim).
- **Editor-Focused**: This is an editor grammar package, **not a standalone CLI executable or compiler**.
- **Installation Boundaries**: Installations are strictly editor-targeted (`make install-helix`, `make install-neovim`). Do not add generic Unix system-install hierarchies (`PREFIX`, `BINDIR`, `/usr/local/share`), man pages, or compiler-specific harness tooling.

## Commands and Workflow

- **`make` or `make all`**: Compiles shared library `build/parser.so` from C sources.
- **`make build`**: Compiles `src/parser.c` and `src/scanner.c` with compiler warnings enabled (`-Wall -Wextra`).
- **`make generate`**: Regenerates C parser sources from `src/grammar.js` using `tree-sitter` CLI (developer profile).
- **`make test`**: Runs test suite via `test/test_runner.sh` (zero git dependency; runs AST corpus tests if CLI present).
- **`make test-user`**: Runs user/packager tests (C compilation, dlopen ABI, symbols, queries; no `tree-sitter` CLI needed).
- **`make test-dev`**: Runs grammar developer tests (requires `tree-sitter` CLI).
- **`make install-helix`**: Installs grammar and queries into user's Helix configuration (`~/.config/helix/`).
- **`make install-neovim`**: Installs grammar, queries, and filetype detection into user's Neovim configuration (`~/.local/share/nvim/`, `~/.config/nvim/`).
- **`make dist`**: Builds reproducible source tarball in `build/dist/tree-sitter-zoril-<ver>.tar.xz`.
- **`make dist-bin`**: Builds reproducible binary tarball in `build/dist/tree-sitter-zoril-<ver>-<os>-<arch>.tar.xz`.
- **`make dist-check`**: Builds both tarballs twice to verify bit-for-bit reproducibility (`cmp -s`) and smoke-tests user extraction/build paths.
- **`make clean`**: Removes build directory (`build/`).
- **`make help`**: Displays all available make targets with short descriptions.

## Dependency Profiles

1. **User / Packager Profile**:
   - For end users, packagers, and editor installs.
   - Requires only a C compiler (`gcc` or `clang`), standard C library (`libc`, `libdl`), and GNU `make`.
   - Commands: `make`, `make build`, `make test`, `make test-user`, `make install-helix`, `make install-neovim`, `make dist`, `make dist-bin`, `make dist-check`.

2. **Grammar Developer Profile**:
   - For contributors modifying `src/grammar.js` or queries.
   - Requires User dependencies plus `tree-sitter` CLI.
   - Commands: `make generate`, `make test-dev`.

## Testing Standards

- Tests adhere to the format: `[PASS] group test_name` / `[FAIL] group test_name`.
- Output ends with a single-line summary: `Total: N run, P passed, F failed`.
- `make test` must not depend on git: test suites must run and pass in an extracted source tarball without git on PATH, and when extracted inside an enclosing git repository.
- Verify parse compatibility against the vendored Zoril corpus in `test/zrl/` (or via `ZORIL_CORPUS_DIR`).

## Project Planning and Tasks

- Tasks are tracked in `doc/tasks/` per **SPEC-TASKMARK-03** (`active.tm.md`, `completed.tm.md`, `future.tm.md`).
- Run `tm validate doc/tasks/*.tm.md` to ensure validity before committing.
- Commit messages use imperative mood with subject under 72 characters; bodies explain why, not just what.

## Personal Information Screening & Self-Contained Repository

- This repository is generic by default (no personal identifiers, usernames, private hostnames, or home directories).
- The project is self-contained: no references to paths outside the git repository (except standard user config locations like `~/.config/` or `~/.local/`).
