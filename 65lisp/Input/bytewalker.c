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

// wow, no keyclicks!
int mygetc() {
  int x;

  do {
    asm("jsr $EB78");
    asm("ldx #0");
    x= __AX__;
} while(!x);

  return x;
}

// dummies
word T,nil,doapply1,print;

//#include <stdio.h> // 3152
//#include <conio.h> // 2899

//#include <atmos.h>
//#include <tgi.h>

word dollar;
word n, i, j, x, y, d, lives, spacek;

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
  
word _x, _y, _area, _w, _h, _c, _s; // locals
word randombox() {
  _x= random(38);
  _y= random(150);

  _area= random(100) + 2;

  _w= random(15) + 2;
  if (_x+_w>40) _w= 40-_x;

  _h= 6*_area/_w + 1;
  if (_y+_h>200) _h= 200-_y;

  _c= random(7)+1; // 1-7 avoid black

  // make sure no overlap with existing!
  _s= 0;
  for(i= _y; i<_y+_h; ++i)
    for(j= _x; j<_x+_w; ++j)
      _s+= HIRESSCREEN[i*40+j]&(255-64);

  // something there...
  if (_s) return 0;

  // A block INVERTED; fills as follows
  // ink colors on the right _c
  gfill(_x, _y, _w, _h, _c+128);
  // first col: background invertse _c
  gfill(_x, _y, 1, _h, _c+128+16);
  // last col: backgroudn inverse black
  gfill(_x+_w-1, _y, 1, _h, 0+128+16);
}

word placedollar() {
  _x= random(27)+10;
  _y= random(120)+80;

  _area= random(20) + 2;

  _w= random(8) + 3;
  if (_x+_w>40) _w= 40-_x;

  _h= 6*_area/_w + 1;
  if (_y+_h>200) _h= 200-_y;

  _c= 4; // yellow money (inverted blue)

  // make sure no overlap with existing!
  if (0) {
    _s= 0;
    for(i= _y; i<_y+_h; ++i)
      for(j= _x; j<_x+_w; ++j)
        _s+= HIRESSCREEN[i*40+j]&(255-64);

    // something there...
    // if (_s) do again
  }

  // A block INVERTED; fills as follows
  // ink colors on the right _c
  gfill(_x, _y, _w, _h, dollar);
  // first col: background invertse _c
  gfill(_x, _y, 1, _h, _c+128+16);
  // last col: backgroudn inverse black
  gfill(_x+_w-1, _y, 1, _h, 0+128+16);
}


word step(word b) {
  if (b) {
    ++x; if (x>=240) x= 12;
  } else {
    ++y; if (y>=200) y= 0;
  }
}

word win() {
  zap();
  i= 3;
  while(x+i<200 && y+i<240 && x-i>12 && y>5) {
    curset(x, y, 3);
    circle(i, 2);
    i++;
  }
  return 0;
}

word _u; // local
word walk(word b) {
  // This will interpret each git until
  // no more bit set, shifting up
  _u= 0;

  play(1, 0, 0, 380);

  while(b) {

    // do d pixel steps for each bit
    i= d; do {

      if (!_u) 
        sound(1, b+lives, 10);
      else
        sound(1, b+lives + _u, 10);

      step(b&128);
      wait(lives/2+7);
      // detect hit path walked before
      // or hti block
      if (point(x, y) || (*gcurp & 128)) {

        // win?
        if (*gcurp == dollar)
          return win();

        // first hit this block
        if (i<8) {
          shoot();
          freq(2, 220+lives*2, 15);
          ++d; // make it harder
          if (lives) --lives;
          // chagne back color (count down)
          gfill(0, 0, 1, 200, lives+16);
          gfill(1, 0, 1, 200, 0);
        }
        ++_u;

        // if it's "colour" attribute - takeit over!
        if ((*gcurp & 128) && ((*gcurp & 127) < 8))
          *gcurp= 64+128;
        curset(x, y, 1);

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

  // silencio
  play(0, 0, 0, 0);
  return 1;
}

word won, level, score;
void main() {
  // init "constants"
  spacek= keypos(' ');
  dollar = '$'+64+128; // graphics, inverted

  level= 0;

  // cursor off - TODO: not working
  poke(0x22d, 0);
  // keyclick off - TODO: not working
  poke(0x22e, 0);

  do {

    // prepare
    clrscr();
    hires();
    ping();

    srand(level+42);

    // fill screen with boxes
    if (0)
    do {
      randombox();
    } while(getchar()==' ');

    placedollar();

    // start game
    x= 5; y= 0; lives= 7; d= 1; n= 0;

    // loop
    do {
//      asm("cli");
//      *(char*)0x30f=0xff;
//      *(char*)0x30c=0xdd;

// good, enables all keys
      asm("jsr $E93D"); // reenable keyboard & intr

//      poke(0x380, 0x00);
     won= !walk(mygetc());
        
//      walk(cgetc());
//      wait(5);

//      if (random(100)<10) randombox();
      if (!(++n & 7)) randombox();
      sprintf(SCREENXY(2,26), DOUBLE BGWHITE BLUE "Level: %d Lives: %d Loscore %d    ",
             level, lives, n);
      sprintf(SCREENXY(2,27), DOUBLE BGWHITE BLUE "Level: %d Lives: %d Loscore %d    ",
             level, lives, n);

    } while(lives && !won);

    // Dead?
    if (won) {

      // win
      text();
      clrscr();
      zap();

      ++level;

    } else{

      // loose
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

      // TODO: try again save level
    }
      
  } while(1);
    
}
