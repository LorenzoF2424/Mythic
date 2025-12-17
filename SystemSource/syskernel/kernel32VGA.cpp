
#include "displayVGA.h"

extern "C" void main() { // KERNELLLLLLLLLLLLLLLLLLLLLLL

    cls();

    const char *s="BENVENUTO NEL KERNEL FUNZIONA PORCO DIO VALERIO SUCCHIAMELO!!!";
    const char *s2="che bello usare c++";
    /*for (int i=0;i<80*25*2;i=i+2) {
        *(char*)(0xb8000+(i))= 0;
        *(char*)(0xb8000+(i+1))= 0x0F;

    }*/
    int color=15;
    for (int i=0;i<16;i++)    {
        printfVGA32((char*)s,cursorAt(0,i),14);
        color--;
    }

    printfVGA32(s2,cursorAt(0,24),VGA_COLOR_BLUE);


    while (1) {
    }
}