// Gentap - generate .tap file for ORIC ATMOS

#include <stdio.h>

#define SCREEN     0xbb80
#define SCREENSIZE 28*40

int main(int argc, char** argv) {
  // avoid first line!
  int start= SCREEN+40;
  int end  = start+SCREENSIZE-40;

  char *name= argv[1];
  char letter = name[0];

  // header

  // - sync 
  for(int i=0; i<128; ++i) putchar(0x16);
  putchar(0x24);
  // - reserved (2)
  putchar(0);
  putchar(0);
  // - 0=BASIC, $80= machinecode
  putchar(0x80);
  // - 0=no autorun, $c7=autorun (basic/machiencode)
  putchar(0);
  // - EndAddress (hi,lo!)
  putchar(end >> 8);
  putchar((char)end);
  // - StartAddress (hi,lo!)
  putchar(start >> 8);
  putchar((char)start);
  // - "varies" unused
  putchar(0);
  // - Name (zero terminated)
  fputs(name, stdout);
  putchar(0);

  // - Data
  
  // make a screen full of letter
  for(int i=0; i<SCREENSIZE; ++i)
    putchar(letter);
}
