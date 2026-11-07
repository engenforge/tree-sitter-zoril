#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include "tree_sitter/parser.h"

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <so_path> <test_name>\n", argv[0]);
        return 1;
    }
    const char *path = argv[1];
    const char *test = argv[2];

    void *handle = dlopen(path, RTLD_NOW);
    if (!handle) {
        fprintf(stderr, "dlopen failed: %s\n", dlerror());
        return 1;
    }

    if (strcmp(test, "dlopen") == 0) {
        dlclose(handle);
        return 0;
    }

    const TSLanguage *(*lang_fn)(void) = (const TSLanguage *(*)(void))dlsym(handle, "tree_sitter_zoril");
    if (!lang_fn) {
        fprintf(stderr, "dlsym tree_sitter_zoril failed\n");
        dlclose(handle);
        return 1;
    }

    const TSLanguage *lang = lang_fn();
    if (!lang) {
        fprintf(stderr, "tree_sitter_zoril returned NULL\n");
        dlclose(handle);
        return 1;
    }

    if (strcmp(test, "name") == 0) {
        int ok = (lang->name && strcmp(lang->name, "zoril") == 0);
        dlclose(handle);
        return ok ? 0 : 1;
    }

    if (strcmp(test, "abi") == 0) {
        int ok = (lang->abi_version >= 13 && lang->abi_version <= 15);
        dlclose(handle);
        return ok ? 0 : 1;
    }

    if (strcmp(test, "symbols") == 0) {
        int ok = (lang->symbol_count > 0);
        dlclose(handle);
        return ok ? 0 : 1;
    }

    if (strcmp(test, "scanner") == 0) {
        const char *scanner_syms[] = {
            "tree_sitter_zoril_external_scanner_create",
            "tree_sitter_zoril_external_scanner_destroy",
            "tree_sitter_zoril_external_scanner_scan",
            "tree_sitter_zoril_external_scanner_serialize",
            "tree_sitter_zoril_external_scanner_deserialize",
            NULL
        };
        for (int i = 0; scanner_syms[i]; i++) {
            if (!dlsym(handle, scanner_syms[i])) {
                fprintf(stderr, "missing scanner symbol: %s\n", scanner_syms[i]);
                dlclose(handle);
                return 1;
            }
        }
        dlclose(handle);
        return 0;
    }

    fprintf(stderr, "unknown test: %s\n", test);
    dlclose(handle);
    return 1;
}
