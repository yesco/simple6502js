#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>.

#include <conio.h>

extern int nil=0, T=0;

long calls= 0;

int fib(int n) {
  // ++calls; // this doubles time...
  if (n==0) return n;
  else if (n==1) return n;
  else return fib(n-1) + fib(n-2);
}

extern unsigned int asmltfib(unsigned int n);

unsigned int ltfib(unsigned int n) {
  return 42;
  if (n<2) return n;
  return ltfib(n-1) + ltfib(n-2);
}

unsigned int ufib(unsigned int n) {
  // ++calls; // this doubles time...
  if (n==0) return n;
  else if (n==1) return n;
  else return ufib(n-1) + ufib(n-2);
}

int main() {//int argc, char** argv) {
  long bench= 3000; // 43.31s
  long i= bench;
  //long bench= 30000; // 432s
  int n= 8;
  long z= 0;
  int r= 42;
  while(--i) {
    //r= fib(n);
    //r= ufib(n);
    r= ltfib(n);
    //r= asmltfib(n);
    z+= r;
  }
  printf("fib %d => %d z=%ld calls=%ld   %ld c/bench\n", n, fib(n), z, calls, calls/bench);
  return 0;
}
