// CONIO-RAW 
//
// A raw, NON-ROM-less implementation of display and
// keyboard routines for ORIC ATMOS.
//
// Intended to be used under Loci
// 
// (c) 2024 Jonas S Karlsson (jsk@yesco.org)

// Modelled and replacing cc65 <conio.h>

// Functions:
// - clrscr()
// - gotoxy(x, y)
// - cputc(c)
// - putchar(c) - macro
// - wherex()
// - wherey()
// - revers()
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
// - ungetchar(c)
// - getchar() - macro
// 

// TextMode
// TODO: how to solve graphics mode?

#define CHARSET    (0xB400)        // $B400-B7FF
#define ALTSET     (0xB800)        // $B800-BB7F
#define TEXTSCREEN ((char*)0xBB80) // $BB80-BF3F
#define SCREENROWS 28
#define SCREENCOLS 40
#define SCREENSIZE (SCREENROWS*SCREENCOLS)
#define SCREENEND  (TEXTSCREEN+SCREENSIZE)

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

void clrscr() {
  memset(cursc, ' ', 28*40);
  curx= cury= 0;
  cursc= TEXTSCREEN;
  return;
}

// TODO:
//void revers(char) {}
void revers();

void scrollup(char n) {
  memcpy(TEXTSCREEN, TEXTSCREEN+40, (28-n)*40);
  memset(TEXTSCREEN+(28-n)*40, ' ', 40*n);
  cury= 27;
  cputc(0);
}

void cputc(char c) {
  if ((c & 0x7f) < ' ') {
    if (c < 128) {
      // control-codes
      switch(c) {
      case  7  : break; // TODO: bell?
      case  8  : --curx; --cursc; break;
      case  9  : ++curx; ++cursc; break;
//    case 10  : ++cury; cursc+= 40; break;
      case 11  : --cury; cursc-= 40; break;
      case 12  : clrscr(); return;
      case '\r': curx= 0; break;
      case '\n': curx= 0; ++cury; break;
//    case '\r': curx= 0; break;
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

// wrong: CD K->X W 3 =
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
  "m^b$]" KLCTRL "z@c",
  "k(;^\0\0|\0",
  " <>" KUP KLSHIFT KLEFT KDOWN KRIGHT,
  "uiop]" KFUNCT KDEL "}{",
  "yhge\0asw",
  "*l)|" KRSHIFT KRETURN "\0-"};

extern char gKey;
extern void KeyboardRead();

// peek/poke all in one *MEM(4711)= 42;
#define MEM(a) *((char*)a)

// Reads hardware keyboard ROW using column MASK
// 
// ROW:  0-7
// MASK: 0x00 -> key pressed in row?
// MASK: mask for column 0-7
//   (0xFE 0xFD 0xFB 0xF7 0xEF 0xDF 0xBF 0x7F)
//
// Returns: ROW if no key presssed, otherwise
//   (ROW|8) if key pressed
char key(char row, char mask) {
  MEM(0x0300)= row;
  MEM(0x030f)= 0x0e; // select column reg
  MEM(0x030c)= 0xff; // tell AY register number
  MEM(0x030c)= 0xdd; // clear CB2 (prevents hang?)
  MEM(0x030f)= mask; // write column reg
  MEM(0x030c)= 0xfd;
  MEM(0x030c)= 0xdd;
  // and #08  ???
  return MEM(0x0300);
}

int unc= 0;
char keybits[8]={0};

int ungetchar(int c) {
  return unc? -1: unc=c;
}

char kbhit() {
  if (!unc) {
    static const char MASK[]= {
      0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F };
    char row= 0, c= 0, col, v, k;
    asm("SEI");
    for(;row<8;++row) {
      v= 0;
      if (key(row, 0x00)!=row) { // some key in row pressed
        for(col=0;col<8;++col) {
          v<<= 2;
          if (key(row, MASK[col])!=row) {
            ++v;
            k= upperkeys[row][col];
            if      (k==*KLCTRL  || k==*KRCTRL)  c-= 64;
            else if (k==*KLSHIFT || k==*KRSHIFT) c+= 32;
            else if (k==*KFUNCT)                 c+= 128;
            else c+= k; // LOL TODO: several keys?
          }
        }
      }
      keybits[row]= v;
      asm("CLI");
    }
    unc= c;
  }
  return unc;
}

char cgetc() {
  char c;
  while(!kbhit());
  c= unc;
  unc= 0;
  return c;
}

#define getchar() cgetc()
