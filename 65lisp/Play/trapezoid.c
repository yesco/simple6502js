#define MAIN
#include "../hires-raw.c"

char T, nil, print, doapply1;

// cos is 90' off, i.e., 64!
//   sin(x)=cos(x-π/2) and cos(x)=sin(π/2+x) 
// sin has symmtries...

int sin[64]= {0,3,6,9,12,15,18,21,24,28,31,34,37,40,43,46,48,51,54,57,60,63,65,68,71,73,76,78,81,83,85,88,90,92,94,96,98,100,102,104,106,108,109,111,112,114,115,117,118,119,120,121,122,123,124,124,125,126,126,127,127,127,127,127};

// RETURNS: sin(x)*2^7, so you >>7 !
// TODO: check!
int sin128(int b) {
  if (b<0)   return  sin128(-b);
  if (b<64)  return  sin[b];        // < 90
  if (b>255) return  sin128(b&255); // >360
  if (b>128) return -sin128(b-128); // >180
             return  sin128(128-b); // > 90
}

// see sin()
int cos128(int b) { return sin128(64+b); }

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
      if (0) {

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
  gcurx= x1; gcury=  y1; draw(x2-x1,  +d, 1);
  gcurx= x1; gcury=  y2; draw(x2-x1,  -d, 1);
}

char maskvertstripe[]=   {0b00,  1+4+16 +64+128}; // 1 => 0 bits
char maskhorizstripe[]=  {0b01,  0 +64+128, 255}; // 2 => 1 bits
char maskgray[]=         {0b01,  1+4+16 +64+128, 2+8+32 +64+128}; // 2 => 1 bit
char masksquare[]=       {0b011, 1+2+4 +64+128, 1+2+4 +64+128, 8+16+32 +64+128, 8+16+32 +64+128}; // 4 => 2 bits!

void main() {
  char c, h, b;
  int dx= 99, dy= 99;

  // init tables
  int i;

  hires();
  gclear();
  
  c= 0;
  gotoxy(0, 25);

  do {
    unsigned int C, W, F, T= time();

    gclear();
    C= time();

    //wall(40, 50, 150);
    trap(0,    6*6-1, 70,       130, -20, maskgray);
    trap(6*6, 30*6-1, 50,       150,  15, maskvertstripe);
    trap(30*6,38*6-1, 50+15, 150-15, -30, masksquare);
    trap(38*6,40*6-1, 50+15-30, 150-15+30, 0, maskhorizstripe);
    W= time();

    /// xor down to fill! clevef simple!
    //xorfill(3);   	// 345 hs filling w masks
    xorfill(2);   	// 188 hs filling 37 hs w ASM? lol
    // all: 62hs => 1.61 frame-rate, lol
    // (C overhead... just 40x column => 34hs, so 3hs overhead/loop columns, 10%)
    // ASM: 5.08x faster! (for simple xorfill(2)
    F= time();

    switch(c) {
      // height change
    case KEY_UP:     if (--h<-99) h= -99; break;
    case KEY_DOWN:   if (++h>+99) h= +99; break;
      // angle change
    case KEY_LEFT:   ++b; break;
    case KEY_RIGHT:  --b; break;
    }
    
    gotoxy(0, 25); printf("all=%d hs, clear=%d wall=%d fill=%d ", T-F, T-C, C-W, W-F);
    wait(500);
  } while (1);
}
