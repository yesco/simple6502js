// 65EMACS - An EMACS style editor for 6502
// (>) 2024 Jonas S Karlsson, jsk@yesco.org
//
// Edits a multiline string inside a given buffer.
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

#include "simconio.c"

#define CTRL 1-'A'
#define META 128

// TODO: resize
void edit(char* e, size_t size) {
  char *p= e, *cur= e, *sl, *el, *last= e+size-1, k;
  int xpos= 0, yank= 0, elen, curlen;

  *last= 0; // end used as yank buffer
  do {
    // update screen
    clrscr();
    if (cur!=e) printf("%.*s", (int)(cur-e), e);
    printf("[s"); // save cursor // TODO: only vt100
    if (cur<e+size) printf("%s<<<\n", cur);

    // show yank buffer if not empty
    if (*last) {
      printf("\n\nYANK>>>");
      p= last; yank= 0;
      while(*p) putchar(*p--),yank++;
      printf("<<<\n");
    }
    //printf("\n: cur=%d size=%d yank=%d size=%d\n", cur-e, strsize(e), yank, size);
    revers(1); printf("65EMACS: ESC< ^APNBFOKYEG ESC> ^X\n"); revers(0);

    printf("[u"); // restore cursor // TODO: only vt100

    // start of line
    sl= cur; while(sl>e && sl[-1]!='\n') --sl;
    el= cur; while(*el && *el!='\n') ++el;

    // adjust for x column ctrl-P and ctrl-N (must be here after new sl/el)
    if (xpos) { cur= (sl+xpos<el)? sl+xpos: el; xpos= 0; continue; } // update cursor

    elen= strlen(e);
    curlen= elen + cur-e;

    // -- process key
    xpos= 0;
    k= getchar();
    if (k==27) k= 128+getchar()-32;
    switch(k) {

    // movement // TODO: simplier, make a search fun?
    case META+'<': case META+'V':cur= e; break;
    case META+'>': case CTRL+'V':cur= e+elen; break;
    case CTRL+'P': xpos= cur-sl; cur= sl-1; break;
    case CTRL+'A': cur= sl; break;
    case CTRL+'B': --cur; break;
    case CTRL+'F': ++cur; break;
    case CTRL+'N': xpos= cur-sl; cur= el+1; break;
    case CTRL+'E': cur= el; break;

    // exit/other
    case CTRL+'C': case CTRL+'X': return;

    // cut and paste (CTRL-K and CTTRL-Yank)
    // TODO: erm code ugly...
    // TODO: CTRL-K on '(' will cut only till matching ')' !
    case CTRL+'K': if (*cur) do {
          k= *cur; memmove(cur, cur+1, e+size-cur-1); *last= k;
        } while(*cur && *cur!='\n' && k!='\n'); break;
    case CTRL+'Y': if (elen+2*yank>size-5) break; // safe
      p= last; while(*p) {
        k= *p--; memmove(cur+1, cur, curlen+1); *cur= k;
      } break;
    case CTRL+'G': memset(e+elen, 0, size-elen); break;

    // edit
    case CTRL+'H': case 127: if (cur>e) memmove(cur-1, cur, elen); --cur; break;
    case CTRL+'D': memmove(cur, cur+1, elen); break;
    case CTRL+'O': memmove(cur+1, cur, elen-1); *cur= '\n'; break;
    default: if ((k>=' ' && k<127) || k=='\n') {
      memmove(cur+1, cur, elen); *cur= k; ++cur; } break;
    }

    // fix cur in bounds
    if (cur < e) cur= e;
    if (cur > e+elen) cur= e+elen;
  } while(1);
}

char buff[2014]= "foobar\nfie\nfum";

int main(int argc, char** argv) {
  edit(buff, sizeof(buff));
  return 0;
}
