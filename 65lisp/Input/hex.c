// hex print in C

// - for unix
//typedef unsigned int word;
//#include <stdio.h>

// cc65:  +78 B
// mc02: +150 B  (- 286 136)
// TODO: can save (+ 12 10 6 3 1 1 2) = 35
word printh(word n) {
  if (15<n) printh(n>>4);
  n&= 15;
  if (n<10) return putchar(n+'0');
  return putchar(n+'7'); // 'A'-10
}

word main() {
  printh(0x4321);
}

