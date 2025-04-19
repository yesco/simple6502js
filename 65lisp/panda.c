//#define MAIN
//#include "conio-raw.c"

#include <stdlib.h>
#include <stdio.h>

// dummy
char nil, T, print, doapply1;

#define NV 16

char lastop= 0, lastlast= 0;
int nv= 0, v[NV]= {0};
char is[NV]= {0};

void result() {
  char i;
  printf("=> ");
  for(i= 1; i<=nv; ++i) {
    //if (is[i]) printf("%7d ", v[i]);
    if (is[i]) printf("%d ", v[i]);
  }
  putchar('\n');
}

void panda(char* cmd);

void op(char c, char* cmd) {
  //printf("\n[OP(%c) %c]\n", c, lastop); //result();

  // TODO: is[] is slow and crude better have (out ....)
  switch(lastop) {
  case 0: lastop= c; return;
    // binop
    // TODO: pa, pb shifting???
  case '+': v[nv+1]= v[nv-1]+v[nv]; break;
  case '-': v[nv+1]= v[nv-1]-v[nv]; break;
  case '*': v[nv+1]= v[nv-1]*v[nv]; break;
  case '/': v[nv+1]= v[nv-1]/v[nv]; break;

    // .. 1_10 == 1..10
  case '_': { 
    int end= v[nv], * p= v+ ++nv, snv= nv;
    int slastlast= lastlast, slast= lastop;
    if (!cmd || !*cmd) return;
    //is[nv]= 1;
    ++cmd;
    for(*p= v[nv-2]; *p <= end; ++(*p)) {
      nv= snv;
      //lastlast= slastlast; lastop= slast;
      lastop= 0; lastlast= 0;
      //printf("--------- %d (..%d): c=%c lastop=%c cmd=\"%s\"\n", *p, end, c?c:'?', lastop, cmd);
      panda(cmd);
    }

    // backtrack... (fail)
    nv= snv-1;
    //is[nv]= 0;
    lastlast= '_';
    lastop= 0;
    return;
  }
    

    // one arg
  case 's': v[nv+1]= v[nv]*v[nv]; break;

  default: printf("Illegcal command: '%c'\n", c); exit(1);
  }

  is[++nv]= 1;

  lastlast= lastop;
  lastop= c;
}

// make parser to output objectlog?
void panda(char* cmd) {
  char c;
  // TOOD: set/reset (string) stack-heap

  //printf("%% panda> %s\n", cmd);

  --cmd;
 next:
  if (lastlast=='_') return;
  //printf("\n%% P: '%c' %d\n", cmd[1], cmd[1]);

  switch(c= *++cmd) {
  case 0:   is[nv]= 1; op(0, cmd); result(); return;
    // formatting
  case ';': op(0, cmd); is[nv]= 1; goto next; // TODO: no space
  case ',': op(0, cmd); is[nv]= 1; goto next; // TODO: tab?
  case ' ': goto next; // TODO: space/formatted (?)

    // print string 
    // TODO: accumulate/set as output value
#ifdef FOO
    // TODO: NOT CORRECT!
  case '"': case '\'': {
    char q= c;
    while((c=*++cmd) && c!=q) putchar(c);
    goto next;
  }
#endif

  default:
    // TODO: remove op(0) ?
    if (c>='0' && c<='9') { v[++nv]= c-'0';
      // removed and crashes!
      op(0, cmd);
      goto next; }

    // is an op - delay
    op(c, cmd);
    goto next;
  }
}

// TODO: aggregators
// - NO fish
// - SUM all
// - PRODUCT all
// - WHERE ... (implied)
// - THOSE THAT / IF

// n is even iff n mod 2 is 0
// n is odd iff not even
// n is even if it mode 2 is 0
// sum all number from 1 to 100
//
// b divides a iff a mod b is 0
// 3 is a factor of 6 iff 3 divides 6
// the factors of the number 6 divides it (cannot)
// 42 is a prime iff it has no factors
// is 42 a prime?
// 42 prime
// 42 factors => 2 7 3


//int main(int argc, char** argv) {
int main(void) {
//  char* cmd= "1, 2, 3 + 4, 5 s, 6 + 7, 1 _ 9, 8";
//  char* cmd= "1, 2, 3 + 4, 5 s, 6 + 7, 1 _ 9 + 1, 8";
//  char* cmd= "1_2, 4_5";
  char* cmd= "1_9 + 9, 1_9 + 8";
//  char* cmd= "1_9, 1_9";
//  char* cmd= "1_9, '*', 1_9"; // TODO: wrong, need "heap"

  printf("Panda> %s\n", cmd);
  panda(cmd);
  //printf("AFTER PANDA\n");
  putchar('\n');

  putchar('\n');

  return 42;
}
