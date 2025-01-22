// HIres SPRITE
//
// ORIC ATMOS C-implementation of HIRES screen pixel
// sprites.
//
// (c) 2024 Jonas S Karlsson

// For sprites we esentially implement a number of 
// BITBLT methods:
//
// - LongBlit2Cell
// - CellBlit2Long (TODO?)
// - ByteBLit (TODO?)
// - CellBlit (pixel positions)
// - ClrCellBlit
//
// op: 0=clear 1=set 2=xor 3="movecursor" 4=and 5=or 6=mirror 7=copy
//     |128= stretch (how to specify?)


// Microsoft: Bitblt(destdevice, x, y, w, h, fromdevice, fromx, fromy, op)
//   op: 0=clear 1=set 2=xor 4=and 5=or 6=mirror 7=copy 8=
//   MaskBlt, PlgBlt, StretchBlt


#include <stdio.h>

#define MAIN
#include "hires-raw.c"

// Dummys for ./r script
int T,nil,doapply1,print;


// LONGBLT
unsigned long spHi[]= { /* height */ 32, /* Lwidth*/ 1,
  //0123456789abcdef0123456789abcdef
  //  123456123456123456123456123456
  0b11111111111111111111111111111111,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,

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
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,

  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b10000000000000000000000000000001,
  0b11111111111111111111111111111111,
};

// BYTEBLT
char sprite[]= { /* heigth */ 16, /* widthbytes */ 4,
  0b11111111, 0b11111111, 0b11111111, 0b11111111,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b10000000, 0b00000000, 0000000000, 0b00000001,
  0b11111111, 0b11111111, 0b11111111, 0b11111111,
};

// CELLBLT
char sp6[]= { /* heigth */ 24, /* widthbytes */ 4,
  0b00111111, 0b00111111, 0b00111111, 0b00111111,
  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,

  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,


  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,

  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,

  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,

  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,


  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,

  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00100000, 0b00000000, 0000000000, 0b00000001,
  0b00111111, 0b00111111, 0b00111111, 0b00111111,
};

// LongBlit2Cell
//
// Any way of making this more efficient/faster?

// TODO: idea, it could write and restore background
// stream of bytes, just play back next time.
void LongBlit2Cell(unsigned long* sp) {
  char h= *sp, w= *++sp, r, c, i;
  unsigned long l;

  unsigned t= time();
  // last pixel pos in x
  // 
  // gcurx=0 32 bits -> bi= 2
  //   1-----------------------------32
  //   012345 6789ab cdef01 234567 89abcdef
  //   012345 012345 012345 012345 01234512
  //                            bm=  000011
  char x= gcurx + w*32-1;
  char *sc= HIRESSCREEN + (gcury*5)*8 + div6[gcurx+1];
  char bi= mod6[x]+1;        
  char bm= PIXMASK[6-bi]*2-1; // extract mask

//  char bm= PIXMASK[(6-bi)%6]*2-1;

  char bits, mask;

  r= h;
  do {
    c= w;
    do {
      l = *++sp;

      // first is disaligned, take bi bits
      i= (bi==0)? 6: 7; // cells+1
      sc[--i]= (l & bm)<<(6-bi) | 64;
      l >>= bi;

      // take cell groups of 6 bits
      while(--i) {
        sc[i]= (l & 63) | 64;
        //l >>= 6;
        l= shift6(l);
      }

      // next row
      sc+= 40;

    } while(--c);
  } while(--r);

  gotoxy(0,25);
  printf("%uhs (%d,%d) x=%d bi=%d bm=%02x\n", t-time(), gcurx, gcury, x, bi, bm);
}

void CellBlit(char* p) {
  char h= p[0], w= p[1], r= h, c;
  char *s= HIRESSCREEN + (gcury*5)*8 + div6[gcurx];
  char m= mod6[gcurx];

  ++p;
  for(r= 0; r<h; ++r) {
    for(c= 0; c<w; ++c) {
      s[c]= *++p;
    }
    s+= 40;
  }
}

void ClrCellBlit(char* p) {
  char h= p[0], w= p[1], r= h, c;
  char *s= HIRESSCREEN + (gcury*5)*8 + div6[gcurx];
  char m= mod6[gcurx];

  ++p;
  for(r= 0; r<h; ++r) {
    for(c= 0; c<w; ++c) {
      s[c]= 64;
    }
    s+= 40;
  }
}

#define BBCLEAR   0
#define BBSET     1
#define BBXOR     2
#define BBNOP     3

#define BBCOPY    4
#define BBAND     5
#define BBOR      6
#define BBMIRROR  7
#define BBSTRETCH 8 // TODO: (need params, how?)

typedef struct BitMap {
  char type;
  char mod6; // if set, then it's not aligned (first mod6 bit uesless)
  char rowbytes; // should be 1 byte more than needed by width pixels
  unsigned int width;
  unsigend int height;
  // need extra pointer, or this needs to be put before HIRES/LORES screens, lol
  // otherwise this would basically STEAL the last ALTCHARSET character definition...
  char bits[];
} BitMap;

// possible types?
// - HIRESSCREEN-1 (means full copy)
// - TEXTSCREEN-1  (means full copy)
// - 

BitMap* mkBitMap(char type, int w, int h) {
  char rowsbytes= (w+(6+5))/6; // always one more, allow non-aligned
  BitMap* r= calloc( * h + sizeof(BitMap), 1);
  r->type= type; r->width= w; r->height= h; r->rowbytes= rowbytes;
 of ALT  return r;
}

BitMap hiresBitMap  { 42, 0, 40, 240, 200}; // can we store it before HIRES? lol
BitMap screenBitMap { 42, 0, 40, 240, 200}; // can we store it before LORES? lol

char parseDev(char* p) {
  if (p<256) return 42; // charset, address varies
  if (p>=HIRESSCREEN && p<HIRESCREEN+HIRESSIZE)  return HIRESMODE;
  if (p>=TEXTSCREEN  && p<TEXTSCREEN+SCREENSIZE) return TEXTMODE;
  // TODO: hmmm?
  return *p;
}

char* bltaddr(char* p, char x, char y, char dev) {
  return dev==42? x*8 + (dev==HIRESMODE? HIRESCHARSET: CHARSET):
    (x==0 && y==0)? p:
      (y*5)*8 + x +
      (dev==HIRESMODE? HIRESSCREEN:
       dev==TEXTMODE ? TEXTSCREEN: p);
}
    
// BITBLT OPS
//
// Copy
//  '='         = copy bits/bytes

// Set/unset
//  1 0 '1' '0' = set all bits 1 or 0

// Inverse ops:
//  128 '7'     = set inverse bit    (1)
//  i           = invert inverse bit (^)
//  r           = revert inverse bit (0)

// Logical ops:
//  '&'         = and
//  '|'         = or
//  '^'         = xor
//  '~'         = reverse bits
//  '-'         = subtract bits ("undraw")

// Exchange
//  'x'         = exchange two areas values


void memop(char op, char* d, char* f, char len) {
  // copy
  // TODO: |64 ? or at least for charset
  char fwdest= 40; // TODO: set for real...
  if (op=='=') { memmove(d, f, len); return; }
  else {
    // TODO: is forward direction safe?
    --d; --f; ++len;
    switch(op) {

    // fixed values
    case 0:
    case '0': while(--len) { *++d = 64; } return;
    case 1: case 64:
    case '1': while(--len) { *++d = 64+63; } return;

    // inverting
    case 128: while(--len) { *++d |= 128; } return;
    case 'i': while(--len) { *++d ^= 128; } return;
    case 'r': while(--len) { *++d &= 127; } return;

    // logical ops
    // TODO: what it does with attributes? undefined?
    case '&': while(--len) { *++d &= ++f; } return;
    case '|': while(--len) { *++d |= *++f; } return;
    case '^': while(--len) { ++d; *d = (*d ^ *++f)|64; } return;
    case '~': while(--len) { ++d; *d = ((~*d)&63)|64; } return;
    case '-': while(--len) { *++d &= (~*++f)|64; } return;

    // Exchange:
    case 'x': while(--len) { op= *++f; *f = *++d; *d= op; } return;

    // Plot Char/Text using default text font
    case 't': { char *p, r, c, *def;
        while(--len) {
          c= ((int)(f)&0xff00)? *f++: (char)(int)f; // stringptr or char
          def= c*8 + (HIRESCHARSET-1);
          p= ++d-fwdest; r= 8;
          do {
            *(p+=40)= *++def;
          } while(--r);
        } } break;

    case 'T': // plot using proportional font
  }
  // TODO: edgecases of part bytes, before and after depend modm
  // TODO: outside?
  // pike: d= (s^m)|(d^~m)
  // pike: d= (s^d)&m
}

void BitBlt(char op,
            char* dest, char mod,
              int x,    int y, // if x,y==0,0 then dest used
              char w,   char h, // if w,h==0,0 assume all?
            char* from, char mod,
              int fx,   int fy // if fx,fy==0,0 then from used
) {
  // TODO: more ops!
  assert(op==BBCOPY);
  
  char dd= parseDev(dest);
  char sd= parseDev(from);

  // Same-Same

  if (dd==sd) {
    switch(dd) {

    case HIRESMODE:
      if (x) goto notsame;
      x= div6[x];
      // fallthrough: x is now "columns"

    case TEXTMODE: {
      // TODO: screencopy(): it's been suggested a memcpy w strides? (40)
      dest= bltaddr(dest, x,  y,  dd);
      from= bltaddr(from, fx, fy, dd);
      if (dest<from) { // copy up
        while(h--) memop(op, dest+=40, from+=40, w);
        return;
      } else { // copy down
        int x= (5*(h+2))*8; dest+= x; from++ x;
        while(h--) if memcpy(dest-= 40, from-=40);
      } } return;

    default: // generic pointer, pointer
      memmove(dest, from, (y*5)*8++w); return;
    }
    return;
  }

  // -- All other combinations
  // (these may need format conversions, and easy way is to
  //  convert to intermediary format..... CELL???)
  
  // TODO: specific optimized cases

 notsame:
  {
    
  }
  // generic inbetween formats
  {
    char * tmp= malloc((w+1)*h), * p;
    char dm= mod6[x], fm= mod6[fx], wm= mod6[w];
    char dgw= div6[dm+w+5]+1, fgw= div6[fm+w+5]+1; // ?
    char i;

    p= tmp;
    switch(fd) {
    case HIRESMODE:
      fx= div6[x];
    case TEXTMODE:
      p-= fgw;
      from= bltaddr(from, fx, fy, fd)-40;
      i= h; while(i--) memcpy(p+= fgw, from+=40, fgw);
      break;
    }

    // TODO: do bitshifting using fm
    //p= tmp;
    //i= h; while(i--) { shiftrow <<fm bits???}

    // TODO: do bitshifting using dm
    //p= tmp;
    //i= h; while(i--) { shiftrow >>dm bits???}

    // TODO: can't use fm-dm??? hmmmm.

    // tmp/p may still have one extra byte...
    
    p= tmp;
    switch(dd) {
    case HIRESMODE:
      x= div6[x];
    case TEXTMODE:
      p-= dgw;
      dest= bltaddr(dest, x, y, dd)-40;
      i= h; while(h--) memcpy(dest+=40, p+= dgw, dgw);
    }
    
    free(tmp);
  }
}

void main() {
  long W= 100, w;

  hires();

  // draw sprite()
  gcurx= 10; gcury= 100; LongBlit2Cell(spHi);
  gcurx= 0;  gcury=  50; LongBlit2Cell(spHi);

  // move it around using keys
  gcurx= 0;  gcury= 0;
  while(1) {
    // TODO: undraw...
    drawsprite(spHi);
    switch(cgetc()) {
    case KEY_UP    : --gcury; break;
    case KEY_DOWN  : ++gcury; break;
    case KEY_RIGHT : ++gcurx; break;
    case KEY_LEFT  : --gcurx; break;
    }
  }

  // move it on "schedule"
  while(1) {
    gcury= 150;
    for(gcurx= 50; gcurx<200; gcurx+= 6) {
      --gcury; drawsprite62(sp6);
      ++gcury; gcurx-= 6; drawsprite62(sp6);
      --gcury; gcurx+= 6;
      wait(100);
    }
    for(; gcurx>=50; gcurx-= 6) {
      gcury= 150; drawsprite62(sp6);
      wait(50);
    }
  }
}
