#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>


uint32_t strlen(char str[]) {
    
    uint32_t cont=0,i=0;
    while (str[cont]!='\0') {cont++;}
    return cont;
}


void strcpy(char *dest, char *src) {


    for (int i=0;i<strlen(src);i++)
        dest[i]=src[i];

}