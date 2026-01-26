// fibonacci recursion

// - for unix
//typedef unsigned int word;
//#include <stdio.h>
//void putu(word u) { printf("%u", u); }

word add(word a, word b) {
  return a+b;
}

word fib(word n) {
  if (n<2) return n;
  // no complex expressions (yet)
  // return fib(n-1) + fib(n-2);
  return add(fib(n-1), fib(n-2));
}

word i;
word main() {
  // 25 would overflow
  for(i=0; i<25; ++i) {
    putu(i); putchar('\t'); putu(fib(i)); putchar('\n');
  }
}
