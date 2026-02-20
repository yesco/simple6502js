#include <stdio.h>
#include <stdint.h>

typedef uint16_t word;

word xs= 1;

word xorshift() {
  xs ^= xs << 7;
  xs ^= xs >> 9;
  xs ^= xs << 8;
  return xs;    
}


word j,i,s;

int main() {
  s= 0;
  j=0; while(j<5) { ++j;
    i= 0; while(++i) {
      s+= xorshift();
      //printf("%u", xorshift()); putchar('\n');
    }
  }
  return s;
}
