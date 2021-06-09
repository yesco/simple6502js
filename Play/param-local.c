#include <stdio.h>

int locals = 0;
int params = 0;

int lp_n = 0;
int* lps[32] = {NULL};

int ParamLocal(int* p, int bytes, int local, char* name) {
  for(int i=0; i<lp_n; i++) {
    (*(lps[i]))+= bytes;
  }
  lps[lp_n++] = p;

  // allocate space
  if (local) {
    for(int i=0; i<bytes; i++)
      printf("  PHA; // %s\n", name);
    locals += bytes;
  }

  return 0x100 + bytes - (local?0: 2);
}

int main() {

  printf("before\n");

 gsub: (void)0;
  // PROC(gsub, {
  //   PARAM(n); PARAM(m);
  //   LOCAL(g); LOCAL(h);
  int n = ParamLocal(&n,1,0,"n"); params++;
  int m = ParamLocal(&m,2,0,"m"); params++;

  // this one took two bytes
  int ret = ParamLocal(&ret,2,0,"ret"); params++;

  // save (3 bytes)
  printf("  PHA; // saved_a\n");
  int saved_a = ParamLocal(&saved_a,1,0,"saved_a");

  printf("  TXA; PHA; // saved_x\n");
  int saved_x = ParamLocal(&saved_x,1,0,"saved_x");

  printf("  TYA; PHA; // saved_y\n");
  int saved_y = ParamLocal(&saved_y,1,0,"saved_y");
  
  printf("  TSX; // get stack\n");
  //int saved_s = ParamLocal(&saved_s,1,0,"saved_s");
  int saved_s = 0;

  printf("  LDA 0x00; // init locals\n");
  int g = ParamLocal(&g,1,1,"g");
  int h = ParamLocal(&h,2,1,"h");

  printf("n\t%x\nm\t%x\nret\t%x\nsaved_a\t%x\nsaved_x\t%x\nsaved_y\t%x\nsaved_s\t%x\ng\t%x\nh\t%x\n", n, m, ret, saved_a, saved_x, saved_y, saved_s, g, h);

  // ... do work

//  TXS; // remove locals
  // restore (3 bytes)
//  PLA; TAY; PLA; TAX; PLA;

  printf("  INC absx(ret); // adjust ret\n");
  printf("  // modify ret (+1)\n");
  printf("  BNE nopccarry;\n");
  printf("  INC absx(ret+1);\n");
  printf(" nopccarry;\n");

  // remove parameters
  printf("  TXS; // restore before local\n");
  
  printf("  PLA; TAY; // restore y\n");
  printf("  PLA; TAX; // restore x\n");
  printf("  PLA; // restore a\n");
  printf("  // NOTE: it's callers problem to remove parameters from stack!\n");
  printf("  RTS;\n");
  return 0;

  printf("\n  // restore\n");
  printf("  LDA absx(saved_a);\n");
  printf("  LDY absx(saved_y);\n");
  printf("  PHA;\n");
  printf("    LDA absx(a);\n");
  printf("    TAX;\n");
  printf("    
  printf("  PLA;\n");

  printf(
  return 0;

// remove parameters
  while(locals--) {
    printf("  PLP; // drop local byte\n");
  }
}

