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

#include <conio.h>
//#include <peekpoke.h>

///#include "simconio.c"
//void revers(char) {}

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

void savecursor() {
  //printf("[s"); // TODO: only vt100
  x= wherex(); y= wherey();
  w= SCREENROWADDR;
}

void restorecursor() {
    // restore cursor
    //printf("[u"); // TODO: only vt100
    // gotoxy(x, y); // doesn't work!
    // POKE#268,D
    // POKE4269,A
    // DOKE#12, DEEK(#27A)+(D – 1)*40
    //printf("\n(*%d;%d*)", x, y);
    *(char*)0x268= y;
    *(char*)0x269= x;
    //*(int*)0x12= (*(int*)0x27a)-(y-1)*40;
    SCREENROWADDR= w;
}

// TextMode, Graphics mode: 

#define CHARSET    (0xB400) // -0xB7FF
#define ALTSET     (0xB800) // -0xBB7F
#define TEXTSCREEN (0xBB80) // -0xBF3F
#define SCREENXY(x, y) ((char*)(TEXTSCREEN+40*(y)+(x)))

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
    //printf("(CLEAR:%d", ++clear);
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

    //printf(" REDRAW:%d", ++redraw);
    //printf(" XPOS=%d", xpos);
    //printf(" KEY=%d)\n", lastkey);

    // fix cur in bounds
    if (cur < e) cur= e;
    if (cur > e+elen) cur= e+elen;

    // 0276-#0277  timer
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

int main(int argc, char** argv) {
  edit(buff, sizeof(buff));
  return 0;
}
#endif // EMACS

