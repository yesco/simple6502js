// deCompressZ - Companion to txt2tzt.c

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
  char c, u;

  while((c=nextc()) != 255) {
    u= c & 0x7f;
    if (u<32) {
      if (u!=c) pc(';');
      pc('\n');
      while(u>10) {
        pc(' '); --u;
      }
    } else {
      pc(u);
      if (u!=c) pc(' ');
    }
  }
  --in;

  // report savings
  fprintf(stderr, "[Restored %d bytes from (%d/%d) => %d%%]\n",
          out-in, in, out, in*100/out);
  return 0;
}
