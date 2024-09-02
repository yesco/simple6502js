#include <stdio.h>
#include <assert.h>
#include <ctype.h>

typedef unsigned int uint;
typedef unsigned long ulong;

typedef unsigned long D24;

// TODO: macro?
D24 d24(long m, int e) {
  // TODO: negative?
  //printf("a--- %ld %d\n", m, e);

  // without this, wrong value clang
  // no need on 6502
  if (0);
  while(m & 0xffff0000) {
    m/= 100; e+= 2;
    //printf("b--- %ld %d\n", m, e);
  }

  // no can used on 6502
  //if (0);
  while((m & 0xff0000) && e<=-2) {
    m/= 100; e+= 2;
  }

  //if (0); // no
  while(!(m % 100) && e<= -2) {
    m/= 100; e+= 2;
}    
  return (((long)e)<<16) + m;
}

D24 dmul(D24 a, D24 b) {
  long r= (a&0xffff)*(b&0xffff), e= (a&0xff0000) + (b&0xff0000);
  printf("1--- %ld %ld\n", r, e>>16);
  while(r & 0xff0000) {
    r/= 100; e+= 0x020000;
    //printf("2--- %ld %ld\n", r, e>>16);
  }
  return r | e;
}

D24 ddiv(D24 a, D24 b) {
  long am= (a&0xffff), ae= a&0xff0000;
  long bm= b&0xffff, be= b&0xff0000;
  long r= 0;
  // erh, this is never guaraneed to work!!!
  //am*= 10000; ae-= 4;
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


uint xsqrt(uint x) {
  uint base= 128, y= 0;
  char i;
  for(i=8; i; --i) {
    y+= base;
    if ((y*y) > x) {
      // base should not have been added, so we substract again
      y-= base;  
    }
    base>>= 1;
  }
  return y;
}

ulong xsqrtl(ulong x) {
  ulong base= 128L<<8, y= 0;
  char i;
  for(i=16; i; --i) {
    y+= base;
    //printf("...%2d %ld %ld\n", i, base, y);
    if ((y*y) > x) {
      // base should not have been added, so we substract again
      y-= base;  
    }
    base>>= 1;
  }
  return y;
}


int main(int argc, char** argv) {
  // Wow, ulong takes double time on my tablet...
  ulong rl, sl= 0;
  uint nl, r, s= 0;
  //ulong z, steps= 256L*256*256*10;
  ulong z, steps= 1024L;
  for(z= steps; z; --z) {
    //r = xsqrt(z); s+= r;
    rl= xsqrtl(z); sl+= rl;
  }
  printf(" xsqrt sum=%u\n", s);
  printf("xsqrtl sum=%lu\n", sl);

  //printf(" xsqrt(%u)= %u (%u) sum=%u\n", n, r, r*r, s);
  //printf("xsqrtl(%lu)= %lu (%lu) sum=%lu\n", nl, rl, rl*rl, sl);

{
  D24 xa, xb, xm;
  long a= 270, b= 42;
  printf("\n%ld * %ld =%ld\n", a, b, a*b);
  xa= d24(a, 0); xb= d24(b, 0);
  dput(xa); putchar('\n');
  dput(xb); printf("\n\n");

  xm= dmul(xa,xb);
  dput(xm); printf("\t<=== *\n\n");

  dput(ddiv(xm, xa)); printf("\t<= m/270\n");
  dput(ddiv(xm, xb)); printf("\t<= m/42\n\n");

  dput(dmul(d24(248248248, 0), d24(12, 0)));
  printf("\n%lu  right mul\n\n", 248248248L*12);

  dput(ddiv(d24(248248248, 0), d24(12, 0)));
  printf("\n%lu  right div\n\n", 248248248L/12);

  dput(ddiv(d24(12, 0), d24(248248248, 0)));
  //printf("\n%g  right div", 12L/248248248.0);
  printf("\n4.83387e-08  right div == should be!\n\n");
 }
}
