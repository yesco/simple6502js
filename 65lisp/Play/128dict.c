#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>

#include "../simconio.c"

// idea: compression by pointing at last 128+N characters using hi-bit, take N characters

// not very good, for bigrams can save 30%
// I guess it's better than wasting 1/8 bits = 12.5%

#define N 2

//        sherlock   sweden.html
// N:  1  100%      100%
//     2   67%       71%
//     3   78%       75%
//     4   86%       76%
//     5   90%       79%

// return:
//   0 - failed to match
//   n - matched n chars
char match(char* d, char* s) {
  signed char i= 0, dc, sc, n= 0, r;

  for(i=0; i<N; ++i) {
    sc= s[i]; if (!sc) return 0;
    dc= d[i]; if (!dc) return 0;
    if (dc > 0) {
      // simple char
      //printf("\t- match char: '%c' '%c' -> %d\n", dc, sc, dc==sc);
      if (dc!=sc) return 0;
      ++n;
    } else {
      // dictionary entry
      //printf("\t- match dic entry: %d\n", dc);
      r= match(d+i+dc, s+n);
      if (!r) return 0;
      n+= r;
    }
  }
  //printf("  -----> N=%d\n", n);
  return n;
}

void oneline(char* o) {
  char *dict= calloc(strlen(o)+1, 0), *de= dict;
  char *s= o, *d= o, *p, i, r, max, *best;
  int n= 0;

  while(*s) {
    // sliding dictionary
    d= de-128-N-1;
    if (d<dict) d= dict;
    // search from xo for N matching characters of s
    max= 0;
    best= NULL;
    //printf(">>> '%s'\n", s);
    for(p= de-N; p>=d; --p) {
      //printf("  %ld ? '%.5s'\n", p-de, p);
      r= match(p, s);
      //if (r) break;
      if (r) {
        //printf("    n=%d [%.*s]\n", r, r, s);
        if (r>max) { max= r; best= p; }
      }
    }
    p= best;

    // match
    if (max) {
      //printf("%.*s< @%3d -> %d\n", max, s, -(int)(de-p), (unsigned char)-(int)(de-p+128));

      //putchar(' '); revers(1);  printf("%.*s", max, s); revers(0); putchar(' ');

      *de = -(int)(de-p); ++de;
      s+= max;
    } else {
      //printf("%c\n", *s);
      //putchar(*s);
      *de= *s; ++de;
      ++s;
    }
    ++n;
    printf("\n\n%3d%% %8d/%8d\n", (int)((n*10050L)/(s-o)/100), n, s-o);
  }

  printf("\n\n%3d%% %8d/%8d\n", (int)((n*10050L)/strlen(o)/100), n, (int)strlen(o));

}

int main(void) {
  //char *s= "eE aAAaa foo";
  //char *s= "Hello My name is Jonas S Karlsson";
  //char *s= "hello my name is jonas s karlsson";
  char* ln= NULL; size_t l= 0;

  printf("> ");
  while (getline(&ln, &l, stdin)>=0) {
    ln[strlen(ln)-1]= 0;
    oneline(ln);
    printf("> ");
  }


  return 0;
}
