// Sprite.c - ORIC hires graphic sprites

// (C) 2025 jsk@yesco.org
//
// Read doc+settings below:
//
// TODO: minimal sprite but super-many! (8x66 pixel sprite?)
//
// ORIC: 8 sprites 24x24
// (/ (* 105.0 1056) (* (* 4 6) 24) 8) = 24.0 fps!

//
// Do Benchmark test

//#define BENCH

#ifdef BENCH

  #define Nsprites 7

  #define SPRITE_XMIN 2*6
  #define SPRITE_XMAX 239

  #define SPRITE_YMIN 0
  #define SPRITE_YMAX 199

  #define SPRITE_PLACE

#else

// TODO: move it out to another file
#define ORICGAME

// Number of sprites that can be defined/used

#ifdef ORICGAME
#define Nsprites 9
#endif ORICGGAME

// * higher number sprite is above lower numbers
//   (drawing order low-high)

// * 8 sprites collision detection
//   - about 10% (?) overhead (bitsetting)

#define COLLISION

//   - sprite bounce when colliding
//     ("physics: exchange direction and speed")

#define COLLBOUNCE

//     user defined and will be called
//        void collision(sprite* s, char i); 

//#define COLLFUNC


//        display collision cells by inverse (slow 2x overhead)

//#define DISPCOLL

// * optional protected foreground (sprites "behind")
//    7) inverse hi-bit set = don't overwrite
//       23-25% speed-loss w OVERWRITE (OVERWRITE)
//       faster w more foreground!

//#define PROTECT_HIBIT

//    6) 6th bit==0 (== not normal pixels)
//       ??% speed-loss (w OVERWRITE)a

//#define PROTECT_6BIT

// - 3 methods of update (TODO: definable/sprite)
//
//    w) DEFAULT: OVERWRITE (bitblt/byteblit)
//       Use: when background empty
//            pixel movement
//            many sprites (>6)
//            fast movements
//            non-overlapping sprites (otherwise flickrs)
//            all sprites undraw/redraw in order
//            ink color attributes ok
//               (don't mix with protect?)

#define COLORATTR

//    x) XORWRITE (and undraw, 2x cost basically)
//       Use: preserve background (inverts sprite pixels)
//            sprites moves occasionally
//            no color attributes
//          TODO: clever update: merge old+new for direction
//
//    m) MASKWRITE (using mask, 4x?)
//       Use: using mask for precision-sprites
//            few detailed (main character?)
//            perfect overlap w other sprites
//            can be transparent
//            preserves background
//             a) use backbuffer for background, use to restore
//             b) save as draw (overlap, needs redraw reverse order)
//
//    z) TODO: COMPRESEDWRITE (interpreted w skips)
//       Use: sparse bitmaps, irregular shapes
//            animations (can mix?)
//       ???Format:
//             BYTE COPY:
//               0--7 - background color
//               16--23 - ink color
//              (32--63 - repeat last N-30)
//               64--127 - pixels
//
//             SKIP/COMPRESS
//               128+ 0 - quote next char
//               128+ 1--31 - repeat last N= C-128+1 (2..32+2-1)
//               128+ 32--127 - skip N= C-128-32+1
//
//             CONTROL (?)
//                8 n - back n cells
//                9 n - forward n cells
//               10 n - down n cells
//               11 n - up
//               12 - home
//               13 - "newline"
//               14 - 

// * canvas default bouncy border:
//

// protect 2 color attr columns
#define SPRITE_XMIN 2*6
#define SPRITE_XMAX 239

#define SPRITE_YMIN 0
#define SPRITE_YMAX 199

#if defined(PROTECT_HIBIT) || defined(PROTECT_6BIT)
  // unprotect the color columns as they are protected otherwise
  #undef  SPRITE_XMIN
  #define SPRITE_XMIN 0
#endif

// Sprites are automatically lined up and given dx,dy and drawn
// Good for testing etc
//
#define SPRITE_PLACE


// "Tomorrow, tomorrow, tomorrow".... story girl boy...
// creating movie, diable, fictional RPG gmae inside the novel - erh???

#endif // BENCH


// old bench...

// = 859cs ALL
// = 823cs ALL (LDA savings, etc) 342pM
// =  45cs movement (not calling erase/draw)
// = 103cs not calling gpfill/drawsprite: just if if if
// = 286cs not calling drawsprite
// = 580cs not calling erasesprite
// =  69cs not calling gpfill+draw (non-drawing stuff)
// GPFILL macro calling not correct (messes memory)
// (= 311cs GPFILL() 15cs savings... 5%?)
// (= 272cs GPFILL()+no LDA - 39cs savings! 12%ish)
// = 241cs erasesprite
//    24cs   passing parameters to erasesprite!
//   217cs   gpfill asm cost
// = 537cs drawsprite (-erasesprite) - 486pM
// = 754cs   gpfill+drawsprite (useful drawing work!)

// (- 823 754)

// <<< END_DOC, END_DEF





#ifndef MAIN
  #define MAIN
#endif

// for debugging/module testing
// TODO: move to MAIN (?)
#include "../hires-raw.c" // using hires(); gclear(); gfill()?

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

// sprite.status
#define SP_OFF 0
#define SP_ON  128

// TODO: make property[Nsprites] = faster!
typedef struct sprite {
  // possible states
  // - (unallocated)
  // -   0 = off (hidden)
  // -   1 = on (shown)
  // - 129 = moving (have dx, dy)
  signed char status;

  // TODO: higher resolution than this
  // alt 1) higher resolution x,y,dx,dy
  //        could have simulated time!
  // alt 2) instead of dx,dy have tx,ty (ticks!)
  //        every tick just --tx,--ty
  //        if 0, reset and update x,y (w dxdy)
  // alt 3) like now

  // TODO: char? faster
  // TODO: x=y=0 == disabled? or 255? or .enabled
  int x, y;
  // this could be subpixel/frame
  signed char dx, dy;

  // sizes in bytes/cells width, and lines h
  char w, h;

  // opt
  char wx;
  // TODO: how much do these save during moving?
  char xmax, ymax;
  char xmin, ymin;

#ifdef SPRITESAVE
  // saved background
  char* bg; // same size as bitmap
#endif // SPRITESAVE

  // current (TODO: remove?)
  char* bitmap;
  char* mask;

  // shifted bitmaps/masks
  // TODO: move out?
  char* shbitmap[6];
  char* shmask[6];

  // TODO: 
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

#ifdef COLLISION

char spxloc[40], spyloc[25];

// This one i O(n^2) use bits method instead?
char spritecollision(sprite* a, sprite* b) {
  if (a->x > b->x) return -spritecollision(b, a);
  {
    int ax1= a->x, ax2= ax1 + a->wx;
    int ay1= a->y, ay2= ay1 + a->bitmap[1];

    int bx1= b->x, bx2= bx1 + b->wx;
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

#endif //COLLISION

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

void drawsprite(register sprite* s) {
  static char w, h, *l;
  static char * sp, * msk;
  static char m;
  static char ww;
  static char hh;

  m= mod6[s->x];
  sp=  s->shbitmap[m];
  msk= s->shmask[m];
  w= *sp; h= sp[1];

  ww= 40-w; hh= h;
  l= rowaddr[s->y] + div6[s->x];

  ++ndraw;

  // TODO: clipping?

  // copy to zp for asm
  // TODO: allocate them! lol

  *(int*)0x90= (int)sp+2;   // sprite byte data
  *(int*)0x92= (int)l;      // screen address + y offset
  *(int*)0x94= (int)msk+2;  // mask byte data

#ifdef SPRITE_SAVE
  // TODO: too conplicated w partial clear?
  // and always undraw redraw when move is flicker... :-(
  *(int*)0x96= (int)(s->sav)+2;  // save under sprite
#endif // SPRITE_SAVE

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

#ifdef PROTECT_HIBIT    
    // skip if hibit set
    asm("lda ($92),y"); // a= l[y]
    asm("bmi %g", skip0);
#endif // PROTECT_HIBIT
#ifdef PROTECT_6BIT
    // skip if hibit set
    asm("lda ($92),y"); // a= l[y]
    asm("rol");         // M= a&6bit lol
    asm("bpl %g", skip0);
#endif // PROTECT_6BIT
#ifdef SPRITE_SAVE
    // TODO: if combined with protect put there!
    asm("lda ($92),y");  // a= l[y]
    asm("sta ($96),y)"); // save it
#endif // SPRITE_SAVE

    // draw
    asm("lda ($90),y"); // a = sp[y];
    asm("sta ($92),y"); // l[y]= a;
  skip0:

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
    // load screen value
    asm("lda ($92),y"); // a = l[y];

    // draw
    asm("eor ($90),y"); // a^= sp[y]; // draw+undraw
    asm("ora #$40");
    asm("sta ($92),y"); // l[y]= a;
  skip1:

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
    // load current screen value
    asm("lda ($92),y"); // a = l[y];

// TODO: #ifdef PROTECT_HIBIT     (see case 0)

    // skips "foreground"
    if (0) {
      // skip inverted cells
      // (case 0): 1837cs - 1680 = 157cs 16% overhead
      asm("bmi %g", skip2);
    } else {
      // skip anything w bit 6 == zero
      // (case 0): 1881cs - 1680 = 201cs 21% overhead
      //  [0,63] (and +128) = non-normal pixels
      asm("rol");
      asm("bpl %g", skip2);
    }

    // draw
    asm("and ($94),y"); // a&= mask[y];
    asm("ora ($90),y"); // a|= sp[y];
    asm("ora #$40");
    asm("sta ($92),y"); // l[y]= a;
  skip2:

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

// graphics Pixel fill
// (copied modifyed from hires-raw.c/gfill)
// (don't change attributes/hibit)

// TODO: specialize for spriteerase
//       a) don't want to load fillvalue v all the time
//       b) to go next line step 40-w like drawsprite
//       c) count using var not register

static char ww, hh, vv;

// TODO: remove, or fix, 5% overhead by calling!
#if 0
#define GPFILL(c,r,w,h,v) \
  do { if (r<200) { \
    ww=(w); hh=(h); vv=(v); gpfill(); } \
    *(int*)0x90= rowaddr[r]+(c) -1; \
  } while(0)
#else
#define GPFILL(c,r,w,h,v) gpfill(c,r,w,h,v)
#endif

void gpfill(char c, char r, char w, char h, char v) {
//void gpfill() {
  // TODO: adjust so not out of screen?
  // TODO: can share with lores?
  //static char ww, hh, vv;

  if (r>= 200) return;
  ww= w; hh= h; vv= v;

  *(int*)0x90= (int)rowaddr[r]+c -1; // -1 because y=w

  asm("ldx %v", hh);

 nextrow:
  //for(; h; --h) {
    //for(cell= w; cell; --cell) p[cell]=v; // 619hs
    //memset(p+= 40, v, w); // 100x 10x10 takes 337hs !

    // specialized memset (w<256)
    asm("lda %v", vv);
    asm("ldy %v", ww);

  next:

#ifdef PROTECT_HIBIT    
    // skip if hibit set
    asm("lda ($90),y"); // a= l[y]
    asm("bmi %g", skip);
    // TOOD: maybe reuse X?
    asm("lda %v", vv); // TODO: this slows down...
#endif // PROTECT_HIBIT
#ifdef PROTECT_6BIT
    // skip if hibit set
    asm("lda ($90),y"); // a= l[y]
    asm("rol");         // M= a&6bit lol
    asm("bpl %g", skip);
    // TOOD: maybe reuse X?
    asm("lda %v", vv); // TODO: this slows down...
#endif // PROTECT_6BIT

    asm("sta ($90),y"); // l[y]= 0x40;
  skip:

    // next col
    asm("dey");
    asm("bne %g", next);

    // p+= 40;
    // *(int*)0x90+= 40;
    asm("clc");
    asm("lda #40");
    asm("adc $90");
    asm("sta $90");
    asm("lda $91");
    asm("adc #00");
    asm("sta $91");
    
    // while(--h);
    asm("dex");
    asm("bne %g", nextrow);
}


// TODO: move into "movesprite()"
// TODO: pass "64" as parameter (col attr f foreground!)
void erasesprite(register sprite* s, int newx, signed char dy) {
  static char xdiv;
  static signed char d;

  xdiv=div6[s->x]; // 6cs

  // 1609cfps -> 1753cs, saves some

  // for xor, lol
  //drawsprite(s); return;

  // TODO: this doesn't handle overlapping. mask?
  // TODO: clipping?

  // clever, no change in cell column (clear above/below)
  if (!(char)s->dx || !(d=(div6[newx] - xdiv))) {
    // same x, or same cell (in height)

    // - clear vertically only
    if (dy > 0) {
      // clear below
      GPFILL(xdiv, s->y, s->w, dy, 64);
      return;
    } else if (!(char)dy) {
      return; // not moved!
    } else { // dy < 0
      // clear above
      GPFILL(xdiv, s->y+dy + s->h, s->w, -dy, 64);
      return;
    }
  }
  // TODO: move cells left/right

  // more general case requires two function calls
  // it appears to be more expensive than just one...

#ifdef URK
  // it appears two function calls is more expensive than one!
  // if not there 1753cfps -> 1649cfps if enabled... lol
  if (!dy && d > 0) { // move right
    if (d < s->w) { // short move right
      GPFILL(xdiv, s->y, d, s->h, 64);
    }
  } else { // d < 0
//    if (-d < s->w) { // short move left
//      GPFILL(xdiv, s->y+s->w+d, -d, dy, 64);
//      return;
//    }
  }
#endif

  // Otherwise: fallthrough:

  // -- clear all (flickers little)
  GPFILL(xdiv, s->y, s->w, s->h, 64);
}

#define Z 37

void b(char x, char y) {
  box(x, y, Z, Z);
}

sprite sploc[Nsprites];

int colls= 0;

void spritetick() {
  static char i, j, k, c, cx, cy, *px, *py, z, zz;
  //static int newx, newy;//
  static char newx, newy;
  register sprite* s;
  static char spbit;

  spbit= 1;

  s= sploc;

#ifdef COLLISION
  // clear sprite locations
  memset(spxloc, 0, sizeof(spxloc));
  memset(spyloc, 0, sizeof(spyloc));
#ifdef DISPCOLL
  gfill(0, 190, 40, 8, 64);
  gfill(div6[230], 0, 2, 200, 64);
#endif // DISPCOLL

  // for debug
  gotoxy(0, 25);
#endif // COLLISION

  for(i=0; i<Nsprites; ++i) {
    // sprite not active, or temporary disabled
    if (s->status < 0) { ++s; continue; }

    // cc65 doesn't generate good code! 10cs better...
    //if (!(z=s->dx) && !(z=s->dy)) continue; // adding z makes it better!
    if (!(char)s->dx && !(char)s->dy) continue; // same as casting char (signed problem)
    //if (0==s->dx && 0==s->dy) continue; // jsr ldaix lol

    // undraw
    // TODO: undraw in opposite order...lol
    // TODO: or, have "backing" snapwhot 8000bytes to pull bytes from...

    // TODO: movesprite();
    
    // update pos
    newx= s->x; newy= s->y;

    // this faster than while? lol
  rex2:
    if ((newx+= s->dx) + s->wx >= SPRITE_XMAX || newx < SPRITE_XMIN) {
      s->dx= -s->dx; goto rex2;
    }

    // inmaterial time difference...
    //z= s->xmax; zz= s->xmin;
    //if (newx >= z || newx < SPRITE_XMIN) s->dx= -s->dx; // slower!
    //if (newx >= z || newx < SPRITE_XMIN) s->dx= (((char)s->dx)^255)+1;
    //if (newx >= z || newx < zz) 

//    if (z >= zz) s->dx= -s->dx;
//    if (newx < SPRITE_XMIN) s->dx= -s->dx;
    //newx+= (char)s->dx;
    //newx+= s->dx;

  rex3:
    if ((newy+= s->dy) + s->h >= SPRITE_YMAX || newy < SPRITE_YMIN) {
      s->dy= - s->dy; goto rex3;
    }
    z= s->ymax; zz= s->ymin;
    //if (newy >= zz || newy < SPRITE_YMIN) s->dy= - s->dy;
    //if (newy >= z || newy < zz) s->dy= (((char)s->dy)^255)+1;
    //newy+= (char)s->dy;
    //newy+= s->dy;

    // TODO: passing parameters is expensive
    erasesprite(s, newx, newy - s->y);

    // move
    s->x= newx;
    s->y= newy;

    // draw
    drawsprite(s);
      
#ifdef COLLISION
    // collision?
    // disabled:  990cs
    //  enabled: 1760cs !!!
    //           1679cs (w print, sp[0] or k moved out)
    // 
    // doubles the cost - same as drawing sprite!
    // (can we put it inside the spritedraw?)
    // 
    // mark where the sprite is
    // (cheaper than boundary checking but still
    //  expensive)
    // TODO: make it incremental
    //   (together with erasesprite "clever" opt)
    px= spxloc+div6[newx];
    cx= 0;

    k= s->w;
    if (1) {

      *(int*)0x80= px-1; // 2 bytes

      asm("ldy %v", k);      // k
    nextx:
      asm("lda %v", spbit);  // a= spbit
      asm("ora ($80),y");    // a|= px[y]
      asm("sta ($80),y");    // px[y]= a
      asm("ora %v", cx);     // a|= cx
      asm("sta %v", cx);     // cx= a
      asm("dey");            // --k
      asm("bne %g", nextx);  // if (k==0) goto nexty

    } else {

      for(j=0; j<k; ++j) {
        cx |= (px[j] |= spbit);
#ifdef DISPCOLL        
          gcurx= newx+6*j; gcury= 190+i; gmode= 1; setpixel();
#endif // DISPCOLL
      }

    }

    py= spyloc+(newy>>3);
    cy= 0;

    k= s->h/8+1;
    if (1) {

      *(int*)0x80= py-1; // 2 bytes, -1 for k is 1 bigger

      asm("ldy %v", k);      // k
    nexty:
      asm("lda %v", spbit);  // a= spbit
      asm("ora ($80),y");    // a|= py[y]
      asm("sta ($80),y");    // py[y]= a
      asm("ora %v", cy);     // a|= cy
      asm("sta %v", cy);     // cy= a
      asm("dey");            // --k
      asm("bne %g", nexty);  // if (k==0) goto nexty

    } else {

      for(j=0; j<k; ++j) {
        cy |= (py[j] |= spbit);
#ifdef DISPCOLL
          gcurx= 230+i; gcury= newy+j; gmode= 1; setpixel();
#endif // DISPCOLL
      }

    }
      
    // 3856cs - 4x overhead!
    // for(j=0; j<=i; ++j) c= spritecollision(s, sploc+i); 

    // - Any collisions?
    c= cx & cy;

    // more than one bit set
    if (c&(c-1)) {
      static hit;
      hit= 0;

      if (1) { // no print to see overhead
        //   print: 1640cs
        // noprint: 1654cs(?) (wow low overhead!)
        k= 1;
        for(j=0; j<8; ++j) {
          if (c & k) {
            putchar('0'+j);
            ++colls;

#ifdef COLLFUNC
            if (j!=i) collision(s, i);
#endif // COLLFUNC

#ifdef COLLBOUNCE
            {
              sprite* o= sploc+j;
              int t;

              // all reverse speed and direction
              t= s->dx; s->dx= o->dx; o->dx= t;
              t= s->dy; s->dy= o->dy; o->dy= t;
            }
#endif // COLLBOUNCE

          }
          k<<= 1;
        }
      }
      putchar('.');
    }

#endif // COLLISION

    ++s;

    // TODO: any above >7 cannot detect collision!
    spbit<<= 1;

  } // next sprite
  
// Hilites all cells by inverse if colliding
#ifdef DISPCOLL
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
  putchar('<');

#endif // DISPCOLL

}

// shift one step right
// TODO: very slow (1s?), optimize
char* spriteshift(sprite* s, char* bm) {
  char j, w= s->w, h= s->h;
  unsigned int size= w * h + 3; // space for w,h,42
  char * nw= malloc(size), * p= nw+2;
  unsigned int v= 0;

  assert(nw);
  memcpy(nw, bm, size);

  //while(*p) { // lol, can do?
  do {
    v= 0; j= w;

    #ifdef COLORATTR
      // keep first "column" of sprite fixed (is attribute)
      ++p; --j;
    #endif // COLORATTR

    // shift line of pixel cells
    do {
      v<<= 6;
      v|= *p & 63;
      *p= ((v >> 1) & 63)| 64; // TODO: ((char)v) ?
      ++p;
    } while(--j);
  } while(--h);

  return nw;
}

void shiftbitmaps(sprite* s) {
  char j;

  // - create x scrollable copies
  s->shbitmap[0]= s->bitmap;
  s->shmask[0]= s->mask;

  for(j=1; j<6; ++j) {
    // create a copy, scroll 1 pixel
    s->shbitmap[j]=          spriteshift(s, s->shbitmap[j-1]);
    s->shmask  [j]= s->mask? spriteshift(s, s->shmask  [j-1]): NULL;
  }
}

// for self-moving sprites: don't change s->dx, s->dy
// directly, call this
// TODO: maybe this isn't needed.... maybe overhead so small
// to do dynamic test?
void spritespeed(sprite* s, signed char dx, signed char dy) {
  s->dx= dx;
  s->dy= dy;

  dx= dx<0? -dx: dx;
  dy= dy<0? -dy: dy;

  s->xmin= SPRITE_XMIN + dx;
  s->ymin= SPRITE_YMIN + dy;
  s->xmax= SPRITE_XMAX - dx - s->wx;
  s->ymax= SPRITE_YMAX - dy - s->h;
}

void placesprite(register sprite* s, char x, char y) {
  erasesprite(s, 0, 0); // TODO: if not drawn...
  s->x= x; s->y= y;

  //while(!(oric->dx= rand()%8 -4));
  //while(!(oric->dy= rand()%8 -4));

  drawsprite(s);
}

void placespriterandom(sprite* s) {
  placesprite(s,
    s->xmin + rand() % (s->xmax - s->xmin),
    s->ymin + rand() % (s->ymax - s->ymin) );
}

// default show position (lines them up!)
char spritex= SPRITE_XMIN+12, spritey= SPRITE_YMIN;

// Define no I sprite from COPYFROM (if <I) or use BITMAP and MASK.
// Basically, any sprite with lower number can be used as template.
// Set COPYFROM to I when defining.

// Result: returns sprite* for modification

sprite* defsprite(char i, char copyfrom, char* bitmap, char* mask) {
  sprite* s= sploc+i;
  char j;

SCREENLAST[-1]= 'a';
  // - init sprite fields
  if (copyfrom < i) {
SCREENLAST[-1]= 'b';
    memcpy(s, sploc+copyfrom, sizeof(*s));
SCREENLAST[-1]= 'c';
  } else {
SCREENLAST[-1]= 'd';
    memset(s, 0, sizeof(*s));
    s->bitmap= bitmap;
    s->mask= mask;
    if (bitmap) {
      s->w= bitmap[0];
      s->h= bitmap[1];
      assert(s->w * s->h < 256); // max size for asm
      s->wx= s->w * 6;
    }
SCREENLAST[-1]= 'e';
  }
SCREENLAST[-1]= 'f';

#ifdef SPRITE_PLACE
  s->status= 1;

  //TODO: if not set, may be illegal pos? loop probelm in update/move
  // (default) position
SCREENLAST[-1]= 'g';
  if (spritex + s->wx >= SPRITE_XMAX) { spritex= SPRITE_XMIN; spritey+= 40; } 
  s->x= spritex;
  spritex+= s->wx;
  s->y= spritey;

  // intial speed
  s->dx= +1+i/2;
  s->dy= +i*11/10+1;
SCREENLAST[-1]= 'h';
#endif // SPRITE_PLACE
SCREENLAST[-1]= 'i';

  // TODO: every time dx, dy is updated need update this
  s->xmax= SPRITE_XMAX - s->wx + s->dx;
  s->ymax= SPRITE_YMAX - s->h  + s->dy;
  s->xmin= SPRITE_XMIN + s->dx;
  s->ymin= SPRITE_YMIN + s->dy;

SCREENLAST[-1]= 'j';
  if (bitmap && !s->shbitmap[1])
    shiftbitmaps(s);

SCREENLAST[-1]= 'k';
  // TODO: maybe require enable? or use default flag?
// TODO: printf messes up memory?
// NULL pointer allocate?
// gotoxy(0,25);printf("%d: (%d,%d)   ", i, s->x, s->y);
SCREENLAST[-1]= 'l';
// cgetc();
SCREENLAST[-1]= 'm';
  if (bitmap) drawsprite(s);
SCREENLAST[-1]= 'n';
// cgetc();
SCREENLAST[-1]= 'x';
  return s;
}

sprite* defsequence(char i, char copyfrom, char** bitmaps) {
  sprite* s= defsprite(i, copyfrom, NULL, NULL);

  memcpy(s->shbitmap, bitmaps, sizeof(s->shbitmap));
  s->bitmap= s->shbitmap[0]; // TODO: remove s->bitmap? redundant?
  s->w= bitmaps[0][0];
  s->h= bitmaps[0][1];
  s->wx= s->w * 6;

  return s;
}

#ifdef MAIN

// dummy
char T,nil,doapply1,print;


// various convenience macros for defining sprites
#include "../bits.h"

// sprites lineup for oric shoot'em up!
#include "sprite-oric.c"
#include "sprite-boot.c"
#include "sprite-explosion.c"

char L= 30;

void draw_paddle(char up, char draw) {
  if (up) {
    gfill(20, 100-L, 1, 2*L+1, draw);
  } else {
    gfill(20-div6[L], 100-3, div6[2*L]+1, 2*3, draw);
  }
}

void xpaddle(char a) {
  char x, y, m= a&63;
  switch(((a-32+256)/64)&3) {
  case 0: x= 64;   y= m;    break;
  case 1: x= 64-m; y= 64;   break;
  case 2: x= -64;  y= 64-m; break;
  case 3: x= m-64; y= m-64; break;
  }
  x/= 4; y/= 4;
  gcurx= 120; gcury= 100; draw(x, y, 2);
}

void paddle(char x, char y) {
  gcurx= 120; gcury= 100; draw(x-120, y-100, 2);
}

sprite *oric, *spectrum, *c64, *boot, *explode;

//#define KLEN 30 // kick
#define KLEN 20 // kick gives 4 areas
//#define KLEN 18 // 
//#define KLEN 8
void kick(signed char dx, signed char dy) {
  char i;
  
  // stop sprites, enable boot
  for(i=0; i<Nsprites; ++i) sploc[i].status= -sploc[i].status;
  
  // "kick" - boot out
  spritespeed(boot, dx, dy);
  for(i=0; i<KLEN; ++i) {
    spritespeed(boot, boot->dx+dx, boot->dy+dy);
    //spritespeed(boot, boot->dx*2, boot->dy*2);
    spritetick();
    //gotoxy(0,25); printf("%d %d %d %d   ", i, boot->status, boot->x, boot->y);
    //wait(10);
  }

  // TODO: what it hit: change their vectors!

  // boot back
  //spritespeed(boot, -dx, -dy);
  //for(i=0; i<KLEN; ++i) spritetick();

  spritespeed(boot, 0, 0);

  // restore movement, stop boot
  for(i=0; i<Nsprites; ++i) sploc[i].status= -sploc[i].status;
}

// "bench" report speed Nsprites=7, sprites= enterprise
void report(unsigned int ndraw, unsigned int T) {
  char i;
  long bytes= 0;
  long optimalBps= 1000000L/16; // copy 1 byte 16c=5+6+2+3 (lda(),y;sta(),y;inx;bne)
  long Bps;

  for(i=0; i<Nsprites; ++i) {
    sprite* s= sploc+i;
    bytes+= (s->w * s->h) * (s->mask? 2: 1); // TODO: multiply 2 for xor
  }
  Bps= ndraw*100L*bytes/Nsprites/T;

  gotoxy(0,25);
  // TODO: Bps is all wrong? why?
  printf("%d: %ucs %ldsp/s %ldcfps %ldBps (%dpM) bytes=%ld COLLS=%d (673) ",
         ndraw, T, ndraw*100L/T, ndraw*10000L/Nsprites/T, Bps, (int)(Bps*1000/optimalBps), bytes, colls);
  cgetc();
}

// 1008: 650cs 155sp/s 1723cfps 15817Bps (253pM) 918B
// 1008:1004cs 100sp/s 1115cfps 10240Bps (163pM) - COLLISION, expensive +55%
// 1008: 716cs 140sp/s 1564cfps 14359Bps (229pM) - COLLISION asm +10%
// 1008: 735cs 137sp/s 1523cfps 13988Bps (223pM) - COLLISION COLLS=272 
// -- adjusted valuie N=9 but didn't count drawsprite boot
//    (moved ++ndraw into drawsprite, so was missing one count!)
// 1008: 646cs 155sp/s 1726cfps 15852Bps (253pM) 918B - COLLISION
// 1008  569cs 176sp/s 1960cfps 17997Bps (287pM) 918B - no coll...
void oric_main() {
  char ku= keypos(KEY_UP),   kd= keypos(KEY_DOWN);
  char kl= keypos(KEY_LEFT), kr= keypos(KEY_RIGHT);
  char i;
  unsigned int T;

  // draw screen
  hires(); gclear();

  // init sprites
  oric    = defsprite(0, 0, oric_thin_color, NULL);
  spectrum= defsprite(1, 1, sinclair_color, NULL);
  c64     = defsprite(2, 2, c64_color, NULL);
  // (9duplicates)
            defsprite(3, 0, NULL, NULL); // oric
            defsprite(4, 1, NULL, NULL); // spec
            defsprite(5, 2, NULL, NULL); // c64
            defsprite(6, 0, NULL, NULL); // oric

  boot    = defsprite(7, 7, boot_color, NULL); {
    placesprite(boot, 120 - boot->wx/2, 100 - boot->h/2);
    spritespeed(boot, 0, 0);
    boot->status= -boot->status;
  }

  explode = defsequence(8, 8, explosion); {
    spritespeed(explode, 1, 0);
  }

  // main loop
  T= time();

 again:
  while(ndraw<=1000) {
//  while(1) {

    spritetick();
    // Make it on top, if disabled/not moving; it's not drawn.
    // TODO: change that? redraw all at overlap?
    drawsprite(boot);

    if (0) {
      if (keypressed(ku))
        spritespeed(boot, boot->dx, boot->dy-1);
      if (keypressed(kd))
        spritespeed(boot, boot->dx, boot->dy+1);
      if (keypressed(kr))
        spritespeed(boot, boot->dx+1, boot->dy);
      if (keypressed(kl))
        spritespeed(boot, boot->dx-1, boot->dy);
    } else {
    // kick boot ?
    if (keypressed(ku)) kick(0, -1);
    if (keypressed(kd)) kick(0, +1);
    if (keypressed(kr)) kick(+1, 0);
    if (keypressed(kl)) kick(-1, 0);
*SCREENLAST= 'D';
    }
    //gotoxy(0, 25); printf("(%3d %3d) - ", x, y);
  }

  report(ndraw, T-time());

  ndraw= -32766;
  goto again;
}

// test sprites
// (good for extracting formula fps vs w and h)
#include "sprite-pineapple.c"
#include "sprite-test.c"

// used for benchmark main
#include "sprite-enterprise.c"

void init() {
  char i;
  sprite* s;

  for(i=0; i<Nsprites; ++i) {

#ifdef COLORATTR
    if (1) {
      if (0) {
        s= defsprite(i, 0, pineapple_color, NULL);
      } else if (0) {
        s= defsprite(i, 0, mini_pineapple_color, NULL);
        while((s->x= SPRITE_XMIN+rand()&127) > SPRITE_XMAX);
        while((s->y= SPRITE_YMIN+rand()&127) > SPRITE_YMAX);
        s->dx= rand()&7-4;
        s->dy= rand()&7-4;
        drawsprite(s);
      } else {
        s= defsprite(i, 0, micro_pineapple_color, NULL);
        s->dx= 0;
        s->dy= (rand()&3)+1;
  s->xmax= SPRITE_XMAX - s->wx + s->dx - 6;
  s->ymax= SPRITE_YMAX - s->h  + s->dy - 8;
  s->xmin= SPRITE_XMIN + s->dx + 6*2;
  s->ymin= SPRITE_YMIN + s->dy + 6;
        while((s->x= s->xmin+6+(rand()&127)) > s->xmax);  s->x-= mod6[s->x];
        while((s->y= s->ymin+(rand()&127)) > s->ymax);
        drawsprite(s);
      }    
    } else {
      // lineup for oric shoot'em up!
      switch(i%4) {
      case 0: s= defsprite(i, 0, c64_color, NULL); break;
      case 1: s= defsprite(i, 1, sinclair_color, NULL); break;
      case 2: s= defsprite(i, 2, oric_thin_color, NULL); break;
      case 3: s= defsprite(i, 3, color_enterprise, NULL); break;
      }
    }
#else
    // - All same
    //s= defsprite(i, 0, oric_thin, NULL);
    // TODO: ifdef SPRITE_BENCH
    s= defsprite(i, 0, enterprise, NULL);
    //s= defsprite(i, 0, disc, disc_mask);
#endif // COLORATTR

  }
}

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


// N=7 1001 1836 cs 54 hsp/s 778 hfps
// N=7 1001 1446 cs 69 hsp/s 988 hfps - no erase... (-21%)

// ----ENTERPRISE sprite----
// - bigger than ever... 11*6 x 16 sprite N=7 sprites
//
// 1001: 2442cs 40sp/s 585cfps - full clear (flicker)
// 1001: 1835cs 54sp/s 779cfps - clever clear (+ 390cs)
// (1001: 1445cs 69sp/s 989cfps - no clear (traces) (21%))
// 1001: 1699cs 58sp/s 841cfps - drawsprite static vars
//       1689cs rowaddr used only initially
//       1627cs -Oi but memcpy still not inlined...
// 1001: 1127cs  88sp/s 1268cfps 13756 Bps (asm memcpy)
// 1001:  978cs 102sp/s 1462cfps 18013 Bps (gfill: asm for memset)
// 1001:  966cs 103sp/s 1480cfps 18237 Bps (gfill: all asm)
// 1001:  952cs 105sp/s 1502cfps 18505 Bps (gfill: value)
// (1001: 751cs 133sp/s 1904cfps 23458 Bps (erase: 27% overhead))
// 1001:  946cs 105sp/s 1511cfps (sprite s pass around)

// == xor and other
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
// 1001:  973cs 102sp/s 1469cfps (no protect)

// 1001: 1193cs  83sp/s 1198cfps (protect hibit, 23% w fore!)
// 1001: 1213cs  82sp/s 1178cfps (protect hibit: 25% no fore)
// 1001: 1252cs  79sp/s 1142cfps (protect 6bit: 27% w fore)
// 1001: 1272cs  78sp/s 1124cfps (protect 6bit: 31% no fore)
// 1001: 1283cs  84sp/s 1208cfps (7.5% faster! -"- register sprite, static)
// 1001: 1028cs  97sp/s 1391cfps (COLORATTR enterprise, 2 cols more)
// 1001:  903cs 107sp/s 1537cfps (no protect, no color)
// 1001:  732cs 136sp/s 1953cfps 13635Bps (218pM) bytes-698 = 21.8% of optimal copy N=7 (oric,sinclari,c64,enterprise)
// (1001:  575cs 174sp/s 2486cfps  9400Bps (150pM) bytes= 378 (7x oric_thin))

// 1001:  987cs 101sp/s 1448cfps 17849Bps (285pM) bytes=1232 (7x enterprise)
// 1001:  946cs 105sp/s 1511cfps 18623Bps (297pM) (removed gotoxy, sploc+i => ++s;
// 1001:  923cs 108sp/s 1549cfps 19087Bps (305pM) (enterprise, wx)
// 1001:  883cs 113sp/s 1619cfps 19951Bps (319pM) (enterprise, -Oirs, ) (/ 923 883.0) 4.5% faster
// 1001:  823cs 121sp/s 1737cfps 21406Bps (342pM) 6.8% faster
// ---- 3.0x faster than when we begin!!!

// useful work:
//   (      754cs ... gfill+drawsprite "usefull" memory work 400pM)
//   (1001: 435cs 230sp/s  3287cfps 12426Bps (198pM) oric_thin)
// was 565cs - 24% faster now!

// 1001:  816cs 122sp/s 1752cfps 21590Bps (345pM) bytes=1232

void main() {
  unsigned int T;

#ifdef ORICGAME
  oric_main();
#endif // ORIGGAME

  hires();
  gclear();

  // - draw background
  gfill(0, 0, 1, 200, 0+16+128); // paper

  // - draw foreground!

#ifdef COLORATTR
  // If all sprites have color, sometimes when they
  // overlap, attribute gets overwritten, so hide line!
  // OR define PROTECT_6BIT
  gfill(1, 0, 1, 200, 0+0 +128); // ink: black!
#else
  gfill(1, 0, 1, 200, 0+2 +128); // ink: green
#endif

#ifdef PROTECT_HIBIT
#if 1
  // vert
  gpfill(30,  0,  1, 200, 128+1+4+16+64);
  gpfill(10,  0,  1, 200, 128+1+4+16+64);
  // horiz
  gpfill( 2,  0,  38,  6, 128+1+4+16+64);
  gpfill( 2, 194, 38,  6, 128+1+4+16+64);
#endif
#endif // PROTECT_HIBIT

#ifdef PROTECT_6BIT
#if 1
  // vert
  gpfill(30,  0,  1, 200, 128+1+4+16+32);
  gpfill(10,  0,  1, 200, 128+1+4+16+32);
  // horiz
  gpfill( 2,  0,  38,  6, 1+4+16+32);
  gpfill( 2, 194, 38,  6, 1+4+16+32);
#endif
#endif // PROTECT_6BIT

  init();

  T= time();
 again:
  while(ndraw<=1000) {
    spritetick();
  }

  report(ndraw, T-time());

  ndraw= -32766;
  goto again;
}

#endif // MAIN
