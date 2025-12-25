typedef unsigned int word;

// $bb80 #xbb80
char* SCREEN= (char*)46000U;
char* CHARDEFS= (char*)4680U;

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

  while(h > 0) {
    i= w;
    while(i-- > 0) p[i]= v;
    p+= 40;
  }
}

void lores(char m) {
  m= m==1? ALT: NORMAL;

  // 32 is space, or in mode 1 no pixel set
  fill(0, 0, 28, 40, 32);

  // 0-1 => 8->9
  fill(0, 0, 28, 1, NORMAL+m);
}

void setpixel(char x, char y) {
  char* p= y /3 *40 +SCREEN;
  char r= y %3, c= x &1, v;
  x/= 2;
  if (x==1 && y==2) v= 64; // exception
  p[x] |= v;
}

char* chardef(char c) {
  return (c <<3) + CHARDEFS;
}

void plotchar(char x, char y, char ch) {
  char* p= chardef(ch);
  char r, c, v;

  // TODO: wrap?
  x+= 6;

  for(r= 0; r<8; ++r) {
    v= *p++;
    for(c= 0; c<6; ++c) {
      --x;
      if (v & 1) setpixel(x, y);
      v/= 2;
    }
    ++y;
  }
}

void plot(char x, char y, char* s) {
  while(*s) {
    // TODO: wrap?
    plotchar(x, y, *s++);
    x+= 6;
  }
}

word main() {
  lores(1);
  plot(10,10,"Hello ORIC ATMOS 48K");
  return 0;
}
