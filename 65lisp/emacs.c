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
#include <assert.h>

//#include <conio.h>
//#include <peekpoke.h>
///#include "simconio.c"

#include "conio-raw.c" // LOL, no .h

// Dummys for ./r script
int T,nil,doapply1,print;

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

// cursor
char xx=0, yy=1;

// TODO: resize
void edit(char* e, size_t size) {
  char *p= e, *cur= e, *sl, *el, *last= e+size-1, k;
  int xpos= -1, yank= 0, elen, curlen;

  // debugging TODO: remove 
  int clear= 0, redraw= 0; char lastkey= 0;

  cputsxy(0, 0, "65emacs (c) 2024 Jonas S Karlsson");

  *last= 0; // end used as yank buffer
  do {
    // -- update screen
    clrscr();
    //printf("(CLEAR:%d", ++clear);

  cursor:
    // show guessed cursor, will be overwritten here...
    *SCREENXY(xx,yy) |= 128;
    gotoxy(0, 1);

    // turn off cursor? doesn't seem right...

    SCREENSTATE&= 0xfe;

#ifdef EMDEFUG
    printf(" REDRAW:%d", ++redraw);
    printf(" XPOS=%d", xpos);
    printf(" KEY=%d)\n", lastkey);
#endif
    // fix cur in bounds
    if (cur < e) cur= e;
    if (cur > e+elen) cur= e+elen;

    // 270 curon
    //*(char*)0x270= 0;

    // print till current cursor
    if (cur!=e) printf("%.*s", (int)(cur-e), e);

    savecursor();
    *SCREENXY(wherex(), wherey())   |= 128;
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
    xx=wherex(); yy=wherey();

    elen= strlen(e);
    curlen= elen + cur-e;

  next:
    xpos= -1;
    // cursor on
    //*SCREENXY(x, y) |= 128;
    // -- process key
    // TODO: cursor only vis if loop?
    while(!kbhit()) *SCREENXY(wherex(), wherey()) |= 128;
    k= cgetc();
    if (k==27) k= 128+cgetc()-32;

    lastkey= k;

    switch(k) {

    // movement
    // TODO: make a search fun?
    case META+'<': case META+'V':cur= e; goto cursor;
    case META+'>': case CTRL+'V':cur= e+elen; goto cursor;

      // TODO: improve speed of cursor navigation!
    case CTRL+'P': case KEY_UP: xpos= cur-sl+1; cur= sl-1; yy=--wherey(); goto cursor;
    case CTRL+'A': cur= sl; goto cursor;
    case CTRL+'B': case KEY_LEFT: --cur; xx=--wherex(); goto cursor;
    case CTRL+'F': case KEY_RIGHT: ++cur; xx=++wherex(); goto cursor;
// TODO: faster but 
//    case CTRL+'F': case 9: k=*cur; ++cur; xx=++x;
//      if (k=='\n') goto cursor;  putchar(k); goto updateline;
    case CTRL+'N': case KEY_DOWN: xpos= cur-sl+1; cur= el+1; yy=++wherey(); goto cursor;
    case CTRL+'E': cur= el; goto cursor;

    // exit/other
    case CTRL+'C': case CTRL+'X': return;

    // cut and paste (CTRL-K and CTTRL-Yank)
    // TODO: erm code ugly...
    // TODO: CTRL-K on '(' will cut only till matching ')' !
    // TODO: conflict with arrows! remove META
    // detect CTRL ?
    case CTRL+'K': if (*cur) do {
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
      *SCREENXY(wherex(), wherey()) &= 127;
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

  switch(0) {

    // keypos & keypressed
  case 5: clrscr(); {
    char A= keypos('A');
    assert(A);
    while(1) putchar(keypressed(A)? 'A': '.');
    return 0;
    }

    // keymatrix & kbhit & cgetc
  case 4: 
      gotoxy(0,15); savecursor();
      while (1) {
        char a;
#ifdef showmatrix
        gotoxy(0,1);
        printf("a 00 fe fd fb f7 ef df bf 7f ff\n");
        for(a=0; a<8; ++a) {
          printf("%d", a);
          if (pp(a, 0x00)!=a) {
            pp(a, 0xfe);
            pp(a, 0xfd);
            pp(a, 0xfb);
            pp(a, 0xf7);
            pp(a, 0xef);
            pp(a, 0xdf);
            pp(a, 0xbf);
            pp(a, 0x7f);
            pp(a, 0xff);
          } else {
            printf("                        ");
          }
          putchar('\n');
        }
        putchar('\n');
#endif
        if (kbhit()) {
          char c= cgetc();
          //restorecursor();
          if ((c&127)<=' ') printf("^%c", c+64);
          else if (c>=127) printf(" m-%c($%02x) ", c, c);
          else printf("%c",  c&127);
          if (c=='\r') putchar('\n');
          //savecursor();
        }
      }
      return 0;

      // testing asm
  case 3:
    while(1) {
      KeyboardRead();
      printf("%02x  ", gKey);
    }
    return 0;

      // timing of clrscr
  case 2:
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

    // testing putchar?
  case 1:
    clrscr();
    for(y=0; y<28; ++y) {
      putchar('A'+y);
      putchar('0'+(y/10)); putchar('0'+(y%10));
      putchar('/');
      printf("-FOOBAR-%d--\n", y*40);
      return 0;
    }

    // 0 - editor
    case 0: default: break;
  }
  
  edit(buff, sizeof(buff));
  return 0;
}
#endif // EMACS

