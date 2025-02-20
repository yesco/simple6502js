#define MAIN
#include "../hires-raw.c"

//include <stdio.h>
#include <stdlib.h>

// dummy
char T,nil,print,doapply1;



#define K 0
#define R 1
#define G 2
#define Y 3
#define B 4
#define M 5
#define C 6
#define W 7

#define CLR  (0+64)
#define SOME (3+64)
#define ODD  (2+8+32+64)
#define EVEN (1+4+16+64)
#define RND1 42 // lol
#define RND2 43 // lol
#define RND3 44 // lol
#define RND4 45 // lol
#define RND5 46 // lol
#define RND6 47 // lol
#define MORE (1+3+64)
#define FILL (63+64)

char baseline;

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

// draws mountains bottom up, difficult...
void upmountain(char rnd, char col, char base, char height, char steps) {
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

// TODO: idea, parallax: generate different from display...

// TODO: use mask, now only 0 or 1... need special draw?
void mountain(char rnd, char base, char height, char steps, char mask) {
  char x, btm= baseline+base+height, h= height/2, ty;
  signed char r= 0;
  int y= baseline-h, t= 1;

  srand(rnd);
  x= 12;
  gmode= mask;
  while(x<239) {
    // generate delta changes every frew random(steps)
    if (--t < 2) {
      // TODO: less negative the higher? (distored faster drop?)
      // TODO: use & and get step/plateu effects?
      r= (rand()%height) - h;
      t= (rand()%steps)+1;
      ///printf(" %d:", col);
    }
    // one step
    if (r) {
      if (r<0) --y,++r; else ++y,--r;
    }
    // big dleta: step faster
    if (r<-height*3/4 || r>height*3/4) {
      //y+= (r/=2); x+= (rand()&15) < 4;
      y+= (r<0?(++r,-1):(--r,+1));
      // sometimes step up/down faster
      if (rand()&2) continue;
    }
    ++x;

    // no go below baseline
    if (y>baseline) y= baseline;

    // no top, so can overlap previous
    //if (y<top) y= top;
    if (y<0) y= 0;

    gcurx= x;
    ty= x2topy[x]; // TODO: ++array for speed
    //if (ty) {
      gcury= ty+1; draw(0, y-ty, gmode);
    //} else { gcury= y; setpixel(); }

    x2topy[x]= y;
    //printf("%d: %d %d\n", col, t, r);
  }

  baseline= btm-1;
}

void lines(char rnd, char paper, char ink, char height, char steps, char mask) {
  //printf(" L%d%d:%d (%d)", paper,ink,height,baseline);
  if (!height) return;
  baseline-= height;

  if (mask<RND1 || mask>RND6) {
    gfill(0, baseline, 40, height, 64|mask);
  } else if (0) ; else {
    char n, m, * p= rowaddr[baseline-1]-1, * e= rowaddr[baseline+height-1];
    putchar('.');
    while(p<e) {
      // do N RND
      n= mask-RND1+1;
      m= 63; do { m&= rand(); } while(--n);
      // write it
      *++p= 64 | (m&63);
    }
  }
  gfill(0, baseline,  1, height, paper+16);
  gfill(1, baseline,  1, height, ink);
}

void main() {
  char t, i, n=0;
  signed char r;

  hires();

do {
  gclear();

  gotoxy(0, 25);
  printf("Generate World!");

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
  n= (t<<7) ^ t;

  srand(n);

  baseline= 0;
  memset(x2topy, 0, sizeof(x2topy));


  if (0) {
  // -- draw mountain top down
  gfill(0, 0, 1, 200, B); // blue ink col 0

  mountain(++n, 0,  8, 50, CLR);    // clear/draw black
  mountain(++n, 0, 10, 40, FILL);   // blue
  mountain(++n, 0, 30, 32, EVEN);   // every other (line)
  mountain(++n, 0, 50, 16, CLR);    // black front shadow
  }

  // -- draw laysers bottom up
  baseline= 200;


  // just test RNDn
  if (0) {
  lines(++n, B, K, 16,  0, RND6);
  lines(++n, B, K, 16,  0, RND5);
  lines(++n, B, C, 16,  0, RND4);
  lines(++n, C, B, 16,  0, RND1);
  lines(++n, C, G, 16,  0, RND2);
  lines(++n, C, R, 16,  0, RND2);
  continue;
  }


  // - water random sizes
  srand(++n);
  if (rand()&1) {
    srand(++n); lines(++n, B, K, rand() & 3,  0, RND1); // black/blue
    srand(++n); lines(++n, B, C, rand() & 3,  0, RND3); // blue
    srand(++n); lines(++n, B, C, rand() & 7,  0, RND3); // blue/cyan
    srand(++n); lines(++n, C, B, rand() & 7,  0, RND3); // cyan/blue
    srand(++n); lines(++n, C, W, rand() & 1,  0, RND5); // white border
    srand(++n); lines(++n, C, G, rand() & 1,  0, RND4); // green border
  }

  // - soil/green
  srand(++n); lines(++n, G, R, rand() &  1, 16, RND6);
  srand(++n); lines(++n, G, Y, rand() &  1, 60, RND1);
  srand(++n); lines(++n, G, R, rand() &  1, 16, RND5);
  srand(++n); lines(++n, G, G, rand() &  3, 16, RND1);

  // - vegetation
  srand(++n); lines(++n, G, G, rand() & 3, 16, FILL);
  switch(rand()&3) {
  case 0: grass(++n, G, 2, 3);       break; // green grass
  case 1: grass(++n, Y, 2, 8+1+2);   break; // yellow tall grass
  case 2: grass(++n, Y, 0, 32+1);    break; // bamboo
  case 3: grass(++n, R, 0, 16+1+4);  break; // twigs TODO not good?
  }

  // - flowers random in front
  // - houses
  // - trees
  // - fences
  // - flowers random in front of bushes/twigs
  // - bushes/twigs
  // - flowers random in background

} while(t=cgetc());

}
