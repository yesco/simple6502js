// Bouncy boxes in graphics

// "Tomorrow, tomorrow, tomorrow".... story girl boy...
// creating movie, diable, fictional RPG gmae inside the novel
#define MAIN
#include "../hires-raw.c"

char T,nil,doapply1,print;

#include "../bits.h"

char disc[]= {
  24/6, 24,
//123456 123456 123456 123456
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ___xxx xxx___ ______
  ______ _xx___ ___xx_ ______
  ______ x_____ _____x ______
  _____x ______ ______ x_____
  ____x_ ______ ______ _x____
  ____x_ ______ ______ _x____
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ____x_ ______ ______ _x____
  ____x_ ______ ______ _x____
  _____x ______ ______ x_____
  ______ x_____ _____x ______
  ______ _xx___ ___xx_ ______
  ______ ___xxx xxx___ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______

// - bitmask
//123456 123456 123456 123456
  42,
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ___xxx xxx___ ______
  ______ _xxxxx xxxxx_ ______
  ______ xxxxxx xxxxxx ______
  _____x xxxxxx xxxxxx x_____
  ____xx xxxxxx xxxxxx xx____
  ____xx xxxxxx xxxxxx xx____
  ___xxx xxxxxx xxxxxx xxx___
  ___xxx xxxxxx xxxxxx xxx___
  ___xxx xxxxxx xxxxxx xxx___

  ___xxx xxxxxx xxxxxx xxx___
  ___xxx xxxxxx xxxxxx xxx___
  ___xxx xxxxxx xxxxxx xxx___
  ____xx xxxxxx xxxxxx xx____
  ____xx xxxxxx xxxxxx xx____
  _____x xxxxxx xxxxxx x_____
  ______ xxxxxx xxxxxx ______
  ______ _xxxxx xxxxx_ ______
  ______ ___xxx xxx___ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
};

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
  char* sprite;
  char* mask;
} sprite;

int ndraw= 0;

// 409 cs/100 fps? 1.ffps
// 192 cs - memcpy, memset
// 191 cs - sp+= 40 inline
// 201 cs - gfill instead of memset... 5%
// 195 cs - p+=40 in gfill, no calc in erase (2.6%)
// 113 cs - NO ERASE!
// 127 cs - clever Y-erase
// 154 cs - 11 x 16 before 6 x 15 (/ (* 11.0 16) (* 6.0 15)) = 2x!
//
// see main for new bench using 1001 updates

void drawsprite(sprite* s) {
  static char w, h, *l;
  static char* sp;
  sp= s->sprite;
  w= *sp; h= sp[1];
  //l= HIRESSCREEN + (5*(y-1))*8 + div6[x];
  l= rowaddr[s->y] + div6[s->x] - 40;

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
  // TODO: clipping?

  // clever
#ifndef FOO
  if (s->dx==0) {
    if (s->dy > 0) {
      gfill(div6[s->x], s->y, *sp, s->dy, 64);
    } else if (s->dy < 0) {
      gfill(div6[s->x], s->y+s->dy+1+sp[1], *sp, -s->dy, 64);
    }
#else
  if (0) {
#endif
  // TODO:
  //} else if (s->dx >= 6) {  /// and s->dy
  //} else if (-s->dx >= 6) {
  } else {
    char w= *sp, h= *++sp;
    // clear all - flickers
    gfill(div6[s->x], s->y, w, h, 64);
  }
}

#define Z 37

void b(char x, char y) {
  box(x, y, Z, Z);
}

#define N 7
//#define N 4
//#define N 16
//#define N 1
//#define N 2

sprite sploc[N];

void spmove(char* sp) {
  char i;
  for(i=0; i<N; ++i) {
    sprite* s= sploc+i;

    if (!s->dx && !s->dy) continue;

    // undraw
    erasesprite(s, s->sprite);

    // move
  rex:
    if ((s->x+= s->dx) + 6*sp[0] >=240 || s->x < 0) { s->dx= -s->dx; goto rex; }
  rey:
    if ((s->y+= s->dy) + sp[1] >=200 || s->y < 0) { s->dy= -s->dy; goto rey; }

    // draw
    ++ndraw;
    drawsprite(s);
    //b(s->x, s->y);
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
// 1001:  978cs 102sp/s 1462cfps 18013 Bps (gfill: asm for memset)
// 1001:  966cs 103sp/s 1480cfps 18237 Bps (gfill: all asm)
// 1001:  952cs 105sp/s 1502cfps 18505 Bps (gfill: value)
// 1001:  751cs 133sp/s 1904cfps 23458 Bps (erase: 27% overhead)
// 1001:  946cs 105sp/s 1511cfps (sprite s pass around)

// N=1:   915cs 109sp/s 10939cfps 
// N=2:   914cs 109sp/s  5481cfps
// N=4:   928cs 108sp/s  2704cfps
// N=7:                  1507cfps
// N=16:                  608cfps

// = (/ (* 11 16 1001 100) 751.0)

// FPS= 105/N !!! these are large 66x16=1056px sprites!

//                          w     h  N
// (/ (* 105.0 1056) (* (* 11 6) 16) 7) = 15.0 fps

// vic 64: 8 sprites 24x21
// ORIC: 8 sprites 24x24
// (/ (* 105.0 1056) (* (* 4 6) 24) 8) = 24.0 fps!
void main() {
  char i;
  unsigned int T;

  hires();
  gclear();

  for(i=0; i<N; ++i) {
    sprite* s= sploc+i;
    s->x= 130/N*i;
    s->y= 180/N*i;
    //s->dx= +1;
    s->dx= 0;
    s->dy= +i*11/10+1;
    s->sprite= enterprise;
    {
      int markpos= 2+s->sprite[0]*s->sprite[1];
      s->mask= (42==s->sprite[markpos])?
        s->sprite+markpos: NULL;
    }
    drawsprite(s);
  }

  T= time();
  while (ndraw<=1000) {
    spmove(enterprise);

    if (0) { // cost 10%?
      unsigned int X= T-time();
      gotoxy(0,25);
      printf("%d: %ucs %ldsp/s %ldcfps  ", ndraw, X, ndraw*100L/X, ndraw*10000L/N/X);
    }
  }

  if (1) {
    unsigned int X= T-time();
    long bytes= ndraw*enterprise[0]*enterprise[1];
    gotoxy(0,25);
    // TODO: Bps is all wrong? why?
    printf("%d: %ucs %ldsp/s %ldcfps %ldBps ", ndraw, X, ndraw*100L/X, ndraw*10000L/N/X, bytes*100L/X);
  }
}

