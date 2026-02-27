// Game: ByteWalker grafix interpreter

// all 3 lines ignored by MeteoriC!
#define MAIN
#include "../hires-raw.c"
#include "../sound.c"
typedef unsigned int word;
#define curset(x,y,c) CURSET(x,y,c)
#define hires() hires();gclear();
// sfx disables keyboard, lol
#define sfx(a)

// dummies
word T,nil,doapply1,print;

//#include <stdio.h> // 3152
//#include <conio.h> // 2899

//#include <atmos.h>
//#include <tgi.h>

word i, j, x, y, d, lives, spacek;

// give a random nubmer [0..below[
word _r, _m; // locals
word random(word below) {
  // make a bigger than below bitmask
  _m= 1;
  while(_m < below) _m*= 2;
  --_m;

  do {
    _r= rand() & _m;
  } while (_r >= below);
  return _r;
}
  
word _area, _w, _h, _c, _s; // locals
word randombox() {
  x= random(38);
  y= random(150);

  _area= random(30) + 2;

  _w= random(15) + 2;
  if (x+_w>40) _w= 40-x;

  _h= 6*_area/_w + 6;
  if (y+_h>200) _h= 200-y;

  _c= random(7)+1; // 1-7 avoid black

  // make sure no overlap with existing!
  _s= 0;
  for(i= y; i<y+_h; ++i)
    for(j= x; j<x+_w; ++j)
      _s+= HIRESSCREEN[i*40+j]&(255-64);

  // something there...
  if (_s) return 0;

  // A block INVERTED fills as follows
  // ink colors on the right _c
  gfill(x, y, _w, _h, _c+128);
  // first col: background invertse _c
  gfill(x, y, 1, _h, _c+128+16);
  // last col: backgroudn inverse black
  gfill(x+_w-1, y, 1, _h, 0+128+16);
}

word move(word b) {
  while(b) {
    if (b&128) {
      x+= d; if (x>=240) x= 6;
    } else {
      y+= d; if (y>=200) y= 0;
    }
    if (point(x, y) && !(*gcurp & 128)) {
      sfx(SHOOT);
      ++d; // make it harder
      if (lives) --lives;
      gfill(0, 0, 1, 200, lives+16);
      gfill(1, 0, 1, 200, 0);
    }
    curset(x, y, 1);
    b*= 2;
    b&= 0xff;
  }
}

void main() {
  spacek= keypos(' ');

  putchar(17); // ^O cursor off
  putchar(6); // ^F keyclick off

  clrscr();

  do {
    // start new game
    clrscr();
    hires();
    sfx(PING);
    
    do {
      randombox();
    } while(getchar()==' ');

    x= 5; y= 0; lives= 7; d= 1;

    do {
      move(cgetc());
      wait(5);
    } while(lives);

    // Dead
    text();
    sfx(EXPLODE);

    y= 0;
    do {
      ++lives; lives&= 127;
      paper(lives & 7);
      for(i= 0; i<lives; ++i) putchar(' ');
      printf("DEAD");
      //wait(1);
    } while(!keypressed(spacek));
    sfx(ZAP);

  } while(1);
}
