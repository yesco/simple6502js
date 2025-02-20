#define MAIN
#include "../hires-raw.c"

//include <stdio.h>
#include <stdlib.h>

// dummy
char T,nil,print,doapply1;

char baseline= 200;

// height is bits anded with rand!
void grass(char rnd, char col, char base, char height) {
  char x, r;

  gfill(0, baseline-base-height, 1, base+height, col);

  srand(rnd);
  for(x=12; x<240; ++x) {
    r= x&1? rand() & height: 0;

    gcurx= x; gcury= baseline; draw(0, -r-base, 2); // draw up
  }

  baseline-= base+height;
}

void xorpixfillup(char x, char y) {
  char *p= rowaddr[y]+div6[x], m= PIXMASK[mod6[x]];
  // up: find first pixel
  while(!(*(p-=40) & m));
  if (p<HIRESSCREEN) return;
  // set till next pixel
  while(!(*p-=40) & m) *p|= m;
}

char x2topy[240]= {0};

void mountain(char rnd, char col, char base, char height, char steps) {
  char x, top= baseline-base-height-1, h= height/2, ty;
  signed char r= 0;
  int y= baseline-h, t= 1;

  gfill(0, 0, 1, baseline+1, col);

  srand(rnd);
  x= 12;
  gmode= 1;
  while(x<239) {
    if (--t < 2) {
      r= (rand()%height) - h;
      t= (rand()%steps)+1;
      ///printf(" %d:", col);
    }
    if (r) {
      if (r<0) --y,++r; else ++y,--r;
    }
    // step faster if big change
    if (r<-height*3/4 || r>height*3/4) {
      //y+= (r/=2); x+= (rand()&15) < 4;
      y+= (r<0?(++r,-1):(--r,+1));
      // only one pixel per x (requirement from xorfill)
      if (rand()&2) continue;
    }
    ++x;
    if (y>baseline) y= baseline;
    if (y<top) y= top;

    gcurx= x;
    ty= x2topy[x]; // ++
    if (ty) {
      gcury= ty+1; draw(0, y-ty, 1);
    } else { gcury= y; setpixel(); }
    x2topy[x]= y;
    //printf("%d: %d %d\n", col, t, r);
  }

  baseline= top-1;
}

void main() {
  char t, i, n=0;
  signed char r;

  hires();
  gclear();

  gotoxy(0, 25);
  printf("Generate World!\n");

  // === world
  // -- upper sky - cyan - clouds?
  // -- blue sky every second dot . . . . .
  // -- middle sky - blue maybe random black dots
  // -- distant mountain - black/blue
  // -- siluette trees
  // -- siluette buildings
  // -- dark mountain - black 
  // -- forest: black: stripe blue, tree truncs, ove black, branches random

  // -- land
  // - trees AIC: red/green, black shadow around
  // - buildings: brick, special shape+door+window - red/black
  // - grass - green every second pixel
  // - straw - yellow every second pixel
  // - flowers
  // - bushes
  // - moving baseline
  // - soil - green/yellow
  // - soil - green/red

  // -- water
  // - water cyan/white
  // - grass in water pixels?
  // - water - blue
  // - water - black

  // init
  n= 0;
  memset(x2topy, 0, sizeof(x2topy));

  // draw laysers bottom up
  grass(++n, 2, 2, 3);           baseline-= 10;
  grass(++n, 3, 2, 1+2+8);       baseline-= 10;

  mountain(++n, 4, 0, 50, 16);
  mountain(++n, 6, 0, 30, 32);   baseline-= 30;
  mountain(++n, 7, 0, 10, 40);
}
