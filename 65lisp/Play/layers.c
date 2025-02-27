// ORIC ATMOS
// ----------
// Graphic layers mode
//
// $9800: HIRES-ASCII-charset for last 3 lines
// $9C00: HIRES-ALT-charset for last 3 lines
// $A000: HIRES-screen
//  row 0-155?
// 
//($B400: ASCII-charset for text - not there!)
// $B800: ALT-charset for text
// $BB80: TEXT-screen
//   this area can't use the ASCII, only ALT-set
//   by setting the right attribute
//   first on every row
// $BF68: 3 lines TEXT-SCREEN (row 25-26-27)
//   this one uses the HIRESCHARSET,
//   and HIRESALT
// $BFDF: last char on text-screen

#define MAIN
#include "../hires-raw.c"

// Anything, actually should be animations?
char FONT[]= {
  #include "../prop-8x3-4.font"
};

// dummy
char T,nil,doapply1,print;

void main() {
  char * altset= ALTSET+32*8;
  char row= (altset-HIRESSCREEN)/40;
  int i;

  // hires screen
  hires();
  gclear();
  gcurx= 120; gcury= 100; circle(99, 1);

  wait(-100); cgetc();

  // just before ALTSET
  altset[-1]= TEXTMODE+128;
  // alt-set for text-mode
  memcpy(altset, FONT, sizeof(FONT));

  // lores(0)
  //fill(0, 0, 40,25, ' ');
  fill(0, 0, 1, 25, *ALTCHARS);

  for(i=32; i; ++i) {
    if (i/32==26) break;
    *SCREENXY(1+i%32, i/32)= 32+i%96;
  }

  // make over-layer
  wait(-100); cgetc();

   fill(1,  0, 1,  20, 'a');
   fill(2,  0, 1,  20, HIRESMODE+128);

  gfill(19, 0, 1, row, TEXTMODE+128);
   fill(20, 0, 1,  20, 'b');
   fill(21, 0, 1,  20, HIRESMODE+128);

  gfill(38, 0, 1, row, TEXTMODE+128);
   fill(39, 0, 1,  20, 'c');

  for(i=0; i<40; ++i) {
    *SCREENXY(i, 0)= 'd';
  }

   fill(1,  9,38,   1, 'e');
   fill(1, 10,38,   1, 'f');
   fill(1, 11,38,   1, 'g');
   fill(1, 20,38,   1, 'h');

  wait(-100); cgetc();
  fill(0, 0, 1, 25, *ALTCHARS);
  altset[-1]= TEXTMODE+128;

  wait(-100); cgetc();

  // fill last 3 lines with ASCII-table
  for(i=32; i<128; ++i) {
    *SCREENXY(i%32, 24+(i/32))= i;
  }

  wait(-100); cgetc();
  // just before last 3 lines
  *SCREENXY(39,24)= HIRESMODE+128;

  // just before ALTSET
  altset[-1]= TEXTMODE+128;
  // at end of screen
  *(char*)0xbfdf= TEXTMODE+128;

  while(1) {
    memmove(altset, altset+1, 96*8-1);
    wait(7);
  }
}
