#include <stdio.h>

#define N 8192
char flags[N];

int main() {
  for(int t=0; t<10; t++) {
    int count = 0;
    for(int a=0; a<N; a++) flags[a] = 1;

    for(int a=0; a<N; a++) {
      if (flags[a]) {
        count++;
        int p=a+a+3;
        for(int b=a+p; b<N; b+=p) {
          flags[b] = 0;
        }
      }
    }
    printf("primes=%d\n", count);
  }
}
