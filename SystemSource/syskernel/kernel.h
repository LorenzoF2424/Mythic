#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>


int strlen(char str[]) {
    
    int cont=0,i=0;
    while (str[i]!='\0') {

        cont++;

        i++;
    }
    return cont;
}