#include <stdio.h>

// - https://en.m.wikipedia.org/wiki/Rugg/Feldman_benchmarks

// Benchmark 5

// 300 PRINT"S"
// 400 K=0
// 500 K=K+1
// 510 LET A=K/2*3+4-5
// 520 GOSUB 820
// 600 IF K<1000 THEN 500
// 700 PRINT"E"
// 800 END
// 820 RETURN

// ORIC-ATMOS 5: 33s in BASIC

int b5sub(int k) {
  return k/2*3+4-5;
}

void b5() {
  int k= 0, a;

  putchar('S');

 loop:
  k= k+1;
  a= b5sub(k);
  if (k<1000) goto loop;
  putchar('E');
}

// 90x 32.97s ! BASIC is 90x slower...
int main(int argc, char** argv) {
  int i;
  for(i= 90; i; --i) b5();
  putchar('\n');
}
