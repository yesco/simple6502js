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

#include <stdio.h>
#include <assert.h>
#include <ctype.h> // isdigit

int bprint(char* a) {
  int n= strlen(a);
  for(int i=n-1; i>=0; i--)
    putchar(a[i]);
  return n;
}

char* bfix(char* a) {
  int n= strlen(a), first= 1;
  for(int i=n-1; i>=0; i--) {
    if (a[i]>'0') break;
    a[i]= 0;
    n--;
  }
  char* r= strndup(a, n);
  assert(r);
  return r;
}

char* badd(char* a, char* b) {
  int na= strlen(a), nb= strlen(b), l= (na>nb? na: nb)+3;
  char r[l];
  int c= 0;
  memset(r, 0, l);
  //memset(r, '0', l-1);
  putchar('>'); bprint(r); putchar('\n');
  for(int i=0; i<=l; i++) {
    c+= (i<na? a[i]-'0': 0) + (i<nb? b[i]-'0': 0);
    r[i]= (c%10) + '0';
    c/= 10;
  }
  assert(!c);
  bprint(a); putchar('+'); bprint(b); putchar('=');
  bprint(r); putchar('\n');
  
  return bfix(r);
}

// TODO: something in bmul corrupts memory???
char* bmul(char* a, char* b) {
  // "simulate" mul - gives no error...
  return b==b?strdup(a):0;

  int na= strlen(a), nb= strlen(b), l= na+nb+3;
  char r[l];
  memset(r, 0, l);
  for(int ia=0; ia<na; ia++) {
    for(int ib=0; ib<nb; ib++) {
      int i= ia+ib;
      //assert(isdigit(a[ia]));
      //assert(isdigit(b[ib]));
      int c= (a[ia]-'0') * (b[ib]-'0');
      if (!r[i]) r[i]= '0'; // make sure has digit
      if (0) printf("\t%c * %c = %d\n", a[ia], b[ib], c);
      while(c>0) {
        int v= r[i];
        if (v) v-= '0';
        c= v+c;
        r[i++]= (c%10) + '0';
        assert(i<l);
        c/= 10;
      }
      if (0) printf("...i=%d\n", i);
    }
  }
  
  return bfix(r);
}

int bxsub(char* r, char* s, int d) {
  int nr= strlen(r), ns= strlen(s), c=0;
  char x[nr+1];
  strcpy(x, r);
  for(int i=ns-1; i>=0; i--) {
    int ix= i+d;
    if (0) printf("...%c %c\n", x[ix], s[i]);
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
  memset(r, '0', sizeof(r)-1);

  d= na-nb;
  while(d>=0) {
    if (0) {
      printf("---\n");
      bprint(s); putchar('\n');
      for(int j=0; j<i; j++) putchar(' ');
      bprint(b); putchar('\n'); putchar('\n');
    }

    while(bxsub(s, b, d)) {
      r[d]++;

      if (0) {
        bprint(s); putchar('\n');
        for(int j=0; j<i; j++) putchar(' ');
        bprint(b); putchar('\n');
        bprint(r); putchar('\n'); putchar('\n');
      }
    }
    d--; i++;
  }
 
  return bfix(r);
}

#include <stdlib.h>
#include <unistd.h>

int main(int argc, char** argv) {
  if (0) {
    char* a= strdup("54321000  ");
    bprint(bfix(a)); putchar('\n');
    bprint(badd("1234", "12345")); putchar('\n');
    bprint(bmul("999", "999")); putchar('\n');
    bprint(bdiv("1248", "12")); putchar('\n');
    bprint(bdiv("9", "7")); putchar('\n');
  }

  // TODO: this fails later? WTF?
  // memory overwrite?
  bprint(badd("61", "1")); putchar('\n');

  printf("\n\nFIB\n");
  char *fa= strdup("0"), *fb= strdup("1");
  char *fac= strdup("1"), *n= strdup("1");
  while(1) {
    //printf("[H[2J[3J"); putchar('\n');
    bprint(n); putchar('\n');
    putchar('\n');
    char* nf= bmul(fac, n);
    char* of= fac; fac= nf;
    char* nn= badd(n, "1");
    bprint(n); putchar('\n');
    free(n);
    n= nn;

    bprint(fa); putchar('\n');
    char* fc= badd(fa, fb);
    free(fa);
    fa= fb; fb= fc;

    //bprint(of); putchar('\n');
    free(of);

    //usleep(1000*1000);
  }
}

