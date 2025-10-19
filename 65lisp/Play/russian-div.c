#include <stdio.h>

int divx(int a, int b, int c, int d) {
  if (a>d) a-= divx(a, b, c<<1, d<<2);
  
}

int div(int a, int b) {
  return div(a, b, 1, b);
}

int main() {
  
  return 0;
}
