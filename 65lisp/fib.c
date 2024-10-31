#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#include <conio.h>

extern int prin1(int n) { printf(" %d", n); return n; }
extern int print(int n) { printf("\n%d", n); return n; }

extern int nil=0, T=0;

long calls= 0;

int fib(int n) {
  // ++calls; // this doubles time...
  if (n==0) return n;
  else if (n==1) return n;
  else return fib(n-1) + fib(n-2);
}

int fibn(int n) {
  // ++calls; // this doubles time...
  //if (n==0) return 0;
//  else if (n==1) return 1;
  if (n==0) return 1;
  else if (n==1) return 01;
  else return fib(n-1) + fib(n-2);
}

extern unsigned int asmfib(unsigned int n);
extern unsigned int asmfibpha(unsigned int n);
extern unsigned char byteasmfib(unsigned char n);
extern unsigned int fibinline(unsigned int n);

extern unsigned int asmltfib(unsigned int n);

unsigned int ultfib(unsigned int n) {
  if (n<2) return n;
  return ultfib(n-1) + ultfib(n-2);
}

int ltfib(signed int n) {
  if (n<2) return n;
  return ltfib(n-1) + ltfib(n-2);
}


unsigned int two= 2;

int twoltfib(unsigned  int n) {
  if (n<two) return n;
  return twoltfib(n-1) + twoltfib(n-2);
}

unsigned int ufib(unsigned int n) {
  // ++calls; // this doubles time...
  if (n==0) return n;
  else if (n==1) return n;
  else return ufib(n-1) + ufib(n-2);
}

int main() {//int argc, char** argv) {
  long bench= 3000;
  long i= bench;
  //long bench= 30000; // 432s
  int n= 8;
  long z= 0;
  int r= 42;

  n=8;
  while(--i) {
    //r= fib(n);	// 63 B    43.31s
    //r= ufib(n);	//         43.31s
    r= ltfib(n);	//  54 B - 41.53s "best of cc65"
    //r= asmfib(n);	//  39 B   29.17s handwritten (I can generate this!)
    //r= asmfibpha(n);	//  64 B   18.00s handwritten (using pha!) can save 17B (- 64 17) 47... only 42 recursions!
    //r= byteasmfib(n);	//  32 B    8.20s handwritten byte (using pha!)
    //r= fibinline(n);	// 114 B   21.45s inlined "all" (63 lines)
    //printf("result(%d)=%d\n", n, r);
    z+= r;
  }
  printf("fib %d => %d z=%ld calls=%ld   %ld c/bench\n", n, r, z, calls, calls/bench);
  return 0;
}
