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
    if (is[i]) printf("%7d ", v[i]);
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
    if (!cmd) return;
    is[nv]= 1;
    ++cmd;
    for(*p= v[nv-2]; *p <= end; ++(*p)) {
      //printf("--------- %d (..%d): c=%c lastop=%c cmd=\"%s\"\n", *p, end, c?c:'?', lastop, cmd);
      panda(cmd);
      nv= snv;
    }

    // backtrack... (fail)
    is[nv]= 0;
    --nv;
    lastlast= lastop;
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

  //printf("%% panda> %s\n", cmd);

  --cmd;
 next:
  //printf("\n%% P: '%c' %d\n", cmd[1], cmd[1]);

  switch(c= *++cmd) {
  case 0:   is[nv]= 1; op(0, cmd); result(); return;
    // formatting
  case ';': op(0, cmd); is[nv]= 1; goto next; // TODO: no space
  case ',': op(0, cmd); is[nv]= 1; goto next; // TODO: tab?
  case ' ': goto next; // TODO: space/formatted (?)

  default:
    // TODO: remove op(0) ?
    if (c>='0' && c<='9') { v[++nv]= c-'0'; op(0, cmd); goto next; }

    // is an op - delay
    op(c, cmd);
    if (lastlast=='_') return;
    goto next;
  }
}

//int main(int argc, char** argv) {
int main(void) {
  char* cmd= "1, 2, 3 + 4, 5 s, 6 + 7, 1 _ 9, 8";
  printf("Panda> %s\n", cmd);
  panda(cmd);
  //printf("AFTER PANDA\n");
  putchar('\n');

  putchar('\n');

  return 42;
}
