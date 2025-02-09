#define MAIN
#include "../hires-raw.c"

char T, nil, print, doapply1;

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

char xorcolumn[2+100*(3+2+3+3)+1]; // (+ 2 (* 200 (+ 3 3 2)) 1)= 1603 bytes!
char clrcolumn[2+100*3+1];

// actually, it only clears half!
#define clearcol(q) do { asm("ldy %v", q); asm("jsr %v", clrcolumn); } while(0)

void clearcolC(char q) {
  // TODO: asm, or clever get it in...
  static char r, *p; // 109 cs-> 60 cs
  p= HIRESSCREEN+q-40;
  r= 200;

  return;
  // TODO: in C this is superslow...
  while(--r!=0) *(p+= 40)= 64;
  // while(--r>=0) *(p+= 40)= 64; // basic overflow error
}

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
    }
  }
}

void genxorcolumn() {
  int i=0, r= (int)HIRESSCREEN, rr= (int)HIRESSCREEN+HIRESSIZE-40;
  char * p= xorcolumn-1;
  char * c= clrcolumn-1;

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
    // sta absy nextline
    *++p= 0x99;
    *++p= r;
    *++p= r/256;
    // sta absy 120-nextline
    *++p= 0x99;
    *++p= rr;
    *++p= rr/256;

    r+= 40; rr-= 40;
  }

  // rts
  *++c= 0x60;

  *++p= 0x60;

  assert(p+1==xorcolumn+sizeof(xorcolumn));
}

char* colmask[40];

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

void trap(char x1, char x2, char y1, char y2, int d, char* mask) {
  char i, e= x2/6;
  for(i=x1/6; i<=e; ++i) colmask[i]= mask;
  gcurx= x1; gcury=  y1; drawFill(x2-x1,  +d, 1);
  //gcurx= x1; gcury=  y2; draw(x2-x1,  -d, 1);
}

char maskvertstripe[]=   {0b00,  1+4+16 +64+128}; // 1 => 0 bits
char maskhorizstripe[]=  {0b01,  0 +64+128, 255}; // 2 => 1 bits
char maskgray[]=         {0b01,  1+4+16 +64+128, 2+8+32 +64+128}; // 2 => 1 bit
char masksquare[]=       {0b011, 1+2+4 +64+128, 1+2+4 +64+128, 8+16+32 +64+128, 8+16+32 +64+128}; // 4 => 2 bits!

//char other[HIRESSIZE];

void main() {
  char c, h, b;
  int dx= 99, dy= 99;

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

  do {
    unsigned int C, W, F, M, T= time();

    //gclear();
    C= time();

    //wall(40, 50, 150);
    trap(0,    6*6-1, 70,       130, -20, maskgray);
    trap(6*6, 30*6-1, 50,       150,  15, maskvertstripe);
    trap(30*6,38*6-1, 50+15, 150-15, -30, masksquare);
    trap(38*6,40*6-1, 50+15-30, 150-15+30, 0, maskhorizstripe);
    W= time();

    /// xor down to fill! clevef simple!
    //xorfill(3);   	// 345 hs filling w masks
    //xorfill(2);   	// 188 hs filling 37 hs w ASM? lol
    // all: 62hs => 1.61 frame-rate, lol
    // (C overhead... just 40x column => 34hs, so 3hs overhead/loop columns, 10%)
    // ASM: 5.08x faster! (for simple xorfill(2)
    //
    // xorcolumn => 35 hs Clear=7 Walls=18 Fill=10 M=15, (/ 1 0.35)= 2.86 frames/s
    //   (/ 34 10.0) = 3.4x faster (/ 188 10.0) = 18.8x FASTER than C!
    F= time();

    switch(c) {
      // height change
    case KEY_UP:     if (--h<-99) h= -99; break;
    case KEY_DOWN:   if (++h>+99) h= +99; break;
      // angle change
    case KEY_LEFT:   ++b; break;
    case KEY_RIGHT:  --b; break;
    }

    //memcpy(other, HIRESSCREEN, HIRESSIZE);
    M= time();

    gotoxy(0, 26); printf("all=%d hs, clear=%d wall=%d fill=%d M=%d ", T-F, T-C, C-W, W-F, F-M);
    //wait(500);
  } while (1);
}
