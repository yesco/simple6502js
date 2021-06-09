// Is this safe???

#include <stdio.h>

// https://en.cppreference.com/w/cpp/language/eval_order
// 20) In every simple assignment expression
//     E1=E2 and every compound assignment
//     expression E1@=E2, every value computation
//     and side-effect of E2 is sequenced before
//     every value computation and side effect of E1

typedef unsigned char byte;

int __;

int* after(byte *r) {
  static int _;

  printf("after: *r=%d d=%d\n", *r, __);

  *r = __ & 0xff;

  return &_; // safe as it's static!
}

int main() {
  byte a= 1, b= 2, c= 3;

  *(after(&a)) = __ = 11;
  
  printf("later=%d\n", a);
}
