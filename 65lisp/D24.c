#include <stdio.h>
#include <assert.h>
#include <ctype.h>

typedef unsigned long D24;

// TODO: macro?
D24 d24(long m, int e) {
  // TODO: negative?
  //printf("a--- %ld %d\n", m, e);
  while(m & 0xff0000) {
    m/= 100; e+= 2;
    //printf("b--- %ld %d\n", m, e);
  }
  while((m & 0xff0000) && e<=-2) {
    m/= 100; e+= 2;
  }
  while(!(m % 100) && e<= -2) {
    m/= 100; e+= 2;
}    
  return (((long)e)<<16) + m;
}

D24 dmul(D24 a, D24 b) {
  long r= (a&0xffff)*(b&0xffff), e= (a&0xff0000) + (b&0xff0000);
  //printf("1--- %ld %ld\n", r, e>>16);
  while(r & 0xff0000) {
    r/= 100; e+= 0x020000;
    //printf("2--- %ld %ld\n", r, e>>16);
  }
  return r | e;
}

D24 ddiv(D24 a, D24 b) {
  long am= (a&0xffff); int ae= a&0xff0000;
  int bm= b&0xffff, be= b&0xff0000;
  long r= 0;
  // erh, this is never guaraneed to work!!!
  while(am & 0xffff) {
    // TODO: make sure it doesn't overflow?
    // if > ... break;
    am*= 100; ae-= 0x020000;
    r+= 50; // TODO: roudning-ish... lol
  }
  am+= r; // round? ??????
  // TODO: maybe not >> 16 but adjust e and let normalize?
  return d24((am/bm), ((ae-be)>>16));
}

void dput(D24 a) {
  int e= a>>16;
  if (e>16 || e<0) {
    printf("%dE%+d", (int)(a&0xffff), e);
    return;
  }
  printf("%d", (int)(a&0xffff));
  while(e>0) { putchar('o'); e--; }
}


int main(int argc, char** argv) {
  long a= 270, b= 42;
  printf("\n%ld * %ld =%ld\n", a, b, a*b);
  D24 xa= d24(a, 0), xb= d24(b, 0);
  dput(xa); putchar('\n');
  dput(xb); printf("\n\n");
  D24 xm= dmul(xa,xb);
  dput(xm); printf("\t<=== *\n\n");
  dput(ddiv(xm, xa)); printf("\t<= m/270\n");
  dput(ddiv(xm, xb)); printf("\t<= m/42\n\n");
  dput(dmul(d24(248248248, 0), d24(12, 0))); printf("\n%.16g  right mul\n\n", 248248248.0*12);
  dput(ddiv(d24(248248248, 0), d24(12, 0))); printf("\n%.16g  right div\n\n", 248248248.0/12);
  dput(ddiv(d24(12, 0), d24(248248248, 0))); printf("\n%.16g  right div\n\n", 12.0/248248248.0);
}
