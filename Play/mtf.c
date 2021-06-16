#include <stdio.h>

char arr[256];

int main() {
  // init
  for(int i=0; i<256; i++) {
    arr[i]= i;
  }

  int c;
  while((c= getc(stdin)) != -1) {
    // search
    int i= -1;
    while(arr[++i] != c);

    // move
    fputc(i, stdout);
    fprintf(stderr, "%d ", i);

    memmove(arr+1, arr, i);
    arr[0]= c;

    if (0) {
    if (isprint(c)) {
      printf("%02x   %c  %02x\n", c, c, i);
    } else {
      printf("%02x  %02x  %02x\n", c, c,i);
    }
    }
  }
}
