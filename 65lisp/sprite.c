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

//char* A= SAVE "ABCD" NEXT "EFGH" NEXT "IJKL";
char* A= SAVE "ADGJ" NEXT "BEHK" NEXT "CFIL";

char spx,spy,sdx=0,sdy= 0;

void redraw() {
  gotoxy(spx, spy);
  printf(A);
  // TODO: use byteblit();
}

void main() {
  char i;

  clrscr();

  cgetc();
  spritedef('A', sp6);

  spx=5; spy=12; redraw();

  while(1) {
    switch(cgetc()) {
    case 'r':
      spritedef('A', sp6);
      break;
    case KEY_RIGHT:
      if (6 == ++sdx) {sdx=0;
        ++spx;
        clrscr();
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
        clrscr();
        spritedef('A', sp6);
        redraw();
      } else {
        scrollspritecharsdown('A', sp6);
      }
      wait(2);
      break;
    case KEY_UP :
      if (0 == sdy--) {sdy=7;
        --spy;
        clrscr();
        spritedef('A', sp6);
        // TODO: make one
        for(i=8;--i;)scrollspritecharsdown('A', sp6);
        redraw();
      } else {
        scrollspritecharsup('A', sp6);
      }
      wait(2);
      break;
    }
  }
}
