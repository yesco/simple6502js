// BYTE SIEVE PRIME benchmark
typedef unsigned int word;

#include <stdio.h>

#define SIZE 8192
word n, c, i, p, k;
char flag[SIZE];
int main(){
  n=0; do {
    c=0;
    i=0; do flag[i++]= 1; while(i<SIZE);
    i=0; do {
      if (flag[i]) {
        p= i+i+3;
        k=i+p; while(k<SIZE) {
          flag[k]= 0;
          k+=p;
        }
        ++c;
      }
      ++i;
    } while(i<SIZE);
    printf("%u", c);
    ++n;
  } while(n<10);
  return c;
}
