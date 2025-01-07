// CONIO-RAW 
//
// A raw, NON-ROM-less implementation of display and
// keyboard routines for ORIC ATMOS.
//
// Intended to be used under Loci
// 
// (c) 2024 Jonas S Karlsson (jsk@yesco.org)

// TODO: disable ROM cursor?
// TDOO: protect the first 2 columns
// TODO: capslock
// TODO: kbhit, cgetc - don't give repeat directly...
// TODO: kbhit, cgetc - no buffer, so miss keystroke?
// TODO: hook it up to interrupts and buffer!

// Modelled on and replacing cc65 <conio.h>

// Extended terminal operations
// ============================

// - extensive string macros to change color etc
//
// puts( RED BGWHITE "FOOBAR" YELLOW BGBLACK );
//
// Cursor movement
//
// - similar to ORIC, just different codes
//   (to keep printf \n \r \t \v semantics)
// - HOME
// - SAVE RESTORE (NEXT) - saves cursor position!
// - BACK FORWARD DOWN UP

// Formatting
//
// - INVERSE - ENDINVERSE
// - DOUBLE - (auto align row, and types double)
//   ( DOUBLE GREEN "BIG GREEN" NORMAL )

// Clearing
//
// - CLEAR
// - REMOVELINE
// - CENTER - centers the rest of the (assumed) simple text

// Scripting
//
// - WAIT   - waits for key pressed!
// - WAIT1s WAIT3s WAIT10s - waits 1, 3, 10 second(s), or key
// - for example definaing a ANYKEY macro
//   #define ANYKEY  STATUS BLINK "Press any key to continue" \
//                   NORMAL RESTORE WAIT STATUS RESTORE
//   puts(ANYKEY);


// FUNCTIONS
// =========
// - time()   - hundreths of second (hs)
// - wait(hs) - wait HS, -HS= or wait for key, 0= wait key

// Standard cc65
//
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
// - printf(fmt, ...) - uses sprintf and puts
// 
// - kbhit()
// - cgetc()

// Additions:
//
// - SCREENXY(x, y) - gives address *SCREENXY(0,0)='A'
// - savecursor()
// - restorecursor()
// - scrollup(atrowy)
// - putint(i) - very fast!

// - key(row, colmask)
// - keypos(c)          - get char defining single key-row+col
// - keypresed(keypos)  - using keypos() value test that key only

// UNIXy
// 
// - ungetchar(c) - ungets one char ala, ungetc but for stdio
// - getchar()    - macro


#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>

// TextMode
// TODO: how to solve graphics mode HIRESTTEXT?
// TODO: use variable for TEXTSCREEN, allowing virtual screens!
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
//   0: wait till key pressed
// -HS: wait till HS or key pressed, whichever first
// 
// Returns: 0 for +HS
//   -hs waited if key pressed
//   +hs waited (i.e. HS actual)
int wait(int hs) {
  unsigned int t= time(), r;
  char k= hs<=0? (hs=-hs,1): 0;
  while(!hs || (r=t-time()) < hs) {
    //if (r>=0x8000) t+= 0x8000; // correct? LOL
    if (k && kbhit()) { k=2; break; }
  }
  return (1-k)*r;
}

// *SCREEN(X,Y)='A';
#define SCREENXY(x, y) ((char*)(TEXTSCREEN+40*(y)+(x)))

char curx=0, cury=1, *cursc=TEXTSCREEN;
char curinv=0, curdouble=0, curai=0;

void cputc(char c);
char cgetc();

#define wherex() curx
#define wherey() cury

void gotoxy(char x, char y) {
  curx= x; cury= y;
  cputc(0);
}

char savex=0, savey=0;

void savecursor() {
  savex= wherex();
  savey= wherey();
}

void restorecursor() {
  gotoxy(savex, savey);
}

char* cursaved= 0;
void savescreen() {
  if (!cursaved) cursaved= malloc(SCREENSIZE);
  memcpy(cursaved, TEXTSCREEN, SCREENSIZE);
}

void restorescreen() {
  if (cursaved) memcpy(TEXTSCREEN, cursaved, SCREENSIZE);
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

void clearline(char y) {
  char* p= SCREENXY(0, y);
  memset(p, ' ', 40);
  p[0]= curpaper;
  p[1]= curink;
}

// TODO: in curmode=HIRESMODE then scroll only last 3 lines!
void scrollup(char fromy) {
  char* p= SCREENXY(0, fromy);
  memmove(p, p+40, (28-fromy)*40);
  clearline(27);
  if (cury>27) cury= 27;
  cputc(0);
}

// TODO: add new terminal controls

// + no print mode (erase w space) ?

// + no protected
// + protected 2 columns

// + cursor on - hmmm, no use?  call routine
// + cursor off - hmmm, no use? call routine

// + clear till end of line
// + clear to end of screen
// + clear whole line

// + save screen
// + restore screen

// + insert line
// + remove line
// + insert column
// + remove column

#define ESC      "\x1b" // currently not used (skip vt100!?)
#define TAB      "\t"
#define CR       "\r"
#define NEWLINE  "\n"

//#define BELL    "\x07"

// clear (32 chars) & write statusline...RESTORE
#define STATUS   "\x01"
#define STATUS32 "\x02" // overwrite chars at position 32

// Move cursor
#define BACK     "\x08"
#define FORWARD  "\x0f" // ORIC is 09, but is '\t'
#define DOWN     "\x0e" // ORIC is 10, but is '\n'
#define UP       "\x0b"

#define CLEAR    "\x0c"
#define REMOVELINE "\x13"

#define HOME     "\x1c"
#define SAVE     "\x1d"
#define RESTORE  "\x1e"
#define NEXT     "\x1f"

#define TOGGLEAI "\x14"

// Formatting
#define ENDINVERSE "\x10"
#define INVERSE  "\x11"

#define CENTER   "\x12"

// text colours
#define BLACK    "\x80"
#define RED      "\x81"
#define GREEN    "\x82"
#define YELLOW   "\x83"
#define BLUE     "\x84"
#define MAGNENTA "\x85"
#define CYAN     "\x86"
#define WHITE    "\x87"

// background colours
#define BGBLACK    "\x90"
#define BGRED      "\x91"
#define BGGREEN    "\x92"
#define BGYELLOW   "\x93"
#define BGBLUE     "\x94"
#define BGMAGNENTA "\x95"
#define BGCYAN     "\x96"
#define BGWHITE    "\x97"

// charset, double, blink
//   for double it'll align to odd even row
#define NORMAL      "\x88"   
#define ALTCHARS    "\x89"   
#define DOUBLE      "\x8a"
#define ALTDOUBLE   "\x8b"   

#define BLINK          "\x8c"
#define ALTBLINK       "\x8d"
#define DOUBLEBLINK    "\x8e"
#define ALTDOUBLEBLINK "\x8f"

#define FULL       "\x7f"

// Waitinig (for key, or specified seconds)
#define WAIT10s  "\x03" // WAIT 10 seconds or key
#define WAIT3s   "\x04" // WAIT 3 seconds or key
#define WAIT1s   "\x05" // WAIT 1 second or key
#define WAIT     "\x06" // WAIT for key (ACK)

// Combined!
#define ANYKEY  STATUS BLINK "Press any key to continue" NORMAL RESTORE WAIT STATUS RESTORE

void cputc(char c) {
  if ((c & 0x7f) < ' ') {
    if (c < 128) {
      int i= 0;

      // control-codes
      switch(c) {

      //case    0: // *is* UPDATE - cursc from curx,cury

      case    1:                     // STATUS lines write
        savecursor();
        memset(TEXTSCREEN, 32, 32);
        gotoxy(0,0);
        return;
      case    2:                     // STATUS32 xxxxCAPS
        savecursor(); gotoxy(0,32); return;

      case    3: i+= 700;            // WAIT10s
      case    4: i+= 200;            // WAIT3s
      case    5: i+= 100;            // WAIT1s
      case    6:
        while(kbhit()) cgetc();
        wait(-i); break;             // WAIT (key)

      case    7: break;              // TODO: (taco) BELL

      case    8: --curx; break;      // BACK
      case 0x0f: ++curx; break;      // FORWARD
      case 0x0e: ++cury; break;      // DOWN
      case   11: --cury; break;      // UP

      case   12: clrscr(); return;   // CLEAR

      case '\n': curx= 0; ++cury; break;     // NEWLINE 10 ^J
      case '\r': curx= 0; break;             // CR      13 ^M
      case '\t': curx= (curx+8)&0xf7; break; // TAB      8 ^I

      case 0x10: curinv= 0; break;           // ENDINVERSE
      case 0x11: curinv= 128; break;         // INVERSE

      //case 0x12:                           // CENTER (see puts)
      case 0x13: scrollup(1); break;         // REMOVELINE

      case 0x14: curai= !curai; break;       // TOGGLEAI

      //case 0x15: // NAK
      //case 0x16: // SYN
      //case 0x17:
      //case 0x18: // CAN
      //case 0x19: 
      //case 0x1a:
        
      case 0x1b: break; // ESC TODO: ORIC attribute prefix

      case 0x1c: gotoxy(0,1); break;     // HOME
      case 0x1d: savecursor(); break;    // SAVE
      case 0x1e: restorecursor(); break; // RESTORE
      case 0x1f: restorecursor(); savey= ++cury; break; // NEXT
      }

      // fix state, update cursc
      if (curx==255) --cury,curx=39;
      else if (curx>=40) ++cury,curx=0;

      if (cury==255) cury=0; // TODO: scroll up?
      else if (cury>=28) { scrollup(1); return; }

      //if (cursc<TEXTSCREEN) cursc= TEXTSCREEN;
      //else if (cursc>=SCREENEND);

      cursc= SCREENXY(curx, cury);

      return;
    } else {
      char x= c & 0b11111110;
      if      (x==0x8a) curdouble= 1;
      else if (x==0x88) curdouble= 0;
      c&= 0x7f;
    }
  }

  // 32-127, 128+32-255 (inverse)
  if (curdouble) {
    if (cury&1) { ++cury; cputc(0); }
    cursc[40]= c|curinv;
  }
  *cursc= c|curinv;  ++cursc;
  if (++curx>=40) { ++cury; curx=0; }
  if (cury>=28) scrollup(1);
  if (curai) wait(10);
}

//int putchar(int c) { cputc(c); return c; }
#define putchar(c) (cputc(c),c)

// really raw!
void cputsxy(char x, char y, char* s) {
  char *p = SCREENXY(x,y);;
  while(*s) *p=*s,++p,++s;
}

int puts(const char* s) {
  const char* p= s; char c;

  if (!s) return 0;

  --p;
 next:
  switch(c= *++p) {
  case 0: return p-s;
    // ! = these REQUIRE multiby sequence
    //     so cannot do in cputc, but in puts?
    //
    // ! ESC c gives c-64 = ORIC way of attribute
    // ! print in status line col nchars text.... \n
    // ! gotoxy x y - hmmm 0,0 ???
    // ! repeat n c
    
    // ! copy byteblit w c
    // + restore byteblit
    // + swap byteblit
  
    // + nowrap / wrap (autonl)
  case 0x12: c= strlen(s); gotoxy(curx+(40-c)/2, cury); goto next;
  default: putchar(c); goto next;
  }
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

#ifdef TEST

// Dummys for ./r script
int T,nil,doapply1,print;








// useless test of conio-raw.c

void demo() {
  int i;

  printf(CLEAR ANYKEY);

  printf("\n\n\nconio: "
         DOUBLE "Hello"
           YELLOW BGRED "RAW" CYAN BGBLACK
           "World!"
         NORMAL
         WHITE "yeah");

  printf(SAVE);
  printf("\n\n\n" CENTER "Once upon a time..."     WAIT1s);
  printf("\n"     CENTER "In a galaxy far away..." WAIT1s);

  printf("\n" CENTER
         TOGGLEAI
           "AI speaking: what's this?\n"
         TOGGLEAI);

  printf("\n\n"   CENTER "(Wait for it!)"          WAIT3s);
  printf("\n\n\n" CENTER "There was ORIC ATMOS!"   WAIT10s);

  printf("\n\n\n\n\n" CENTER DOUBLE RED "B" GREEN "Y" BLUE "E" NORMAL);

  // Scroll up
  printf(RESTORE);
  i= 27;
  while(i--) printf(WAIT1s REMOVELINE);

}

// TODO: https://www.cc65.org/doc/ld65-5.html
void init_conioraw() {
  // ORIC BASIC ROMs remap interrupt vector to page 2...
  if (MEM(0xFFFF)==0x02) {
    // We're running under an ORIC BASIC ROM!

    // status location is at #26A.
    //  1 – cursor ON when set.
    //  2 – screen ON when set.
    //  4 – not used.
    //  8 – keyboard click OFF when set.
    // 16 – ESC has been pressed.
    // 32 – columns 0 and 1 protected when set.
    #define SCREENSTATE *((char*)0x26a)
    SCREENSTATE= 0; //*(char*)0x026A= 0;
  }
}

void main() {
  int i= 1;

  init_conioraw();

  savescreen();
  clrscr();

  switch(0) {

  case 1: while(!kbhit()) {
      printf("row %d\n", i++);
      wait(5);
    } break;

  default: demo(); break;

  }

  restorescreen();
}

#endif // TEST
