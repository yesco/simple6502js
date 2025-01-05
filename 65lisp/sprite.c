#include <string.h>
#include <assert.h>

#include "conio-raw.c"

long spHi[]= {
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
char sp6[]= { /* heigth */ 3, /* widthbytes */ 4,
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

long x= 0b00000100000000110000001000000001;
long y= 0x04030201;

// Layout as sprite
// 
// A

// Layout of chars, slack space so can scroll
// down and right!

// ADGJ  XXX|
// BEHK  XXX|
// CFIL  ---+

// scrolling down/up use memcpy! (limit 8 down)

void spritedef(char base, char* sprite) {
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

// taking 8x6 char sprite def sp6
void scrollspritecharsdown(char base, char* sprite) {
  char *d= CHARDEF(base);
  char *s= sprite;
  char h= *s++, w= *s++;

  memmove(d+1, d, h*8*w-1);
  *d= 0;
  //memset(d, 255, h*8*w);
}

// Dummys for ./r script
int T,nil,doapply1,print;

void main() {
  char* A= SAVE "ABCD" NEXT "EFGH" NEXT "IJKL";
  clrscr();
  printf("long= %ld %08lx\n", x, x);
  printf("long= %ld %08lx\n", y, y);
  printf(A);
  printf(A);
  printf(A);

  cgetc();
  spritedef('A', sp6);

  while(1) {
    wait(10);
    switch(cgetc()) {
    case KEY_RIGHT:
      // TODO: do in place!
      scrollspriteright(sp6);
      spritedef('A', sp6);
      break;
    case KEY_DOWN :
      scrollspritecharsdown('A', sp6); break;
      break;
    }
  }
}
