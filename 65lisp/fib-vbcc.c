//#include <stdio.h>
//#include <unistd.h>
//#include <stdlib.h>

//#include <conio.h>

//extern int print(int n) { printf("\n%d", n); return n; }

//extern int nil=0, T=0;

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

//extern unsigned int asmfib(unsigned int n);
//extern unsigned int fibinline(unsigned int n);

//extern unsigned int asmltfib(unsigned int n);

unsigned int ultfib(unsigned int n) {
  if (n<2) return n;
  return ultfib(n-1) + ultfib(n-2);
}

// VBCC: 153 bytes!!! better be fast, lol
// cc65: Inline fib best 41 bytes => 114 bytes
int ltfib(signed int n) {
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
    r= fib(n);	// 63 B    43.31s
    //r= ufib(n);	//         43.31s
    //r= ltfib(n);	//  54 B - 41.53s "best of cc65"
    z+= r;
  }
//  printf("fib %d => %d z=%ld calls=%ld   %ld c/bench\n", n, r, z, calls, calls/bench);
  return 0;
}
