// The poor mans Bignum library
//
// (>) 2024 Jonas S Karlsson, jsk@yesco.org

// Simple and stupid implementation
//
// A bignum is just a string, digits in reverse order.
//
// Each operator RETURNS a NEWLY allocated string,
// it's up to you to deallocate it.

// Provides: + * / (-)
//
// Routines: bprint, bfix, badd, bmul, bdiv

// TODO: handle negative numbers, lol
// TODO: subtract (-)

// TODO: improve speed?
//   1. use array of bytes instead, first byte=len (limit <= 255)
//   2. do arith on bytes where each byte holds two digits (00-99)
//   3. don't malloc?

// TODO: for 6502 compiler cc65
//   - no dyn array, only constant...
//   - no usleep()
//   - strlen() limited to 255
//   - if use bytes for 00-99 then upto 512 digits...
//   - if use int for 0000-9999 can use int count front - unlimited

#include <stdio.h>
#include <assert.h>
#include <ctype.h> // isdigit
#include <string.h>

int bprint(char* a) {
  int n= strlen(a), i;
  for(i=n-1; i>=0; i--)
    putchar(a[i]);
  return n;
}

char* bfix(char* a) {
  int n= strlen(a), first= 1, i;
  for(i=n-1; i>=0; i--) {
    if (a[i]>'0') break;
    a[i]= 0;
    n--;
  }
  //return strndup(a, n);
  return strdup(a);
}

char* badd(char* a, char* b) {
  int na= strlen(a), nb= strlen(b), l= (na>nb? na: nb)+1;
  char r[l+1]; // one for zero termination
  int c= 0, i;
  memset(r, 0, l+1);
  // loop one less than length
  for(i=0; i<l; i++) {
    c+= (i<na? a[i]-'0': 0) + (i<nb? b[i]-'0': 0);
    r[i]= (c%10) + '0';
    c/= 10;
  }
  assert(!c);
  //bprint(a); putchar('+'); bprint(b); putchar('=');
  //bprint(r); putchar('\n');
  
  return bfix(r);
}

char* bmul(char* a, char* b) {
  int na= strlen(a), nb= strlen(b), l= na+nb+3, ia, ib;
  char r[l];
  memset(r, 0, l);
  for(ia=0; ia<na; ia++) {
    for(ib=0; ib<nb; ib++) {
      int i= ia+ib;
      int c= (a[ia]-'0') * (b[ib]-'0');
      if (!r[i]) r[i]= '0'; // make sure has digit
      while(c>0) {
        int v= r[i];
        if (v) v-= '0';
        c+= v;
        r[i++]= (c%10) + '0';
        assert(i<l);
        c/= 10;
      }
    }
  }
  
  return bfix(r);
}

int bxsub(char* r, char* s, int d) {
  int nr= strlen(r), ns= strlen(s), c=0, i;
  char x[nr+1];
  strcpy(x, r);
  for(i=ns-1; i>=0; i--) {
    int ix= i+d;
    c= (x[ix]-'0') - (s[i]-'0');
    if (c<0) {
      // borrow
      if (ix+1>=nr || x[ix+1]=='0') return 0;
      x[ix+1]--; // TODO: safe?
      c+= 10;
    }
    assert(c>=0);
    x[ix]= c+'0';
  }
  // accept subtraction
  strcpy(r, x);
  return 1;
}

char* bdiv(char* a, char* b) {
  int na= strlen(a), nb= strlen(b), l= na-nb+3;
  char s[na+1];
  char r[na+1];
  int d, i= 0;
  memset(s, 0, na+1);
  memset(r, 0, na+1);
  strcpy(s, a);
  // hmmm?
  memset(r, '0', na+1-1);

  d= na-nb;
  while(d>=0) {
    while(bxsub(s, b, d)) r[d]++;
    d--; i++;
  }
 
  return bfix(r);
}

// ENDWCOUNT

#include <stdlib.h>
#include <unistd.h>

//int main(int argc, char** argv) {
int main(void) {
  char* a= strdup("54321000  ");
  bprint(bfix(a)); putchar('\n');
  bprint(badd("1234", "12345")); putchar('\n');
  bprint(bmul("999", "999")); putchar('\n');
  bprint(bdiv("1248", "12")); putchar('\n');
  bprint(bdiv("9", "7")); putchar('\n');

  // TODO: this fails later? WTF?
  // memory overwrite?
  bprint(badd("61", "1")); putchar('\n');

  printf("\n\nFIB\n");
  if (1) {
    char *fa= strdup("0"), *fb= strdup("1");
    char *fac= strdup("1"), *n= strdup("1");
    while(1) {
      char *nf, *of, *nn, *fc;
      printf("[H[2J[3J"); putchar('\n');
      printf("n= "); bprint(n); putchar('\n');
      putchar('\n');
      nf= bmul(fac, n);
      of= fac; fac= nf;
      nn= badd(n, "1");
      free(n);
      n= nn;

      printf("fib(n)= "); bprint(fa); putchar('\n');
      fc= badd(fa, fb);
      free(fa);
      fa= fb; fb= fc;

      printf("fac(n)= "); bprint(of); putchar('\n');
      free(of);

      usleep(10*1000);
    }
  }
  
  return 0;
}
