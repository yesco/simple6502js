// CONIO-RAW
//
// (c) 2024 Jonas S Karlsson (jsk@yesco.org)
//
//
// A raw, NON-ROM-less implementation of conio display
// and keyboard routines for ORIC ATMOS.
// 
// Implements full-screen editing, similar to ORIC.
//
// However, it has a twist - it impements an EMACSy
// full-screen editor, intended to be used for editing.
//
// It's RAW since it's intended to be used under Loci,
// when no ROM may be available!

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
// - WAITKEY   - waits for key pressed!
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


// ORIC ORIGINAL TERMINAL CODES
// ============================
// 1 = A :USED FOR EDITING"          - TODO: when do input
// 3 = C :BREAK KEY"                 abort input?
// 4 = D :DOUBLE CHARACTER ON/OFF"   - TODO: double toggle
// 6 = F :KEY CLICK ON/OFF"          - keyclick lol
// 7 = 6 :PING"                      - TODO::
// 8 = H :CURSOR MOVES LEFT"         = 128+24
// 9 = I : CURSOR MOVES RIGHT"       = 128+25
// 10 = J :CURSOR DOWN"              = 128+26
// 11 = K . :CURSOR UP"              = 128+27
// 12 = L :CLEAR SCREEN"             yes
// 14 = N :CLEAR LINE"               yes
// 16 = P :PRINTER ON/OFF" 
// 17 = Q :CURSOR ON/OFF"            = input:
// 19 = S :SCREEN ON/OFF"            hmmm (make it go faster?)
// 20 = T :UPPER CASE ON/OFF"        = input: CAPS-lock
// 24 = X :EDITS LINE FROM MEMORY"   = input
// 26 = Z :BACKGROUND BLACK"         = ah, input... next char like ESC!
// 27 = ESC:AFFECTS NEXT CHARACTER"  = hmm, same...
// 29 = J :INVERSE VIDEO ON/OFF      = TODO:

#include <ctype.h>
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

unsigned int kbhit();

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
char curinv=0, curdouble=0, curai=0, curcaps=0;

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
  memmove(cursaved, TEXTSCREEN, SCREENSIZE);
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
#define STATUS   "\x18"
#define STATUS32 "\x1a" // overwrite chars at position 32

// Move cursor
#define BACK     "\x90" // see KEY_LEFT
#define FORWARD  "\x91" //     KEY_RIGHT
#define DOWN     "\x92" //     KEY_DOWN
#define UP       "\x93" //     KEY_UP

#define CLEAR      "\x0c" // ^L clearscreen
#define REMOVELINE "\x13" // ^K
#define CLEARLINE  "\x0e" // 
//#define INSERTLINE      // ^O ???

//#define HOME   GOTOXY:0;1; // maybe?
#define SAVE     "\x1d"
#define RESTORE  "\x1e"
// useful for sprite print: SAVE "abc" NEXT "def" NEXT "ghi"
// gives  abc
//        def
//        ghi
#define NEXT     RESTORE KEY_DOWN SAVE

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
#define NORMAL         "\x88"
#define ALTCHARS       "\x89"
#define DOUBLE         "\x8a"
#define ALTDOUBLE      "\x8b"

#define BLINK          "\x8c"
#define ALTBLINK       "\x8d"
#define DOUBLEBLINK    "\x8e"
#define ALTDOUBLEBLINK "\x8f"

#define FULL       "\x7f"

// Waiting (for key, or specified seconds)
#define WAIT10s  "\x03" // WAIT 10 seconds or key
#define WAIT3s   "\x04" // WAIT 3 seconds or key
#define WAIT1s   "\x05" // WAIT 1 second or key
#define WAITKEY  "\x06" // WAIT for key (ACK)
//      TOGGLEAI        // waits after each character processed

// Combined!
#define ANYKEY  STATUS BLINK "Press any key to continue" NORMAL RESTORE WAITKEY STATUS RESTORE

#define CTRL (1-'A')
#define META 128

// KEY ENCODING
// ============
// 0-31 : CTRL+'A' ... 'Z' ((CTRL==-64)
// 13   : KYE_RETURN
// 27   : KEY_ESC
// 32   : ' '
// ...
// 127  : KEY_DEL

// -- hi bit set
// 128+ 0-31: ORIC: hibit === raw attribute
// 128+ 31..: ORIC: hibit === INVERSE chars!

// 128+ 0: KEY_FUNCT - same code as BLACK
// 128+ 1:           - same code as RED (ink)
// ...                 IF PRINTED!
// 128+ 7:           - WHITE

// ORIC: these when printed set attributes...
// 128+ 8:           (free) CHARSET
// 128+ 9:           (free) ALTSET
// 128+10:           (free) DOUBLE
// 128+11:           (free) ALTDOBULE
// 128+12:           (free) CHARSETBLINK
// 128+13:           (free) ALTBLINK
// 128+14:           (free) DOUBLEBLINK - lol
// 128+15:           (free) DOUBLEALTBLINK  - lol

// 128+16:           - same as BGBLACK
// ...               ...
// 128+23:           - BGWHITE

// 128+24: KEY_LEFT   when printed will move cursor!
// 128+25: KEY_RIGHT
// 128+26: KEY_DOWN
// 128+27: KEY_UP

// 128+28: KEY_      - FREE! 
// 128+29: KEY_      - FREE!
// 128+30: KEY_      - FREE!
// 128+31: KEY_      - FREE!

// ...
// 128+'A': KEY_FUNCT+'A' (KFUNCT=128)
// ...
// 128+'Z': 

// --- C-M-a gives..
// 128+'a': funct ctrl a !
// ...
// 255

// --- key codes
#define KEY_RETURN  13
#define KEY_ESC     27
#define KEY_DEL    127

// TODO: function keys FUNCT+1 2 3 ...
#define KEY_FUNCT  128

// ORIC keyboard routines gives 8-11 ascii
// - I choose to distinguish these from CTRL-HIJK
#define KEY_LEFT   128+24 // 0x90
#define KEY_RIGHT  128+25 // 0x91
#define KEY_DOWN   128+26 // 0x92
#define KEY_UP     128+27 // 0x93

// Just these by themselves
// TODO: other?
#define KEY_RCTRL  128+28 
#define KEY_LCTRL  128+29
#define KEY_LSHIFT 128+30
#define KEY_RSHIFT 128+31

// --- key strings (for use to construct maps)
#define KRETURN "\x0d" //  13
#define KESC    "\x1b" //  27
#define KDEL    "\x7f" // 127

// ORIC keyboard routines gives 8-11 ascii
// - I choose to distinguish these from CTRL-HIJK
#define KLEFT   "\x98" // 128+24
#define KRIGHT  "\x99" // 128+25
#define KDOWN   "\x9a" // 128+26
#define KUP     "\x9b" // 128+27

#define KRCTRL  "\x81" // 128+1
#define KLCTRL  "\x82" // 128+2
#define KLSHIFT "\x83" // 128+3
#define KRSHIFT "\x84" // 128+4

#define KFUNCT  "\x80" // 128+letter

void bell() {
  char *saved= cursc, t;
  // ORIC: ping();
  // TODO: research how to do directy AY-hardware sounds

  // Visual Bell (reverse twice)
  for(t=3; --t; ) {
    for(cursc=TEXTSCREEN; ++cursc<SCREENEND; ) *cursc ^= 128;
    //wait(10);
  }

  cursc= saved;
}

// interal "raw" terminal

// Basically, it implements EMACS style editing
// on the screen!
//
// On ORIC you traditionally can edit the screen,
// which is a rather unique function.
//
// But ehre we don't have the CTRL-A read character
// under cursor and type nilwilly anywhere into
// a hidden keyboard buffer!
//

// Emacs bindings implemented
//
// CTRL-A : At the aabeginning of line
// CTRL-B : Back one character
// CTRL-D ::Delete current chracter
// CTRL-E : End of line
// CTRL-G : PING, or rather bell() (visual!)
// CTRL-H : // TODO: helps
// CTRL-I : TAB chacter, moves to next 8 char pos
// CTRL-J : newline // TODO: new line/insert/indent!
// CTRL-K : Kill current line (TODO: add to Yank buffer)
// CTRL-L : clears the screen (all erased!)
// CTRL-M : same as RETURN (maybe)
// CTRL-N : Next line
// CTRL-O : insert line break here
// CTRL-P : Previous line
// CTRL-Q : TODO: Quote next char (insert raw?/hex?)
// CTRL-R : TODO: re-search backwards
// CTRL-S : TODO: search, have some code, untested
// CTRL-T : ORIC: CAPS-toggle, implemeneted but have bug
// CTRL-U : TODO: numeric prefix, quadruplicate next char
// CTRL-V : TODO: Next Page
// CTRL-W : TODO: wank? cut region
// CRRL-X : TODO: eXtended commands, file system etc
// CTRL-Y : TODO: Yank insert kill-buffers
// CTRL-Z : TODO: Zleep?

// FUNCT-B: TODO: Backward word
// FUNCT-F: TODO: Forward word
// FUNCT-P: TODO: bottom?
// FUNCT-N: TODO: top?
// FUNCT-Q: TODO: fill-paragraph/reindent "region"

// Special keys
//
// RETURN : new line
// CTRL-J : LF
// CTRL-M ; CR

void cputc(char c) {
  // Basically, if not easily printable?
  if (((c & 0x7f) < ' ') || c==127) {

    // control chars (0-31), or (arrow keys)
    // TODO: why this test, just let switch do it?
    if (c<32 || (c & 0xf8)==0x98 || c==127) {
      int i= 0;

      // EMACS DONE: ^ ABcDEFGhIjk mNoPqrs u  y
      //             M-ab def  ij   n pqrs
      //    almost            h jk      rS 
      //    can't                 L H     T VXZ
      // ESC-q reformat paragraph/fill

      // control-codes
      switch(c) {

      //case 0: // *is* UPDATE - cursc from curx,cury
      case 1: curx= 0; break;                 // ^A beginning of line
      // case  2:                             // ^B back
      //case CTRL+'C':
      case CTRL+'D':                          // ^D del char forward
        memmove(cursc, cursc+1, 39-curx);
        cursc[39-curx]= ' '; break; // TODO: cclearxy()
      case CTRL+'E': gotoxy(39,cury);         // ^E end of line
        while(cursc[-1]==' ') --cursc,--curx;
        break;
      // case 6:                              // ^F forward
      case CTRL+'G': bell(); break;           // ^G break/bell
      // TODO: 8 is roubout
      case  127: if (cursc>TEXTSCREEN)        // ^H -- \b
          // TODO: insert/overwrite
          memmove(cursc-1, cursc, 39-1-curx);
          cursc[39-curx]= ' '; --curx; break;

      case '\b':
      case CTRL+'B':case KEY_LEFT:  --curx; break; // ^B <- 
      case CTRL+'F':case KEY_RIGHT: ++curx; break; // ^F ->
      case CTRL+'N':case KEY_DOWN:  ++cury; break; // ^N DOWN
// TODO:???     case   11 on oric: CTRL+'K' ????
      case CTRL+'P':case KEY_UP:    --cury; break; // ^P up
      case   12: clrscr(); return;                 // ^L clear

      case '\t': curx= (curx+8)/8*8; break;          // ^I TAB
      case '\n': curx= 0; ++cury; break;           // not key
      // TODO: distinguish RETURN
      case '\r': curx= 0; break;                   // ^M

      //case CTRL+'Q': break;                      // TODO: ^Q quote char
      case CTRL+'R':                               // TODO: ^R
      case CTRL+'S': { char k, s[32]={0}; i=0;     // ^S s
          do {
            *cursc ^= 128;
            k=cgetc();
            *cursc ^= 128;

            if (k==KEY_RETURN) break;
            if (k==CTRL+'G') { cursc= 0; break; }
            // TODO: backspace

            s[i]= k; ++i;

            //if (c==CTRL+'S') 
            cursc= memchr(cursc, s[0], SCREENEND-cursc-1);
            //else 
            //  cursc= memrchr(cursc, s[0], cursc-TEXTSCREEN);
          } while (cursc);
          if (!cursc) { bell(); break; }

          // found!
          i= cursc-TEXTSCREEN;
          curx= i % 40;
          cury= i % 40;
          break; }

      // TODO: Not working?
      case CTRL+'T': curcaps = 1-curcaps; break;    // ^T toggle CAPS

      // TODO: use cclear()      // TODO: clear end of line
      // TODO: hmmm... CLEARLINE?
       // TDOO: same key as
      //case CTRL+'K':                             // TODO: ^K CLEARLINE
        //memset(TEXTSCREEN+40*cury, 32, 40);
        //return;
      case CTRL+'K': scrollup(cury); break;    // ^K: REMOVELINE

      // TODO: use cclear()      // TODO: clear end of line
      //case CTRL+'O': scrolldown(1); break;     // ^O INSERTLINE

      //case 0x10: curinv= 0; break;           // ENDINVERSE
      //case 0x11: curinv= 128; break;         // INVERSE

      //case 0x12:                           // CENTER (see puts)
      //case    3: i+= 700;                    // WAIT10s
      //case    4: i+= 200;                    // WAIT3s
      //case    5: i+= 100;                    // WAIT1s
      //case    6:                             // WAITKEY
        //while(kbhit()) cgetc();
        //wait(-i); break;                     


      //case 0x14: curai= !curai; break;       // TOGGLEAI

      //case 0x15: // NAK
      //case 0x16: // SYN                    // TODO: search SYN '2'
      //case 0x17: // ETB
      //case 0x18: // CAN                    // TODO: stop!

      case CTRL+'U': // ^U repeat
      case CTRL+'V': // ^V page down ?  next page?/screen
      case CTRL+'W': //cut region
      case CTRL+'Y': // ^Y yank

      //case CTRL+'X': // extended menu
      //case CTRL+'Z': // ^Z sleep (go other mode?)
      case CTRL+'C': // ^C exit ? // compile

      // case 0x1d: // ORIC - toogleinv?

      // redundant
      //case 0x1c: gotoxy(0,1); break;       // HOME

      case CTRL+'X': // 0x18                  // STATUS txt RESTORE
        savecursor();
        memset(TEXTSCREEN, 32, 32);
        gotoxy(0,0);
        return;
      case CTRL+'Z': // 0x1a                  // STATUS32 txt8 RESTORE
        savecursor(); gotoxy(32,0); return;
        

      // ESC TODO: ORIC attribute prefix
      case 0x1b: break;                                 // TODO: ESC

      case 0x1c: break;
      case 0x1d: savecursor(); break;                   // SAVE
      case 0x1e: restorecursor(); break;                // RESTORE
      case 0x1f: restorecursor(); savey= ++cury; break; // NEXT

      // Cursor:      SAVE RESTORE NEXT HOME GOTOXY bx by
      // Page:        PAGESWAP n, PAGESAVE n PAGELOAD n
      // Status:      STATUS t, STATUS32 t
      // Format:      ENDINVERSE INVERSE CENTER
      // Repeat:      REPEAT n c (CTRL+'U')
      // Input:       WAIT10s WAIT3s WAITKEY WAIT n
      // Lines:       CLEARLINE INSLLINE REMLINE
      // Columns:     CLEARCOL INSCOL REMCOL
      // Bytes:       BFILL BCOPY B
      // Window:
      // Xperiment:   TOOGLEAI

      }

      // fix state, update cursc
      if (curx==255) --cury,curx=39;
      else if (curx>=40) ++cury,curx=0;

      if (cury==255) cury=0; // TODO: scroll up?
      else if (cury>=28) { scrollup(1); return; }

      cursc= SCREENXY(curx, cury);
      return;

    } else {

      // Hi-Bit control chars; DOUBLE specials...
      // (arrowkeys are exempt and handles above)
      char x= c & 0b11111110;
      if      (x==0x8a) curdouble= 1;
      else if (x==0x88) curdouble= 0;

    }
  }

  // 32-127, 128+32-255 (inverse)
  if (curdouble) {
    if (cury&1) { ++cury; cputc(0); }
    cursc[40]= c|curinv;
  }
  *cursc= c^curinv;  ++cursc;
  if (++curx>=40) { ++cury; curx=0; }
  if (cury>=28) scrollup(1);
  if (curai) wait(-10);
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


// TODO: replace with one 64B string?
char* upperkeys[]= { // lol, bad name
  "7N5V" KRCTRL "1X3",
  "JTRF\0" KESC  "QD",
  "M6B4" KLCTRL "Z2C",
//  "K9;-\0\0\\\0", // last char == 39???? - got S-@ once?
  "K9;-\0\0\\'", // last char == 39? - not working
//  "K9;-\0\0\\q", // last char == 39? -- not workgin
  " ,." KUP KLSHIFT KLEFT KDOWN KRIGHT,
  "UIOP" KFUNCT KDEL "][",
  "YHGE\0ASW",
  "8L0/" KRSHIFT KRETURN "\0="};

char* lowerkeys[]= {
  "&n%v" KRCTRL "!x#",
  "jtrf\0" KESC "qd",
  "m^b$" KLCTRL "z@c",
//  "k(;^\0\0|\0", // before and almost works S-@ !
  "k(:^\0\0|\"", // not working
//  "k(:^\0\0|Q",
  " <>" KUP KLSHIFT KLEFT KDOWN KRIGHT,
  "uiop" KFUNCT KDEL "}{",
  "yhge\0asw",
  "*l)?" KRSHIFT KRETURN "\0-"};

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

unsigned int unc= 0;
char keybits[8]={0};

int ungetchar(int c) {
  return unc? 0: unc=c;
}

// upper byte
#define FUNCTmask 0b10000000
#define CTRLmask  0b01000000
#define SHIFTmask 0b00100000
#define ARROWmask 0b00010000

// why these? because they map to CTRL+something
#define ESCmask 0b00001000
#define DELmask 0b00000100
#define RETURNmask 0b00000010

#define RIGHTmask  0b00000001

/// use these: FUNCTBIT & getchar()
#define FUNCTBIT  (FUNCTmask<<8)
#define CTRLBIT   (CTRLmask<<8)
#define SHIFTBIT  (SHIFTmask<<8)
#define ARROWBIT  (ARROWmask<<8)
#define ESCBIT    (ESCmask<<8)
#define DELBIT    (DELmask<<8)
#define RETURNBIT (RETURNmask<<8)

#define RIGHTBIT  0b00000001

static const char KEYMASK[]= {
  0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F };

// True if a key is pressed (not shift/ctrl/funct)
// (stores key in unc)
//
// Returns: 0 - no key, or the character
unsigned int kbhit() {
  char bits= 0;
  if (!unc) {
    char row=0,c=0,o=0,K=0,R=8, col, v, k;
    asm("SEI");
    for(;row<8;++row) {
      v= 0;
      if (key(row, 0x00)) { // some key in row pressed
        for(col=0;col<8;++col) {
          v<<= 2;
          if (key(row, KEYMASK[col])) {
            ++v;
            k= upperkeys[row][col];

            // TODO: test this once after all scannned!
            //   use the matrix(bits), Luke!
            if (k & 128) {
              if (k==*KLCTRL || k==*KRCTRL) {
                o-= 64; bits|=CTRLmask; continue;
              } else if (k==*KLSHIFT || k==*KRSHIFT) {
                o+= 32; bits|=SHIFTmask; continue;
              } else if (k==*KFUNCT) {
                o+=128; bits|=FUNCTmask; continue;
              }
              // maybe arrow keys?
            }
            // if fallthrough these are "real chars"
                 if (k>=*KLEFT)   bits|=ARROWmask;
            else if (k==*KRETURN) bits|=RETURNmask;
            else if (k==*KESC)    bits|=ESCmask;
            else if (k==*KDEL)    bits|=DELmask;
            
            c=k,R=row,K=col; // last char overwrites
          }
        }
      }
      keybits[row]= v;
    }
    asm("CLI");

    // decode ascii
    if (R!=8) {

      // specific workaround for Oricutron that
      // dosn't recognize '" and \| keys1
      if (c==';' && (bits & CTRLmask))
        return unc= (bits & SHIFTmask)? '\'': '\"';

      // TODO: can make this simplier?
      //   not call lowerkeys in two places?
      if (c>='A' && c<='Z') {
        if (o==32) o= 0;
        else if (!o) c= lowerkeys[R][K];
      }
      if (c<'A' && o==32) o=0,c= lowerkeys[R][K];
      unc= (bits<<8) | (c? o+c: 0);
      if (curcaps && isalpha(c)) c ^= 32; // switch lower/upper!
    }
    // update bits (TODO: move here?)
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

void printkey(unsigned int k) {
  if (k & FUNCTBIT)  putchar('F');
  if (k & CTRLBIT)   putchar('C');
  if (k & SHIFTBIT)  putchar('S');
  if (k & ARROWBIT)  putchar('a');
  if (k & ESCBIT)    putchar('e');
  if (k & DELBIT)    putchar('d');
  if (k & RETURNBIT) putchar('r');
  if (k & 0xff00)    putchar('-');
  k= (char)k;
  putchar((k&0x7f)<' '? k+64: k);
  //printf(" ($%04x)", k);
}

// Waits for keypress
// Returns:
unsigned int keylasttime=0;
unsigned int keylast= -1;

// time() doesn't seem correct...
#define KEYREPEAT_DELAY 70 // hs

// getchar() returns an "EXTENDED CHAR"
//
// (char)getchar()     =>   pure ascii
// int getchar() usage => BITS + ascii
// 
// BITS are defined above, search for
// FUNCTBITS and you;ll find them.
int getchar() {
  unsigned int t;
  while(kbhit()==keylast
        && (t=keylasttime-time()) < KEYREPEAT_DELAY)
    unc=0; // force read
  //printf(STATUS32 "%02x%02x%4d" RESTORE, (char)keylast, (char)kbhit(), t);

  if (unc!=keylast) keylasttime=time();
  // wait for key
  while(!kbhit());
  keylast= unc;
  unc= 0;
  return keylast;
}

char cgetc() {
  // This truncates, returning only low byte
  return getchar();
}

#ifdef TEST

// Dummys for ./r script
int T,nil,doapply1,print;








// useless test of conio-raw.c

void demo() {
  int i;

  puts(CLEAR ANYKEY);

  puts("\n\n\nconio: "
       DOUBLE "Hello"
         YELLOW BGRED "RAW" CYAN BGBLACK
         "World!"
       NORMAL
       WHITE "yeah");

  puts(SAVE);
  puts("\n\n\n" CENTER "Once upon a time..."     WAIT1s);
  puts("\n"     CENTER "In a galaxy far away..." WAIT1s);

  puts("\n" CENTER
       TOGGLEAI
         "AI speaking: what's this?\n"
       TOGGLEAI);

  puts("\n\n"   CENTER "(Wait for it!)"          WAIT3s);
  puts("\n\n\n" CENTER "There was ORIC ATMOS!"   WAIT10s);

  puts("\n\n\n\n\n" CENTER DOUBLE RED "B" GREEN "Y" BLUE "E" NORMAL);

  // Scroll up
  puts(RESTORE);
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
  unsigned int i= 1, k= 0;

  init_conioraw();

  savescreen();
  clrscr();

  switch(2) {

  case 2:
    // stupid terminal to test out control keys...

    gotoxy(0, 1);

    while(1) {
      printf(STATUS INVERSE "-ORIMACS:-- *scratch*    L%dc%d",
             wherey(), wherex());
      // TODO: see character code at position!
      puts("   " ENDINVERSE RESTORE);
      puts(STATUS32); printkey(k); puts(" " RESTORE);

      *cursc ^= 128;
      k=getchar();
      *cursc ^= 128;

      // Terminal implementation code!
      // TODO: why is it needed again?
      // is keyboard mapping wrong?
      // CTRL-M hmmm, CRRL-J, hmmm, RETURN
      if (k & RETURNBIT) k= '\n';
      putchar(k);

    } break;

  case 1:
    // just scroll test
    while(!kbhit()) {
      printf("row %d\n", i++);
      wait(5);
    } break;

  case 3: {
    // TODO: use these to implement scroll in cputc()
    char ku= keypos(KEY_UP), kd= keypos(KEY_DOWN);
    char kl= keypos(KEY_LEFT), kr= keypos(KEY_RIGHT);
    char i, j, buff[40], *b, *s;
    unsigned int t;

    /// give us some text
    t= time();
    for(i=0; i<40; ++i) {
      // TODO: vnspprintf can't do?
      //printf("%.*sPanWorld", j, " ");
      for(j=0; j<i; ++j) cputc(' ');
      puts("PanWorld");
    }
    printf("\nTime: %d hs\n", t-time());

    *TEXTSCREEN= 'x'; // for timing!
    t= time();

    // pan-around w wrap
    while(1) {

      switch(cgetc()) {
      case KEY_DOWN:
          asm("SEI");
        memcpy(buff, TEXTSCREEN, 40);
        memmove(TEXTSCREEN, TEXTSCREEN+40, SCREENSIZE-40);
        memcpy(SCREENEND-40, buff, 40);
          asm("CLI");
        break;
      case KEY_UP:
        memcpy(buff, SCREENEND-40, 40);
        memmove(TEXTSCREEN+40, TEXTSCREEN, SCREENSIZE-40);
        memcpy(TEXTSCREEN, buff, 40);
        break;
      case KEY_LEFT:
        while(keypressed(kl)) {
          asm("SEI");
        b= buff-1; s= TEXTSCREEN+39-40;
        for(i=0; i<28; ++i) *++b= *(s+=40),*s=' ';

        memmove(TEXTSCREEN+1, TEXTSCREEN, SCREENSIZE-1);

        // For some reason this variant have no "artifact"?
        // but panning whole screen takes 3s instead of 2s!
        // --- and it's jerky!
        //s= TEXTSCREEN; for(i=0; i<28; ++i) memmove(s+1, s, 39),s+=40;

        b= buff-1; s= TEXTSCREEN+0-40;;
        for(i=0; i<28; ++i) *(s+=40)= *++b; 

        if (*TEXTSCREEN=='x') {
          gotoxy(1,0); printf("TIME: %d hs ", time()-t);
          t= time();
        }

          asm("CLI");
        }
        break;
      case KEY_RIGHT:
        b= buff-1; s= TEXTSCREEN+0-40;
        for(i=0; i<28; ++i) *++b= *(s+=40),*s=' ';

        memmove(TEXTSCREEN, TEXTSCREEN+1, SCREENSIZE-1);

        b= buff-1; s= TEXTSCREEN+39-40;
        for(i=0; i<28; ++i) *(s+=40)= *++b; 

        break;
      }

      if (*TEXTSCREEN=='x') {
        gotoxy(1,0); printf("TIME: %d hs ", time()-t);
        t= time();
      }

    } } break;

      // demo
  default: demo(); break;

  }

  restorescreen();
}

#endif // TEST
