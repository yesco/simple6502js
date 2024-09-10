// 65EMACS - An EMACS style editor for 6502
// (>) 2024 Jonas S Karlsson, jsk@yesco.org
//
// Edits a multiline string inside a given buffer.
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
//   Backspace - del previous char
//   CTRL-D    - del next char
//
//   CTRL-O    - insert line before cursor (\n CTRL-B)
//
//   CTRL-K    - kill (cut till end of line, or on end, cut end)
//   CTRL-Y    - Yank all cuttings stored
//   CTRL-G    - clear yank buffer
//
// Features:
// - keep x-position of previous row when go up/down
//
// Limitations: (for now)
// - lines must fit on screen
// - doesn't grow buffer
// - redraws screen every key stroke (LOL)


#include <stdio.h>
#include <string.h>

#include "simconio.c"

#define CTRL 1-'A'
#define META 128

// TODO: resize
void edit(char* e, size_t len) {
  char *p= e, *cur= e, *sl, *el, *last= e+len-1, k;
  int x= 0, yank= 0;
  *last= 0; // end used as yank buffer
  do {
    // update screen
    clrscr();
    if (cur!=e) printf("%.*s", cur-e, e);
    printf("[s"); // save cursor
    if (cur<e+len) printf("%s<<<\n", cur);
    if (*last) {
      // show yank buffer if not empty
      printf("\n\nYANK>>>");
      p= last; yank= 0;
      while(*p) putchar(*p--),yank++;
      printf("<<<\n");
    }
    //printf("\n: cur=%d len=%d yank=%d size=%d\n", cur-e, strlen(e), yank, len);
    printf("[u"); // restore

    // start of line
    sl= cur; while(sl>e && sl[-1]!='\n') --sl;
    el= cur; while(*el && *el!='\n') ++el;

    // adjust for x column ctrl-P and ctrl-N
    if (x) { cur= (sl+x<el)? sl+x: el; x= 0; continue; } // update cursor

    // process key
    x= 0;
    k= getchar();
    if (k==27) k= 128+getchar()-32;
    switch(k) {

    // movement // TODO: simplier, make a search fun?
    case META+'<': case META+'V':cur= e; break;
    case META+'>': case CTRL+'V':cur= e+strlen(e); break;
    case CTRL+'P': x= cur-sl; cur= sl-1; break;
    case CTRL+'A': cur= sl; break;
    case CTRL+'B': --cur; break;
    case CTRL+'F': ++cur; break;
    case CTRL+'N': x= cur-sl; cur= el+1; break;
    case CTRL+'E': cur= el; break;

    // exit/other
    case CTRL+'C': case CTRL+'X': return;

    // cut and paste (CTRL-K and CTTRL-Yank)
    // TODO: erm code ugly...
    // TODO: CTRL-K on '(' will cut only till matching ')' !
    case CTRL+'K': if (*cur) do {
          k= *cur; memmove(cur, cur+1, e+len-cur-1); *last= k;
        } while(*cur && *cur!='\n' && k!='\n'); break;
    case CTRL+'Y': if (strlen(e)+2*yank>len-5) break; // safe
      p= last; while(*p) {
        k= *p--; memmove(cur+1, cur, strlen(cur)+1); *cur= k;
      } break;
    case CTRL+'G': memset(e+strlen(e), 0, len-strlen(e)); break;

    // edit
    case CTRL+'H': case 127: if (cur>e) memmove(cur-1, cur, e+len-cur); --cur; break;
    case CTRL+'D': memmove(cur, cur+1, e+len-cur-1); break;
    case CTRL+'O': memmove(cur+1, cur, e+len-cur-1); *cur= '\n'; break;
    default: if ((k>=' ' && k<127) || k=='\n') {
      memmove(cur+1, cur, e+len-cur-1); *cur= k; ++cur; } break;
    }

    // fix cur in bounds
    if (cur < e) cur= e;
    if (cur > e+strlen(e)) cur= e+strlen(e);
  } while(1);
}

int main(int argc, char** argv) {
  char buff[200]= "foobar\nfie\nfum";
  edit(buff, sizeof(buff));
  return 0;
}
