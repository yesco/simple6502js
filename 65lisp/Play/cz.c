// (>) 2025 Jonas S Karlsson, jsk@yesco.org
//
// cz: Simple C source compression program.
//
// CompreZzes to about 70% of itself.
//
// Simple scheme, in order to save space on
// editing on 6502 to save memory:
//
// [;] LF ' '*n  => char(( LF+n) | hibitIfSemicolon)
//
// \w ' '        => char(\1 + | hibitIfSpaceFollows)
//

// Test on itself:
//
// clang Play/cz.c && ./a.out < Play/cz.c > Play/cz.c.cz ; clang Play/uncz.c && ./a.out < Play/cz.c.cz > Play/cz.c.cz.c ; ls -l Play/cz.c* Play/uncz.c*

#include <stdio.h>

int in= 0, out= 0;

char tabsize= 8;

char nextc() {
  ++in;
  return fgetc(stdin);
}

char pc(char c) {
  ++out;
  return putchar(c);
}


int main() {
  char c, nc, n;
  char semi= 0;

  nc= nextc();
  while( (c=nc) != 255) {
    semi= 0;
    // semicolon+NL+n spcs sets hibit!
    if (c==';') {
      semi= 0x80;
      c= nextc();
    }
    // spaces are compressed
    // 10= newline
    //  9= tab (2 or 8 spaces?)
    if (c==10 | c==13) {
      nc= nextc();
      if (nc!=c && (nc==10 || nc==13)) {
        // ignore redundant char (CRLF)
        nc= nextc();
      }
      // count spaces
      n= 0;
      while(nc!=255 && n<30) {
        if (nc==' ') ++n;
        else if (nc=='\t') n+= tabsize;
        else break;
        nc= nextc();
      }
      // output compresed NL+spaces
      pc(('\n'+n) | semi);
      semi= 0;
    } else {
      if (semi) pc(';');
      // look ahead
      nc= nextc();
      if (nc==' ') {
        pc(c | 0x80);
        nc= nextc();
      }
      else pc(c);
    }
  }   
  --in;

  // report savings
  fprintf(stderr, "[Saved %d bytes giving (%d/%d) => %d%%]\n",
          in-out, out, in, out*100/in);
  return 0;
}
