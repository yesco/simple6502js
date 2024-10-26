// vbcc: generates about 63 bytes?
// cc65: 21 bytes, 3 routines
int two(int a, int b) {
  return a+b;
}

int owt(int a, int b) {
  return b+a;
}

// cc65: 14 bytes, 4 routines, 
//  handoptimize: 6 bytes, 2 routines
int tow(int a, int b) {
  return a+=b;
}

int main() {//int argc, char** argv) {
  long bench= 3000; // 43.31s
  long i= bench;
  //long bench= 30000; // 432s
  int n= 8;
  long z= 0;
  int r= 42;
  while(--i) {
    r= two(n, n*2)+owt(n, n*2)+tow(n, n*2);
    z+= r;
  }
//  printf("fib %d => %d z=%ld calls=%ld   %ld c/bench\n", n, r, z, calls, calls/bench);
  return 0;
}
