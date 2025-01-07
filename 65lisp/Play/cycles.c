#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

//#include <conio.h>

#include <assert.h>

//#define PROGSIZE
#include "progsize.c"

#include <stdint.h>

typedef int16_t L;
typedef uint16_t uint;
typedef unsigned uchar;

#include "extern-vm.c"

// These needs to be constants during AMS code-gen
extern unsigned int T=42; // TODO: constant

// this isn't recognized if used in another constant by cc65
//extern const unsigned int nil=1; 
// TODO: if this is ever changed, need to change codegen "[9=I" and "UI"
const unsigned int nil=1;

#define NIL (1)

typedef int (*F1)(int);
typedef void (*F)();

unsigned char bytes= 0;

unsigned char gen[256]= {0};

int main(void) {
  static unsigned int bench= 50000, n;
//  static unsigned long bench= 50000, n; // nothing: 17 021 329  ASM.RTS.noax: 17 621 342
// (/ (- 17621342 17021329) 50000.0) = 12 !!!
// (/ (- 17720613 17021329) 50000.0) = 13.98 !!!
//    static unsigned int  bench= 50000, n; // nothing: 1 265 812, gen.RTS: 10 718 610, ASM.RTS: 5 118 609, ASM.RTS.noax: 1 865 530
// (/ 1865530 50000) = 37c/call

//  unsigned int bench= 3000, n= bench+1;
//  unsigned int bench= 3000, n= bench+1;
//  unsigned int bench= 100, n= bench+1; // for fib21
//  unsigned int bench= 1, n= bench+1;
//  unsigned int bench= 100, n= bench+1;
  int r, i;

  n= bench+1;

  if (1) {
    // 3.96s
    gen[0]= 0xEA;
    gen[1]= 0x60;
  } else {
    // 3.86s (/ (- 3864523 3964514) 50000.0) = -2 (#nop!)
    // (/ 3864523 50000) = 77c looping overhead using unsigned int!
    gen[0]= 0x60;
  }

  bytes= 0;

  i= 0xbeef;

while(--n>0) {
  if (0) { // 3.26s unsigned int // 1 265 534 static uint (/ 1265534 50000.0) = 25c / loop 
    //printf("foo\n");
//    3;
  } else if (0) { // 12.82s
    // 25% overhead cmp next...
    // 39.32s
    r= ((F1)gen)(i);
  } else { // 3.96s
//    __AX__= i;
    asm(" jsr %v", gen);
//    r= __AX__;
  }
}

printf("bench: %u times - Code(%d)=%d (%04X) n=%u (%04x)\n", bench, i/2, r/2, r, n, n);

  PROGSIZE;
  return 0;
}
