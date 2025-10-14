// The idea is to test what compilers than use static
// variables for parameters passing what they do when
// two calls to same function overlap/interleave.

char T,nil,doapply1,print;

#include <stdio.h>

int f(int a, int b, int c) {
  return a+b+c;
}

int main(void) {
  // 1..9.sum = 45
  printf("=>%d", f(f(f(1,2,3),4,f(5,6,7)),8,9));
}
