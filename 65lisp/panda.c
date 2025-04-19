//#define MAIN
//#include "conio-raw.c"

#include <stdlib.h>
#include <stdio.h>

// dummy
char nil, T, print, doapply1;

void panda(char* cmd) {
  char c;
  --cmd;
 next:
  switch(c= *++cmd) {
  case 0: return;
  case ' ': putchar(' '); goto next;
  default:
    if (c>='0' && c<='9') putchar(c); goto next;
    printf("Illegcal command: '%c' of \"%s\"\n", c, cmd);
    exit(1);
  }
}

//int main(int argc, char** argv) {
int main(void) {
  char* cmd= "1 2 3 4 5";
  printf("Panda> %s\n", cmd);
  panda(cmd);
  putchar('\n');

  putchar('\n');
  return 42;
}
