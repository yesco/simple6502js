// HIRES-RAA
//
// A raw, NON-ROM-less implementation of hires graphics
// for ORIC ATMOS.
//
// Intended to be used under Loci
// 
// (c) 2024 Jonas S Karlsson (jsk@yesco.org)

#include <string.h>

#include "conio-raw.c"

// HIRES: 10210 bytes
#define HIRESSCREEN ((char*)0xA000) // $A000-BF3F
#define HIRESSIZE   8000
#define HIRESEND    (HIRESSCREEN+HIRESSIZE)

#define HIRESROWS   200
#define HIRESCELLS  40

#define HIRESTEXT   ((char*)0xBF68) // $BF68-BFDF
#define HIRESTEXTSIZE 120
#define HIRESTEXTEND (HIRESTEXT+HIRESTEXTSIZE)

#define HIRESCHARSET ((char*)0x9800) // $9800-9BFF
#define HIRESALTSET  ((char*(0x9C00) // $9C00-9FFF

#define HIRESMODE 30 // and 31
#define TEXTMODE  26 // and 27

// TODO:
// void gfill(r, c, h, w, v);
// void circle(x, y, r, v);
// void line(x, y, xt, ty);
// void draw(w, h);
// void filledbox(w, h);
// void curset(x, y, v);
// char curget(x, y);

char curmode= TEXTMODE;

void hires() {
  if (curmode==TEXTMODE) {
    memcpy(HIRESCHARSET, CHARSET, 128*8);
    // TODO: altset?
    curmode= SCREENEND[-1]= HIRESMODE;
  }
}

void text() {
  if (curmode==HIRESMODE) {
    memcpy(CHARSET, HIRESCHARSET, 128*8);
    // TODO: altset?
    curmode= *SCREENEND= TEXTMODE;
  }
}

void gfill(char row, char cell, char h, char w, char v) {
  // TODO: adjust so not out of screen?
  // TODO: can share with lores?
  char* p= HIRESSCREEN+40*row+cell;
  for(; h; --h) {
    // TODO: is memset faster?
    for(cell= w; cell; --cell) *p=v,++p;
    p+= 40-w;
  }
}

void gclear() { gfill(0,0,HIRESROWS,HIRESCELLS,64); }



// Dummys for ./r script
int T,nil,doapply1,print;

void main() {
  char* p= HIRESSCREEN;
  int j;
  for(j=100; j; --j) printf("FOOBAR   ");
  hires();
  gclear();
  gfill(60, 15, 10*6, 10, 64+63);
  while (1) {
    char c= cgetc();
    *p++= c;
    if (p>=HIRESEND) p= HIRESSCREEN;
  }
  text();
  printf("HELLO TEST\n");
}
