// CONIO-RAW
//
// (c) 2024 Jonas S Karlsson (jsk@yesco.org)
//
//
// A raw, NON-ROM-less implementation of conio display
// and keyboard routines for ORIC ATMOS. It's inteded to
// be used under Loci!
// 
// The terminal can either be "dumb" tty; basically only
// honoring: \n \r \t ^L (clear) and scroll.

// Minimal! (don't change here, change define in your own includsion
//#define TTY // (- 5703 3433) = 2270 bytes for EXTENDED EMACS terminal codes

#ifndef TTY
  #define CONIO_INIT
  #define CONIO_PRINTF
  #define KEY_MAPPING		// (- 6946 6367) = 579 bytes 2*9*8=144B in tables, 
  #define KEY_POS			// (- 7160 6946) = 214 bytes
  #define EXTENDED_KEYS		// (- 7294 6946) = 348 bytes
  #define EXTENDED_DEBUG_KEY      // (- 7092 6946) = 146 bytes
#endif

//#define CONIO_INIT // if you want init_conioraw() to disable ORIC cursor

// TODO: since cc65 uses weak beinding maybe not needed?

// replaces printf so works with
//#define CONIO_PRINTF  // (- 10258 7668) = 3069 bytes!

// Or be an Extended terminal implementing full-screen editing,
// similar to ORIC. Most key-codes can be printed directly
// putchar/cputc to get cursor movements and editing!
//
// However, it has a twist - it impements an EMACSy
// full-screen editor!
//
// Cursor keys works for moving around.
//

//#define VT100 // (- 7668 7194)= 474 bytes

// The terminal implements extra features, such as
// a vt100-ignore mode for unkonwn codes.
//
// It also implements a minimal vt100 code,
// commands on form ESC [ <param> ; ... <letter>
//
//   ABCD - cursor movements
//   H    - gotoxy
//   J    - clear screen
//

// KEYS
// ====
// Keys are encoded capturing not only the expected ASCII-code;
// such as CTRL+'A' gives the keycode that cgetc() returns.
// FUNCT key adds 128 to the code, this is similar to ESC-x M-x or META-x

// minimal usable: TTY+KEY_MAPPING gives only uppercase, no CTRL, no SHIFT
// TODO: fix so that KEY_MAPPING gives CTRL and SHIFT!

// Needed for decoding ASCII keys (total (- 7654 6367)= 1287 bytes!)
//#define KEY_MAPPING		// (- 6946 6367) = 579 bytes 2*9*8=144B in tables, 
//#define KEY_POS			// (- 7160 6946) = 214 bytes
//#define EXTENDED_KEYS		// (- 7294 6946) = 348 bytes
//#define EXTENDED_DEBUG_KEY      // (- 7092 6946) = 146 bytes

// KEYS
// ====
// Keys are encoded capturing not only the expected ASCII-code;
// such as CTRL+'A' gives the keycode that cgetc() returns.
// FUNCT key adds 128 to the code, this is similar to ESC-x M-x or META-x
//
// CTRL-T: changes CAPS-lock when printed! (LOL?)

// TODO: disable ROM cursor?
// TDOO: protect the first 2 columns
// TODO: kbhit, cgetc - no buffer, so miss keystroke?
// TODO: hook it up to interrupts and buffer!

// Modelled on and replacing cc65 <conio.h>

// Extended terminal operations
// ============================
//
// - extensive string macros to change color etc
//
// puts( RED BGWHITE "FOOBAR" YELLOW BGBLACK );
//
//
// Cursor movement
//
// - similar to ORIC, just different codes
//   (to keep printf \n \r \t \v semantics)
// - SAVE RESTORE (NEXT) - saves cursor position!
// - BACK FORWARD DOWN UP

// Formatting 
//
// - INVERSE - ENDINVERSE
// - DOUBLE - (auto align row, and types double)
//   ( DOUBLE GREEN "BIG GREEN" NORMAL )

// Clearing (TODO: need to map codes...)
//
// - CLEAR clrscr()
// - REMOVELINE
// - CENTER - centers the rest of the (assumed) simple text

// Scripting (TODO: need to map codes...)
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
// - putchar(c) - macro - TODO: is that OK?
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
#include <string.h> // memmmove
#include <stdio.h>  // va_list

// not needed?
//#include <stdarg.h> 
//#include <assert.h>
//#define assert(a)


// peek/poke all in one *MEM(4711)= 42;
#define MEM(a) *((char*)a)


// TextMode
#define CHARSET    ((char*)0xB400) // $B400-B7FF
#define CHARDEF(C) ((char*)CHARSET+(C)*8)
#define ALTSET     ((char*)0xB800) // $B800-BB7F
#define TEXTSCREEN ((char*)0xBB80) // $BB80-BF3F
#define SCREENROWS 28
#define SCREENCOLS 40
#define SCREENSIZE (SCREENROWS*SCREENCOLS)
#define SCREENLAST (TEXTSCREEN+SCREENSIZE-1)

// TODO: remove... or use FOO() to indicate is macro not const
//#define SCREENEND()  (curp+SCREENSIZE)


// Minimal detection of TEXTMODE/HIRESMODE
// (for "fun" we use actual screen switching code for indication)
#define TEXTMODE  26 // and 24-39 (2x 60 Hz, 2x 50 Hz)
#define HIRESMODE 30 // and 28-31 (2x 60 Hz, 2x 50 Hz)

char curmode= TEXTMODE;


// hundreths of second

// TODO: make my own interrupt timer!
#define TIMER (*(unsigned int*)0x306)

unsigned int time() {
  // ORIC TIMER 100 interrupts/s,
  // TODO: my own? no ROM...
  return *(unsigned int*)0x276;
}

#ifdef CONIO_INIT

// TODO: https://www.cc65.org/doc/ld65-5.html
// Link it up to auto-init? need .s file?
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

#endif // CONIO_INIT

unsigned int kbhit();

// approximate...
void waitms(long w) {
  w <<= 3;
  while(--w>=0);
}

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

// exampel use: *SCREEN(X,Y)='A';
#define SCREENXY(x, y) ((char*)(curscr+(5*(y))*8+(x)))
//#define SCREENXY(x, y) ((char*)((5*(y))*8+(x)+curscr)) // more code

char curx=0, cury=1, * curp=TEXTSCREEN, * curscr= TEXTSCREEN;
char curinv=0, curdouble=0, curai=0, curcaps=0;

#define TOGGLECURSOR() do { *curp ^= 128; } while(0)

void cputc(char c);
char cgetc();

#define wherex() curx
#define wherey() cury

void gotoxy(char x, char y) {
  curx= x; cury= y;
  curp= SCREENXY(curx, cury);
}

#ifndef TTY
char savex=0, savey=0;

void savecursor() {
  savex= wherex();
  savey= wherey();
}

void restorecursor() {
  gotoxy(savex, savey);
}

char* cursaved= 0;

#include <stdlib.h> // malloc

void savescreen() {
  if (!cursaved) cursaved= malloc(SCREENSIZE);
  memmove(cursaved, curscr, SCREENSIZE);
}

void restorescreen() {
  if (cursaved) memcpy(curscr, cursaved, SCREENSIZE);
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

// 255= Not set
char curpaper=255, curink =255;

void paper(char c) {
  curpaper= c & 7;
  // TODO: hires mode?
  fill(0,1, 1,SCREENROWS-1, (c&0x7) | 16);
// scrollbar?
//  fill(0,1,  1,7,  (c & 7)|16+0);
//  fill(0,8,  1,12, (c & 7)|16+128);
//  fill(0,21, 1,5,  (c & 7)|16+0);
}

void ink(char c) {
  curink= c & 7;
  // TODO: hires mode?
  fill(1,1, 1,SCREENROWS-1, (c & 7));
}

// TODO:
//void revers(char) {}
void revers();

#endif // !TTY

void clearline(char y) {
  char* p= SCREENXY(0, y);
  memset(p, ' ', 40);
#ifndef TTY
  if (curpaper<8) p[0]= curpaper | 16;
  if (curink<8) p[1]= curink;
#endif // !TTY
}

void clrscr() {
  // Don't clear status line (/)
  curp= curscr+40;
  memset(curp, ' ', SCREENROWS*SCREENCOLS-40);
  curx= 0; cury= 1;
}

// TODO: in curmode=HIRESMODE then scroll only last 3 lines!
void scrollup(char fromy) {
  char* p= SCREENXY(0, fromy);
  memmove(p, p+40, (28-fromy)*40);
  clearline(27);
  if (cury>27) { cury= 27; curp-= 40; }
#ifndef TTY
  cputc(0);
#endif // TTY
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

#define ESC      "\x1b" // currently not used (skip vt100!?)
#define TAB      "\t"
#define CR       "\r"
#define NEWLINE  "\n"

#define BELL    "\x07"

// clear (32 chars) & write statusline...RESTORE
#define STATUS   "\x18"
#define STATUS32 "\x1a" // overwrite chars at position 32

// Move cursor
#define BACK     "\x98" // see KEY_LEFT
#define FORWARD  "\x99" //     KEY_RIGHT
#define DOWN     "\x9a" //     KEY_DOWN
#define UP       "\x9b" //     KEY_UP

#define CLEAR      "\x0c" // ^L clearscreen
#define REMOVELINE "\x13" // ^K
#define CLEARLINE  "\x0e" // 
//#define INSERTLINE      // ^O ???

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

// TODO: defunct

//#define WAIT10s  "\x03" // WAIT 10 seconds or key
//#define WAIT3s   "\x04" // WAIT 3 seconds or key
//#define WAIT1s   "\x05" // WAIT 1 second or key
//#define WAITKEY  "\x06" // WAIT for key (ACK)
////      TOGGLEAI        // waits after each character processed

// Combined!
//#define ANYKEY  STATUS BLINK "Press any key to continue" NORMAL RESTORE WAITKEY STATUS RESTORE

#define CTRL (1-'A')
#define META 128
#define FUNCT META

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
#define KEY_LEFT   128+24 // 0x98
#define KEY_RIGHT  128+25 // 0x99
#define KEY_DOWN   128+26 // 0x9a
#define KEY_UP     128+27 // 0x9b

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

// TODO: move all terminal combos here...

#define SAVE     "\x1d"
#define RESTORE  "\x1e"
// useful for sprite print: SAVE "abc" NEXT "def" NEXT "ghi"
// gives  abc
//        def
//        ghi
#define NEXT     RESTORE KDOWN SAVE

// Visual Bell (reverse twice)
void bell() {
  char *saved= curp, t;
  char* end= curscr+SCREENSIZE;
  for(t=3; --t; ) {
    for(curp=curscr; ++curp<end; ) *curp ^= 128;
    //wait(10);
  }
  curp= saved;
}


// VT100 states
#ifdef VT100
  #define CURNPARAM 3
  int curparam[CURNPARAM];
  char curnparam= 0;
  char curvt100= 0;
#endif // VT100


// Print character using internal "raw" terminal

// On ORIC you can traditionally edit the screen,
// just moving about with cursor keys. This is a rather
// unique (?) function on home computers.
//
// Basically, that was implemented by having DEL/and
// arrow keys emit same codes as those for moving about!
//
// Here, instead of ORIC-s control codes we implement
// EMACS style editing on the screen!
//
// Emacs bindings implemented:
//   (Free: CXYZ, TODO: HJK(L)MOQRSTWV
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
// CTRL-U : numeric prefix, or quadruplicate next char
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
// CTRL-M : CR

#ifdef TTY
// Minimal TTY terminal!
// (0-7 text color, 16-23 bg color, goes straight through! as does hi-bit)
void cputc(char c) {
  switch(c) {
  case 0   : gotoxy(curx, cury); return; // recalc pointer
  case 8   : if (curx) --curx; return;
  case 12  : clrscr(); return;
  case '\r': gotoxy(0, cury); return;
  case '\n': gotoxy(0, cury+1); return;
  case '\t': do { ++curp; } while (++curx & 0x7); break;
  default  :
    if (c&128 && c<128+32) c&= 127; // ORIC attributes
    *curp= c; ++curx; ++curp; break;
  }
  if (curx>=40) curx=0,++cury;
  if (cury>=28) scrollup(1);
}

#else // TTY else EXTENDED

void cputc(char c) {
  // not printable ASCII
  if (c < ' ' || c > 126) {
    int i= 0;

    // EMACS DONE: ^ ABcDEFGhIjk mNoPqrs u  y
    //             M-ab def  ij   n pqrs
    //    almost            h jk      rS 
    //    can't                 L H     T VXZ
    // ESC-q reformat paragraph/fill

    // -- control-codes
    switch(c) {
    case 0: break; // *is* UPDATE - recalc curp from curx,cury
    case 1: curx= 0; break;                 // ^A beginning of line
    case CTRL+'C': break;
    case CTRL+'D':                          // ^D del char forward
      memmove(curp, curp+1, 39-curx);
      curp[39-curx]= ' '; return;           // TODO: cclearxy()
    case CTRL+'E': gotoxy(39,cury);         // ^E end of line
      while(curp[-1]==' ') --curp,--curx;  // TODO: BUG: if all spaces? goes prev line?
      return;
    case CTRL+'G': bell(); return;          // ^G break/bell
    case 127: if (curp>curscr)              // ^H -- \b
        // TODO: insert/overwrite
        memmove(curp-1, curp, 39-1-curx);
      curp[39-curx]= ' '; --curx; break;

    case '\b':                                   // backspace
    case CTRL+'B':case KEY_LEFT:  --curx; break; // ^B <-  \b
    case CTRL+'F':case KEY_RIGHT: ++curx; break; // ^F ->
    case CTRL+'N':case KEY_DOWN:  ++cury; break; // ^N DOWN
    case CTRL+'P':case KEY_UP:    --cury; break; // ^P up
    case FUNCT+'P':               cury=1; break; // Top of screen
    case FUNCT+'N':              cury=27; break; // Bot of screen
        
    case CTRL+'L': clrscr(); return;             // ^L clear

    case CTRL+'O': break;                        // TODO: break line in 2

    case '\t': curx= (curx+8)/8*8; break;        // ^I TAB
    case '\n': curx= 0; ++cury; break;           // not key
    case '\r': curx= 0; break;                   // ^M
    // TODO: distinguish RETURN                  // ^J ?

    case CTRL+'Q': break;                        // TODO: ^Q quote char
    case CTRL+'R':                               // TODO: ^R
    case CTRL+'S': { char k, s[32]={0};          // ^S s TODO: test
        char* end= curscr+SCREENSIZE;
        i= 0;
        do {
          *curp ^= 128;
          k=cgetc();
          *curp ^= 128;

          if (k==KEY_RETURN) break;
          if (k==CTRL+'G') { curp= 0; break; }
          // TODO: backspace

          s[i]= k; ++i;

          //if (c==CTRL+'S') 
          curp= memchr(curp, s[0], end-curp-1);
          //else 
          //  curp= memrchr(curp, s[0], curp-curscr);
        } while (curp);
        if (!curp) { bell(); break; }

        // found!
        i= curp-curscr;
        curx= i % 40;
        cury= i % 40;
        break; }

    case CTRL+'T': curcaps = !curcaps; break;    // ^T toggle CAPS

    case CTRL+'K': memset(curscr+40*cury, 32, 40);
      scrollup(cury); break;                     // ^K: REMOVELINE
      // TODO: use cclear()
    //case CTRL+'O': scrolldown(1); break;     // ^O INSERTLINE

    // TODO: use hi-bit codes...

    // four hibit codes have no key mapping... 28 29 30 31
    //
    //case 0x9c: curinv= 0; break;           // ENDINVERSE
    //case 0x9d: curinv= 128; break;         // INVERSE
    //case 0x9e:                             // CENTER (see puts)
    //case 0x9f: i+= 700;                    // WAIT10s

      // 0xa0 == ' '
      //case 0xa0: i+= 200;                    // WAIT3s
      //case 0x85: i+= 100;                    // WAIT1s
      //case 0x86:                             // WAITKEY
      //while(kbhit()) cgetc();
      //wait(-i); break;                     


      //case 0x14: curai= !curai; break;       // TOGGLEAI

      //case 0x95: // NAK
      //case 0x96: // SYN                    // TODO: search SYN '2'
      //case 0x97: // ETB
      //case 0x98: // CAN                    // TODO: stop!

    case CTRL+'U': // TODO: move code from StupidTerminal? ^U repeat
    case CTRL+'V': // ^V page down ?  next page?/screen
    case CTRL+'W': //cut region
    case CTRL+'Y': // ^Y yank

    //case CTRL+'X': // extended menu
    //case CTRL+'Z': // ^Z sleep (go other mode?)

    // case 0x1d: // ORIC - toogleinv?
      break;

    case CTRL+'X': // 0x18                  // STATUS txt RESTORE
      savecursor();
      memset(curscr, 32, 32);
      gotoxy(0,0);
      return;
    case CTRL+'Z': // 0x1a                  // STATUS32 txt8 RESTORE
      savecursor(); gotoxy(32,0); return;

    // ESC TODO: ORIC attribute prefix
    case 0x1b:                                        // ESC: VT-100 mini-compatibility
      #ifdef VT100
        curvt100= 1;
      #endif // VT100
      return;         

    case 0x1c: break; // TODO: use
    case 0x1d: savecursor(); break;                   // SAVE
    case 0x1e: restorecursor(); break;                // RESTORE
    case 0x1f: restorecursor(); savey= ++cury; break; // NEXT

    default: 
      {
        // Hi-Bit control chars; DOUBLE specials...
        char x= c & 0b11111110;
        if      (x==0x8a) curdouble= 1;
        else if (x==0x88) curdouble= 0;
        // print anything else
        else goto print;
      } break;
    }

    goto recalc;
  }

 print:

#ifdef VT100
  // minimal vt100 simulation, TODO: vt52?
  // - https://espterm.github.io/docs/VT100%20escape%20codes.html
  if (curvt100) {
    int n= curparam[0];

    // specials...
    if (curvt100==1) {
      switch(c) {
      case '[': case '?': curvt100= c; curnparam= 0;
        memset(curparam, 0, sizeof(curparam)); return;
      case 'D': // scroll window up one line
      case 'M': // scroll window down one line
      case '7': savecursor(); return;
      case '8': restorecursor(); return;
      }
    } else {
      switch(c) {
        // ESC ? 5 h = reverse video
      case 'm': // 0=off 1=bold 2=low 4=_ 5=blink 7=inverse 8=hide
      //setwin DECSTBM        Set top and bottom line#s of a window  ^[[<v>;<v>r

      // cursor movements
      case 'A': cury-= n; goto vtdone;
      case 'B': cury+= n; goto vtdone;
      case 'C': curx+= n; goto vtdone;
      case 'D': curx-= n; goto vtdone;
      case 'f':
      case 'H': gotoxy(n,curparam[1]); goto vtdone;

      // getcursor DSR         Get cursor position                    ^[6n
      // cursorpos CPR            Response: cursor is at v,h          ^[<v>;<h>R

      case 'K': // clear line
        switch(n) {
        case 0: // clear right
        case 1: // clear left
        case 2: // clear whole line
        case 3: // TODO: cclear()
          goto vtdone;
        }
        
      case 'J': // clear screen
        switch(n) {
        case 0: // from cursor down
        case 1: // cursor up
        case 2: clrscr(); goto vtdone;
        }

      // parse numeric parameters
      case ';': if (++curnparam>CURNPARAM); return; // TODO: overflow?
      default:
        if (isdigit(c))
          curparam[curnparam]= curparam[curnparam]*10 + c-'0';
        // Unknown code: letter terminates
        else if (isalpha(c)) goto vtdone;
      }
    }
    
    return;
  }
#endif // VT100

  // -- ACTUALLY PRINT

  // 32-127, 128+32-255 (inverse)
  if (curdouble) {
    if (cury&1) { ++cury; cputc(0); }
    curp[40]= c|curinv;
  }

  // -- output actual char
  if (curmode==HIRESMODE && cury<25) {
    // copy chardef to graphics memory!
    // TODO: expensive, maybe assume gcurp? but it's not updated...

    // TODO: how to handle scrollup! now text leaks into pixels at bottom then lol!
    #define HIRESSCREEN ((char*)0xA000) // $A000-BF3F // duplicate from hires-raw.c
    #define HIRESCHARSET ((char*)0x9800) // $9800-9BFF

    char* d= (cury*5)*8*8 + curx + HIRESSCREEN - 40;
    char* ch= c*8 + (HIRESCHARSET-1);
    char i= 8;

    // TODO: other fonts? wide-stretch? BitBlt?
    // TODO: out of bounds?
    do {
      *(d+= 40)= *++ch | 64;
      if (curdouble) *(d+= 40)= *ch | 64;
    } while(--i);

  } else {
    // print on text-screen
    *curp= c^curinv;  ++curp;
  }

  // wrap/adjust cursor position
  if (++curx>=40) { ++cury; curx=0; }
  if (cury>=28) scrollup(1);
  if (curai) wait(-10);

  // done with printing
  return;


#ifdef VT100
 vtdone:
  curvt100= 0;
#endif // VT100

 recalc:

  // fix state, update curp
  if (curx==255) --cury,curx=39;
  else if (curx==40) ++cury,curx=0;
  else if (curx>0x80) curx=0;
  else if (curx>40 && curx<0x80) curx=39;

  if (cury>0x80) cury=0;
  else if (cury==28) { scrollup(1); cury=27; return; }
  else if (cury>27) cury=27;

  curp= SCREENXY(curx, cury);
}
#endif // TTY else

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
  
    // + nowrap / wrap (autonl) using strchrnul find \n or eof instead
#ifndef TTY
  case 0x12: c= strlen(s); gotoxy(curx+(40-c)/2, cury); goto next;
#endif // TTY
  default: putchar(c); goto next;
  }
}


char* spr= NULL; size_t sprlen= 0;

// maybe faster than printf
void putint(int n) {
  if (n<0) { putchar('-'); n= -n; }
  if (n>9) putint(n/10);
  putchar('0'+(n%10));
}

void put1hex(char c) {
  putchar("0123456789abcdef"[c&0xf]);
}

void put2hex(char c) {
  put1hex(c/16); put1hex(c);
}

void puthex(unsigned long n) {
  if (n>=16) puthex(n/16);
  put1hex(n);
}

#ifdef CONIO_PRINTF
#include <stdio.h>  // va_list
#include <stdlib.h> // malloc
#include <stdarg.h> // va_list
int printf(const char* fmt, ...) {
  int n= 0;
  va_list argptr;
  va_start(argptr, fmt);
  do {
    n= spr? vsnprintf(spr, sprlen, fmt, argptr): 0;
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
#endif // CONIO_PRINTF

#ifdef KEY_MAPPING

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

// TODO: remove asm, or just use asm? lol
extern char gKey;
extern void KeyboardRead();

unsigned int unc= 0;
char keybits[8]={0};

int ungetchar(int c) {
  return unc? 0: (unc=c);
}

#endif // KEY_MAPPING

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

#ifdef KEY_MAPPING

static const char KEYMASK[]= {
  0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F };

// True if a key is pressed (not shift/ctrl/funct)
// (stores key in unc)
//
// Returns: 0 - no key, or the character
//
// TODO: is kbhit() really returning int? or char? need new name?
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

          #ifdef EXTENDED_KEYS
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
          #endif // EXTENDED_KEYS  
            c=k,R=row,K=col; // last char overwrites
          }
        }
      }
      keybits[row]= v;
    }
    asm("CLI"); // TODO: ???

    // decode ascii
    if (R!=8) {

    #ifdef EXTENDED_KEYS
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
    #endif // EXTENDED_KEYS

      c= c? o+c: 0;
      if (curcaps && isalpha(c) && c<128) c ^= 32; // switch lower/upper!
      unc= (bits<<8) | c;
    }
    // update bits (TODO: move here?)
  }
  return unc;
}

#ifdef KEY_POS
// Get the ORIC ATMOS keymatrix (row,col)-position
// Searches keymatrix for characters 32-127
//
// Returns: row<<4 | col | 8 (0RRR 1CCC)
//   0 if not found
char keypos(char c) {
  char row, col;
  for(row=0; row<8; ++row)
    for(col=0; col<8; ++col)
      // TODO: this line compiles to many bytes!
      // TODO: maybe just have array of bytes, loop over as such? memchr?
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
  asm("SEI"); // TODO: ??
  c= key(keypos>>4, KEYMASK[keypos & 7]);
  asm("CLI"); // TODO: ??
  return c;
}
#endif // KEY_POS

#ifdef EXTENDED_DEBUG_KEY

// print key with F C S a(rrow) e(sc) d(el) r(eturn) - ALFA
// F-A, C-A, FCS-A, Fa- arrow
void printkey(unsigned int k) {
  static char b;
  b= k>>8;

  if (b & FUNCTmask)  putchar('F');
  if (b & CTRLmask)   putchar('C');
  if (b & SHIFTmask)  putchar('S');
  if (b & ARROWmask)  putchar('a');
  if (b & ESCmask)    putchar('e');
  if (b & DELmask)    putchar('d');
  if (b & RETURNmask) putchar('r');
  if (b & 0xff00)     putchar('-');

  k= (char)k;
  putchar((k&0x7f)<' '? k+64: k);
  //printf(" ($%04x)", k);
}
#endif // EXTENDED_DEBUG_KEY

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
  // wait some time to repeat same key
  while(kbhit()==keylast
        && keylasttime-time() < KEYREPEAT_DELAY)
    unc=0; // force read

  // debounce (wait at least 5 hs between keystrokes)
  while(keylasttime-time() < 5);

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

#endif // KEY_MAPPING

// for debugging, lol
#define DID(c) *SCREENLAST=(c)

// Edits a (given) line using emacs-style editing.
//
// Prints the PROMPT, if given. Then edits a char* line
// pointed to by *LNP. It works a bit like readline combined
// with getline. The string edited is *SZP-1 and is malloced
// if not given in *LNP.
//
// Commands:
//   RETURN/LF: ends input
//   CTRL-C   : *eof* (aborts) => -1
//   BS/DELETE: deletes last character
//   CTRL-L   : reprints prompt and string on a new line
// 
// Note: unlike getline(), size is never increased
//
// LNP: pointer to variable (pointing to char* memory) to edit,
//      or *pointer* to a variable being NULL, in which case
//      memory is malloced and user must later free().
// SZP: pointer to unsigned int of size allocated. This is the maxiumum
//      limit+1 of the string. (default: if 0, it is set to *SZP= 41)

// Returns: length of string [0, *SZ-1]
//          -1 if EOF/CTRL-C
//          -2 if LNP or SZP are NULL
int editline(char* prompt, char** lnp, unsigned int* szp) {
  char key, * ln;
  if (!lnp || !szp) return -2;
  if (!*szp) *szp= 41;
  if (!lnp || !*lnp || !*szp)
    *lnp= calloc(*szp, 1);
  ln= *lnp;

 redraw:
  if (prompt) puts(prompt);
  puts(ln);

  do {
    TOGGLECURSOR();
    key= cgetc();
    TOGGLECURSOR();

    switch(key) {

    // EOF
    case CTRL+'C': return -1;

    // RETURN
    case 10: case 13:
      return strlen(ln);

    // BS/DELETE
    case 8: case 127:
      if (*ln) {
        putchar(8); putchar(' '); putchar(8);
        ln[strlen(ln)-1]= 0;
      }
      break;

    // Redraw
    case CTRL+'L': putchar('\n'); goto redraw;

    // char
    default: {
      int z= strlen(ln);
      if (z+1 < *szp) {
        ln[z+0]= key;
        ln[z+1]= 0;
        putchar(key);
      }
    } break;

    }
  } while(1);
}

#undef DID

#ifdef getlines_FOO
// Returns: an mallocated string
//          or NULL on end of file
char* readline (const char *prompt) {
  return NULL;
}

char* fgets(char* s, int size, FILE *stream) {
}

ssize_t getline(char** lineptr, size_t* n, FILE* stream) {
//}

ssize_t getdelim(char** lineptr, size_t* n, int delim, FILE* stream) {
}
#endif // getlines_FOO

#ifdef NOTHING

// Dummys for ./r script
int T,nil,doapply1,print;

// minimial... lol (if no other code -- Play/main.c == 2106 Bytes)
void main() {
  char c;
  clrscr();

  main_oric();

  exit(1);

  puts("FOOBAR fiefum"); putchar('!'); putint(666); cputc('?');

  for(c=0; c<8; ++c) { putchar(c); putint(c); putchar(' '); putchar('\n'); }
  for(c=16; c<16+8; ++c) { putchar(c); putint(c); putchar(' '); putchar('\n'); }

  while(1) {
    c=getchar();
    putchar(c);
  }
}

#endif // NOTHING

#ifdef EMACSTERM

#define COMPRESS_PROGRESS
#include "compress.c"

// Dummys for ./r script
int T,nil,doapply1,print;

void main() {

  // StupidTerm to test out control keys...

#define HIRESSCREEN ((char*)0xA000) // $A000-BF3F
#define HIRESSIZE   8000
#define HIRESEND    (HIRESSCREEN+HIRESSIZE)

#define HIRESROWS   200
#define HIRESCELLS  40

#define HIRESTEXT   ((char*)0xBF68) // $BF68-BFDF
#define HIRESTEXTSIZE 120
#define HIRESTEXTEND (HIRESTEXT+HIRESTEXTSIZE)

#define HIRESCHARSET ((char*)0x9800) // $9800-9BFF
#define HIRESALTSET  ((char*(0x9C00) // $9C00-9FFF

  // 1080 chars
  char* sherlock= "THE COMPLETE SHERLOCK HOLMES Arthur Conan Doyle Table of contents A Study In Scarlet The Sign of the Four The Adventures of Sherlock Holmes A Scandal in Bohemia The Red-Headed League A Case of Identity The Boscombe Valley Mystery The Five Orange Pips The Man with the Twisted Lip The Adventure of the Blue Carbuncle The Adventure of the Speckled Band The Adventure of the Engineer's Thumb The Adventure of the Noble Bachelor The Adventure of the Beryl Coronet The Adventure of the Copper Beeches The Memoirs of Sherlock Holmes Silver Blaze The Yellow Face The Stock-Broker's Clerk The \"Gloria Scott\" The Musgrave Ritual The Reigate Squires The Crooked Man The Resident Patient The Greek Interpreter The Naval Treaty The Final Problem The Return of Sherlock Holmes The Adventure of the Empty House The Adventure of the Norwood Builder The Adventure of the Dancing Men The Adventure of the Solitary Cyclist The Adventure of the Priory School The Adventure of Black Peter The Adventure of Charles Augustus Milverton The Adventure of the Six Napoleons The Adventure of the Three Stor";

  int u= -1, n, k;

  init_conioraw(); // turn of ORIC BASIC cursor...


  #ifdef HIRES
  // hires();
  memcpy(HIRESCHARSET, CHARSET, 256*8); curmode= curscr[SCREENSIZE-1]= HIRESMODE;
  // gclear();
  memset(HIRESSCREEN, 64, HIRESSIZE);
  #endif // HIRES

  gotoxy(0, 1);

  paper(*YELLOW);
  ink(*MAGNENTA);

  //puts(KESC "[20;13H*HERE!");

  while(1) {
    //printf(STATUS INVERSE "-OriMacs:-- *scratch*   L%2dc%2d " ENDINVERSE RESTORE,
    //wherey(), wherex());
    //puts(STATUS32); printkey(k); puts(" " RESTORE);

    // show cursor, wait for char
    *curp ^= 128;
    k=getchar();
    *curp ^= 128;

    // Terminal implementation code!
    // TODO: why is it needed again?
    // is keyboard mapping wrong?
    // CTRL-M hmmm, CRRL-J, hmmm, RETURN
    if (k & RETURNBIT) k= '\n';

    if ((char)k==CTRL+'Z') {
      char* saved;
      Compressed* zip;
      int i;
      unsigned int C, rle;
      curscr[SCREENSIZE+1]= 0; // lol // TODO: remove!
      saved= strdup(TEXTSCREEN+40);
      rle= RLE(TEXTSCREEN+40, SCREENSIZE-40);
      gotoxy(32, 0); printf("RLE=%4d ", rle);

      C= time();
      //zip= compress(TEXTSCREEN+40, SCREENSIZE-40);
      zip= compress(TEXTSCREEN+40, rle);
      assert(zip);
      C= C-time();
      while((char)kbhit()!=CTRL+'C') {
        int ol= strlen(saved), n= zip->len;
        unsigned int T;
        clrscr();
        asm("CLI"); // TODO: ??
        T= time();
        decompress(zip, TEXTSCREEN+40);
        unRLE(TEXTSCREEN+40, zip->origlen, SCREENSIZE-40);
        //i = strprefix(TEXTSCREEN+40, saved);
        //if (i<=0) { gotoxy(10, 25); printf("DIFFER AT POSITION: %d\n", i); }
        printf(STATUS "=>%3d%% %4d/%4d z=%u hs dez=%u hs\n\n" RESTORE, (int)((n*10050L)/ol/100), n, (int)ol, C, T-time());
        wait(50);
      }
    }
    if ((char)k==CTRL+'X') {
      char i, j;
      for(i=0; i<40; ++i) {
        for(j=0; j<i; ++j) cputc(' ');
        puts("Compresz");
      }
    }
    if ((char)k==CTRL+'C') {
      puts(sherlock);
    } 

    // repeat character/take argument
    if ((char)k==CTRL+'U' && u<0) u*= 4;
    else if (abs(u) > 1 && isdigit((char)k)) {
      if (u<0) u=0;
      u= 10*u + (char)k-'0';
    } else {
      // print char! (n-times?)
      n= u<0? -u: u;
      if (n>1080) n= SCREENSIZE;
      do {
        putchar(k);
      } while(--n > 0);
      u= -1;
    }
  }
}

#endif // EMACSTERM

// TODO: ANYKEY etc are missing... need to remap, maybe to ESC?

#ifdef TEST

// useless test of conio-raw.c

#ifdef DEMO_BORKEN
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
#endif // DEMOBORKEN

#define COMPRESS_PROGRESS
#include "compress.c"

// Dummys for ./r script
int T,nil,doapply1,print;

void main() {
  unsigned int i= 1, k= 0;

  init_conioraw();

  savescreen();
  clrscr();

  switch(4) {

  case 4:
    {
      char *ln= NULL;
      unsigned int lnz= 0;
      int r;
      printf("start getline\n");
      //ln= calloc(lnz= 3, 1);
      while((r= editline("prompt> ", &ln, &lnz))>=0) {
        printf("\n=> %d >%s< #%d\n", r, ln, lnz);
      }
      free(ln);
      printf("end getline\n");
    }

  case 1:
    // just scroll test
    while(!kbhit()) {
      printf("row %d\n", i++);
      wait(5);
    } break;

  case 3: {
    // panning around
    // TODO: make a function
    // TODO: use the asm from...  somewhere...
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

    // TODO: make scrollkey()?

    // pan-around w wrap
    while(1) {
      switch(cgetc()) {
      case KEY_DOWN:
          asm("SEI");
        memcpy(buff, TEXTSCREEN, 40);
        memmove(TEXTSCREEN, TEXTSCREEN+40, SCREENSIZE-40);
        memcpy(curscr+SCREENSIZE-40, buff, 40);
          asm("CLI");
        break;
      case KEY_UP:
        memcpy(buff, curscr+SCREENSIZE-40, 40);
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
  //default: demo(); break;

  }

  restorescreen();
}

#endif // TEST
