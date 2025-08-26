// Dummys for ./r script LOL
//int T,nil,doapply1,print;

// 2434 bytes with printf, 
// #include <stdio.h>

extern void showsize();
extern void start();

#include "disasm.c"

unsigned char* last= 0;
extern char *out, *output;

// disasm from last position/call
extern void dasm() {
  if (!last) last= output;
  // TODO: this hangs as printf data in ZP corrupted?
  // TODO: use my own printf? lol
  // TODO: define putd(),puth(),put2h()...
  //printf("\nDASM $%u-$%u!\n", last, out);
  disasm(last, out, 2);
  last= out;
}

// from conio-raw.c
#define TEXTSCREEN ((char*)0xBB80) // $BB80-BF3F
#define SCREENROWS 28
#define SCREENCOLS 40
#define SCREENSIZE (SCREENROWS*SCREENCOLS)
#define SCREENLAST (TEXTSCREEN+SCREENSIZE-1)

// empty main: 284 Bytes (C overhead)

// 423 bytes w printz (- 423 284 30)= 109

// (- 495 423) = 72 bytes for test 28*3 etc...

// 618 bytes w _nil,_t,_eval (- 618 423 72 109) = 14 bytes(?)

// 741 bytes printh (- 741 690) = 51 bytes for printhex

void main() {
  //printf("Hello World!\n");
  
  *TEXTSCREEN= 'A';

  showsize();

  start();

  TEXTSCREEN[2]= 'C';
}
