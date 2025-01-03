// HIRES-RAA
//
// A raw, NON-ROM-less implementation of hires graphics
// for ORIC ATMOS.
//
// Intended to be used under Loci
// 
// (c) 2024 Jonas S Karlsson (jsk@yesco.org)

// void hires()
// void text()
// void gclear()
// void gfill(row, cell, height, width, value)
// 

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
    memcpy(HIRESCHARSET, CHARSET, 256*8); // incl ALTSET
    curmode= SCREENEND[-1]= HIRESMODE;
  }
}

// TODO: oric name?
void text() {
  if (curmode==HIRESMODE) {
    memcpy(CHARSET, HIRESCHARSET, 256*8); // incl ALTSET
    curmode= *SCREENEND= TEXTMODE;
  }
}

void gfill(char row, char cell, char h, char w, char v) {
  // TODO: adjust so not out of screen?
  // TODO: can share with lores?
  char* p= HIRESSCREEN+40*row+cell;
  for(; h; --h) {
    //for(cell= w; cell; --cell) p[cell]=v; // 619hs
    memset(p, v, w); // 100x 10x10 takes 337hs !
    p+= 40;
  }
}

void gclear() {
  memset(HIRESSCREEN, 64, HIRESSIZE);
}

void curset(char x, char y, char v) {
  char* p= HIRESSCREEN+ 40*y + x/6;
  char m= 32>>(x%6);
  // TODO; if attribute, don't modify...
  //   or extra v mode?
  switch(v) {
  case 0: *p &= ~m;
  case 1: *p |= m;
  case 2: *p ^= m;
  }
}

char point(char x, char y) {
  char* p= HIRESSCREEN+ 40*y + x/6;
  char m= 32>>(x%6);
  return *p & m;
}

void draw(char x, char y, char dx, char dy, char v) {
  if (dx<0) { x+= dx; dx= -dx; }
  if (dy<0) { y+= dy; dy= -dy; }
  if (dx>dy) {
    char i= dx+1;
    while(--i) {
      char yy= y+dy*i/dx;
      curset(x+i, yy, v);
    }
  } else {
    char i= dy+1;
    while(--i) {
      char xx= x+dx*i/dy;
      curset(xx, y+i, v);
    }
  }
}

// Dummys for ./r script
int T,nil,doapply1,print;

void main() {
  char* p= HIRESSCREEN;
  int j;

  for(j=100; j; --j) printf("FOOBAR   ");
  hires();
  gclear();
  gfill(60, 15, 10*6, 10, 64+63);

  for(j=0; j<200; ++j) {
    draw(0, j, 239, 30, 2);
  }

  //text();
  //printf("HELLO TEST\n");
  //gotoxy(10,25); printf("TIME %d times = %d hs", N*2, t-time());
}
