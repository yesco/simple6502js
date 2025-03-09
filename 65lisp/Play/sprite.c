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

// Possible ideas:
// - https://chipmunk-physics.net/release/ChipmunkLatest-Docs/#CollisionDetection
// - https://en.m.wikipedia.org/wiki/Collision_detection

// TODO: detect when drawing! (if not 64 then clash?)
//   (requires restore?)
// TODO: use a single pixel detector(?)
//
// TODO: make decision of detection only
//   (assign bit i to sprite only if required)
// TODO: type of sprites, id of sprite
// TODO: detect fine bitmap clash (shifted AND?)
// TODO: detect center of "gravity" collision/distance
// TODO: calculate pixel center of gravity position
// TODO: use callback on sprites "overlap()"
// TODO: pixelbased bounding box to refine overlap
// TODO: and pixels/mask
// TODO: add Z-dimension, further filters it out
// TODO: more than 8 objects?
// TODO: pixel object collision detect (cent of grav?)
// TODO: grid datastructure (expensive)

// Bitmap on X and Y colission detection
//
// main idea:
// - not a grid
// - just 8 sprites - 1 byte col and row
//   40 cols + 25 rows (basically text-screen!)
// - just a bitmap for X/6 and Y/8 extent of sprite
// - sprite bit i is set in Xmap and Ymap
//   for all it's X and Y cell locations
// - updated "every cycle" (all redrawn?)
// - when updating a sprite
//   a) OR the bitmaps for all X positions
//   b) OR the bitmaps for all Y positions
//   c) AND those two resulting bitmaps
//   d) if more than one bit set (in both)
//      then there is a:
//          BOUDNING BOX COLLISION!
//   e) dispatch a a finer checker on either
//      objects (callbacks?)
char spxloc[40], spyloc[25];

// This one i O(n^2)
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
  static char m;
  static char ww;
  static char hh;

  m= mod6[s->x];
  sp= s->shbitmap[m];
  msk= s->shmask[m];
  w= *sp; h= sp[1];

  ww= 40-w; hh= h;
  l= rowaddr[s->y] + div6[s->x];

  // TODO: clipping?
  *(int*)0x90= sp+2; // sprite byte data
  *(int*)0x92= l;    // loop this many lines
  *(int*)0x94= msk;  // mask byte data

  // -- ASM: a memcpy w strides, lol (w<256)
  // (be careful to change!)

  switch(0) {

  case 0:
    // - old style overwrite - very fast

    asm("ldy #0"); // y= sprite byte data index
    asm("clc");    // set it for once top!

  nextrow0:
    asm("ldx %v", w); // x= w bytes width

  nextcell0:
    // draw
    asm("lda ($90),y"); // a = sp[y];
    asm("sta ($92),y"); // l[y]= a;

    // step
    asm("iny"); // ++y next byte
    asm("dex"); // --x nextcell
    asm("bne %g", nextcell0);

    // step line
    // *(int*)0x92+= 40-w (= ww);
    asm("clc"); // TODO: set it for once at top!
    asm("lda $92");
    asm("adc %v", ww);
    asm("sta $92");
    asm("bcc %g", nott0);

    asm("inc $93");
    asm("clc"); // make it always clear!
  nott0:

    // ... while(--h); // more lines
    asm("dec %v", hh);
    asm("bne %g", nextrow0);
    break;

  case 1:
    // - xor draw/undraw (doesn't disturb backgr)

    asm("ldy #0"); // y= sprite byte data index
    asm("clc"); // set it for once top!

  nextrow1:
    asm("ldx %v", w); // x= w bytes width

  nextcell1:
    // draw
    asm("lda ($92),y"); // a = l[y];
    asm("eor ($90),y"); // a^= sp[y]; // draw+undraw
    asm("ora #$40");
    asm("sta ($92),y"); // l[y]= a;

    // step
    asm("iny"); // ++y next byte
    asm("dex"); // --x nextcell
    asm("bne %g", nextcell1);

    // step line
    // *(int*)0x92+= 40-w (= ww);
    asm("clc"); // TODO: set it for once at top!
    asm("lda $92");
    asm("adc %v", ww);
    asm("sta $92");
    asm("bcc %g", nott1);

    asm("inc $93");
    asm("clc"); // make it always clear!
  nott1:

    // ... while(--h); // more lines
    asm("dec %v", hh);
    asm("bne %g", nextrow1);
    break;

  case 2:
    // - draw w mask - expensive!

    asm("ldy #0"); // y= sprite byte data index
    asm("clc"); // set it for once top!

  nextrow2:
    asm("ldx %v", w); // x= w bytes width

  nextcell2:
    // draw
    asm("lda ($92),y"); // a = l[y];
    asm("and ($94),y"); // a&= mask[y];
    asm("ora ($90),y"); // a|= sp[y];
    asm("ora #$40");
    asm("sta ($92),y"); // l[y]= a;

    // step
    asm("iny"); // ++y next byte
    asm("dex"); // --x nextcell
    asm("bne %g", nextcell2);

    // step line
    // *(int*)0x92+= 40-w (= ww);
    asm("clc"); // TODO: set it for once at top!
    asm("lda $92");
    asm("adc %v", ww);
    asm("sta $92");
    asm("bcc %g", nott2);

    asm("inc $93");
    asm("clc"); // make it always clear!
  nott2:

    // ... while(--h); // more lines
    asm("dec %v", hh);
    asm("bne %g", nextrow2);
    break;

  }

}

// TODO: move into "movesprite()"
void erasesprite(sprite* s, int newx, signed char dy) {
  static char xdiv;
  static char* sp;
  xdiv=div6[s->x];
  sp= s->bitmap;

  // for xor, lol
  //drawsprite(s); return;

  // TODO: this doesn't handle overlapping. mask?
  // TODO: clipping?

  // clever
  if (s->dx == 0 || div6[newx]==xdiv) {
    // same x, or same cell (in height)

    // - clear vertically only
    if (!dy) return; // not moved!
    if (dy > 0) {
      // clear below
      gfill(xdiv, s->y, *sp, dy, 64);
      return;
    } else {
      // clear above
      gfill(xdiv, s->y+dy+sp[1], *sp, -dy, 64);
      return;
    }
  }
  // TODO: small move left/right
  //} else if one cell to the left
  //} else if one cell to the right

  // Otherwise: fallthrough:

  // -- clear all (flickers little)
  {
    char w= *sp, h= *++sp;
    gfill(xdiv, s->y, w, h, 64);
    return;
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

//#define DISPCOLL 1
#define DISPCOLL 0

void spmove() {
  char i, j, k, c, cx, cy, *px, *py;
  static int newx, newy;
  sprite* s;
  char* sp;
  char spbit= 1;

  // clear sprite locations
  assert(N<8);

  memset(spxloc, 0, sizeof(spxloc));
  memset(spyloc, 0, sizeof(spyloc));
  if (DISPCOLL) {
    gfill(0, 190, 40, 8, 64);
    gfill(div6[230], 0, 2, 200, 64);
  }

  gotoxy(0, 25);

  for(i=0; i<N; ++i) {
    s= sploc+i;
    sp= s->bitmap;

    if (!s->dx && !s->dy) continue;

    // undraw
    // TODO: undraw in opposite order...lol
    // TODO: or, have "backing" snapwhot 8000bytes to pull bytes from...

    // TODO: movesprite();
    
    // update pos
    newx= s->x; newy= s->y;

    // this faster than while? lol
  rex2:
    if ((newx+= s->dx) + 6*sp[0] >= 240 || newx < 0) {
      s->dx= -s->dx; goto rex2;
    }
  rex3:
    if ((newy+= s->dy) + sp[1] >= 200 || newy < 0) {
      s->dy= - s->dy; goto rex3;
    }

    erasesprite(s, newx, newy - s->y);

    // move
    s->x= newx;
    s->y= newy;

    // draw
    ++ndraw;
    drawsprite(s);
      
    // collision?
    if (1) {
      // mark where the sprite is
      px= spxloc+div6[newx];
      py= spyloc+(newy>>3);
      cx= 0;
      k= sp[0];
      for(j=0; j<k; ++j) {
        cx |= (*px |= spbit); ++px;
        if (DISPCOLL) {
          gcurx= newx+6*j; gcury= 190+i; gmode= 1; setpixel();
        }
      }
      cy= 0;
      k= sp[1]/8+1;
      for(j=0; j<k; ++j) {
        cy |= (*py |= spbit); ++py;
        if (DISPCOLL) {
          gcurx= 230+i; gcury= newy+j; gmode= 1; setpixel();
        }
      }
      
      //for(j=0; j<=i; ++j) {
      // 3856cs - 4x overhead!
      //c= spritecollision(s, sploc+i); 

      c= cx&cy;
      // more than one bit set
      if (c&(c-1)) {
        k= 1;
        for(j=0; j<8; ++j) {
          if (c & k) putchar('0'+j);
          k<<= 1;
        }
        putchar(' ');
      }

    } // collision

    spbit<<= 1;
  } // next sprite
  
  if (DISPCOLL)
    for(i=0; i<40; ++i) {
      for(j=0; j<25; ++j) {
        c= spxloc[i] & spyloc[j];
        // more than one bit set?
        if (c&(c-1)) {
          px= HIRESSCREEN+j*8*40+i;
          for(k=0; k<8; ++k) {
            *px ^= 128; px+= 40;
          }
        }
      }
    }

  putchar('|');
  //cgetc();
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

void initsprites(char n) {
  char i;

  // init sprites
  for(i=0; i<n; ++i) {
    sprite* s= sploc+i;

    // position
    s->x= 130-130/n*i;
    s->y= 180/n*i;

    //s->dx= 0;
    s->dx= +1;

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
          //drawsprite(s);
          //cgetc();
          //erasesprite(s);
        }
      }
      if (s->shbitmap[0]) {
        s->bitmap= s->shbitmap[0];
        s->mask= s->shmask[0];
      }
    }

    drawsprite(s);
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
// 1001: 1599cs  67sp/s  894cfps (xor, i.e. 2x drawsprite, asm)
// 1001: 1270cs  78sp/s 1125cfps (old style, erasesprite, +new asm drawsprite)
// ---- TODO: ^^^----- why is it slower? erasesprite flicker
// 1001:  914cs 109sp/s 1564cfps (eraseclever, asm:drawsrpite) +3.5fps!

// 1001: 1176cs  85sp/s 1215cfps (not moving x)
// 1001: 1169cs  85sp/s 1223cfps (smooth moving x)
//       1171cs  85sp/s 1221cfps 
//        980cs 102sp/s 1459cfps (erasesprite cell opt)
// 1001:  971cs 103sp/s 1472cfps 
// 1001:  961cs 104sp/s 1488cfps (statics in erasesp)



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
  unsigned int T;

  hires();
  gclear();
  gfill(0, 0, 1, 200, 0+16);
  gfill(1, 0, 1, 200, 0+2);

  initsprites(N);

  T= time();
  while(ndraw<=1000) {
    spmove();

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

