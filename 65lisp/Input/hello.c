// Hello World! - loops

#include <stdio.h>

typedef unsigned int word;

word i;

word spaces(word n) {
  while(n--) putchar(' ');
}

int main() {
  for(i=0; i<150; ++i) {
    spaces(i);
    printf("%s","Hello World!");
  }
}

