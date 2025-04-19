#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#include <conio.h>

extern int prin1(int n) { printf(" %d", n); return n; }
extern int print(int n) { printf("\n%d", n); return n; }

extern int nil=0, T=0;


typedef unsigned char uchar;
typedef unsigned int uint;

// a bit for every 4 bytes (cons cells) - 2KB
#define BITS (65536/4/8)

// byte is slightly faster 36.7s for scan whole memory, 38.48 for uint
uchar used[BITS];
//uint used[65536/4/16];

// TODO: use bit mask? 8 bytes 8bits/byte
#define SETBIT(n) (used[(n)/32]|= (1<<(n/4)%8))
//#define SETBIT(n) (used[(n)/16]|= (1<<(((n)/16)&0x0f)))
//#define USED(n) (used[(n)/32] & (1<<(n/4)%8))

// global 30.52s !
uint i;
uint v;

// So, marking 64K memory, as any aligned pointers
// 2*64K pointers, setting a bit, takes 31s!

// TODO: how long take in assembly?

// Maybe only limit to known locations:
// - cons cells
// - atoms as they are globals

// this os kindof a misnomer,
// it just checks and marks any 4 byte memory region if its pointed to

// a real gc only follows live data!
// there is no easy way to null out pointers when not used
void markwholemem() {
  // we check any alignment
  i= 0xffff;
  do {
    v= *(uint*)--i;
    // mark any potiential pointer
    //if (v & 1)
      SETBIT(v);
    //printf("%04X: %04x %d %d\n", i, v, n, x);
  } while (i);
}

void mark(uint *p, uint n) {
  // we check any alignment
  i= 0xffff;
  for(;--n;) {
    v= *(uint*)p++;
    // mark any potiential pointer
    if (v & 1) // 4.23 if commented out
      SETBIT(v);
    //printf("%04X: %04x %d %d\n", i, v, n, x);
  }
}


void sweep() {
}

// 8192 cells is 4096 cons is 16384 bytes - takes 1.86--4.40s
uint cell[8192];

void gc() {
  memset(used, 0, sizeof(used));
  //memset(cell, 1, sizeof(cell)); // 1.86s
  memset(cell, 0, sizeof(cell)); // 4.40s
  
  if (0) {
    // 31s
    markwholemem(); // TODO: bitmask & asm
  } else {
    // 4.18s - only known pointers 
    mark(cell, sizeof(cell)/sizeof(*cell));
    // TODO: mark all atoms
  }

  sweep();
}

// dummy
char doapply1;

int main() {//int argc, char** argv) {
  long bench= 3000;
  long i;

  bench= 1;
  i= 1;

  while(i--) {
    gc();
  }

  return 0;
}
