#include <stdio.h>
#include <assert.h>
#include <ctype.h>

typedef unsigned int D12;

// TODO: macro?
D12 d12(long m, int e) {
  // TODO: negative?
  while(m & 0xff00) {
    m/= 10; e++;

  }
  return e*256 + m;
}

D12 dmul(D12 a, D12 b) {
  int r= (a&0xff)*(b&0xff), e= (a&0xff00) + (b&0xff00);
  while(r & 0xff00) {
    r/= 10; e+= 0x0100;
  }
  return r | e;
}

D12 ddiv(D12 a, D12 b) {
  int am= ((a&0xff)+4)*100, ae= a&0xff00;
  int bm= b&0xff, be= b&0xff00;
  return d12((am/bm), ((ae-be)>>8)-2);
}

void dput(D12 a) {
  int e= a>>8;
  if (e>8 || e<0) {
    printf("%dE+%d", a&0xff, a>>8);
    return;
  }
  printf("%d", a&0xff);
  while(e>0) { putchar('o'); e--; }
}


int main(int argc, char** argv) {
  long a= 270, b= 42;
  printf("\n%ld * %ld =%ld\n", a, b, a*b);
  D12 xa= d12(a, 0), xb= d12(b, 0);
  dput(xa); putchar('\n');
  dput(xb); putchar('\n');
  D12 xm= dmul(xa,xb);
  dput(xm); printf("\n");
  dput(ddiv(xm, xa)); printf("\n");
  dput(ddiv(xm, xb)); printf("\n");
}
