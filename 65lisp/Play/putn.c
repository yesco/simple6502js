// --- C-style
#include <stdio.h>
#include <stdlib.h>

void putn(int i) {
  if (i<0) putchar('-'),i=-i;
  if (i>9) putn(i/10);
  putchar('0' + i%10);
}

void putnum(int i) {
  putn(i); putchar(' ');
}

// --- Forth-style
int base= 10;

#define FORMAT(n) { long _n=n, _i; char _b[256]={0}, *_p=_b+sizeof(_b)-1;
#define C(c)        *--_p= c;
#define N(d)        C(d>9? d+7: '0'+d);
#define D           N(_n%10) _n/= 10;
#define S           _i=_n;_n=labs(_n); do{D}while(_n); if(_i<0) C('-');
#define DONE        printf("%s ", _p); }

void forthy() {
  printf("---- FORTYH ---\n");

  FORMAT(4711) S DONE;
  
  FORMAT(1234567890123L) D D D C('.') D S DONE;

  putchar('\n');
}

char B[256]={0}, *p; long N;
void hbegin(long n) { N=n; p= B+sizeof(B)-1; }
void hc(char c)     { *--p= c; }
void hn(int n)      { hc(n>9? n+7: '0'+n); }
void h()            { hn(N%base); N= N/10; }
void hs()           { long n=N; N= labs(N); do { h(); } while(N); if (n<0) hc('-'); }
void hend()         { printf("%s", p); }
void hputn(long n)  { hbegin(n); hs(); hend(); }
void hputnum(long n){ putn(n); putchar(' '); }

int main(int argc, char** argv) {
  putnum(0);
  putnum(4711);
  putnum(-4711);
  putchar('\n');

  putchar('\n');

  hbegin(4771); hc('a'); hc('b'); hc('c'); hend();
  putchar('\n');

  hbegin(4771); h(); h(); hend();
  putchar('\n');

  hbegin(4771); hs(); hend();
  putchar('\n');

  hbegin(1234567890123); h(); h(); h(); hc('.'); h(); hs(); hend();
  putchar('\n');

  hbegin(-4711); hs(); hend();
  putchar('\n');

  hputnum(4711); hputnum(-4711);
  putchar('\n');

  putchar('\n');
  forthy();
}
