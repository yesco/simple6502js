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

word main() {
  lores(1);

  fill(0, 1, 25, 1, WHITE+BG);
  fill(0, 2, 25, 1, BLACK);

  //             123456789012
  tplot(6,  1+0*7, "The MeteoriC");
  tplot(6,  1+1*7, "Programming");
  tplot(6,  1+2*7, "Language");

  // print a big C!
  if (1) {
    char *b= bigC;
    // AFTER
    char y= 3*7, x;
    char i,n;
    do {
      for(n=3; --n; ) {
        x= 20; ++y;
        for(i=0; i<40; ++i) {
          if (b[i]>' ') setpixel(x, y);
          ++x;
        }
      }
      b+= 40;
    } while (*b);
    // reverse!
    do {
      b-= 40;
      for(n=3; --n; ) {
        x= 20; ++y;
        for(i=0; i<40; ++i) {
          if (b[i]>' ') setpixel(x, y);
          ++x;
        }
      }
    } while(*b);

    fill(8, 2, 16, 1, CYAN); // too bright
    fill(8, 2, 16, 1, BLUE); // too dark, lol AIC?
  }

  // print red frame label "MINIMAL" in a box
  if (1) {
    fill(15, 26, 4, 1, RED);
    //plot(55, 50, "mini");
    splot(15, 27, "\x37\x23\x23\x23\x23\x23\x23\x23\x23\x23\x4b");
    splot(16, 27, "\x35\x0aMINIMAL\x0b\x4a");
    splot(17, 27, "\x35\x0aMINIMAL\x0b\x4a");
    splot(18, 27, "\x55\x50\x50\x50\x50\x50\x50\x50\x50\x50\x5a");
  }

  //             123456789012
//tplot(6,    8*8, "jsk@yesco.org");
//tplot(6,  4+9*8, "JS Karlsson");
  tplot(2,  4+9*8, "jsk@yesco.org");

 A:
  goto A;
}
