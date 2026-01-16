#include <stdio.h>
#include <string.h>

typedef unsigned int word;

// dummies
char T, nil, doapply1, print;

char* SCREEN= (char*)0xbb80;
char* CHARSET= (char*)0xb400;

char* chardef(char c) {
  return c*8 + CHARSET;
}

const int
  BLACK= 0, RED= 1, GREEN= 2, YELLOW= 3, 
  BLUE= 4, MAGENTA= 5, CYAN= 6, WHITE= 7,
  // +BG for background
  BG= 16, 

  NORMAL=8, ALT= 9,
  // +DOUBLE+FLASHING
  DOUBLE= 2, FLASHING= 4;

void fill(char r, char c, char h, char w, char v) {
  char* p= r *40 +SCREEN +c;
  char i;

  while(h-- > 0) {
    i= w;
    while(i-- > 0) p[i]= v;
    p+= 40;
  }
}

void lores(char m) {
  // 32 is space, or in mode 1 no pixel set
  fill(0, 0, 28, 40, 32);

  // 0-1 => 8->9
  fill(0, 0, 28, 1, NORMAL+m);
}

char MASK[]= {1, 2,
              4, 8,
              16, 64};

void setpixel(char x, char y) {
  char* p= (y /3) *40 +SCREEN;
  char r= y %3, c= x &1;
  char m= MASK[r*2 + c], a= x/2;
//  if (x<2 || x>79 || y>=28*3) return;
  // TODO: protect color attributes?
  m |= p[a];
  if ((m&127) >= 96) m&= (255-32);
  p[a] = m;
}

void plotchar(char x, char y, char ch) {
  char* p= chardef(ch);
  char r, c, v;

  // TODO: wrap?

  r=8; do {
    v= *p++;
    x+= 6;
    c= 6; do {
      --x;
      if (v & 1) setpixel(x, y);
      v/= 2;
    } while(--c);
    ++y;
  } while(--r);
}

void tplot(char x, char y, char* s) {
  while(*s) {
    // TODO: wrap?
    plotchar(x, y, *s++);
    x+= 6;
  }
}

void splot(char r, char c, char* s) {
  memcpy(SCREEN + r*40 + c, s, strlen(s));
}

char bigC[]= {
//          111111111122222222223333333333
//0123456789012345678901234567890123456789
 "\0                                       "
 "             xxxxxxxxxxxx               "
 "        xxxxxxxxxxxxxxxxxxxxxx          "
 "     xxxxxxxxxxxxxxxxxxxxxxxxxxxxx      "
 "   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    "
 "  xxxxxxxxxxxx            xxxxxxxxxxx   "
 "  xxxxxxxxx                  xxxxxxxxx  "
 " xxxxxxxxx                    xxxxxxxxx " 
 " xxxxxxxxx                    xxxxxxxxx " 
 " xxxxxxxxx                              "
 " xxxxxxxxx                              "
 " xxxxxxxxx                              "
 " xxxxxxxxx                              "
 "\0"
// <14
};

char threelines(char* b, char y) {
  char n, x, i;
  for(n=3; --n; ) {
    x= 20; ++y;
    for(i=0; i<40; ++i) {
      if (b[i]>' ') setpixel(x, y);
      ++x;
    }
  }
  return y;
}

void wait(int cs) {
  int i;
  while(cs-- > 0) {
    for(i= 300; --i; );
  }
}

word main() {
  // cursor off
  putchar('Q'-64);

  lores(1);

  fill(0, 1, 25, 1, WHITE+BG);
  fill(0, 2, 25, 1, BLACK);

  //                123456789012
  // kerning lol
  tplot(6        , 1+0*8, "6502");
  tplot(6+  4*6+2, 1+0*8, "Meteori");
  tplot(6+ 11*6+1, 1+0*8, "C");

  tplot(6        , 1+1*8, "compi");
  tplot(6+  4*6+5, 1+1*8, "ler");
  tplot(6+  7*6+7, 1+1*8, "&");
  tplot(6+  8*6+7, 1+1*8, "IDE");

  // print a big C!
  if (1) {
    char *b= bigC;
    // AFTER
    char y= 2*7+1;
    do {
      y= threelines(b, y);
      b+= 40;
    } while (*b);
    // one extra
    y= threelines(b-40, y);
    // reverse!
    do {
      b-= 40;
      y= threelines(b, y);
    } while(*b);
  }

  // oric atmos diagonal slash red line
  if (1) {
    char *p= SCREEN + 6*40 + 25;
    char r;
    for(r=0; r<19; ++r) {
      wait(1);
      p[0]= RED+BG;
      p[1]= RED+BG;
      p[2]= RED+BG;
      p[3]= RED+BG;
      p[4]= RED+BG;
      // make horizontal line by not whitening
      if (r<17) p[5]= WHITE+BG;
      p+= 40-1;
    }
  }

  // color the C blue
  wait(30);
  fill(6, 2, 18, 1, CYAN); // too bright
  fill(6, 2, 18, 1, BLUE); // too dark, lol AIC?

  // print red frame label "MINIMAL" in a box
  if (1) {
    char row= 13, col= 25;
    wait(30);
    fill(row, col++, 4, 1, RED);
    splot(row++, col, "\x37\x23\x23\x23\x23\x23\x23\x23\x23\x23\x4b");
    splot(row++, col, "\x35\x0aMINIMAL\x0b\x4a");
    splot(row++, col, "\x35\x0aMINIMAL\x0b\x4a");
    splot(row++, col, "\x55\x50\x50\x50\x50\x50\x50\x50\x50\x50\x5a");
  }

  wait(30);
  tplot(2,  4+9*8, "jsk@yesco.org");

 A:
  goto A;
}
