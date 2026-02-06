// BYTE SIEVE PRIME benchmark
typedef unsigned int word;

#ifdef __CC65__
  #include <stdlib.h>
#endif

#include <stdio.h>

#define SIZE 8192
word n, c, i, p, k, m;
char *flag;
int main(){
  m= SIZE;
  flag= malloc(m);
  n=0; do {
    c=0;
    i=0; do flag[i++]= 1; while(i<m);
    i=0; do {
      if (flag[i]) {
        p= i+i+3;
        k=i+p; while(k<m) {
          flag[k]= 0;
          k+=p;
        }
        ++c;
      }
      ++i;
    } while(i<m);
    printf("%u", c);
    ++n;
  } while(n<10);
  return c;
}
