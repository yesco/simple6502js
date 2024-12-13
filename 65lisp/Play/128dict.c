#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>

// idea: compression by pointing at last 128+N characters using hi-bit, take N characters

// not very good, for bigrams can save 30%
// I guess it's better than wasting 1/8 bits = 12.5%

#define N 3

//        sherlock   sweden.html
// N:  1  100%      100%
//     2   67%       71%
//     3   78%       75%
//     4   86%       76%
//     5   90%       79%

void oneline(char* o) {
  char *s= o, *d= o, *p, i, match;
  int n= 0;

  while(*s) {
    // sliding dictionary
    d= s-128-N;
    if (d<o) d= o;
    // search from xo for N matching characters of s
    match= 0;
    for(p= s-N-1; p>=d; --p) {
      //printf(">>> %.5s\n", p);
      match= 1;
      for(i= 0; i<N; ++i)
        if (p+i>=s || !s[i] || p[i]!=s[i]) { match= 0; break; }
      if (match) break;
    }

    // match
    if (match) {
      printf("%.*s @%3d -> %d\n", N, s, -(int)(s-p), (unsigned char)-(int)(s-p+128));
      s+= N;
    } else {
      printf("%c\n", *s);
      ++s;
    }
    ++n;
  }

  printf("%3d%% %8d/%8d\n", (int)((n*10050L)/strlen(o)/100), n, (int)strlen(o));

}

int main(void) {
  //char *s= "eE aAAaa foo";
  //char *s= "Hello My name is Jonas S Karlsson";
  //char *s= "hello my name is jonas s karlsson";
  char* ln= NULL; size_t l= 0;

  printf("> ");
  while (getline(&ln, &l, stdin)>=0) {
    oneline(ln);
    printf("> ");
  }


  return 0;
}
