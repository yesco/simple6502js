// ORIC ATOMOS poor man's DECIMALS (simplier than floats)
// (>) 2024 Jonas S Karlsson, jsk@yesco.org

// Here we implement a non-IEEE 30 bit decimal with about:
// - "1 sign bit"
// - 20 bits (6 digits) precision
// -  9 bits exponent (-254 .. 254)
//
// The implementation uses a decimal storage, not storing
// the digits but the mantissa is a binary 21 bit with sign,
// and the exponent is 9 bits with sign.

// This simplifies implementation.

// bit layout:
//
// --------------------CONS--------------------
// ---------CDR--------    ---------CAR--------
// eeee eeee  emmm mmm0    mmmm mmmm  mmmm mmm0
// --------int15------     ------int15--------
//
// Why only 30 bits? It's for it to fit into a concell,
// of the 65lisp, with 15 bits each from two 15-bit ints.

#define DECDEBUG(a) do{ }while(0)
//#define DECDEBUG(a) do{ a; }while(0)

#define DEC

#include <stdio.h>
#include <stdlib.h>

// HMMM
typedef   int8_t S;
typedef  uint8_t C;
#ifndef LISP
typedef  int16_t L; // hmmm
#endif // LISP
typedef uint16_t X; // hmmm
typedef  int32_t W;
typedef uint32_t U;

// A decimal30 IS a cons of two numbers!

#ifdef LISP
char isdec(L x) { return iscons(x) && isnum(CAR(x)) && isnum(CDR(x)); }
#endif

typedef union dec30 {
  U uabcd;
  W abcd;
  struct { L cd, ab; };
  struct { X ucd, uab; };
  struct { S d, c, b, a; };
  struct { C ud, uc, ub, ua; };
} dec30;

int decexp(dec30 *a) {
  // TODO: verify
  return (a->ab)>>7; // sign extend, 9 bits => 16 bits
}

// TODO: hide behind debug
void bput(U m) {
  int i;
  putchar(' ');
  for(i=0; i<32; ++i) {
    if (i%4==0) putchar(' ');
    if (i%8==0) putchar(' ');
    if (i%16==0) putchar(' ');
    putchar( (m&0x80000000)? '1': '0' );
    m<<=1;
  }
  putchar('\n');
}

long decman(dec30 *a) { // sign extend .b take 7 high bits
  // TODO: verify...
  DECDEBUG(printf("decman:\n"));
  DECDEBUG(printf("dec="); bput(a->uabcd));
  DECDEBUG(printf("mlo="); bput((a->ucd)>>1));
  DECDEBUG(printf("mhi="); bput((a->ub)<<1));
  DECDEBUG(printf("his="); bput((S)((a->ub)<<1)));
  DECDEBUG(printf("hia="); bput(((W)((S)((a->ub)<<1)))>>2));
  DECDEBUG(printf("m  ="); bput(((((W)((S)((a->ub)<<1)))>>2)<<15) | ((a->ucd)>>1)));
  return ((((W)((S)((a->ub)<<1)))>>2)<<15) | ((a->ucd)>>1);
}

void dmake(long m, int e, dec30 *r) {
  long o= m; // debug TODO: remove
  char neg= (m<0);
  m= labs(m);

  // Normalization (too big m, div 10...)
  // (+5 for rounding, kind of works)
  while(m&0xffe00000) { m+= 5; m/= 10; ++e;}
  if (neg) m= -m;

  DECDEBUG(if (o!=m) printf("adjusted dec: m=%ld e=%d -> %d\n", m, e));

  // TODO: inf and nan?
  assert(e<=254);
  assert(e>=-254);

  // encode
  DECDEBUG(bput(m));
  r->ab= (e<<7)&0xff80; // 9 bits from e stored in ab: 1111 1111 1000 0000
  r->cd= (m<<1)&0xfffe;
  r->b|= (m>>14)&0x7e; // 6 bits from m stored in b:             0111 1110
  DECDEBUG(bput(r->uabcd));
}

#ifdef LISP
// Returns a lisp value, either a normal num if fits
// or a dec30 if needed.
L mkdec(long m, int e) {
  dec30 d;
  if (!e && labs(m)<INT_MAX/2) return mknum(m);

  dmake(m, e, &d);

  // remove after testing
  assert(isnum(d.cd));
  assert(isnum(d.ab));

  return cons(d.cd, d.ab);
}

L readdec(char c, char base) {
  long m= 0;
  int e= 0;
  signed char d= 1, neg= 0, eneg= 0;

  // base prefix? 0x 0b 0ctal
  char b= base;
  if (c=='0') {
    c= tolower(nextc());
    if (c=='x') b= 16; else if (c=='b') b= 2; else if (isdigit(c)) b= 8;
    else unc(c); // error("Unknown base char: ", MKNUM(c));
    c= nextc();
  }

  while (c && !isspace(c)) {
    if ((d>1 && isdigit(c)) || c=='.') d++;
    c= tolower(c);
    //printf("READDEC: '%c' (%d)\n", c, c); // debug
    if (c=='+') ; // ignore
    else if (c=='-') { if (d>=0) neg= 1; else eneg= 1; }
    else if (b==10 && (c=='e' || c=='d'))  d= -d;
    else if (isdigit(c) || (c>='a' && c<='a'+b-10)) {
      if (d>=0) m= m*b + (c<='9'? c-'0': c-'a'+10);
      else      e= e*b + c-'0';
    } else break;

    // overflow, throw away lower digit
    // (rounding w +5 isn't perfect...)
    while(((U)m) >= 0x00100000) { m+= 5; m/= 10; e++; }

    c= nextc();
  }
  unc(c);
  DECDEBUG(printf("dec: m=%ld d=%d e=%d -> %d\n", m, d, e, e-(abs(d)-1)));
  e-= (abs(d)-1);
  return mkdec(neg? -m: m, eneg? -e: e);
}
#endif // LISP

char dlog10(long m) {
  char i= 0; m= labs(m);
  while(m>=10) { m/= 10; i++; } // expensive
  return i;
}

int dlog2(long m) {
  char i= 0; m= labs(m);
  while(m) { m>>= 4; i+= 4; }
  return i;
}

void dmul(dec30 *a, dec30 *b, dec30 *r) {
  // TODO: avoid overflow
  long am= decman(a), bm= decman(b);
  char neg= 0;
  int e= 0, bits;
  if (am<0) { neg= 1;     am= -am; }
  if (bm<0) { neg= 1-neg, bm= -bm; }

  do {
    bits= dlog2(am)+dlog2(bm);
    if (bits<=32) break;
    // Too big result, div10 the biggest
    e++;
    if (am>bm) { am+= 5; am/= 10; }
    else       { bm+= 5; bm/= 10; }
  } while (1);
  // TODO: error for big numbers
  dmake(am*bm, e+decexp(a)+decexp(b), r);
}

void ddiv(dec30 *a, dec30 *b, dec30 *r) {
  long am= decman(a), bm= decman(b);
  char neg= 0;
  if (am<0) { neg= 1;     am= -am; }
  if (bm<0) { neg= 1-neg, bm= -bm; }
  // maximize to get highest precision (*2 both)
  while(!(am & 0xfff00000) && !(bm & 0xfff00000)) { am<<=1; bm<<=1; }
  if (neg) am= -am;
  // TODO: error for big numbers
  dmake(am / bm, decexp(a) - decexp(b), r);
}

void dadd(dec30 *a, dec30 *b, dec30 *r) {
  long am;
  int ae= decexp(a), be= decexp(b), tmp;
  dec30 *p;
  char neg= 0;
  // if needed swap so a has biggest exp
  if (ae < be) { tmp=ae;ae=be;be=tmp; p=a;a=b;b=p; }
  am= decman(a);
  if (am<0) { neg= 1; am= -am; }

  while(ae > be) { ae--; am*= 10; }
  // now they have same exponent
  dmake(am + decman(b), ae, r);
}

void dsub(dec30 *a, dec30 *b, dec30 *r) {
  dec30 rb; dmake(-decman(b), decexp(b), &rb);
  dadd(a, &rb, r);
}

void dput(dec30 *a) {
  printf("%ldd%+d", decman(a), decexp(a));
}

void dputf(dec30 *a) {
  char s[16]= {0};
  long m= decman(a);
  int ae= decexp(a), e=ae+dlog10(m);
  #ifdef LISP
  DECDEBUG(putchar('\n'); dput(a));
  DECDEBUG(printf("\nDPUTF: m=%ld e=%d de=%d (", m, ae, e));
  DECDEBUG(prin1(CAR((L)a)); printf(" . "); prin1(CDR((L)a)); putchar(')'); NL);
  DECDEBUG(NL);
  #endif //LISP
  if (m < 0) { putchar('-'); m= -m; }
  snprintf(s, sizeof(s), "%ld", m);
  if (e>=0 && e<9) { printf("%s", s); while(ae-->0)putchar('0'); putchar('d'); }
  else if (e<0 && e>-5) { printf("0."); while(++ae<0)putchar('0'); printf("%sd", s); }
  else printf("%c%s%sd%+d", s[0], s[1]?".":"", s+1, e);
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
void dsqrt(dec30 *a, dec30 *r) {
  long m= decman(a), e= decexp(a);
  // increse precision
  while(m && !(0x7f000000 & m)) { m*= 100; e-= 2; }
  if (e&1) { m*=10; --e; }
  dmake(xsqrtl(m), e/2, r);
}

void ddput(dec30 *a) {
  putchar('\n');
  dput(a);
  putchar('\n');
  dputf(a);
}

// ENDWCOUNT

#ifndef LISP
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
  dec30 xa, xb, xm;
  long a= 270, b= 42;
  printf("\n%ld * %ld =%ld\n", a, b, a*b);
  dmake(a, 0, &xa); dmake(b, 0, &xb);
  ddput(&xa); putchar('\n');
  ddput(&xb); printf("\n\n");

  dmul(&xa, &xb, &xm);
  ddput(&xm); printf("\t<=== *\n\n");

  dec30 xd1; ddiv(&xm, &xa, &xd1);
  ddput(&xd1); printf("\t<= m/270\n");
  dec30 xd2; ddiv(&xm, &xb, &xd2);
  ddput(&xd2); printf("\t<= m/42\n\n");

  dec30 xp1; dmake(248248248, 0, &xp1);
  dec30 xp2; dmake(12, 0, &xp2);
  dec30 xd3; dmul(&xp1, &xp2, &xd3);
  ddput(&xd3);
  printf("\n%lu  right mul\n\n", 248248248L*12);

  dec30 xp3; dmake(12, 0, &xp3);
  dec30 xd4; ddiv(&xp1, &xp3, &xd4);
  ddput(&xd4);
  printf("\n%lu  right div\n\n", 248248248L/12);

  dec30 xd5; ddiv(&xp3, &xp1, &xd5);
  ddput(&xd5);

  //printf("\n%g  right div", 12L/248248248.0);
  printf("\n4.83387e-08  right div == should be!\n\n");
 }
 
 printf("----- negs dputf ---\n");
 for(int i=0; i<15; ++i) {
   printf("%d\t", i);
   dec30 a; dmake( i,  i, &a); dputf(&a); putchar('\t');
   dec30 b; dmake( i, -i, &b); dputf(&b); putchar('\t');
   dec30 c; dmake(-i,  i, &c); dputf(&c); putchar('\t');
   dec30 d; dmake(-i, -i, &d); dputf(&d); putchar('\t');
   dec30 e; dsqrt(&a, &e);     dputf(&e); putchar('\n');
 }

 printf("----- sqrt ---\n");
 for(int i=0; i<15; ++i) {
   printf("%d\t", i);
   dec30 a; dmake( 1,  i, &a); dputf(&a); putchar(' ');
   dec30 e; dsqrt(&a, &e);     dputf(&e); putchar(' ');
                             dput(&e);  putchar(' ');
   dec30 d; dmul(&e, &e, &d);  dputf(&d); putchar('\n');
 }
}
#endif // LISP
