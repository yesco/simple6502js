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

static const char PIXMASK[]= { 32, 16, 8, 4, 2, 1 };

// optimizations, 10x draw line
// 938hs plain
// 892hs PIXMASK -5.16% 
// 842hs (5*y)*8 -5.94%
// 708hs q=x/6  -18.9%
// 672hs static q,m,*p -3.81%
// 632hs inline curset -6.33%
// 618hs static yy -2.3%
// 569hs move mod lookup out, mi loop, -8.6%
// 560hs shift static m -1.6%
// 390hs remove q/6 from loop -43.6%
// 313hs remove mult from dy*i -24.6%
// 113hs remove /6 from loop -77%
//  72hs not calculate p -57%    13x FASTER!
// 112hs ORIC BASIC    we are 50% faster than BASIC

// TODO: no effect on draw long line...
//   however on many curset?
char div6[255], mod6[255];
//    char q= div6[x]; // no time saving!?
//    char mi= mod6[x]; // nah

void curset(char x, char y, char v) {
  static char q, m, *p;
  q= x/6;
  p= HIRESSCREEN+ (5*y)*8 + q;
  m= PIXMASK[x-q*6];
  // TODO; if attribute, don't modify...
  //   or extra v mode?
  switch(v) {
  case 0: *p &= ~m;
  case 1: *p |= m;
  case 2: *p ^= m;
  }
}

char point(char x, char y) {
  char q= x/6;
  char* p= HIRESSCREEN+ (5*y)*8 + q;
  char m= PIXMASK[x-6*q];
  return *p & m;
}

void draw(char x, char y, int dx, int dy, char v) {
  static char adx, ady, m, s, *p;

  adx= dx>=0? dx: -dx;
  ady= dy>=0? dy: -dy;

  if (adx>ady) {
    if (dx<0) { x+= dx; dx= -dx; y+= dy; dy= -dy; }
    y+= dy;
    x+= dx;
    {
      // inline curset
      int i= adx+1;
      char q= x/6;
      char mi= x-q*6;
      m= PIXMASK[mi];
      s= 0;
      p= HIRESSCREEN+40*y+q;

      while(--i) {

        // adjust y
        if ((s+= ady) > adx) {
          s-=adx;
          if (dy>=0) {
            if ((p-= 40)<HIRESSCREEN) break;
          } else {            
            if ((p+= 40)>=HIRESEND) break;
          }
        }

        // plot it
        switch(v) { // about 10% overhead
        case 0: *p &= ~m;
        case 1: *p |= m;
        case 2: *p ^= m;
        }

        // step x, wrap around bit
        if ((m<<=1)==64) m=1,--p;
      }
    }
  } else { // dy >= dx
    if (dy<0) { x+= dx; dx= -dx; y+= dy; dy= -dy; }
    y+= dy;
    x+= dx;
    {
      // inline curset
      int i= ady+1;
      char q= x/6;
      char mi= x-q*6;
      m= PIXMASK[mi];
      s= 0;
      p= HIRESSCREEN+(5*y)*8+q;

      while(--i) {

        // adjust x
        if ((s+= adx) > ady) {
          s-=ady;
          // step x, wrap around bit
          if (dx>=0) {
            if ((m<<=1)==64) m=1,--p; // ok
          } else {
            if (!(m>>=1)) m=32,++p;
          }
        }

        // plot it
        switch(v) { // about 10% overhead
        case 0: *p &= ~m;
        case 1: *p |= m;
        case 2: *p ^= m;
        }

        // step y
        p-= 40;
        if (p<HIRESSCREEN) break;
      }
    }
  }
}

void circle(char x, char y, int r, char v) {
  // 181/256 == 1/sqrt(2)
  int dy=(r*181)>>8, dx= dy;
  while(--dy>=0) {
    // bad approxmiation, lol
    dx+= 1;


    curset(x+dx, y+dy, v);
    curset(x-dx, y+dy, v);

    curset(x+dy, y+dx, v);
    curset(x-dy, y+dx, v);


    curset(x+dx, y-dy, v);
    curset(x-dx, y-dy, v);

    curset(x+dy, y-dx, v);
    curset(x-dy, y-dx, v);

  }
}

// Dummys for ./r script
int T,nil,doapply1,print;

void main() {
  char* p= HIRESSCREEN;
  int j;
  unsigned int t;

  for(j=0; j<255; ++j) {
    div6[j]= j/6;
    mod6[j]= j%6;
  }

  for(j=100; j; --j) printf("FOOBAR   ");
  hires();
  gclear();
  gfill(60, 15, 10*6, 10, 64+63);

  t= time();

  if (1) {
    circle(120, 100, 75, 2);
  } else if (0) {
    for(j=0; j<10; ++j) {
      //draw(0, j, 239, 30, 2); // 92hs
      //draw(239, j+30, -239, -30, 2); // 92hs same reverse

      //draw(0, 30+j, 239, -30, 2); // 92hs

      draw(j, 0, 30, 199, 2); // 75hs
//      draw(j+30, 199, -30, -199, 2); // 75hs same reverse

      draw(30+j, 0, -30, 199, 2); // 76hs
      //draw(j, 199, 30, -199, 2); // ???? what is it
    }
  } else { 
    // BASIC: 7.47s, DLFAT: 3.75s
    // ... 4.63s using dx,dy= int
    // ... 4.68s with bounds check
    //    ( 4.40?s if hardcode xor)
    for(j=0; j<200; j+= 10) {
      draw(j,     0,     199-j, j,     2);
      draw(199,   j,     -j,    199-j, 2);
      draw(199-j, 199,   j-199, -j,    2);
      draw(0,     199-j, j,     j-199, 2);
    }
  }

  gotoxy(10,25); printf("TIME %d times = %d hs", 10, t-time());

  //text();
  //printf("HELLO TEST\n");
  //gotoxy(10,25); printf("TIME %d times = %d hs", N*2, t-time());
}
