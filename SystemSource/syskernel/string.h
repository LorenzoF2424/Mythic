#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>


uint32_t strlen(const char *str) {
    
    uint32_t cont=0;
    while (str[cont]!='\0') {cont++;}
    return cont;
}


void strcpy(char *dest, char *src) {


    for (uint32_t i=0;i<strlen(src);i++)
        dest[i]=src[i];

}