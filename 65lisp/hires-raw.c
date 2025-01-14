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
#include <assert.h>

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

// TODO:
// void gfill(r, c, h, w, v);
// void circle(x, y, r, v);
// void line(x, y, xt, ty);
// void draw(w, h);
// void filledbox(w, h);
// void curset(x, y, v);
// char curget(x, y);

extern char curmode; // defined in conio-raw.c

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
    curmode= SCREENEND[-1]= *HIRESSCREEN= TEXTMODE;
  }

  { char v, * p= HIRESSCREEN;
    while(p<HIRESEND) {
      v= *p;
      if (v==HIRESMODE || v==HIRESMODE+1 ||
          v==HIRESMODE+128 || v==HIRESMODE+1+128) 
        v= *p = TEXTMODE;
      ++p;
    }
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

// TODO: no effect on draw long line...
//   however on many curset?
char div6[240], mod6[240];
char mask6[240];
char* rowaddr[200];

char shift6lo[256], shift6hi[256];
#define SHIFT6(x) ((unsigned long)(shift6lo[(x) & 0xff] || shift6hi[((x)>>8) & 0xff]))

unsigned long shift6(unsigned long l) {
  char* b= (char*)l;
  // return l>>6; slow
  unsigned long r;
  r= SHIFT6(b[0]);
  r+= SHIFT6(b[1])<<8;
  r+= SHIFT6(b[2])<<16;
  r+= SHIFT6(b[2])<<24;
  return r;
}

//    char q= div6[x]; // no time saving!?
//    char mi= mod6[x]; // nah


// TODO: rename
static char gcurx, gcury, gmode;

// TODO: remove?
static char curq, curm, *curp;

// light-wedith function, call by setting
//   (gcurx, gcury, gmode)
void setpixel() {
  if (gmode==2) { 
    // 84hs to use rowaddr[] - 30% faster
    // *(rowaddr[gcury] + div6[gcurx]) ^= PIXMASK[mod6[gcurx]];
    // 99hs - 10% faster than else
    *(HIRESSCREEN+ (5*gcury)*8 + div6[gcurx])
      ^= PIXMASK[mod6[gcurx]];
  } else { // 109hs
    // 305hs - just slightly faster than BASIC!
    // curq= gcurx/6;
    // curp= HIRESSCREEN+ (5*gcury)*8 + curq;
    // curm= PIXMASK[gcurx-curq*6];
    curp= HIRESSCREEN+ (5*gcury)*8 + div6[gcurx];
    curm= PIXMASK[mod6[gcurx]];
    switch(gmode) {
    case 0: *curp &= ~curm; break;
    case 1: *curp |= curm;  break;
    case 2: *curp ^= curm;  break;
    }
  }
}

// probably uses less code than call!
#define GXY(x,y) do {gcurx= (x); gcury= (y); } while (0)
#define CURSET(x,y,v) do { GXY(x, y); gmode= (v); setpixel(); } while (0)

char point(char x, char y) {
  gcurx= x; gcury= y; gmode= 3; setpixel();
  return *curp & curm;
}


// draw(dx, dy, v)

//#define draw(dx,dy,v) drawSimple(dx,dy,v)
#define draw(dx,dy,v) drawFast(dx,dy,v)

// Dammnit - this displays crap and out of bounds?
// so simple, what is going wrong?
void drawSimple(int dx, int dy, char v) {
  char i,x,y;

  char adx= dx<0?-dx:dx;
  char ady= dy<0?-dy:dy;

  gmode= v;

  if (adx>ady) {
    if (dx<0) { gcurx+=dx; dx=-dx; gcury+=dy; dy=-dy; }
    x= gcurx+dx+1;
    y= gcury;
    for(i= dx+1; --i;) {
      gcury= y+i*ady/adx; gcurx= --x;
      if (gcurx>=240 || gcury>=200)
      printf("x=%d y=%d dx=%d dy=%d i=%d\n", gcurx, gcury, dx, dy, i);
      assert(gcurx<240);
      assert(gcury<200);
      //*(HIRESSCREEN+ (5*gcury)*8 + div6[gcurx])
      //^= PIXMASK[mod6[gcurx]];
      setpixel();
    }
  } else {
    if (dy<0) { gcurx+=dx; dx=-dx; gcury+=dy; dy=-dy; }
    x= gcurx;
    y= gcury+dy+1;
    for(i= dy+1; --i;) {
      gcurx= x+i*adx/ady; gcury= --y;
      if (gcurx>=240 || gcury>=200)
      printf("x=%d y=%d dx=%d dy=%d i=%d\n", gcurx, gcury, dx, dy, i);
      assert(gcurx<240);
      assert(gcury<200);
      //*(HIRESSCREEN+ (5*gcury)*8 + div6[gcurx])
      //^= PIXMASK[mod6[gcurx]];
      setpixel();
    }
  }
}

// optimizations, 10x draw line
// 112hs ORIC BASIC    we are 50% faster than BASIC
// 938hs plain
// 892hs PIXMASK -5.16%         (curset)
// 842hs (5*y)*8 -5.94%         (curset)
// 708hs q=x/6  -18.9%          (curset)
// 672hs static q,m,*p -3.81%   (curset)
// 632hs inline curset -6.33%   
// 618hs static yy -2.3%
// 569hs move mod lookup out, mi loop, -8.6%
// 560hs shift static m -1.6%
// 390hs remove q/6 from loop -43.6%
// 313hs remove mult from dy*i -24.6%
// 113hs remove /6 from loop -77%q
//  72hs not calculate p -57%  13x imprve,
//
//    (/ 112 72.0) = 55% faster than ORIC

// TODO: works, but can we have smaller code?
//   some bug manifested only in 1) LineBench?
//
// gcurx,gcury changed after
void drawFast(int dx, int dy, char v) {
  register char* p;
  register char s, m, adx, ady;
  char i;

  adx= dx>=0? dx: -dx;
  ady= dy>=0? dy: -dy;

  gmode= v;

  if (adx>ady) {
    if (dx<0) { gcurx+= dx; dx= -dx; gcury+= dy; dy= -dy; }
    gcury+= dy;
    gcurx+= dx;
    {
      // inline curset
      // TODO: too much duplication - make macro!
      char q= gcurx/6;
      char mi= gcurx-q*6;

      i= adx+1;
      m= PIXMASK[mi];
      s= 0;
      p= HIRESSCREEN+40*gcury+q;

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
        switch(gmode) { // about 10% overhead
        case 0: *p &= ~m; break;
        case 1: *p |= m;  break;
        case 2: *p ^= m;  break;
        }

        // step x, wrap around bit
        if ((m<<=1)==64) m=1,--p;
      }
    }
  } else { // dy >= dx
    if (dy<0) { gcurx+= dx; dx= -dx; gcury+= dy; dy= -dy; }
    gcury+= dy;
    gcurx+= dx;
    {
      // inline curset
      // TODO: too much duplication - make macro!
      char q= gcurx/6;
      char mi= gcurx-q*6;
      i= ady+1;
      m= PIXMASK[mi];
      s= 0;
      p= HIRESSCREEN+(5*gcury)*8+q;

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

        // TODO: simple function w globals?
        // plot it
        switch(gmode) { // about 10% overhead
        case 0: *p &= ~m; break;
        case 1: *p |= m;  break;
        case 2: *p ^= m;  break;
        }

        // step y
        p-= 40;
        if (p<HIRESSCREEN) break;
      }
    }
  }
}

// https://en.m.wikipedia.org/wiki/Midpoint_circle_algorithm
//
// Surprising little and simple code to draw circle!
void circle(char r, char v) {
  // TODO: try use register vars!
  static int  rr, e;
  static char x,y, dx,dy;

  gmode= v;
  x= gcurx, y= gcury;

  // Algorithm
  rr= r/16;
  dx= r;
  dy= 0;

  do {
    ++dy;
    rr+= dy;
    e=rr-dx;
    if (e>=0) {
      rr= e;
      --dx;
    }

    // TODO: out-of-bounds?

    // set 8 symmetries
#define setpixel() *(rowaddr[gcury] + div6[gcurx]) ^= mask6[gcurx]
    gcurx= x+dx; gcury= y+dy; setpixel();
    gcurx= x-dx;              setpixel();
                 gcury= y-dy; setpixel();
    gcurx= x+dx;              setpixel();
    
    gcurx= x+dy; gcury= y+dx; setpixel();
    gcurx= x-dy;              setpixel();
                 gcury= y-dx; setpixel();
    gcurx= x+dy;              setpixel();
#undef setpixel()
                 
  } while (dx>dy);
}

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

// bitblt?
//
// Any way of making this more efficient/faster?

// TODO: idea, it could write a restore background
// stream of bytes, just play back next time.
void drawsprite(unsigned long* sp) {
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

  printf("%uhs (%d,%d) x=%d bi=%d bm=%02x\n", t-time(), gcurx, gcury, x, bi, bm);
}

void drawsprite62(char* p) {
  char h= p[0], w= p[1], r= h, c;
  char *s= HIRESSCREEN + (gcury*5)*8 + div6[gcurx];
  char m= mod6[gcurx];

  ++p;
  for(r= 0; r<h; ++r) {
    for(c= 0; c<w; ++c) {
      s[c]^= *++p;
    }
    s+= 40;
  }
}

void clearsprite62(char* p) {
  char h= p[0], w= p[1], r= h, c;
  char *s= HIRESSCREEN + (gcury*5)*8 + div6[gcurx];
  char m= mod6[gcurx];

  ++p;
  for(r= 0; r<h; ++r) {
    for(c= 0; c<w; ++c) {
      s[c]^= 64;
    }
    s+= 40;
  }
}

char sc[SCREENSIZE], *scend= sc+SCREENSIZE;

void zoom() {
  register char *p, *xx;
  static char *t,*s;
  static char v, i, inv, c, tc;

  p= s= HIRESSCREEN + (gcury*5)*8 + div6[gcurx];
  c= 0; tc= 0;

  xx= t= sc;
  while(1) {

    // get next cell
  nextline:
    v= *p;

    // TODO: inefficient?
    if (xx+6 > scend) break;

    if ( (v & 0x7f) < 32) {
      // attribute

      // remove graphics aa
      if ( (v & 0x7e) == HIRESMODE )
        v= *p = TEXTMODE;

      for(i=7; --i; ) {
        *xx= v; ++xx;
        if (++tc==41) { tc=0; p= s+= 40;
          xx= t+= 40;
          goto nextline; }
      }
    } else {
      // 6 bits
      //inv= v & 128; ????
      for(i=7; --i; ) {
        //*cursc= ( v&1? 0x1f: ' ') | inv;
        //*cursc= v&1? inv+32: 32;
        *xx= v&32? 128+' ': ' ';
        v <<= 1; ++xx;
        if (++tc==41) { tc=0; p= s+= 40;
          xx= t+= 40;
          goto nextline; }
      }
    }

    ++p;
  }

  // flicker-free!
  memcpy(TEXTSCREEN, sc, SCREENSIZE);
}

/////////////////////////////////////////////////////////////
// testing

// Dummys for ./r script
int T,nil,doapply1,print;

#define COMPRESS_PROGRESS

#include "compress.c"

void hirescompress() {
  char* saved;
  Compressed* zip;
  int len;
  unsigned C;

  gotoxy(0,25); printf("COMPRESzING...");
  //saved= malloc(HIRESSIZE);
  //assert(saved);
  //memcpy(saved, HIRESSCREEN, HIRESSIZE);
  C= time();
  asm("CLI");
  zip= compress(HIRESSCREEN, HIRESSIZE); // strlen?  lol, fix it!
  assert(zip);
  C= C-time();
  len= zip->len;
  gotoxy(0,25); printf("DONE COMPRESS! => %d    <", len);
  gotoxy(0,26); printf("Comprez: %3d%% %4d/%4d      ", (int)(len*10050L/HIRESSIZE/100), len, HIRESSIZE);

  while((char)kbhit()!=CTRL+'C') {
    int i;
    unsigned int T;
    asm("CLI");
    T= time();
    decompress(zip, HIRESSCREEN);
    //i= strprefix(HIRESSCREEN, saved);
    //if (i<=0) { gotoxy(10, 27); printf("  DIFFER AT POSITION: %d  ", i); }
    gotoxy(0,27); printf("Z=%u hs DZ=%u hs         ", C, T-time());
    wait(50);
    gclear();
  }
}

void main() {
  char* p= HIRESSCREEN;
  int i,j;
  unsigned int t;

  // init lookup table
  for(j=0; j<240; ++j) {
    div6[j]= j/6;
    mod6[j]= j%6;
    mask6[j]= PIXMASK[mod6[j]];
    rowaddr[j]= HIRESSCREEN + 40*j;
  }

  for(j=0; j<256; ++j) {
    shift6lo[j]= j>>6;
    shift6hi[j]= (j>>2) & 0xfd;
  }

  //for(j=300; j; --j) printf("FOOBAR   ");

  hires();
  gclear();
  gfill(60, 15, 10*6, 10, 64+63);

  gclear();
  // turn off, cursor keeps inverting random bit on text screen!
  asm("SEI"); 

  gotoxy(10, 25); printf("Start...");
  t= time();

  switch(11) {

  case 11:
    // compress clear screen
    break;

  case 1: {
    // WTF does my code do? lol
    char i;
    printf("LineBench-3. hires-raw.c Jonas\n");
    for (i=0; i<239; ++i) {
      //GXY(i, 0); draw(239-i-i, 199, 2);
      GXY(239-i, 199); draw(i+i-239, -199, 2);
    }
    for (i=0; i<199; ++i) {
      GXY(0, i); draw(239, 199-i-i, 2);
    } } break;

  case 2: {
    long W= 100, w;

    // draw sprite()
    gcurx= 10; gcury= 100; drawsprite(spHi);
    gcurx= 0;  gcury=  50; drawsprite(spHi);

    
    gcurx= 0;  gcury= 0;
    while(1) {
      drawsprite(spHi);
      switch(cgetc()) {
      case KEY_UP    : --gcury; break;
      case KEY_DOWN  : ++gcury; break;
      case KEY_RIGHT : ++gcurx; break;
      case KEY_LEFT  : --gcurx; break;
      }
    }

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
    } } break;

  case 3:
    // DFLAT circles - https://youtu.be/kxXUAiZ40lY
    //   (they have no timing for it? in video)
    //          (but it looks faster)
    // 1175 hs - without rowaddr[] and mask6[]
    //  865 hs - my code w rowaddress[] macro and mask6[]
    // - generally DFLAT says circle: 12x faster than BASIC ROM
//    asm("SEI"); // no differencea
    for(i=10; i>=0; --i) {
      for(j=9; j<65; j+=65/13) {
        GXY(120, 100);
        circle(j, 2);
      }
    }
    break;
    
  case 4:
    // = 5x circle(120,100,75+j,2)
    // - generally DFLAT says circle: 12x faster than BASIC ROM
    //   so they would be -- 26 hs?
    //
    //  320hs ORIC ATMOS BASIC
    //   97hs circle() w setpixel()
    //   81hs - fancy pointer stuff, 1010 BYTES! - reverted
    //   93hs - with mod6[] and div6[] - (/ 320 93.0) = 3.44x ! 
    //   70hs - with rowaddr[] and mask6[] - 4.57 ...
    for(j=0; j<5; ++j) {
      GXY(120, 100);
      circle(75+j, 2);
    }
    break;

  case 5:
    for(j=0; j<10; ++j) {
      //draw(0, j, 239, 30, 2); // 92hs
      //draw(239, j+30, -239, -30, 2); // 92hs same reverse

      //draw(0, 30+j, 239, -30, 2); // 92hs

      gcurx=j; gcury=0; draw(30, 199, 2); // 75hs
//      draw(j+30, 199, -30, -199, 2); // 75hs same reverse

      gcurx=30+j; gcury=0; draw(-30, 199, 2); // 76hs
      //draw(j, 199, 30, -199, 2); // ???? what is it
    }
    break;

  case 6: 
    // square turning
    //
    // BASIC: 7.47s, DLFAT: 3.75s
    // me ... 4.64s with bounds check, pure C!
    //    ( 4.40?s if hardcode xor)
    #define M (200-1)
    for(j=0; j<=M; j+= 10) {
      gcurx= j;   gcury=0;   draw(M-j, j,   2);
      gcurx= M;   gcury=j;   draw(-j,  M-j, 2);
      gcurx= M-j; gcury=M;   draw(j-M, -j,  2);
      gcurx= 0;   gcury=M-j; draw(j, j-M,   2);
    }
    #undef M

    //goto zoom;

    break;

  case 7:
    // single line draw test
    GXY(10, 10); draw(150, 100, 2);
    break;

  case 8:
    text();

    // red scan line from top to bottom of text screen
#define DOTIMES(N, WHAT) do { int _dotimes=N; do {WHAT;} while (--_dotimes>0); } while(0)

    DOTIMES(100, { printf("FOOBAR   "); } );

    gotoxy(39, 1); DOTIMES(27, { *cursc=HIRESMODE; cursc+=40; } );
    { char* p= HIRESSCREEN;
      DOTIMES(200, { *p=curpaper; p+= 40; } );
    }
    { char* p= HIRESSCREEN+1;
      DOTIMES(200, { *p=TEXTMODE; p+= 40; } );
    }
    { char* p= HIRESSCREEN+3;
      DOTIMES(200, { *p=7; p+= 40; } );
    }

    while(1)
    { char* p= HIRESSCREEN;
      DOTIMES(200, {
          *p=16+1; // bgred
          DOTIMES(40, {});
          *p=curpaper;
          p+= 40; } );
    }
    break;

  case 9:
    // - https://osdk.org/index.php?page=articles&ref=ART19
    // BASIC takes 320 hs...
    // Inline here: I get 75 hs, no address lookup.
    // They get 64 hs w addess lookup.
    // And with machine code they get 29 hs.
    // ... using mask6[] - I get 60 hs in C!
    // ... using rowaddr[] - I get 49 hs !!! using C
    for(gcury= 75; gcury<= 125; ++gcury) {
      for (gcurx = 150; gcurx <= 210; gcurx+=2) {
        //CURSET(x, y, 1);
        // *(HIRESSCREEN+ (5*gcury)*8 + div6[gcurx])
          //|= PIXMASK[mod6[gcurx]];
        //*(HIRESSCREEN+ (5*gcury)*8 + div6[gcurx])
        //|= mask6[gcurx];
        *(rowaddr[gcury] + div6[gcurx]) |= mask6[gcurx];
      }
    }
    break;

  case 10:
    // come here from 
  zoom:

    text();
    // lol
//    {  char c;
//      for(p=HIRESSCREEN,c=200; --c; ) 
//        *p=TEXTMODE, p+=40;
//    }
//    curmode= SCREENEND[-1]= TEXTMODE;

    // a text graphics zoomer!
    {
      int x= 0, y= 0;
      unsigned int t;

      while(1) {
        t= time();
        gcurx= x; gcury= y; zoom();
        gotoxy(15, 25); printf(" %d hs (%d,%d)  ", t-time(), x, y);

        // wait for release
        //while(kbhit());

        // step
        switch(cgetc()) {
        case KEY_LEFT:  x-=6; break;
        case KEY_RIGHT: x+=6; break;
        case KEY_DOWN:  y+=4; break;
        case KEY_UP:    y-=4; break;
        }

        // fix out of bounds
        if (x<0) x= 0;
        if (y<0) y= 0;
        if (x>240-44) x= 240-44;
        if (y>200-25-3) y= 200-25-3;
      }
    }
  }
  gotoxy(25,25); printf(" TIME %d hs", t-time());
  hirescompress();

  //text();
  //printf("HELLO TEST\n");
  //gotoxy(10,25); printf("TIME %d times = %d hs", N*2, t-time());
}
