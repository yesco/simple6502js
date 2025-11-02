// Test on itself:
//
// clang Play/txt2tzt.c && ./a.out < Play/txt2tzt.c > Play/txt2tzt.c.tzt ; ls -l Play/txt2tzt.c*

#include <stdio.h>

unsigned int in= 0, out= 0;

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
        c= nextc();
      } else c= nc;
      // count spaces
      n= 0;
      while(n<30) {
        if (c==' ') ++n;
        else if (c=='\t') n+= tabsize;
        else break;
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

  // report savings
  fprintf(stderr, "[Saved %u bytes giving (%u/%u) => %u%%]\n",
          in-out, out, in, out*100/in);
  return 0;
}
