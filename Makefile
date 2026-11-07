CC ?= gcc
CFLAGS ?= -Wall -Wextra -O3 -shared -fPIC
TREE_SITTER ?= $(shell command -v tree-sitter 2>/dev/null)
BUILD_DIR ?= build
PARSER_SO ?= $(BUILD_DIR)/parser.so
SRCS = src/parser.c src/scanner.c $(wildcard src/tree_sitter/*.h)

.PHONY: all generate build test test-user test-dev install-helix install-neovim install-nvim dist dist-src dist-bin dist-check clean help

all: build

generate:
	@if [ -z "$(TREE_SITTER)" ]; then \
		echo "Error: 'tree-sitter' CLI command not found."; \
		echo "On Arch Linux: sudo pacman -S tree-sitter-cli"; \
		echo "On Debian/Ubuntu: npm install -g tree-sitter-cli or cargo install tree-sitter-cli"; \
		exit 1; \
	fi
	tree-sitter generate src/grammar.js

$(PARSER_SO): $(SRCS)
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -I src src/parser.c src/scanner.c -o $@

build: $(PARSER_SO)

test: build
	./test/test_runner.sh

test-user: build
	./test/test_runner.sh --profile=user

test-dev: build
	./test/test_runner.sh --profile=dev

install-helix: build
	./scripts/install-helix.sh

install-neovim: build
	./scripts/install-neovim.sh

install-nvim: install-neovim

dist:
	./scripts/dist.sh src

dist-src:
	./scripts/dist.sh src

dist-bin: build
	./scripts/dist.sh bin

dist-check: build
	./scripts/dist.sh check

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all             Alias for 'build' (default target)"
	@echo "  build           Compile build/parser.so from C sources (user profile)"
	@echo "  generate        Regenerate C parser sources from src/grammar.js using tree-sitter CLI"
	@echo "  test            Run test suite (auto-detects profile; only requires C compiler)"
	@echo "  test-user       Run user/packager test suite (only requires C compiler)"
	@echo "  test-dev        Run grammar developer test suite (requires tree-sitter CLI)"
	@echo "  install-helix   Install grammar and queries into Helix configuration"
	@echo "  install-neovim  Install grammar and queries into Neovim configuration"
	@echo "  dist            Build reproducible source tarball in build/dist/"
	@echo "  dist-src        Alias for 'dist'"
	@echo "  dist-bin        Build relocatable binary tarball in build/dist/"
	@echo "  dist-check      Build both tarballs twice to verify reproducibility and smoke-test paths"
	@echo "  clean           Remove build directory (build/)"
	@echo "  help            Display this help message"
