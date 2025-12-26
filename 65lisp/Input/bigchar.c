#include <stdio.h>

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

void plot(char x, char y, char* s) {
  while(*s) {
    // TODO: wrap?
    plotchar(x, y, *s++);
    x+= 6;
  }
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
 "\0"
// <14
};

word main() {
  lores(1);

  fill(0, 1, 25, 1, WHITE+BG);
  fill(0, 2, 25, 1, BLACK);

  //             123456789012
  plot(6,  1+0*8, "The C");
  plot(6,  1+1*8, "Programming");
  plot(6,  1+2*8, "Language");

  if (1) {
    // print a big C!
    char *b= bigC;
    // AFTER
    char y= 3*8+2, x;
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

    fill(9, 2, 16, 1, BLUE);
  }

  //             123456789012
//plot(6,    8*8, "jsk@yesco.org");
//plot(6,  4+9*8, "JS Karlsson");
  plot(2,  4+9*8, "jsk@yesco.org");

 A:
  goto A;
}
