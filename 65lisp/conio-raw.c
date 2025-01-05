// CONIO-RAW 
//
// A raw, NON-ROM-less implementation of display and
// keyboard routines for ORIC ATMOS.
//
// Intended to be used under Loci
// 
// (c) 2024 Jonas S Karlsson (jsk@yesco.org)

// TDOO: protect the first 2 columns
// TODO: capslock
// TODO: disable ROM cursor?
// TODO: kbhit, cgetc - don't give repeat directly...
// TODO: kbhit, cgetc - no buffer, so miss keystroke?
// TODO: hook it up to interrupts and buffer!

// Modelled on and replacing cc65 <conio.h>

// Functions:
// - time() - hundreths of second (hs)
// - wait(hs) 

// - clrscr()
// - paper(c)
// - ink(c)
// - gotoxy(x, y)
// - cputc(c)
// - putchar(c) - macro
// - wherex()
// - wherey()
// - revers() - TODO
// - cputsxy(x, y, s) - doesn't update cursor pos
// - puts(s)
// - printf(fmt, ...) - uses sprintf
// 
// - kbhit()
// - cgetc()

// Additions:
// - SCREENXY(x, y) - gives address *SCREENXY(0,0)='A'
// - savecursor()
// - restorecursor()
// - scrollup(rows)
// - putint(i)

// - key(row, colmask)
// - keypos(c)
// - keypresed(keypos)

// Unixy:
// - ungetchar(c)
// - getchar() - macro

#include <string.h>
#include <stdarg.h>
#include <stdio.h>

// TextMode
// TODO: how to solve graphics mode?
#define CHARSET    ((char*)0xB400) // $B400-B7FF
#define CHARDEF(c) ((char*)0xB400+c*8)
#define ALTSET     ((char*)0xB800) // $B800-BB7F
#define TEXTSCREEN ((char*)0xBB80) // $BB80-BF3F
#define SCREENROWS 28
#define SCREENCOLS 40
#define SCREENSIZE (SCREENROWS*SCREENCOLS)
#define SCREENEND  (TEXTSCREEN+SCREENSIZE)

// hundreths of second
unsigned int time() {
  // ORIC TIMER 100 interrupts/s,
  // TODO: my own? no ROM...
  return *(unsigned int*)0x276;
}

char kbhit();

// wait HS hectoseconds
// -HS: wait till HS or keystroke
// 
// Returns: 0 for +HS
//   -hs waited if key pressed
//   +hs waited (i.e. HS actual)
int wait(int hs) {
  unsigned int t= time(), r;
  char k= hs<0? (hs=-hs,1): 0;
  while((r=t-time()) < hs) {
    if (r>=0x8000) t+= 0x8000; // correct? LOL
    if (k && kbhit()) { k=2; break; }
  }
  return (1-k)*r;
}

// *SCREEN(X,Y)='A';
#define SCREENXY(x, y) ((char*)(TEXTSCREEN+40*(y)+(x)))

char curx=0, cury=0, *cursc= TEXTSCREEN;

#define wherex() curx
#define wherey() cury

char savex=0, savey=0;

#define savecursor() do { savex= wherex(); savey= wherey(); } while(0)
#define restorecursor() gotoxy(savex, savey)

void cputc(char c);

void gotoxy(char x, char y) {
  curx= x; cury= y;
  cputc(0);
}

// TODO: what's ORIC wherey() default? 0 or 1
void clrscr() {
  // Don't clear status line (/)
  cursc= TEXTSCREEN;
  memset(cursc+40, ' ', (SCREENROWS-1)*SCREENCOLS);
  curx= 0; cury= 1;
  cputc(0);
  return;
}

void fill(char x, char y, char w, char h, char c) {
  // TODO: adjust so not out of screen?
  // TODO: and use for hires?
  char* p= SCREENXY(x, y);
  for(; h; --h) {
    // TODO: is memset faster?
    for(x= w; x; --x) *p=c,++p;
    p+= 40-w;
  }
}

char curpaper= 0, curink =7;

void paper(char c) {
  curpaper= c & 7;
  fill(0,1, 1,SCREENROWS-1, c | 16);
// scrollbar?
//  fill(0,1,  1,7,  (c & 7)|16+0);
//  fill(0,8,  1,12, (c & 7)|16+128);
//  fill(0,21, 1,5,  (c & 7)|16+0);
}

void ink(char c) {
  curink= c & 7;
  fill(1,1, 1,SCREENROWS-1, (c & 7));
}

// TODO:
//void revers(char) {}
void revers();

// TODO: in curmode=HIRESMODE then scroll only last 3 lines!
void scrollup(char n) {
  memcpy(TEXTSCREEN, TEXTSCREEN+40, (28-n)*40);
  memset(TEXTSCREEN+(28-n)*40, ' ', 40*n);
  *(SCREENEND-40)= curpaper;
  *(SCREENEND-39)= curink;
  cury= 27;
  cputc(0);
}

// TODO: add new terminal controls

// - home
// - gotoxy x y - hmmm 0,0 ???
// - repeat n c

// - print in status line col nchars text.... \n
// - nowrap / wrap (autonl)

// - clear till end of line
// - clear to end of screen
// - clear whole line

// - save screen
// - restore screen

// - cursor on
// - cursor off

// - reverse on
// - reverse off

#define SAVE    "\x1d"
#define RESTORE "\x1e"
#define NEXT    "\x1f"

void cputc(char c) {
  if ((c & 0x7f) < ' ') {
    if (c < 128) {
      // control-codes
      switch(c) {
      case  7  : break; // TODO: bell?
      case  8  : --curx; --cursc; break;     // back
      case  9  : ++curx; ++cursc; break;     // forward
//    case 10  : ++cury; cursc+= 40; break;  // down ?
      case 11  : --cury; cursc-= 40; break;  // up
      case 12  : clrscr(); return;
      case '\r': curx= 0; break;
      case '\n': curx= 0; ++cury; break;
//    case '\r': curx= 0; break;

      case 0x1a: 
      case 0x1b: break; // ESC
      case 0x1c: 
      case 0x1d: savecursor(); break;
      case 0x1e: restorecursor(); break;
      case 0x1f: restorecursor(); savey= ++cury; break;
      }
      // fix state
      if (curx==255) --cury,curx=39;
      else if (curx>=40) ++cury,curx=0;

      if (cury==255) cury=0; // TODO: scroll up?
      else if (cury>=28) { scrollup(cury-27); return; }

      //if (cursc<TEXTSCREEN) cursc= TEXTSCREEN;
      //else if (cursc>=SCREENEND);

      cursc= SCREENXY(curx, cury);

      return;
    }
  }
  // 32-127, 128+32-255 (inverse)
  *cursc= c; ++cursc;
  if (++curx>=40) { ++cury; curx=0; }
  if (cury>=28) scrollup(cury-27);
}

//int putchar(int c) { cputc(c); return c; }
#define putchar(c) (cputc(c),c)

// raw?
void cputsxy(char x, char y, char* s) {
  char *p = SCREENXY(x,y);
  while(*s) *p=*s,++p,++s;
}

int puts(const char* s) {
  const char* p= s;
  if (!s) return 0;
  while(*p) putchar(*p),++p;
  return p-s;
}


char* spr= NULL; size_t sprlen= 0;

#include <stdlib.h>

// maybe faster than printf
void putint(int n) {
  if (n<0) { putchar('-'); n= -n; }
  if (n>9) putint(n/10);
  putint('0'+(n%10));
}

int printf(const char* fmt, ...) {
  int n= 0;
  va_list argptr;
  va_start(argptr, fmt);
  do {
    n= spr? vsnprintf(spr, sprlen, fmt, argptr): 0;
    //putchar('['); printnum(n); putchar(']');
    if (!n || n>sprlen) {
      sprlen= (n>sprlen)?n+30: 80;
      spr= realloc(spr, sprlen);
      n= 0;
    }
  } while(!n);
  puts(spr);
  va_end(argptr);
  return n;
}

#define CTRL 1-'A'
#define META 128

// key encoding
// 0-31 : CTRL+'A' ... 'Z' ((CTRL==-64)
// 13   : KRETURN
// 27   : KESC
// 32   : ' '
// ...
// 127  : KDEL
// 128  : KFUNCT
// ...
// 128+ 8: KLEFT
// 128+ 9: KLEFT
// 128+10: KLEFT
// 128+11: KLEFT
// ...
// 128+'A': KFUNCT+'A' (KFUNCT=128)
// ...
// 128+'Z'
// 128+'a': funct ctrl

// --- key codes
#define KEY_RETURN  13
#define KEY_ESC     27
#define KEY_DEL    127

// ORIC keyboard routines gives 8-11 ascii
// - I choose to distinguish these from CTRL-HIJKEY_
#define KEY_LEFT   128+ 8
#define KEY_RIGHT  128+ 9
#define KEY_DOWN   128+10
#define KEY_UP     128+11

#define KEY_RCTRL  128+1
#define KEY_LCTRL  128+2
#define KEY_LSHIFT 128+3
#define KEY_RSHIFT 128+4

// TODO: function keys FUNCT+1 2 3 ...
#define KEY_FUNCT  128

// --- key strings (for use to construct maps)
#define KRETURN "\x0d" //  13
#define KESC    "\x1b" //  27
#define KDEL    "\x7f" // 127

// ORIC keyboard routines gives 8-11 ascii
// - I choose to distinguish these from CTRL-HIJK
#define KLEFT   "\x88" // 128+ 8
#define KRIGHT  "\x89" // 128+ 9
#define KDOWN   "\x8a" // 128+10
#define KUP     "\x8b" // 128+11

#define KRCTRL  "\x81" // 128+1
#define KLCTRL  "\x82" // 128+2
#define KLSHIFT "\x83" // 128+3
#define KRSHIFT "\x84" // 128+4

#define KFUNCT  "\x80" // 128+letter


// TODO: replace with one 64B string?
char* upperkeys[]= {
  "7N5V" KRCTRL "1X3",
  "JTRF\0" KESC  "QD",
  "M6B4" KLCTRL "Z2C",
  "K9;-\0\0\\\0", // last char == 39?
  " ,." KUP KLSHIFT KLEFT KDOWN KRIGHT,
  "UIOP" KFUNCT KDEL "][",
  "YHGE\0ASW",
  "8L0\\" KRSHIFT KRETURN "\0="};

char* lowerkeys[]= {
  "&n%v" KRCTRL "!x#",
  "jtrf\0" KESC "qd",
  "m^b$" KLCTRL "z@c",
  "k(;^\0\0|\0",
  " <>" KUP KLSHIFT KLEFT KDOWN KRIGHT,
  "uiop" KFUNCT KDEL "}{",
  "yhge\0asw",
  "*l)|" KRSHIFT KRETURN "\0-"};

// TODO: remove asm
extern char gKey;
extern void KeyboardRead();

// peek/poke all in one *MEM(4711)= 42;
#define MEM(a) *((char*)a)

// Reads hardware keyboard ROW using COLMASK
// 
// ROW:  0-7
// COLMASK: mask for column 0-7
//   (0xFE 0xFD 0xFB 0xF7 0xEF 0xDF 0xBF 0x7F)
// COLMASK: 0x00 -> any key pressed in row
//
// Returns: 0 if no key pressed, 8 if pressed
char key(char row, char colmask) {
  MEM(0x0300)= row;
  MEM(0x030f)= 0x0e;    // select column reg
  MEM(0x030c)= 0xff;    // tell AY register number
  MEM(0x030c)= 0xdd;    // clear CB2 (prevents hang?)
  MEM(0x030f)= colmask; // write column reg
  MEM(0x030c)= 0xfd;
  MEM(0x030c)= 0xdd;
  return MEM(0x0300) & 8;
}

int unc= 0;
char keybits[8]={0};

int ungetchar(int c) {
  return unc? -1: unc=c;
}

static const char KEYMASK[]= {
  0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F };
// True if a key is pressed (not shift/ctrl/funct)
// (stores key in unc)
//
// Returns: 0 - no key, or the character
char kbhit() {
  if (!unc) {
    char row=0,c=0,o=0,R=8,K=0, col, v, k;
    asm("SEI");
    for(;row<8;++row) {
      v= 0;
      if (key(row, 0x00)) { // some key in row pressed
        for(col=0;col<8;++col) {
          v<<= 2;
          if (key(row, KEYMASK[col])) {
            ++v;
            k= upperkeys[row][col];
            if      (k==*KLCTRL  || k==*KRCTRL)  o-= 64;
            else if (k==*KLSHIFT || k==*KRSHIFT) o+= 32;
            else if (k==*KFUNCT)                   o+=128;
            else c=k,R=row,K=col; // several keys: last overwrites
          }
        }
      }
      keybits[row]= v;
    }
    asm("CLI");
    if (R!=8) {
      // TODO: can make this simplier?
      //   not call lowerkeys in two places?
      if (c>='A' && c<='Z') {
        if (o==32) o= 0;
        else if (!o) c= lowerkeys[R][K];
      }
      if (c<'A' && o==32) o=0,c= lowerkeys[R][K];
      unc= c? o+c: 0;
    }
  }
  return unc;
}

// Get the ORIC ATMOS keymatrix (row,col)-position
// Searches keymatrix for characters 32-127
//
// Returns: row<<4 | col | 8 (0RRR 1CCC)
//   0 if not found
char keypos(char c) {
  char row, col;
  for(row=0; row<8; ++row)
    for(col=0; col<8; ++col)
      if (c==upperkeys[row][col] || c==lowerkeys[row][col])
        return (row<<4) | col | 8;
  return 0;
}

// Using a KEYPOS test if key is pressed
// (this is a very efficient test for a single key)
// 
// Returns: 0=not pressed or !0 if pressed (8)
char keypressed(char keypos) {
  char c;
  asm("SEI");
  c= key(keypos>>4, KEYMASK[keypos & 7]);
  asm("CLI");
  return c;
}

char cgetc() {
  char c;
  while(!kbhit());
  c= unc;
  unc= 0;
  return c;
}

#define getchar() cgetc()
