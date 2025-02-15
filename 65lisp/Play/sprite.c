// Bouncy boxes in graphics

#define MAIN
#include "../hires-raw.c"

char T,nil,doapply1,print;

#include "../bits.h"

// - https://shop.startrek.com/products/star-trek-the-original-series-beverage-containment-system-personalized-travel-mug
char enterprise[]= {
  11, 16,
  _111111 _111111 _111111 _111111 _111111 _1_____ _______ _______ _______ _______ _______
  _111111 _111111 _111111 _111111 _111111 _1_____ _______ _______ ______1 _1_____ _______
  __11111 _111111 _111111 _111111 _111111 _11____ _______ _______ ____111 _111___ _______
  ___1111 _111111 _111111 _111111 _111111 _11____ _______ _______ _111111 _111111 _______
  _______ _______ _______ _______ _11____ _______ _111111 _111111 _111111 _111111 _1111__
  _______ _______ _______ _______ _11____ _______ _111111 _111111 _111111 _111111 _1111__
  _______ _______ _______ _______ _11____ _____11 _11111_ _______ _111111 _111111 _______
  _______ _______ _______ _______ _11____ ___1111 _111___ _______ ____111 _1111__ _______
  _______ _______ _______ _______ _111111 _111111 _11____ _______ ______1 _11____ _______
  _______ _______ _______ ____111 _111111 _111111 _111___ _______ _______ _1_____ _______
  _______ _______ _______ ____111 _111111 _111111 _111_1_ _______ _______ _______ _______
  _______ _______ _______ ___1111 _111111 _111111 _11111_ _______ _______ _______ _______
  _______ _______ _______ ___1111 _111111 _111111 _111111 _1_____ _______ _______ _______
  _______ _______ _______ _______ _111111 _111111 _11111_ _______ _______ _______ _______
  _______ _______ _______ _______ __11111 _111111 _111_1_ _______ _______ _______ _______
  _______ _______ _______ _______ ____111 _111111 _111___ _______ _______ _______ _______

/*
  // nice but very narrow... not good proportions

  6, 15,
  xxxxxx xxxxxx xxxxxx x_____ ______ ______
  _xxxxx xxxxxx xxxxxx xx____ __xx__ ______
  __xxxx xxxxxx xxxxxx x_____ xxxxx_ ______
  ______ ______ xx____ ___xxx xxxxxx xxxxxx
  ______ ______ xx____ ___xxx xxxxxx xxxxxx
  ______ ______ xx____ __xxxx x__xxx xxx___
  ______ ______ xx____ _xxxxx ____xx x_____
  ______ ______ xxxxxx xxxxx_ _____x x_____
  ______ ___xxx xxxxxx xxxxxx x_____ ______
  ______ ___xxx xxxxxx xxxxxx x_x___ ______
  ______ __xxxx xxxxxx xxxxxx xxxx__ ______
  ______ __xxxx xxxxxx xxxxxx x_x___ ______
  ______ ______ xxxxxx xxxxxx x_____ ______
  ______ ______ _xxxxx xxxxxx ______ ______
  ______ ______ ___xxx xxxxx_ ______ ______
*/
};


char BITSRIGHT[]= { 0x3f, 0x1f, 0x0f, 0x07, 0x03, 0x01};
// TODO: 7... lol
char BITSLEFT[] = { 0x00, 0x20, 0x30, 0x38, 0x3c, 0x3e, 0x3f};

// 371cs/100
// 539cs/100 for pixel-left-right (/ 1.0 0.0539) = 18 bps
// 496cs move s, e out
// 495cs row-addr...
void box(char x, char y, char w, char h) {
  char i, b, * l= HIRESSCREEN+ (5*(y-1))*8 + div6[x], * p= l;
  char s= BITSRIGHT[mod6[x]], e= BITSLEFT[mod6[x+w]+1];

  b= div6[w];
  do {
    i= b;
    p= (l+=40)-1;
    *++p ^= s;
    if (i) {
      while(--i) *++p ^= 63-32-1;
      *++p ^= e;
    }
  } while(--h);
}

typedef struct sprite {
  int x, y;
  signed char dx, dy;
} sprite;

int ndraw= 0;

// 409 cs/100
// 192 cs - memcpy, memset
// 191 cs - sp+= 40 inline
// 201 cs - gfill instead of memset... 5%
// 195 cs - p+=40 in gfill, no calc in erase (2.6%)
// 113 cs - NO ERASE!
// 127 cs - clever Y-erase
// 154 cs - 11 x 16 before 6 x 15 (/ (* 11.0 16) (* 6.0 15)) = 2x!
//
// see main for new bench using 1001 updates

void drawsprite(char x, char y, char* sp_) {
  static char w, h, *l;
  static char* sp;
  sp= sp_;
  w= *sp; h= sp[1];
  //l= HIRESSCREEN + (5*(y-1))*8 + div6[x];
  l= rowaddr[y] + div6[x] - 40;

  // TODO: clipping?
  sp+= -w+2;
  *(int*)0x90= sp;
  *(int*)0x92= l;
  do {
    *(int*)0x92+= 40;
    *(int*)0x90+= w;

    if (0) {
      //memcpy(l+= 40, sp+= w, w);
      memcpy(*(int*)0x92, *(int*)0x90, w);
    } else {
      // specialized memcpy (w<256)
      asm("ldy #0");
      asm("ldx %v", w);
    next:
      asm("lda ($90),y"); // a= sp[y];
      asm("sta ($92),y"); // l[y]= a;
      //
      asm("iny");
      asm("dex");
      asm("bne %g", next);
    }
  } while(--h);
}

void erasesprite(sprite* s, char* sp) {
  char w= *sp, h= *++sp;
  // TODO: clipping?

  // clever
#ifndef FOO
  if (s->dy > 0) {
    gfill(div6[s->x], s->y, w, s->dy, 64);
  } else if (s->dy < 0) {
    h-= s->dy-1;
    gfill(div6[s->x], s->y+h, w, -s->dy, 64);
#else
 if (0) {
#endif
  // TODO:
  //} else if (s->dx >= 6) { 
  //} else if (-s->dx >= 6) {
  } else {
    // clear all - flickers
    gfill(div6[s->x], s->y, w, h, 64);
  }
}

#define Z 37

void b(char x, char y) {
  ++ndraw;
  //box(x, y, Z, Z);
  drawsprite(x, y, enterprise);
}

#define N 7
sprite sploc[N];

void spmove(char* sp) {
  char i;
  for(i=0; i<N; ++i) {
    sprite* s= sploc+i;

    if (!s->dx && !s->dy) continue;

    // undraw
    erasesprite(s, enterprise);

    // move
  rex:
    if ((s->x+= s->dx) + 6*sp[0] >=240 || s->x < 0) { s->dx= -s->dx; goto rex; }
  rey:
    if ((s->y+= s->dy) + sp[1] >=200 || s->y < 0) { s->dy= -s->dy; goto rey; }

    // draw
    b(s->x, s->y);

  }
}

// N=7 1001 1836 cs 54 hsp/s 778 hfps
// N=7 1001 1446 cs 69 hsp/s 988 hfps - no erase... (-21%)

// - bigger than ever... 11*6 x 16 sprite N=7 sprites
//
// 1001: 2442cs 40sp/s 585cfps - full clear (flicker)
// 1001: 1835cs 54sp/s 779cfps - clever clear (+ 390cs)
// 1001: 1445cs 69sp/s 989cfps - no clear (traces) (21%)
// 1001: 1699cs 58sp/s 841cfps - drawsprite static vars
//       1689 rowaddr used only initially
//       1627cs -Oi but memcpy still not inlined...
// 1001: 1127cs  88sp/s 1268cfps 13756 Bps (asm memcpy)
// 1001:  978cs 102sp/s 1462cfps 18374 Bps (gfill: asm for memset)
// 1001   966cs 103sp/s 1480cfps 18784 Bps (gfill: all asm)
// = (/ (* 103 11 16 1001) 966.0)
void main() {
  char i;
  unsigned int T;

  hires();
  gclear();

  for(i=0; i<N; ++i) {
    sprite* s= sploc+i;
    s->x= i*25;
    s->y= i*25;
    //s->dx= +1;
    s->dx= 0;
    s->dy= +i*13/10+1;
    b(s->x, s->y);
  }

  T= time();
  while (ndraw<=1000) {
    spmove(enterprise);

    if (0) {
      unsigned X= T-time();
      gotoxy(0,25);
      printf("%d: %ucs %ldsp/s %ldcfps  ", ndraw, X, ndraw*100L/X, ndraw*10000L/7/X);
    }
  }

  if (1) {
    unsigned X= T-time();
    long bytes= ndraw*enterprise[0]*enterprise[1];
    gotoxy(0,25);
    printf("%d: %ucs %ldsp/s %ldcfps %ldBps ", ndraw, X, ndraw*100L/X, ndraw*10000L/7/X, bytes*100L/X);
  }
}

