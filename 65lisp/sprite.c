// SPRITE-RAW

// This is an embryo to movable sprites,
// using the text-screen and redefinable charcters.

// A sprite is a placable bitmap.
//
// It can have a combination of these qualities:
// - size of one character      (uses 1 of 96 chars)
// - size of 2h x 3w characters (uses 6-12 of 96 chars)
// - either: 2 bit of: | texture | mask | z height
// - cut/outline of one bit around (may require one more row?)
// - (repetable tile) pattern
// - animated cycle
// - updateable pattern from state 
// - pixel scrollable up/down    (12 chars)
// - pixel scrollable left/right (12 chars)
// - movable
// - restricted to one of two sets of rows/regions
// - all over movable (cost 2x space)
// - can be a single one
// - can have multiple instances
// - multi instances in sync
// - multi instances not in sync (more costly)

// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - --
// - -- - - - AAEIIM- - - -- - - - - -- - - - - - -- - - - -- - - -- - --
// - -- - - - BBFJJN- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - CCGKKO- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 
// - -- - - - - -- -- - - -- - - - - -- - - - - - -- - - - -- - - -- - -- 

// BITMAP formats
//
// -- GENERIC BITMAP
// LONGMAP:  L x     32 bit                    L longs x r rows pixels (byte order 4backwards)
// BYTEMAP:  c x      8 bit                    c chars x r rows pixels (row: col by col, next row)
//
// -- ORIC SPECIFIC
// LCELLMAP: L x 4x6=30 bit 6 bit/char         L longs x r rows
// CELLMAP:  c x            6 bit/char         c chars x r rows


// SPRITES  (N=n+1)
// 
// There are 5 sizes of sprites
//
// 1x PLAYER    24x24 movable xy/20c, x/15c, y/16c, tile/12c   (906B, 720B, 128B, 96B)
// 2x BALL      18x16 movable xy/12c, x/ 8c, y/ 9c, tile/ 6c   (576B, 348B,  72B, 48B)
// 3. MISSILES  12x16 movable xy/ 9c, x/ 6c, y/ 6c, tile/ 4c   (432B, 288B,  48B, 32B)
// 4. HORIZ     6nx 8         xy/2Nc, x/ Nc, y/2nc, tile/ nc   (96*N, 48*N, 16*n, 8*n)
// 5. VERT      6 xn8         xy/2Nc, x/2nc, y/1Nc, tile/ nc   (16*N, 16*n,  8*N, 8*n)
//
// If you have two sets of lines, any interleaving is possible,
// you can have two sets of sprites (ALPHABETIC, ALTERNATIVE)

// xyPLAYER(1)  - 1 sprite move independently XY                            =  20c, 906B
// xyPLAYER(4)  - 4 sprites jiggles in xy sync, but 4 different XY positions=  20c, 906B
// xyBALL(1)    - 1 sprite move independently XY                            =  12c, 576B
// xyMISSILE(4) - 4 sprites perfectly independently movable                 = 4*9c, 432B
//  yVERT(8,16) - 16 sprite sync strep char, bug 16 xy pos                  =   8c,   8B
//
// (+ 20 20 12 (* 4 9) 8) = 96 maxed out!

// - PLAYER (max 2? 3?)
//
//     AEIM|Q
//     BFJN|R
//     CGKO|S     w: 4,  h: 3 == 4*6 x 3*8 = 24 x 24 px
//     ----+-
//     DHLP|T
//
// xySprite24x24 (width 4 chars, height 3 chars) uses 5x4= 20 chars
// x Sprite24x24                                      5x3= 15 chars
//  ySprite24x24                                      4x4= 16 chars

//
//
//     ADG|J
//     BEH|K      w: 3,  h: 2 == 3*6 x 2*8 = 18 x 16 px
//     ---+-
//     CFI|L
//
// xySprite18x16 (width 3 chars, height 2 chars) - uses 4*3= 12 chars
// x Sprite18x16                                   uses 4*2=  8 chars
//  ySprite18x16                                   uses 3*3=  9 chars 
//   Sprite18x16                                   uses 3*2=  6 chars

#include <string.h>
#include <assert.h>

#include "conio-raw.c"

long sp32Hi[]= {
  //0123456789abcdef0123456789abcdef
  //  123456123456123456123456123456
  0b11111111111111111111111111111111,
  0b10000000000000000000000000000001,
  0b10001000000010000000000000000001,
  0b10001000000010000000000000000001,
  0b10001000000010000000000000000001,
  0b10001111111110000000001000000001,
  0b10001000000010000000001000000001,
  0b10001000000010000000001000000001,
  0b10001000000010000000001000000001,
  0b10001000000010000000001000000001,
  0b10000000000000000000001000000001,
  0b10000000000000000000001000000001,
  0b10000000000000000000001000000001,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b11111111111111111111111111111111,
};

// sprite 16 x 18 pixels (padding right+bottom)
// 96 bytes! 3*4= 12 chars
char sp6[]= { /* heigth */ 3, /* widthbytes */ 4,
              /* keep pointers to shifted variants? */
  0b00111111, 0b00111111, 0b00111111,  0b00000000,
  0b00100000, 0b00000000, 0b00000001,  0b00000000,
  0b00100010, 0b00000000, 0b00000001,  0b00000000,
  0b00100001, 0b00000000, 0b00000001,  0b00000000,

  0b00100000, 0b00100000, 0b00000001,  0b00000000,
  0b00100000, 0b00010000, 0b00000001,  0b00000000,
  0b00100000, 0b00001000, 0b00000001,  0b00000000,
  0b00100000, 0b00000100, 0b00000001,  0b00000000,


  0b00100000, 0b00000010, 0b00000001,  0b00000000,
  0b00100000, 0b00000001, 0b00000001,  0b00000000,
  0b00100000, 0b00000000, 0b00100001,  0b00000000,
  0b00100000, 0b00000000, 0b00010001,  0b00000000,

  0b00100000, 0b00000000, 0b00001001,  0b00000000,
  0b00100000, 0b00000000, 0b00000101,  0b00000000,
  0b00100000, 0b00000000, 0b00000001,  0b00000000,
  0b00111111, 0b00111111, 0b00111111,  0b00000000,


  0b00000000, 0b00000000, 0b00000000,  0b00000000,
  0b00000000, 0b00000000, 0b00000000,  0b00000000,
  0b00000000, 0b00000000, 0b00000000,  0b00000000,
  0b00000000, 0b00000000, 0b00000000,  0b00000000,

  0b00000000, 0b00000000, 0b00000000,  0b00000000,
  0b00000000, 0b00000000, 0b00000000,  0b00000000,
  0b00000000, 0b00000000, 0b00000000,  0b00000000,
  0b00000000, 0b00000000, 0b00000000,  0b00000000,
};

char* byteblit(char h, char w, char* b) {
  char *p; 
  if (!b) b= malloc(2+h*w); assert(b);
  p= b; *p= h; *++p= w;
  do {
    memcpy(p, SCREENXY(curx, cury), w);
    p+= w;
  } while (--h);
  return b;
}

// Layout as sprite
// 
// A

// Layout of chars, slack space so can scroll
// down and right!
//
// w: 3*6 y: 2*8 => (18x16)
//
// ADGJ  XXX|
// BEHK  XXX|
// CFIL  ---+

// scrolling down/up use memcpy! (limit 8 down)

// XYSprite18x16: 3 chars by 2 lines
//
// Writes the sprite in row-column, last column+row empty
// into the chardef of BASE characters from SPRITE definition.
// 
// It ueses (3+1)*(2+1)= 4*3= 12 chars
void spritedef(char base, char* sprite) {
  char *d= CHARDEF(base);
  char *s= sprite;
  char h= *s++, w= *s++;
  char r,c,i, *x;

  // Parsing:
  // sp6 style byte layout:
  // - easy to do chardef
  for(c=0; c<w; ++c) {
    x= s;
    for(r=0; r<h; ++r) {
      // copy one char
      for(i=0; i<8; ++i) {
        *d++ = *x; x+= w;
      }
      // step down to next char-row
    }
    ++s; // next column
  }
}

void spritedefABC(char base, char* sprite) {
  char *d= CHARDEF(base);
  char *s= sprite;
  char h= *s++, w= *s++;
  char r,c,i, *x;

  // Parsing:
  // sp6 style byte layout:
  // - easy to do chardef
  for(r=0; r<h; ++r) {
    x= s;
    for(c=0; c<w; ++c) {
      // copy one char
      for(i=0; i<8; ++i) {
        *d++ = *x; x+= w;
      }
      x= ++s; // step next char
    }
    s+= -w + w*8; // step down
  }
}

// taking 8x6 char sprite def sp6
void scrollspriteright(char* sprite) {
  char *s= sprite;
  char h= *s++, w= *s++, r;
  unsigned long l,tl;
  char *cl= (char*)&l; // overlaps l
  
  // only works for this shape...
  assert(w==4);

  for(r=0; r<h*8; ++r) {
    // make long from 4 char scan line
    cl[0]= s[3];
    cl[1]= s[2];
    cl[2]= s[1];
    cl[3]= s[0];

    // shift right
    l >>= 1;

    // recover hibit of each cell
    tl = l & 0x80808080;
    tl >>= 2; // move to 6th bit!
    l |= tl;
    l &= 0x3f3f3f3f; // remove 2 highest

    // write it back
    s[0]= cl[3];
    s[1]= cl[2];
    s[2]= cl[1];
    s[3]= cl[0];

    // next
    s+= 4;
  }
}

void scrollspritecharsright(char base, char* sprite) {
  char *d= CHARDEF(base);
  char *s= sprite;
  char h= *s++, w= *s++, r;
  unsigned long l,tl;
  char *cl= (char*)&l; // overlaps l
  char o= h*8;
  
  // only works for this shape...
  assert(w==4);

  for(r=0; r<h*8; ++r) {
    // make long from 4 char scan line
    cl[0]= d[3*o];
    cl[1]= d[2*o];
    cl[2]= d[1*o];
    cl[3]= d[0*o];

    // shift right
    l >>= 1;

    // recover hibit of each cell
    tl = l & 0x80808080;
    tl >>= 2; // move to 6th bit!
    l |= tl;
    l &= 0x3f3f3f3f; // remove 2 highest

    // write it back
    d[3*o]= cl[0];
    d[2*o]= cl[1];
    d[1*o]= cl[2];
    d[0*o]= cl[3];

    // next scanline
    ++d;
  }
}

// taking 8x6 char sprite def sp6
void scrollspritecharsdown(char base, char* sprite) {
  char *d= CHARDEF(base);
  char *s= sprite;
  char h= *s++, w= *s++;

  memmove(d+1, d, h*8*w-1);
  *d= 0;
}
void scrollspritecharsup(char base, char* sprite) {
  char *d= CHARDEF(base);
  char *s= sprite;
  char h= *s++, w= *s++;

  memmove(d, d+1, h*8*w-1);
}

// Dummys for ./r script
int T,nil,doapply1,print;

char* A= SAVE "ADGJ" NEXT "BEHK" NEXT "CFIL";
//char* A= SAVE "ABCD" NEXT "EFGH" NEXT "IJKL";

char spx,spy,sdx=0,sdy= 0;

char* savedA= NULL;

// interpret sprite movement, save each "print" char
// TODO: replace by MOVE! lol
void save(char** savep, char* sprite) {
  char *p;
  if (!*savep) *savep= calloc(strlen(sprite)+(1+(4+2+2)), 1);
  p= *savep;
  memset(p, 0, strlen(sprite)+(1+(4+2+2)));
  
  // save location so it's self-printable!
  p+= sprintf(p, "\x1b[%d;%dH", wherex(), wherey());

  // specialized interpreter for SAVE/RESTORE/DOWN/print!
 next:
  *p= *sprite;
  switch(*sprite) {
  case 0x00: return;
  case 0x1d:  // SAVE
  case 0x1e:  // RESTORE
  case KEY_DOWN: // DOWN
    // TODO: more codes?
    putchar(*sprite); break;
  default: *p= *cursc; ++cursc; ++curx; break; // save char!
  }
  ++sprite; ++p;
  goto next;
}

void redraw() {
  // restore
  puts(savedA);

  // draw new (save first)
  // TODO: combine?
  // TODO: shadow update in virtual screen?
  gotoxy(spx, spy);
  save(&savedA, A);

  // TODO: redef char here?

  gotoxy(spx, spy);
  puts(A);

  // TODO: use byteblit();
}

void main() {
  char i;

  clrscr();

  // Show charset
  { char j=32;

    gotoxy(1,1); puts("CHR: ");
    for(;j<128;++j) putchar(j);
    putchar('\n');
    gotoxy(0,1); puts("ALT:" ALTCHARS);
    for(;j<128;++j) {
        if (wherex()%40==0) puts(ALTCHARS);
        putchar(j);
    }
  }
  putchar('\n');
  { char r, c;
    for(r=3; r<25; ++r) {
      for(c=0; c<=39; c+=2) {
        putchar(96+c/2);
        putchar(96+c/2);
      }
    }
  }
    

  spritedef('A', sp6);

  { char i;
    for(i=0; i<25; ++i) {
      gotoxy(i-1,i); putchar('z');
      printf(KESC "[%d;%dH\\(%d,%d)", i,i,i,i);
    }
  }

  // init sprite
  spx=5; spy=12;
  save(&savedA, A);
  redraw();

  // move sprite w cursor keys
  while(1) {
    switch(cgetc()) {
    case 'r':
      spritedef('A', sp6);
      break;
    case KEY_RIGHT:
      if (6 == ++sdx) {sdx=0;
        ++spx;
        //clrscr();
        spritedef('A', sp6);
        redraw();
      } else {
        scrollspritecharsright('A', sp6);
      }
      break;
    // these are so fast that we put wait...
    case KEY_DOWN :
      if (8 == ++sdy) {sdy=0;
        ++spy;
        //clrscr();
        spritedef('A', sp6);
        redraw();
      } else {
        scrollspritecharsdown('A', sp6);
        wait(2);
      }
      break;
    case KEY_UP :
      if (0 == sdy--) {sdy=7;
        --spy;
        //clrscr();
        spritedef('A', sp6);
        // TODO: make one
        for(i=8;--i;)scrollspritecharsdown('A', sp6);
        redraw();
      } else {
        scrollspritecharsup('A', sp6);
        wait(2);
      }
      break;
    }
  }
}
