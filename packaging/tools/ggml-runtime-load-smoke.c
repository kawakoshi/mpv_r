#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <windows.h>

typedef size_t (*reg_count_fn)(void);
typedef void *(*reg_get_fn)(size_t);
typedef const char *(*reg_name_fn)(void *);
typedef void (*load_all_fn)(void);

int main(void) {
    HMODULE ggml = LoadLibraryA("ggml.dll");
    HMODULE base = LoadLibraryA("ggml-base.dll");
    if (!ggml || !base) {
        fprintf(stderr, "LoadLibrary failed: %lu\n", GetLastError());
        return 2;
    }

    reg_count_fn count = (reg_count_fn)(void *)GetProcAddress(ggml, "ggml_backend_reg_count");
    reg_get_fn get = (reg_get_fn)(void *)GetProcAddress(ggml, "ggml_backend_reg_get");
    load_all_fn load_all = (load_all_fn)(void *)GetProcAddress(ggml, "ggml_backend_load_all");
    reg_name_fn name = (reg_name_fn)(void *)GetProcAddress(base, "ggml_backend_reg_name");
    if (!count || !get || !load_all || !name) {
        fputs("Required ggml backend symbol is missing.\n", stderr);
        return 3;
    }

    size_t before = count();
    load_all();
    size_t after = count();
    int saw_cpu = 0;

    printf("before=%zu\nafter=%zu\nnames=", before, after);
    for (size_t i = 0; i < after; ++i) {
        const char *backend_name = name(get(i));
        if (i) {
            putchar(',');
        }
        fputs(backend_name ? backend_name : "(null)", stdout);
        if (backend_name && strcmp(backend_name, "CPU") == 0) {
            saw_cpu = 1;
        }
    }
    putchar('\n');

    if (after <= before || !saw_cpu) {
        fputs("The dynamically loaded CPU backend was not registered.\n", stderr);
        return 4;
    }
    return 0;
}
