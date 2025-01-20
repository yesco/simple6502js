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

char parseDev(char* p) {
  if (p<256) return (char)(int)p;
  if (p>=HIRESSCREEN && p<HIRESCREEN+HIRESSIZE)  return HIRESMODE;
  if (p>=TEXTSCREEN  && p<TEXTSCREEN+SCREENSIZE) return TEXTMODE;
  // Depending on screenmode? Hmmm...
  if (p>=CHARSET     && p<CHARSET+128*8)         return 42;
  if (p>=ALTSET      && p<ALTSET+80*8)           return 43; // TODO: 80?
  // 
  return *p;
}

char* bltaddr(char* p, char x, char y, char dev) {
  return (x==0 && y==0)? p:
    (y*5)*8 + x +
    (dev==HIRESMODE? HIRESSCREEN:
     dev==TEXTMODE ? TEXTSCREEN: p);
}
    
void BitBlt(char op,
            char* dest, char mod,
              char x,     char y, // if x,y==0,0 then dest used
              char w,     char h, // if w,h==0,0 assume all?
            char* from, char mod,
              char fx,    char fy // if fx,fy==0,0 then from used
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
        while(h--) memcpy(dest+=40, from+=40, w);
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
    char * tmp= malloc((w+1)*h), * p;
    char dm= mod6[x], fm= mod6[fx], wm= mod6[w];
    char dgw= (dm?1:0)+div6[dm+w+5], fgw= (fm?1:0)+div6[fm+w+5]; // ?
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
    p= tmp;
    i= h; while(i--) { shiftrow <<fm bits???}

    // TODO: do bitshifting using dm
    p= tmp;
    i= h; while(i--) { shiftrow >>dm bits???}

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
