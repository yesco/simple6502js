#include <stdio.h>
#include <stdlib.h>

// HMMM
typedef int16_t I;
typedef uint16_t L;

typedef struct dec {
  I m, e;
} dec;

void dmake(long m, int e, dec *r) {
  char neg= (m<0);
  m= labs(m);
  // TODO: neg
  // Normalization
  // (+5 for rounding, kind of works)
  while(m && ((m&0x7fff0000) || m%10==0)) { m+= 5; m/= 10; ++e;}
  r->m= neg?-m:m; r->e= e;
}

void dmul(dec *a, dec *b, dec *r) {
  long m= ((long)(a->m))*((long)(b->m));
  dmake(m, a->e + b->e, r);
}

void ddiv(dec *a, dec *b, dec *r) {
  long m= a->m;
  int e= 0; 
  // TODO: neg
  while(!(m & 0x7f000000)) { m*= 10; e--; }
  dmake(m / b->m, e + a->e - b->e, r);
}

void dadd(dec *a, dec *b, dec *r) {
  if (a->e < b->e) return dadd(b, a, r);
  // a is biggest e
  long m= a->m;
  int e= a->e;
  // TODO: neg
  while(e > b->e) { e--; m*= 10; }
  // now they have same exponent
  dmake(m + b->m, e, r);
}

void dsub(dec *a, dec *b, dec *r) {
  long m= a->m;
  int e= 0; 
  // TODO: neg
  while(!(m & 0x7f000000)) { m*= 10; e--; }
  dec rb= { .m= -b->m, .e= b->e };
  return dadd(a, &rb, r);
}

int dlog10(int m) {
  int i= 0; m= abs(m);
  while(m>=10) { m/= 10; i++; }
  return i;
}

void dput(dec *a) {
  printf("%dd%+d", a->m, a->e);
}

void dputf(dec *a) {
  char s[16]= {0};
  int m= a->m, e= a->e + dlog10(m);
  if (m < 0) { putchar('-'); m= -m; }
  snprintf(s, sizeof(s), "%d", m);
  if (e>=0 && e<9) { printf("%s", s); while(e-->0)putchar('0'); putchar('d'); }
  else if (e<0 && e>-9) { printf("0."); while(++e<0)putchar('0'); printf("%sd", s); }
  else printf("%c%s%sd%+d", s[0], s[1]?".":"", s+1, a->e+dlog10(a->m));
}

long xsqrtl(long x) {
  long base= 128L<<8, y= 0;
  char i;
  for(i=16; i; --i, y+= base) {
    if ((y*y) > x) y-= base; // nah
    base>>= 1;
  }
  return y;
}

// TODO: not right?
void dsqrt(dec *a, dec *r) {
  long m= a->m, e= a->e;
  // increse precision
  while(m && !(0x7ff00000 & m)) { m*= 100; e-= 2; }
  // sqrt(10) != 10*sqrt(100)
  if (e&1) { m*=10; --e; }
  dmake(xsqrtl(m), e/2, r);
}

void ddput(dec *a) {
  putchar('\n');
  dput(a);
  putchar('\n');
  dputf(a);
}

int main(int argc, char** argv) {
  
#ifdef FOO
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
#endif

{
  dec xa, xb, xm;
  long a= 270, b= 42;
  printf("\n%ld * %ld =%ld\n", a, b, a*b);
  dmake(a, 0, &xa); dmake(b, 0, &xb);
  ddput(&xa); putchar('\n');
  ddput(&xb); printf("\n\n");

  dmul(&xa, &xb, &xm);
  ddput(&xm); printf("\t<=== *\n\n");

  dec xd1; ddiv(&xm, &xa, &xd1);
  ddput(&xd1); printf("\t<= m/270\n");
  dec xd2; ddiv(&xm, &xb, &xd2);
  ddput(&xd2); printf("\t<= m/42\n\n");

  dec xp1; dmake(248248248, 0, &xp1);
  dec xp2; dmake(12, 0, &xp2);
  dec xd3; dmul(&xp1, &xp2, &xd3);
  ddput(&xd3);
  printf("\n%lu  right mul\n\n", 248248248L*12);

  dec xp3; dmake(12, 0, &xp3);
  dec xd4; ddiv(&xp1, &xp3, &xd4);
  ddput(&xd4);
  printf("\n%lu  right div\n\n", 248248248L/12);

  dec xd5; ddiv(&xp3, &xp1, &xd5);
  ddput(&xd5);

  //printf("\n%g  right div", 12L/248248248.0);
  printf("\n4.83387e-08  right div == should be!\n\n");
 }
 
 printf("----- negs dputf ---\n");
 for(int i=0; i<15; ++i) {
   printf("%d\t", i);
   dec a; dmake( i,  i, &a); dputf(&a); putchar('\t');
   dec b; dmake( i, -i, &b); dputf(&b); putchar('\t');
   dec c; dmake(-i,  i, &c); dputf(&c); putchar('\t');
   dec d; dmake(-i, -i, &d); dputf(&d); putchar('\t');
   dec e; dsqrt(&a, &e);     dputf(&e); putchar('\n');
 }

 printf("----- sqrt ---\n");
 for(int i=0; i<15; ++i) {
   printf("%d\t", i);
   dec a; dmake( 1,  i, &a); dputf(&a); putchar(' ');
   dec e; dsqrt(&a, &e);     dputf(&e); putchar(' ');
                             dput(&e);  putchar(' ');
   dec d; dmul(&e, &e, &d);  dputf(&d); putchar('\n');
 }
}
