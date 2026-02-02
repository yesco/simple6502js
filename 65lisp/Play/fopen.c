// sim6502 works!
//
// ./rawsim Play/fopen

#include <stdio.h>

int main(int argc, char** argv) {
  FILE* f= fopen("fil", "r");
  int c;
  volatile unsigned long start, end;

  printf("f= $%04x\n", f);
  while((c= fgetc(f))!=EOF) {
    putchar(c); putchar('.');
  }
  fclose(f);

  printf("\n\nKeybaord input:\n");

  while((c= fgetc(stdin))!=EOF) {
    putchar(c); putchar(c); putchar(c);
    printf("\n");
    if (c=='C'-'@') break;
  }

  printf("a\nb\nc\n   bar\rfoo\n");

  return 42;
}
