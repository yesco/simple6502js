// Game: ByteWalker grafix interpreter

// all 3 lines ignored by MeteoriC!
#define MAIN
#include "../hires-raw.c"
#include "../sound.c"
typedef unsigned int word;
#define curset(x,y,c) CURSET(x,y,c)
#define hires() do { hires();gclear(); } while(0)
#define poke(a, v) (*(char*)a)= v

#define call(a) (((*)())a)()
//typedef (*f)(

#define ping() asm("jsr $fa9f")
#define shoot() asm("jsr $fab5")
#define explode() asm("jsr $facb")
#define zap() asm("jsr $fae1")

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

  _area= random(100) + 2;

  _w= random(15) + 2;
  if (x+_w>40) _w= 40-x;

  _h= 6*_area/_w + 1;
  if (y+_h>200) _h= 200-y;

  _c= random(7)+1; // 1-7 avoid black

  // make sure no overlap with existing!
  _s= 0;
  for(i= y; i<y+_h; ++i)
    for(j= x; j<x+_w; ++j)
      _s+= HIRESSCREEN[i*40+j]&(255-64);

  // something there...
  if (_s) return 0;

  // A block INVERTED; fills as follows
  // ink colors on the right _c
  gfill(x, y, _w, _h, _c+128);
  // first col: background invertse _c
  gfill(x, y, 1, _h, _c+128+16);
  // last col: backgroudn inverse black
  gfill(x+_w-1, y, 1, _h, 0+128+16);
}

word step(word b) {
  if (b) {
    ++x; if (x>=240) x= 12;
  } else {
    ++y; if (y>=200) y= 0;
  }
}

word move(word b) {
  // This will interpret each git until
  // no more bit set, shifting up
  while(b) {

    // set d pixel steps for each bit
    i= d; do {
      step(b&128);
      // detect hit path walked before
      // or hti block
      if (point(x, y) || (*gcurp & 128)) {

        // first hit this block
        if (i<8) {
          shoot();
          ++d; // make it harder
          if (lives) --lives;
          // chagne back color (count down)
          gfill(0, 0, 1, 200, lives+16);
          gfill(1, 0, 1, 200, 0);
        }

        // keep going till out of block
        i= 255;
      } else {
        // setpixel
        --i; if (i>8) i= 0;
        curset(x, y, 1);
      }
    } while(i);

    b*= 2;
    b&= 0xff;
  }
}

void main() {
  spacek= keypos(' ');

  // cursor off
  poke(0x22d, 0);
  // keyclick off
  poke(0x22e, 0);

  do {
    // prepare
    clrscr();
    hires();
    ping();
    
    // fill screen with boxes
    do {
      randombox();
    } while(getchar()==' ');

    // start game
    x= 5; y= 0; lives= 7; d= 1;

    // loop
    do {
      move(cgetc());
      wait(5);
    } while(lives);

    // DEAD
    explode();
    text();

    lives= y= 0;
    do {
      ++lives; lives&= 127;
      paper(lives & 7);
      for(i= 0; i<lives; ++i) putchar(' ');
      printf("DEAD");
      //wait(1);
    } while(!keypressed(spacek));
    zap();

  } while(1);
}
