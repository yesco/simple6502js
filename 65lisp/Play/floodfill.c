#include "fillpict.c"

char x, y, dx= 0, dy= 1;

void rotate() {
  // dx dy
  // 0  1
  // -1 0
  // 0 -1
  // 1  0
  // 0  1
  char ox= dx;
  dx= -dy; dy= ox;
}

char alldown() {
  char n= 0;
  char nx, ny;
  do {
    nx= x+dx; ny= y+dy;
    if (nx<0 || ny<0 || nx>239 || ny>199) break;
    if (point(nx, ny)) break;
    x= nx; y= ny; ++n;
    CURSET(x, y, 1);
  } while (1);
  return n;
}

void floodfill() {
  char c= div6[x], * e= HIRESSCREEN+HIRESSIZE;
  char n;

  // down, left
  do {
    alldown();
    if (x>0 && !point(x-1, y)) --x; else break;
  } while(1);

  // at local bottom left

  // fill line (don't lock in)
  if (!point(x+1, y)) ++y;
  
  while(x<238 && !point(x+1, y) && !point(x+1, y-1)) ++x;

  // down, left
if (0)
  while(1) {
    while(gcurp<e && (gcurp[40]&127)==64) { *gcurp^= 128; gcurp+= 40; }
    if ((gcurp[-1]&127)==64 && c) { *gcurp^= 128; --c; --gcurp; }
    gotoxy(0, 25); printf("col=%d %02x ", c, gcurp[-1]);
  }
}

  if (1) {
    //GenerateTables();  // Only need to do that once
    //memcpy((unsigned char*)0xa000,LabelPicture,8000);
    memcpy(HIRESSCREEN, fillpict, HIRESSIZE);
    //{ char* p= HIRESSCREEN; char i; for(i=0; i<200; ++i) { *p=7-3; p+= 40; } }
    if (1) { //while(!kbhit()) {
      unsigned int T= time();
      //doke(630,0);
      //paint(120,100);
      //xorfill(2);
      printf("xor Filling: %u hs", T-time());
      x= 120; y= 100; floodfill();
      //wait(100);
    }
    cgetc();
    gclear();
  }

