// Bouncy spites in hires graphics

// "Tomorrow, tomorrow, tomorrow".... story girl boy...
// creating movie, diable, fictional RPG gmae inside the novel
#define MAIN
#include "../hires-raw.c"

char T,nil,doapply1,print;

#include "../bits.h"

// To scroll sideways need one empty cell to the right
#define SCROLLABLE

//#define BIGG

//#define WIDER
//  7.39fps loss of fps -30% fps
//  8.29fps w drawsprite loop in asm
// 10.62fps - normal xor
// 12.73fps !- normal xor w drawsprite loop in asm!

// TALLER
//  6.13fps ever more costly: -42% fps
//  7.57fps w - drawsprite loop in asm!
// 10.62fps - normal xor

char disc[]= {

#ifdef BIGG 

#ifdef WIDER
  24/6*2, 24,
//123456 123456 123456 123456
  ______ ______ ______ ______ ______ ______ ______ _____x
  ______ ______ ______ ______ ______ ______ ______ ______
  ______ ______ ______ ______ ______ ______ ______ ______
  ______ ___xxx xxx___ ______ ______ ______ ______ ______
  ______ _xx___ ___xx_ ______ ______ ______ ______ ______
  ______ x_____ _____x ______ ______ ______ ______ ______
  _____x ______ ______ x_____ ______ ______ ______ ______
  ____x_ ______ ______ _x____ ______ ______ ______ ______
  ____x_ ______ ______ _x____ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ____x_ ______ ______ _x____ ______ ______ ______ ______
  ____x_ ______ ______ _x____ ______ ______ ______ ______
  _____x ______ ______ x_____ ______ ______ ______ ______
  ______ x_____ _____x ______ ______ ______ ______ ______
  ______ _xx___ ___xx_ ______ ______ ______ ______ ______
  ______ ___xxx xxx___ ______ ______ ______ ______ ______
  ______ ______ ______ ______ ______ ______ ______ ______
  ______ ______ ______ ______ ______ ______ ______ ______
  ______ ______ ______ ______ ______ ______ ______ ______

// - bitmask
//123456 123456 123456 123456
//  77,
  42,
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxx_
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx x_____ _____x xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx ______ ______ xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxx_ ______ ______ _xxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxx__ ______ ______ __xxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxx__ ______ ______ __xxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx

  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxx__ ______ ______ __xxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxx__ ______ ______ __xxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxx_ ______ ______ _xxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx ______ ______ xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx x_____ _____x xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
#else // WIDER else TALLER
  24/6, 24*2,
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

  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______


// - bitmask
//123456 123456 123456 123456
//  77,
  42,
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx
  xxxxxx x_____ _____x xxxxxx
  xxxxxx ______ ______ xxxxxx
  xxxxx_ ______ ______ _xxxxx
  xxxx__ ______ ______ __xxxx
  xxxx__ ______ ______ __xxxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx

  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxxx__ ______ ______ __xxxx
  xxxx__ ______ ______ __xxxx
  xxxxx_ ______ ______ _xxxxx
  xxxxxx ______ ______ xxxxxx
  xxxxxx x_____ _____x xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx

  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx

#endif // WIDER
#else // BIGG else ...
#ifdef SCROLLABLE
  // Notice empty column to the right,
  // this is so dimensions are same when scrolled
  // copies to be made
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ xxxxxx ______ ______
  ____xx ______ xx____ ______
  ___x__ ______ __x___ ______
  __x___ ______ ___x__ ______
  _x____ ______ ____x_ ______
  _x____ ______ ____x_ ______
  x_____ ______ _____x ______
  x_____ ______ _____x ______
  x_____ ______ _____x ______
  x_____ ______ _____x ______
  x_____ ______ _____x ______
  x_____ ______ _____x ______
  _x____ ______ ____x_ ______
  _x____ ______ ____x_ ______
  __x___ ______ ___x__ ______
  ___x__ ______ __x___ ______
  ____xx ______ xx____ ______
  ______ xxxxxx ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______

// - bitmask
//123456 123456 123456 123456
//  77,
  42, // indicator of bitmask following
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx ______ xxxxxx xxxxxx
  xxxx__ ______ __xxxx xxxxxx
  xxx___ ______ ___xxx xxxxxx
  xx____ ______ ____xx xxxxxx
  x_____ ______ _____x xxxxxx
  x_____ ______ _____x xxxxxx
  ______ ______ ______ xxxxxx
  ______ ______ ______ xxxxxx
  ______ ______ ______ xxxxxx
  ______ ______ ______ xxxxxx
  ______ ______ ______ xxxxxx
  ______ ______ ______ xxxxxx
  x_____ ______ _____x xxxxxx
  x_____ ______ _____x xxxxxx
  xx____ ______ ____xx xxxxxx
  xxx___ ______ ___xxx xxxxxx
  xxxx__ ______ __xxxx xxxxxx
  xxxxxx ______ xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx

#else // SCROLLABLE

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
//  77,
  42,
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx
  xxxxxx x_____ _____x xxxxxx
  xxxxxx ______ ______ xxxxxx
  xxxxx_ ______ ______ _xxxxx
  xxxx__ ______ ______ __xxxx
  xxxx__ ______ ______ __xxxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx

  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxxx__ ______ ______ __xxxx
  xxxx__ ______ ______ __xxxx
  xxxxx_ ______ ______ _xxxxx
  xxxxxx ______ ______ xxxxxx
  xxxxxx x_____ _____x xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
#endif SCROLLABLE

#endif BIGG
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
  // TODO: higher resolution than this
  int x, y;
  signed char dx, dy; // this could be subpixel/frame

  // current (TODO: remove?)
  char* bitmap;
  char* mask;

  // TODO: move out?
  char* shbitmap[6];
  char* shmask[6];

  // TODO: 
  char bitmaps[6];
  char z; // z order
} sprite;

char spritecollision(sprite* a, sprite* b) {
  if (a->x > b->x) return -spritecollision(b, a);
  {
    int ax1= a->x, ax2= ax1 + a->bitmap[0]*6;
    int ay1= a->y, ay2= ay1 + a->bitmap[1];

    int bx1= b->x, bx2= bx1 + b->bitmap[0]*6;
    int by1= b->y, by2= by1 + b->bitmap[1];

    char r;

    // we know: ax1 < bx1

    // no collision if a << b
    if (ax2 <= bx1) return 0;

    // we know: x-overlaps
    //
    // Possiblities:
    //             00000          00000
    //                    1111111  
    //      55555    77   1111111
    //  ....55555....77...1111111
    //  .............77...1111111
    //  .............77......
    //  .....44444...77......     0000
    //  .....44444...77...8888888
    //  .............77...8888888
    //  .............77......
    //  .............77......
    //  ....666......77....222222
    //      666      77    222222
    //          000                00000
    //
    //
    if (by2 <= ay1) return 0; // above
    if (ay2 <= by1) return 0; // below
    r= 0;
    // TODO: near overlap? adjacent/touch?

    // overlapping
    if (by1 <= ay1) r+= 1; // upper & 1
    if (by2 >= ay2) r+= 2; // lower & 2
    if (bx2 <= ax2) r+= 4; // inner & 4
    return r? r: 8;        // right & 8
  }
}

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
  static char * sp, * msk;
  sp= s->bitmap;
  msk= s->mask;
  w= *sp; h= sp[1];

  if (0) {
  l= rowaddr[s->y] + div6[s->x];

  // TODO: clipping?
  *(int*)0x90= sp+2;
  *(int*)0x92= l;
  *(int*)0x94= msk;

  do {
    // specialized memcpy (w<256)
    asm("ldy #0");
    asm("ldx %v", w);
  next:
    if (0) {
      asm("lda ($92),y"); // a = l[y];
      // TODO: two variants?
      //asm("and ($94),y"); // a&= mask[y];
      asm("eor ($90),y"); // a^= sp[y]; // draw+undraw
      //asm("ora ($90),y"); // a|= sp[y];
      // TODO: shouldn't need this... lol
      // TODO: if and reset the bit eor would set it?
      asm("ora #$40");
      asm("sta ($92),y"); // l[y]= a;
    } else {
      asm("lda ($90),y"); // a = sp[y];
      asm("sta ($92),y"); // l[y]= a;
    }


    //
    asm("iny");
    asm("dex");
    asm("bne %g", next);
    
    // step
    *(int*)0x92+= 40;
    *(int*)0x90+= w;
    *(int*)0x94+= w;
  } while(--h);

  } else {
    // new optimization
    static char ww;
    static char hh;

    ww= 40-w; hh= h;

  l= rowaddr[s->y] + div6[s->x];

  // TODO: clipping?
  *(int*)0x90= sp+2;
  *(int*)0x92= l;
  *(int*)0x94= msk;

  asm("ldy #0");
  asm("clc"); // set it for once top!

  nextrow:

  // specialized memcpy (w<256)
  asm("ldx %v", w);

  nextcell:

    if (0) {

  asm("lda ($92),y"); // a = l[y];
  //asm("and ($94),y"); // a&= mask[y];
  asm("eor ($90),y"); // a^= sp[y]; // draw+undraw
  //asm("ora ($90),y"); // a|= sp[y];
  asm("ora #$40");
  // OLD overwrite! - very fast!
  //asm("lda ($90),y"); // a = sp[y];
  asm("sta ($92),y"); // l[y]= a;
    
    } else {
      // old style overwrite
      asm("lda ($90),y"); // a = sp[y];
      asm("sta ($92),y"); // l[y]= a;
    }

  //
  asm("iny");
  asm("dex");
  asm("bne %g", nextcell);

  // *(int*)0x92+= 40-w (= ww);
  asm("clc"); // set it for once top!
  asm("lda $92");
  asm("adc %v", ww);
  asm("sta $92");

  asm("bcc %g", nott);
  asm("inc $93");
  asm("clc"); // make it always clear!
  nott:

  // ... while(--h);
  asm("dec %v", hh);
  asm("bne %g", nextrow);

  }
}

void erasesprite(sprite* s) {
  char* sp= s->bitmap;
  // for xor
  //drawsprite(s); return;

  // TODO: clipping?

  // TODO: this doesn't handle overlapping. mask?
  // clever
#ifndef NOTCLEVER
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

//  gclear();

  for(i=0; i<N; ++i) {
    sprite* s= sploc+i;

    if (!s->dx && !s->dy) continue;

    // undraw
    // TODO: undraw in opposite order...lol
    // TODO: or, have "backing" snapwhot 8000bytes to pull bytes from...

    erasesprite(s);

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

// shift one step right
void spriteshift(char* bm, char w, char h) {
  char j, * p= bm;
  unsigned int v= 0;
  //while(*p) { // lol, can do!
  do {
    v= 0; j= w;
    do {
      v<<= 6;
      v|= *p & 63;
      *p= ((v >> 1) & 63)| 64;
      ++p;
    } while(--j);
  } while(--h);
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
// 1001: 1599cs  67sp/s  894cfps (xor, i.e. 2x drawsprite, asm)
// 1001: 1270cs  78sp/s 1125cfps (old style, erasesprite, +new asm drawsprite)
// ---- TODO: ^^^----- why is it slower? erasesprite flicker
// 1001:  914cs 109sp/s 1564cfps (eraseclever, asm:drawsrpite) +3.5fps!

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

  // init sprites
  for(i=0; i<N; ++i) {
    sprite* s= sploc+i;

    // position
    s->x= 130-130/N*i;
    s->y= 180/N*i;

    s->dx= +1;
    //s->dx= 0;
    s->dy= +i*11/10+1;

    s->bitmap= enterprise;

    // - have mask?
    {
      int markpos= 2+ s->bitmap[0] * s->bitmap[1];
      s->mask= (42==s->bitmap[markpos])?
        s->bitmap+markpos+1: NULL;
    }

    // - create scrollable copies
    s->shbitmap[0]= s->bitmap;
    s->shmask[0]= s->mask;

    if (1)
    { char j; int bytes= s->bitmap[0] * s->bitmap[1] + 3;
      for(j=1; j<6; ++j) {
        char* nw= malloc(bytes);
        memcpy(nw, s->shbitmap[j-1], bytes);
        spriteshift(nw+2, s->bitmap[0], s->bitmap[1]);
        s->shbitmap[j]= nw;

        // TODO: make mask also use +2...
        if (s->mask) {
          nw= malloc(bytes);
          memcpy(nw, s->shmask[j-1], bytes);
          //spriteshift(nw, s->bitmap[0], s->bitmap[1]);
          s->shmask[j]= nw;
        } else {
          s->shmask[j]= NULL;
        }
      }
    }

    // show
    if (1)
    { char j;
      for(j=0; j<6; ++j) {
        s->bitmap= s->shbitmap[j];
        s->mask= s->shmask[j];
        if (s->bitmap) {
          drawsprite(s);
          cgetc();
          erasesprite(s);
        }
      }
      if (s->shbitmap[0]) {
        s->bitmap= s->shbitmap[0];
        s->mask= s->shmask[0];
      }
    }

    drawsprite(s);
  }

  T= time();
  while(ndraw<=1000) {
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

