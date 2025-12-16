#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

extern "C" void main() {

    char s[30]="PORCO DIO FUNZIONA!!!";
    // Riempie tutto lo schermo di 'X' verde
    for (int i=0;i<80*2;i=i+2) {
        *(char*)(0xb8000+(i))= 'F';
        *(char*)(0xb8000+(i+1))= 0x0F;

    }
    
    while (1) {
    }
}