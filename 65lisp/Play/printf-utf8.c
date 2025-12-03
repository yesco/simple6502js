#include <stdio.h>
#include <stdlib.h>
#include <locale.h>
#include <wchar.h>

int main(void) {
    // Enable UTF-8 locale
    setlocale(LC_ALL, "");

    // Euro sign as Unicode code point (most portable)
    wchar_t euro = 0x20AC;

    printf("Amount: 49.99 %lc\n", (wint_t)euro);
    printf("Total: 1000%lc only!\n", (wint_t)euro);

    // Or use wide printf (often more reliable on some systems)
    wprintf(L"Special offer: 50%lc\n", euro);

    return 0;
}

