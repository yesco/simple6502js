// DOONE
//
// Not DOOM?
//
// trying to do simple 3D rendering on 2D doom-style

#define MAIN
#include "../hires-raw.c"

// dummys
char T, nil, print, doapply1;

// oric style textures 6x6, 6 rows of 6 cells
// - repeated, fixed horizontal by row number (%6)
// - hi bits 64+128 need to be set (as it's anded)
char textures[11][6]= {
  // wall textures 0-7 (+1 in map)
#define EAGLE 1
  { // 0: eagle - lol
    0b11110010,
    0b11001010,
    0b11111110,
    0b11101000,
    0b11101110,
    0b11000000,
  },
#define REDBRICK 2
  { // 1: redbrick
    0b11000001,
    0b11111111,
    0b11001000,
    0b11001000,
    0b11111111,
    0b11001001,
  },
#define PURPLESTONE 3
  { // 2: purplestone
    0b11011010,
    0b11011101,
    0b11110100,
    0b11011011,
    0b11101101,
    0b11111101,
  },
#define GREYSTONE 4
  { // 3: greystone
    0b11101010,
    0b11010101,
    0b11101010,
    0b11010101,
    0b11101010,
    0b11010101,
  },
#define BLUESTONE 5
  { // 4: bluestone
    0b11110110,
    0b11010111,
    0b11101101,
    0b11100111,
    0b11011101,
    0b11110110,
  },
#define MOSSY 6
  { // 5: mossy
    0b11001001,
    0b11100010,
    0b11011010,
    0b10100100,
    0b11101000,
    0b11000010,
  },
#define WOOD 7
  { // 6: wood
    0b11110000,
    0b11011110,
    0b11000000,
    0b11001100,
    0b11110010,
    0b11000001,
  },
#define COLORSTONE 8
  { // 7: colorstone
    0b11100001,
    0b11010110,
    0b11000100,
    0b11001010,
    0b11010010,
    0b11010100,
   },

  // sprite textures 8-10 (+1 in list)
  // TODO: these need to be bigger!
  // TODO: flexible sizes... wx, wy
#define GREENLIGHT 9
  { //  8: green light
    0b11001100,
    0b11011110,
    0b11111111,
    0b11001000,
    0b11000000,
    0b11000000,
  },
#define PILLAR 10
  { //  9: pillars
    0b11011110,
    0b11001100,
    0b11001100,
    0b11001100,
    0b11001100,
    0b11011110,
  },
#define BARREL 11
  { // 10: barrels
    0b11001100,
    0b11010010,
    0b11110011,
    0b11111111,
    0b11111111,
    0b11011110,
  },
};
  
// map and sprites coordinates from
// - https://lodev.org/cgtutor/raycasting.html 
// (no other code from there)
#define WX 24
#define WY 24
char map[WY][WX] = {
  {8,8,8,8,8,8,8,8,8,8,8,4,4,6,4,4,6,4,6,4,4,4,6,4},
  {8,0,0,0,0,0,0,0,0,0,8,4,0,0,0,0,0,0,0,0,0,0,0,4},
  {8,0,3,3,0,0,0,0,0,8,8,4,0,0,0,0,0,0,0,0,0,0,0,6},
  {8,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6},
  {8,0,3,3,0,0,0,0,0,8,8,4,0,0,0,0,0,0,0,0,0,0,0,4},
  {8,0,0,0,0,0,0,0,0,0,8,4,0,0,0,0,0,6,6,6,0,6,4,6},
  {8,8,8,8,0,8,8,8,8,8,8,4,4,4,4,4,4,6,0,0,0,0,0,6},
  {7,7,7,7,0,7,7,7,7,0,8,0,8,0,8,0,8,4,0,4,0,6,0,6},
  {7,7,0,0,0,0,0,0,7,8,0,8,0,8,0,8,8,6,0,0,0,0,0,6},
  {7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,6,0,0,0,0,0,4},
  {7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,6,0,6,0,6,0,6},
  {7,7,0,0,0,0,0,0,7,8,0,8,0,8,0,8,8,6,4,6,0,6,6,6},
  {7,7,7,7,0,7,7,7,7,8,8,4,0,6,8,4,8,3,3,3,0,3,3,3},
  {2,2,2,2,0,2,2,2,2,4,6,4,0,0,6,0,6,3,0,0,0,0,0,3},
  {2,2,0,0,0,0,0,2,2,4,0,0,0,0,0,0,4,3,0,0,0,0,0,3},
  {2,0,0,0,0,0,0,0,2,4,0,0,0,0,0,0,4,3,0,0,0,0,0,3},
  {1,0,0,0,0,0,0,0,1,4,4,4,4,4,6,0,6,3,3,0,0,0,3,3},
  {2,0,0,0,0,0,0,0,2,2,2,1,2,2,2,6,6,0,0,5,0,5,0,5},
  {2,2,0,0,0,0,0,2,2,2,0,0,0,2,2,0,5,0,5,0,0,0,5,5},
  {2,0,0,0,0,0,0,0,2,0,0,0,0,0,2,5,0,5,0,5,0,5,0,5},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5},
  {2,0,0,0,0,0,0,0,2,0,0,0,0,0,2,5,0,5,0,5,0,5,0,5},
  {2,2,0,0,0,0,0,2,2,2,0,0,0,2,2,0,5,0,5,0,0,0,5,5},
  {2,2,2,2,1,2,2,2,2,2,2,1,2,2,2,5,5,5,5,5,5,5,5,5}
};

typedef struct Sprite {
  unsigned int x;
  unsigned int y;
  char texture;
} Sprite;

#define numSprites 19

Sprite sprite[numSprites] = {
  {205*256/10,115*256/10,10}, //green light in front of playerstart
  //green lights in every room
  {185*256/10,45*256/10,  10},
  {10*256/10, 45*256/10,  10},
  {100*256/10,125*256/10, 10},
  {35*256/10, 65*256/10,  10},
  {35*256/10, 205*256/10, 10},
  {35*256/10, 145*256/10, 10},
  {145*256/10,205*256/10, 10},

  //row of pillars in front of wall: fisheye test
  {185*256/10, 105*256/10, 9},
  {185*256/10, 115*256/10, 9},
  {185*256/10, 125*256/10, 9},

  //some barrels around the map
  {215*256/10, 15*256/10, 8},
  {155*256/10, 15*256/10, 8},
  {16*256/10,  18*256/10, 8},
  {162*256/10, 12*256/10, 8},
  {35*256/10,  25*256/10, 8},
  {95*256/10,  155*256/10,8},
  {100*256/10, 151*256/10,8},
  {105*256/10, 158*256/10,8},
};

// cos is 90' off, i.e., 64!
//   sin(x)=cos(x-π/2) and cos(x)=sin(π/2+x) 
// sin has symmtries...

int sin[64]= {0,3,6,9,12,15,18,21,24,28,31,34,37,40,43,46,48,51,54,57,60,63,65,68,71,73,76,78,81,83,85,88,90,92,94,96,98,100,102,104,106,108,109,111,112,114,115,117,118,119,120,121,122,123,124,124,125,126,126,127,127,127,127,127};

// RETURNS: sin(x)*2^7, so you >>7 !
// TODO: check!
int sin128(char b) {
  //if (b<0)   return  sin128(-b);
  if (b<64)  return  sin[b];        // < 90
  if (b>128) return -sin128(b-128); // >180
             return  sin128(127-b); // > 90
}

// see sin()
int cos128(int b) { return sin128(63-b); }

// 1803 + 303 + 1201
char xorcolumn[2+100*(3+2+3+2+2+3+3)+1]; // big. fast. lol
char clrcolumn[2+100*3+1];   // y
char cpycolumn[200*(3+3)+1]; // x->y

void genxorcolumn() {
  int i=0, r= (int)HIRESSCREEN, rr= (int)HIRESSCREEN+HIRESSIZE-40;
  char * p= xorcolumn-1;
  char * c= clrcolumn-1;
  char * cp= cpycolumn-1;

  // lda #$40
  *++c= 0xa9;
  *++c= 0x40;

  // lda #$00
  *++p= 0xa9;
  *++p- 0x00;

  // do half, write mirrored on line 100 !
  // (save half effort and only needd to draw 1 line)
  // TODO: however, texture would be symmetrical of middle
  //   and possibly misaligned...
  for(i=0; i<100; ++i) {
    // sta absy nextline
    *++c= 0x99;
    *++c= r;
    *++c= r/256;

    // eor absy
    *++p= 0x59;
    *++p= r;
    *++p= r/256;
    // ora #64
    *++p= 0x09;
    *++p= 64;
    // tax - save non-textured byte
    *++p= 0xaa;
    // andz $texture! 6x6
    *++p= 0x25;
    *++p= 0x80+(i%6);
    // sta absy nextline
    *++p= 0x99;
    *++p= r;
    *++p= r/256;
    // ---  maybe not mirror texture??? lol
    // txa - restore non-textured byte
    *++p= 0x8a;
    // andz $texture! 6x6
    *++p= 0x25;
    *++p= 0x80+(5-(i+4)%6);
    // sta absy 120-nextline
    *++p= 0x99;
    *++p= rr;
    *++p= rr/256;
    // txa - restore non-textured byte
    *++p= 0x8a;

    r+= 40; rr-= 40;
  }

  r= (int)HIRESSCREEN;
  for(i=0; i<200; i++) {
    // lda absx 
    *++cp= 0xbd;
    *++cp= r;
    *++cp= r/256;

    // sta absy
    *++cp= 0x99;
    *++cp= r;
    *++cp= r/256;

    r+= 40;
  }

  // rts
  *++c= 0x60;

  *++p= 0x60;

  *++cp= 0x60;

  assert(p+1==xorcolumn+sizeof(xorcolumn));
}


// TODO: allocate... lol
#define TEXTURE ((char*)0x80)

// pointer to texture for each column
// TODO:: remove, old method
char* colmask[40];

// actually, it only clears half!
#define clearcol(q) do { \
  asm("ldy %v", q); \
  asm("jsr %v", clrcolumn); \
} while(0)


void drawFill(int dx, int dy, char v) {
  register char* p;
  register char s, m, adx, ady;
  register char i;

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
      static char q, mi;
      q= div6[gcurx];
      mi= mod6[gcurx];

      i= adx+1;
      m= PIXMASK[mi];
      s= 0;
      p= HIRESSCREEN+40*gcury+q;
      *p= 64;
      clearcol(q);

      while(--i) {

        // adjust y
        if ((s+= ady) > adx) {
          s-=adx;
          if (dy>=0) {
            if ((p-= 40)<HIRESSCREEN) break;
          } else {            
            if ((p+= 40)>=HIRESEND) break;
          }
          *p= 64;
        }

        *p |= m;

        // step x, wrap around bit
        if ((m<<=1)==64) {
          asm("ldy %v", q);
          asm("jsr %v", xorcolumn);
          m=1;
          *--p= 64; --q;
          clearcol(q);
          // TODO: clear up
        }
      }
      asm("ldy %v", q);
      asm("jsr %v", xorcolumn);
    }
  } else { // dy >= dx
    if (dy<0) { gcurx+= dx; dx= -dx; gcury+= dy; dy= -dy; }
    gcury+= dy;
    gcurx+= dx;
    {
      // inline curset
      // TODO: too much duplication - make macro!
      static char q, mi;
      q= div6[gcurx];
      mi= mod6[gcurx];

      i= ady+1;
      m= PIXMASK[mi];
      s= 0;
      p= HIRESSCREEN+(5*gcury)*8+q;
      *p= 64;
      clearcol(q);

      while(--i) {

        // adjust x
        if ((s+= adx) > ady) {
          s-=ady;
          // step x, wrap around bit
          if (dx>=0) {
            if ((m<<=1)==64) {
              asm("ldy %v", q);
              asm("jsr %v", xorcolumn);
              m=1;
              *--p= 64; --q;
              clearcol(q);
            }
          } else {
            if (!(m>>=1)) {
              asm("ldy %v", q);
              asm("jsr %v", xorcolumn);
              m=32;
              *++p= 64; ++q;
              clearcol(q);
            }
          }
          // TODO: clear up
        }

        // plot it
        *p |= m;

        // step y
        p-= 40;
        if (p<HIRESSCREEN) break;
        *p= 64;

      }
      asm("ldy %v", q);
      asm("jsr %v", xorcolumn);

    }
  }
}

void xorfill(char m) {
  static char r, c, v;
  register char* p;

  switch(m) {

  case 1: // xor every byte only (no fill)
    for(c=0; c<40; ++c) {
      p= HIRESSCREEN-40+c;
      v= 0;
      for(r=0; r<200; ++r) {
        p+=40;
        *p^= 63;
      }
    } break;

  case 2: { // xor fill all screen
    for(c=0; c<40; ++c) {
      p= HIRESSCREEN-40+c;
      v= 0;
      if (1) {

        asm("ldy %v", c);
        asm("jsr %v", xorcolumn);

      } else if (0) {

      for(r=0; r<200; ++r)
        *p= v= (*(p+=40)^v)|64;
      } else {

      // x = 0 // B2 C2
      asm("ldx #0");
      // y= 200 // B2 C2
      asm("ldy #200");

    nexty: // C43 (+ 18 12 8 5 ) (* 43 200) (/ 1000000.0 (* 8600 40)) = 2.9 frame-rate, lol...
      // we


      // p+= 40; // B10 C18+4
      asm("clc");
      asm("lda %v", p);
      asm("adc #40");
      asm("sta %v", p);
      asm("bcc %g", noinc);
      asm("inc %v+1", p);
    noinc:

      // a=(*p^x)|64; // 9B C12
      asm("txa");
      asm("ldx #0");
      // TODO: addressing using y 1 cycle cheaper, total savings: 1+1=2, lol
      // if using y, can use table for row start, y stay "fixed", but where to store "v"?
      asm("eor (%v,x)", p);
      asm("ora #64");

      // x= *p= a // 3B C8
      asm("sta (%v,x)", p);
      asm("tax");

      // end? // 3B C5
      asm("dey");
      asm("bne %g", nexty);
      }
    }
  } break;

  case 3: { // xor fill with MASK all scree
    char maskmask, *mask; 
    for(c=0; c<40; ++c) {
      v= 0;
      p= HIRESSCREEN-40+c;

      mask= colmask[c];
      if (mask) { maskmask= *mask++; }
      
      if (!mask)
        for(r=0; r<200; ++r)
          *p= v= (*(p+=40)^v)|64;
      else
        for(r=0; r<200; ++r)
          *p= (v= (*(p+=40)^v)|64) & mask[r & maskmask];

    }
  } break;

  case 4: // xor fill limited area
    for(c=40/6-1; c<=(40+180)/6+1; ++c) {
      p= HIRESSCREEN + 50*40-40 + c;
      v= 0;
      for(r=50; r<150; ++r)
        *p= v= (*(p+=40)^v)|64;
    }
    break;
  }
}

// Draws a trapezoid, with parallel x-sides
void trap(char x1, char x2, char y1, char y2, int d, char texture) {
//void trap(char x1, char x2, char y1, char y2, int d, char* texture) {
  char i, e= x2/6;
  //for(i=x1/6; i<=e; ++i) colmask[i]= mask;
  memcpy(TEXTURE, ((char*)textures)+6*(texture-1), 6);
  gcurx= x1; gcury=  y1; drawFill(x2-x1,  +d, 1);
}

char maskvertstripe[]= {
  0b00,
  1+4+16 +64+128, 1+4+16 +64+128,
  1+4+16 +64+128, 1+4+16 +64+128,
  1+4+16 +64+128, 1+4+16 +64+128};
char maskhorizstripe[]= {
  0b01,
  0 +64+128, 255,
  0 +64+128, 255,
  0 +64+128, 255};
char maskgray[]= {
  0b01,
  1+4+16 +64+128, 2+8+32 +64+128,
  1+4+16 +64+128, 2+8+32 +64+128,
  1+4+16 +64+128, 2+8+32 +64+128};
char masksquare[]= {
  0b011,
  1+2+4 +64+128, 1+2+4 +64+128, 1+2+4 +64+128,
  8+16+32 +64+128, 8+16+32 +64+128, 8+16+32 +64+128};
char maskdiag[]= {
  0b011,
  1 +64+128, 2 +64+128, 4 +64+128,
  8 +64+128, 16 +64+128, 32 +64+128};

//char other[HIRESSIZE];

signed char sgn(int x) { return x<0? -1: !x? 0: +1; }

void drawmap(unsigned int x, unsigned int y, int dx, int dy) {
  char px= x/(256*8), py= y/(256*8);
  char r, c;
  for(r=0; r<WY; ++r) {
    for(c=0; c<WX; ++c) {
      char m= map[r][c];
      if (m) { gotoxy(c,r); putchar(m? m+'0': ' '); }
      if (r==px && c==py) { gotoxy(c,r); putchar(0xff); }
    }
  }
}

void ginvchar(char x, char y) {
  char i, * p= HIRESSCREEN+40*y*8+x;
  for(i=0; i<8; ++i) *(p+=40) ^= 128;
}

char mapmode= 0, debug= 0, render= 1;

char wx, wy;

// Using a ray from (x,y) in direction (dx,dy) find
// first wall hit.
// TODO: or could be sprite?
//
// Requires enclosed map space, otherwise no terminate.
unsigned int hitxraycast(unsigned int x, unsigned int y, int dx, int dy) {
  signed char sx= 1, sy= 1;
  char ax= dx, ay= dy;
  int s; // TODO: signed char ? or char
  char hitx= 1;

  char i, *p;

  wx= x/(256*8); // TODO: WX?
  wy= y/(256*8); // TODO: WY ?

  if (dx<0) { ax= -ax; sx= -sx; }
  if (dy<0) { ay= -ay; sy= -sy; }

  if (mapmode) ginvchar(wx, wy);

  if (ay<=ax) {
    s= -ax;

    while(!map[wy][wx]) {
      if ((s+= ay)>0) { s-= ax; wy+= sy; hitx= 1; }
      else { wx+= sx; hitx= 0; }

      if (mapmode) ginvchar(wx, wy);
    }

  } else {
    s= -ay;

    while(!map[wy][wx]) {
      if ((s+= ax)>0) { s-= ay; wx+= sx; hitx= 0; }
      else { wy+= sy; hitx= 1; }

      if (mapmode) ginvchar(wx, wy);
    }

  }

  return hitx;
}

// fast inverse square root
// - https://en.m.wikipedia.org/wiki/Fast_inverse_square_root

// TODO: this is duplicataion of drawwalls
void hitwall(unsigned int x, unsigned int y, int sx, int sy) {
  int rx, ry;
  int d;
  char wh;

  // find wall
  if (hitxraycast(x, y, sx, sy)) {
    d= wx-sx/(256*8);
  } else {
    d= wy-sy/(256*8);
    // TODO: make "darker"
  }
  if (d<0) d= -d;
  ++d; // never 0, lol
  wh= 99/d; // TODO: costly - find cheaper/table

  //gfill(30, 3*6, 10, 3*6, 64);  // not needed as char current overwrite, not xor
  gotoxy(30, 3); printf("%d: %d '%c' ", map[wy][wx], d, 'a'+d);
  gotoxy(30, 4); printf("(%d,%d)  ", wx, wy);
  gotoxy(30, 5); printf("h=%d ", wh);

}

// 130 cs - draw w gclear, fill loop
//  87 cs - draw w clrcolumn, xorcolumn
//  53 cs - simplified rx,ry sin/cos!
//  43 cs - only test once for kbhit!
//  41 cs - simplify, but always clear,xorcolumn
void drawwalls(unsigned int x, unsigned int y, char a, int sx, int sy) {
  static int lastwall; // to draw a "blacK" line between walls
  static int newwall;

  static char c; // static so can call asm...
  static char rx, ry;
  static int d, wh;
  static char* p;
  static char i;
  static char va;
  va= a+(64+(64-40*1)/2); // 90d left from forward + center viewport width 40/256*360= 56.25d!

  lastwall= 0;
  for(c= 0; c<40; ++c) {
    //HIRESSCREEN[c] ^= 128;

    // only used for direction! no need scale!
    rx= cos128(va);
    ry= sin128(va);
    //gotoxy(c, 1+(c%15)); printf("%d:%d,%d", va, rx, ry);

    // find wall, distance from screen(!)
    if (hitxraycast(x, y, rx, ry)) {
      d= wx-sx/(256*8);
    } else {
      d= wy-sy/(256*8);
      // TODO: make "darker"
    }
    if (d<0) d= -d;
    ++d; // never 0, lol

    // for detecting change in walls and draw black line
    newwall= (wy<<8) + wx;

    // draw slice of wall
    //wh= 99/d; // TODO: costly - find cheaper/table
    // TODO: simplify
    wh= 100-d*8; // 0..23
    p = HIRESSCREEN+(100-1-wh)*40+c;
    // draw if not too far away
    clearcol(c);
    if (render && wh>0) { // TODO: wh get's negative for 'g' and won't show?
      if (newwall==lastwall) {
        *p^= 64+63;
        //*p^= 64+63;
      } else {
        *p^= 64+31;
        
        // set texture
        memcpy(TEXTURE, ((char*)textures)+6*(map[wy][wx]-1), 6);
      }
    }
    asm("ldy %v", c);
    asm("jsr %v", xorcolumn);
    
    if (debug) {
      gotoxy(c, 0); putchar('a'+d);
    
      gotoxy(c, 2); putchar('0'+wx);
      gotoxy(c, 3); putchar('0'+wy);

      gotoxy(c, 5); putchar('0'+map[wy][wx]);
    }

    lastwall= newwall;

    // rotate right a "slice" step 1/256th turn! -> 40=> 56.25d!
    --va; // lol, not so precise... 1

    if (c==10 && kbhit()) break; // respond faster!
  }
}


void main() {
  char c, h, b;
  int dx= 99, dy= 99;
  char x= 0;
  int f= 0;
  unsigned int START;
  // init tables
  int i;

  unsigned int G, S= time();
  genxorcolumn(); // 19 hs to generate!
  G= time();

  // start drawing

  hires();
  gclear();

  c= 0;
  gotoxy(0, 25); printf("genxorcolumn(): %d hs ", S-G);

  // sin cos test
  if (0) {
    char r= 100;
    gmode= 1; // this doesn't fill the full circle! 0-64 isn't enough
    while(r--!=0 && !kbhit()) {
      char b= 0; signed char dx, dy;
      do {
        dx= (r*cos128(b))>>7; dy= (r*sin128(b))>>7;
        gcurx= 120+dx; gcury= 100+dy; setpixel();
        // 4 symmetries (actual 8 if use 0-32 (0-45 degress))
        // gcurx= 120-dx; gcury= 100-dy; setpixel();
        // gcurx= 120+dx; gcury= 100-dy; setpixel();
        // gcurx= 120-dx; gcury= 100+dy; setpixel();
      } while(++b);
    }
  }

  // raycasting
  if (1) {
    int asp= 1;
    int sp= 8;
    int speed= 256*sp;
    char a= 64; // angle 90d
    unsigned x= 4*256*sp, y= 16*256*sp, h= 0; // player pos
    int dx= 0, dy= -sp; // step at speed, 90d

    // screen
    int sd= 2*256; // distance
    int sw= 64; // -sw..+sw
    int sx, sy;
    char va;

    // temp
    int rx, ry;

    // wall
    unsigned int wall;

    unsigned int F, T, fT= 0;
    char c, wh=42;
    int d;
    char k;
    char* p;

    while (1) {
      // Done
      F= T-time();
      ++f; fT+= F;
      gotoxy(0, 25); printf(
"%d cs c/s=%4ld (%4ld) "
"(%3u,%3u) w(%2d,%2d) d%2d h%3d \ta=%3d (%+3d,%+3d)   ",
F, 10000L/F, f*100000L/fT,
x/(256*8), y/(256*8), wx, wy, d, wh, a, dx, dy,
0);

      // draw direction ("cursor")
      k= 0;
      do { // tricky loop to draw/cgetc/undraw
        // draw direction
        { char px= x/(256*8/6), py= y/(256*8/8);
          gcurx= px; gcury= py; draw(dx>>5, dy>>5, 2);
        }
        // TODO: uses dx,dy but need distance from sx, sy?
        if (mapmode) hitwall(x, y, dx, dy);

        if (k) break;
        k= cgetc();
      } while(1);

      T= time();

      // -- Draw frame
      // left most side of view
      // (forward to "screen" and 90d left forward again)
      sx= -(dy>>5); // TODO: use dw? speed>>6 => 64
      sy= (dy>>5)+(dx>>5);

      // Movement
      switch(k) {
      case 'b': { // benchmark!
        // 11273 cs # 256 = 2.27 fps        44 cs/f
        //  3577 cs # 256 = 7.15 fps memcpy 13 cs/f    0
        //  3945 cs # 256 = 6.48 fps drawc0 15 cs/f +368 cs/256 f
        //  2543 cs # 256 =10.06 fps         9 cs/f
        //  2327 cs # 256 =11.00 fps         9 cs/f
        //  ^sei 8.5% faster (after drawwalls, handtimed)
        static newwall, lastwall;

        f= 0;
        T= time();
        a= 0;
        drawwalls(x, y, a, sx, sy);
        asm("sei");
        do {
          if (0) {
            drawwalls(x, y, a, sx, sy);
          } else {
            // 3577 cs #256 => 7.15
            // TODO: my own scroll/column copy, should be 640 cs!
            if (0) {
              memmove(HIRESSCREEN+1, HIRESSCREEN, HIRESSIZE-1); 
            } else {
              static char f, t;
              for(f=38; f--;) {
                t= f+1;
                asm("ldx %v", f);
                asm("ldy %v", t);
                asm("jsr %v", cpycolumn);
              }
            }
            // draw first column, others already there!
            {
              static char c; // static so can call asm...
              static int d, wh;
              static char* p;
              static char i;
              static char va;
              // 90d left from forward + center viewport width 40/256*360= 56.25d!
              va= a+(64+(64-40*1)/2); 
              // find wall, distance from screen(!)
              if (hitxraycast(x, y, cos128(va), sin128(va))) {
                d= wx-sx/(256*8);
              } else {
                d= wy-sy/(256*8);
                // TODO: make "darker"
              }
              if (d<0) d= -d;
              ++d; // never 0, lol

              // for detecting change in walls and draw black line
              newwall= (wy<<8) + wx;

              // draw a column-slice of wall
              wh= 100-d*8; // 0..23
              p = HIRESSCREEN+(100-1-wh)*40+c;

              clearcol(c);
              if (render && wh>0) { // TODO: wh get's negative for 'g' and won't show?
                //TODO:
                if (newwall==lastwall) {
                  *p^= 64+63;
                } else {
                  // left side black line - since scroll right... lol
                  *p^= 64+62;
                  // set texture - inline?
                  memcpy(TEXTURE, ((char*)textures)+6*(map[wy][wx]-1), 6);
                }
              }
              asm("ldy %v", c);
              asm("jsr %v", xorcolumn);

              lastwall= newwall;
            }
          }
          ++a; ++f;
        } while (a);
        F= T-time();
        gotoxy(0, 25);
        printf("BENCH: %d cs #%d %d cs/f %ld cfps                  ",
               F, f, F/f, f*10000L/F);
        cgetc();
      } break;

      case 'd': debug= 1-debug; break;
      case 'r': render= 1-render; break;
      case 'm': case ' ':
        gclear();
        if (mapmode= 1-mapmode) drawmap(x, y, dx, dy);
        break;

        // forward backward
      case KEY_UP:     x+= dx; y+= dy; break;
      case KEY_DOWN:   x-= dx; y-= dy; break;
        // angle change
      case KEY_LEFT:   a+= asp*2; // lol
      case KEY_RIGHT:  a-= asp;
        dx=  sp*cos128(a);
        dy= -sp*sin128(a);
        break;
      }

      // draw 40 columns screen
      if (!mapmode) {
        drawwalls(x, y, a, sx, sy);
      }

    } // while(1)


  }

  // walking and turning
  if (1) {
    char a= 64; // angle 90d
    int speed= 256;
    int x= 120*256, y= 100*256, h= 0; // player pos
    int dx= 0, dy= -speed; // step at speed, 90d

    unsigned int F, T, fT= 0;
    char c;

    while (1) {
      // draw direction
      gcurx= speed/10; gcury= speed/10; draw(dx/10, dy/10, 2);

      // Done
      F= T-time();
      ++f; fT+= F;
      gotoxy(0, 26); printf("all=%d cs fpcs=%ld (%ld) f=%d t=%d ",
                            F, 10000L/F, f*100000L/fT, f, fT);
      c= cgetc();

      T= time();
      // undraw direction
      gcurx= speed/10; gcury= speed/10; draw(dx/10, dy/10, 2);

      // Draw frame
      gcurx= x/256; gcury= y/256; gmode= 1; setpixel();

      // Movement
      switch(c) {
        // forward backward
      case KEY_UP:     x+= dx; y+= dy; break;
      case KEY_DOWN:   x-= dx; y-= dy; break;
        // angle change
      case KEY_LEFT:   a+= 16*2; // lol
      case KEY_RIGHT:  a-= 16;
        dx=  (speed*cos128(a))>>7;
        dy= -(speed*sin128(a))>>7;
        break;
      }
    } // while(1)

  }

  START= time();
  do {
    unsigned int C, W, F, M, T= time();

    //gclear();
    C= time();

    // -- frame rate 3.47 fps for all 4 walls w texture
    trap(x+0,    x+6*6-1, 70,       130, -20, GREYSTONE);
    trap(x+6*6, x+30*6-1, 50,       150,  15, REDBRICK);
    trap(x+30*6,x+38*6-1, 50+15, 150-15, -30, PURPLESTONE);
    trap(x+38*6,x+40*6-1, 50+15-30, 150-15+30, 0, BLUESTONE);

    //x+= 6;
    if (x>70) x= 0;

    F= time();

    //memcpy(other, HIRESSCREEN, HIRESSIZE);
    M= time();

    ++f;
    gotoxy(0, 26); printf("all=%d cs fpcs=%ld f=%d t=%d ",
                          T-F, f*10000L/(START-F), f, START-F);
                          
    //wait(500);
  } while (1);
}
