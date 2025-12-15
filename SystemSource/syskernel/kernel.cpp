#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

extern "C" void main() {
    *(char*)0xb8000 = 'A';
    *(char*)0xb8001 = 0x0F;
    *(char*)0xb8002 = 'C';
    *(char*)0xb8003 = 0x0F;
    return;
}