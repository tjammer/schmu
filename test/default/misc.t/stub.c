#include <stdbool.h>
#include <stdio.h>

void assert(bool b) {
    #include "assert.h"
    assert(b);
}

void Printi(int i) {
    printf("\n%i", i);
}
