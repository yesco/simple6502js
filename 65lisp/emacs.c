// 65EMACS - An EMACS style editor for 6502
// (>) 2024 Jonas S Karlsson, jsk@yesco.org
//
// Edits a multiline string inside a given buffer.
//
// Limitations:
// - buffer as given by user is fixed, never resized
// - lines longer than 38 wraps and it gets meessy
//   (use CTRL-L to redraw screen)
// - more lines than fit will not display/edit correctly

// Adds 4552 bytes to PROGSIZE
//
// TODO: how big in lisp and in bytecode?
//
//
// MOVEMENT
//
//   CTRL-B    - back one char
//   CTRL-F    - forward one char
//
//   CTRL-P    - prev line
//   CTRL-N    - next line
//
//   CTRL-A    - beginning of line
//   CTRL-E    - end of line
//
//   ESC <     - beginning of file (ESC v)
//   ESC >     - end of file (CTRL-V)
//
//
// EDITING
//
//   Backspace - del previous char
//   CTRL-D    - del next char
//
//   CTRL-O    - insert new line before cursor (\n CTRL-B)
//
//
// CUT'N'PASTE
//
//   CTRL-K    - kill (cut till end of line, or at end, cut end)
//   CTRL-Y    - Yank *all* cuttings stored
//   CTRL-G    - clear yank buffer
//
// OTHER
//
//   CTRL-X/C  - exit

// Features:
// - keep x-position of previous row when go up/down
//
// Limitations: (for now)
// - lines must fit on screen (or will wrap)
// - doesn't grow buffer
// - redraws screen every key stroke (LOL)

#include <stdio.h>
#include <string.h>

//#include <conio.h>
//#include <peekpoke.h>
///#include "simconio.c"
//void revers(char) {}

// hundreths of second
unsigned int time() {
  return *(unsigned int*)0x276;
}

// Do my own screen print

// TextMode, Graphics mode: 
#define CHARSET    (0xB400) // -0xB7FF
#define ALTSET     (0xB800) // -0xBB7F
#define TEXTSCREEN ((char*)0xBB80) // -0xBF3F
#define SCREENSIZE (28*40)
#define SCREENEND  (TEXTSCREEN+SCREENSIZE)

#define SCREENXY(x, y) ((char*)(TEXTSCREEN+40*(y)+(x)))

char curx=0, cury=0, *cursc= TEXTSCREEN;

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

#define wherex() curx
#define wherey() cury

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

// Dummys for ./r script
int T,nil,doapply1,print;

#define CTRL 1-'A'
#define META 128

// TODO: these are buffered! use elsewhere
//k= getchar();
//if (k==27) k= 128+getchar()-32;

// status location is at #26A.
//  1 – cursor ON when set.
//  2 – screen ON when set.
//  4 – not used.
//  8 – keyboard click OFF when set.
// 16 – ESC has been pressed.
// 32 – columns 0 and 1 protected when set.
#define SCREENSTATE *((char*)0x26a)

#define SCREENROWADDR *((int*)0x12)

char x,y; int w; int s;
char xx,yy;
char savex=0, savey=0;

#define savecursor() do { savex= wherex(); savey= wherey(); } while(0)
#define restorecursor() gotoxy(savex, savey)

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

#define MEM(a) *((char*)a)

char key(char row, char x) {
  // - set row
  MEM(0x0300)= row;
  // - select column register
  MEM(0x030f)= 0x0e;
  // - tell AY register number
  MEM(0x030c)= 0xff;
  // -- clear CB2 (prevents hang?)
  MEM(0x030c)= 0xdd;
  // -- write column register
  MEM(0x030f)= x;
  MEM(0x030c)= 0xfd;
  MEM(0x030c)= 0xdd;
  // and #08  ???
  return MEM(0x0300);
}

int unc= 0;
char keybits[8]={0};

char kbhit() {
  if (!unc) {
    static const char MASK[]= {
      0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F };
    char row= 0, c= 0, col, v, k;
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



// TODO: resize
void edit(char* e, size_t size) {
  char *p= e, *cur= e, *sl, *el, *last= e+size-1, k;
  int xpos= -1, yank= 0, elen, curlen;

  char homex, homey; int homew;

  // TODO: remove 
  int clear= 0, redraw= 0; char lastkey= 0;

  cputsxy(0, 0, "65emacs (c) 2024 Jonas S Karlsson");

  *last= 0; // end used as yank buffer
  do {
    // -- update screen
    //clrscr();
    putchar(12);
    printf("(CLEAR:%d", ++clear);
    savecursor();
    homex= x; homey= y; homew= w;

  cursor:
    // show guessed cursor

    *SCREENXY(xx,yy) |= 128;

    x= homex;
    y= homey;
    w= homew;
    restorecursor();
    // turn off cursor? doesn't seem right...

    SCREENSTATE&= 0xfe;

    printf(" REDRAW:%d", ++redraw);
    printf(" XPOS=%d", xpos);
    printf(" KEY=%d)\n", lastkey);

    // fix cur in bounds
    if (cur < e) cur= e;
    if (cur > e+elen) cur= e+elen;

    // 270 curon
    //*(char*)0x270= 0;

    // print till current cursor
    if (cur!=e) printf("%.*s", (int)(cur-e), e);

    savecursor();
    *SCREENXY(x,y)   |= 128;
    *SCREENXY(xx,yy) &= 127;

    //printf("<<<%d;%d>>>", x, y);

    // clear till end of line
    //cclear(40-x);
    // cclearxy(x,y,length);

    // print rest of edited text
    if (cur<e+size) printf("%s<<<\n", cur);

    // show yank buffer if not empty
    if (*last) {
      revers(1); printf("\n\nYANK>>>"); revers(0);
      p= last; yank= 0;
      while(*p) putchar(*p--),yank++;
      revers(1); printf("<<<\n"); revers(0);
    }
    //printf("\n: cur=%d size=%d yank=%d size=%d\n", cur-e, strsize(e), yank, size);
    //revers(1); printf("65EMACS ESC< ^APNBFOE^DHKYG ESC> ^X\n"); revers(0);

    restorecursor();

    //SCREENSTATE|= 1;

    // start of line, end of line
    sl= cur; while(sl>e && sl[-1]!='\n') --sl;
    el= cur; while(*el && *el!='\n') ++el;

    // adjust for x column ctrl-P and ctrl-N (must be here after new sl/el)
    // TODO: can do more efficient?
    if (xpos>=0) { --xpos; cur= (sl+xpos<=el)? sl+xpos: el; xpos=-1; goto cursor; }
    // update cursor actual position
    xx=x; yy=y;

    elen= strlen(e);
    curlen= elen + cur-e;

  next:
    xpos= -1;
    // cursor on
    //*SCREENXY(x, y) |= 128;
    // -- process key
    // TODO: cursor only vis if loop?
    while(!kbhit()) *SCREENXY(x, y) |= 128;
    k= cgetc();
    if (k==27) k= 128+cgetc()-32;

    lastkey= k;

    switch(k) {

    // movement // TODO: simplier, make a search fun?
    case META+'<': case META+'V':cur= e; goto cursor;
    case META+'>': case CTRL+'V':cur= e+elen; goto cursor;
    case CTRL+'P': case 11: xpos= cur-sl+1; cur= sl-1; yy=--y; goto cursor;
    case CTRL+'A': cur= sl; goto cursor;
    case CTRL+'B': case 8: --cur; xx=--x; goto cursor;
    case CTRL+'F': case 9: ++cur; xx=++x; goto cursor;
// TODO: faster but 
//    case CTRL+'F': case 9: k=*cur; ++cur; xx=++x;
//      if (k=='\n') goto cursor;  putchar(k); goto updateline;
    case CTRL+'N': case 10: xpos= cur-sl+1; cur= el+1; yy=++y; goto cursor;
    case CTRL+'E': cur= el; goto cursor;

    // exit/other
    case CTRL+'C': case CTRL+'X': return;

    // cut and paste (CTRL-K and CTTRL-Yank)
    // TODO: erm code ugly...
    // TODO: CTRL-K on '(' will cut only till matching ')' !
    // TODO: conflict with arrows! remove META
    // detect CTRL ?
    case META+CTRL+'K': if (*cur) do {
          k= *cur; memmove(cur, cur+1, e+size-cur-1); *last= k;
        } while(*cur && *cur!='\n' && k!='\n'); break;
    case CTRL+'Y': if (elen+2*yank>size-5) break; // safe
      p= last; while(*p) {
        k= *p--; memmove(cur+1, cur, curlen+1); *cur= k;
      } break;
    case CTRL+'G': memset(e+elen, 0, size-elen); break;

    // edit
    case 127: if (cur==e) break;
      --cur; k=*cur; memmove(cur, cur+1, elen);
      if (k=='\n') break;  putchar(8); goto updateline;
    case CTRL+'D': k=*cur; memmove(cur, cur+1, elen);
      //putchar(*cur); putchar(8);
      if (k=='\n') break;  goto updateline;
    case CTRL+'O': memmove(cur+1, cur, elen); *cur= '\n'; break;
    default: if ((k>=' ' && k<127) || k==13) {
      if (k==13) k= '\n';
      memmove(cur+1, cur, elen); *cur= k; ++cur;
      if (k<' ') break; // redraw
      putchar(k);
    updateline:
      //SCREENSTATE &= 127;
      *SCREENXY(x, y) &= 127;
      savecursor();
      p= cur;
      while(*p && *p!='\n' && *p!='\r') putchar(*p),++p;
      putchar(' ');
      restorecursor();
      *SCREENXY(xx, yy) |= 128;
      goto next;
      }
    }
  } while(1);
}


#ifndef EMACS 
char buff[2014]=
  "this is a longer\n  program that is\n    indented and many lines\n    more lines\n    and more\n  and less indent\n  same   and more\nlast lines coming\nalso last lines\nbut this is the last line\nsorry end\n"

  "this is a longer\n  program that is\n    indented and many lines\n    more lines\n    and more\n  and less indent\n  same   and more\nlast lines coming\nalso last lines\nbut this is the last line\nsorry end\n"
;

char pp(char a, char x) {
  char k= key(a, x);
  if (k!=a)
    printf(" %02x", k&(255-8));
  else
    printf("   ");
  return k;
}

int main(int argc, char** argv) {
  int i, j= 10;
  char x, y;
  unsigned int start= time();

  if (1){
  if (0) {
    while(1) {
      KeyboardRead();
      printf("%02x  ", gKey);
    }
  } else {
      gotoxy(0,15); savecursor();
      while (1) {
        char a;
#ifdef FOOR
        gotoxy(0,1);
        printf("a 00 FE FD FB F7 EF DF BF 7F FF\n");
        for(a=0; a<8; ++a) {
          printf("%d", a);
          if (pp(a, 0x00)!=a) {
            pp(a, 0xFE);
            pp(a, 0xFD);
            pp(a, 0xFB);
            pp(a, 0xF7);
            pp(a, 0xEF);
            pp(a, 0xDF);
            pp(a, 0xBF);
            pp(a, 0x7F);
            pp(a, 0xFF);
          } else {
            printf("                        ");
          }
          putchar('\n');
        }
        putchar('\n');
#endif
        asm("SEI");
        if (kbhit()) {
          char c= cgetc();
          //restorecursor();
          if ((c&127)<=' ') printf("^%c", c+64);
          else if (c>=127) printf(" M-%c($%02x) ", c, c);
          else printf("%c",  c&127);
          if (c=='A') putchar('\n');
          //savecursor();
        }
        asm("CLI");
      }
    }
  }
  switch(1) {
  case 1:
    while(j--) {
      clrscr();
      //for(i=28*40+1;--i;) putchar('A');
      for(y=29;--y;)
        for(x=41;--x;)
          putchar('A'+28-y);
    }
    clrscr();
    printf("\nTIMEhs: %u\n", start-time());
    return 0;
  case 2:
    clrscr();
    for(y=0; y<28; ++y) {
      putchar('A'+y);
      putchar('0'+(y/10)); putchar('0'+(y%10));
      putchar('/');
      printf("-FOOBAR-%d--\n", y*40);
      return 0;
    }
    default: break;
  }
  
  edit(buff, sizeof(buff));
  return 0;
}
#endif // EMACS

