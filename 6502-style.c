#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <stdlib.h>

#include "6502.c"

int main()
{
  assert(sizeof(byte)==1);
  assert(sizeof(word)==2);
  assert(sizeof(int)==4);


  // CPU 65002 starts here

reset:
  s = 0xff;

start:

  goto printfibs;

testbne:
  LDA 33;
  CMP 33;
  BNE not;
  printf("z=%d\n", z);
  printf("equal!\n");
  BRK;

not:
  printf("z=%d\n", z);
  printf("not\n");
  BRK;

printfibs:
  for(int i= 0; i<=13; i++) {
    y = i;
    JSR(fib);
    printf("\nfib(%d) = %d\n", i, a);
  }
  BRK;









// recursive fib (of course not efficient!)



#define TMP 0x02

fib: // (Y: n -> A: fib(n), untouched X)
  printf(".");

  CPY 0x02;
  BCS gofib;
  // 0 1
  TYA;
  RTS;

gofib:
    
  // a = fib-1
  DEY;
  JSR(fib); 

  PHA;
  
  // a: fib-2
  DEY;
  JSR(fib); 

  // "ADC a+stack"
  STAZ TMP;
  PLA;
  CLC;
  ADCZ TMP;

  // restore
  INY; INY;

  RTS;










brk:
  printf("BRK!\n");

  return 0;
}

// This is a play with locals allocation
// on the 6502 stack, inspired by:
//
// - http://wilsonminesco.com/stacks/recurse.html?fbclid=IwAR3a0e_Gx8Jb7hzfIJ6l5dcX6E-YJaHW8WnRzdwstTSVw9-LoMfCFtYjaX4
void test_locals() {
  

  // assumption: all routines restore any
  // register they may have used!

 callsub: // 13 cycles overhead, 4 bytes
  PHA;

  LDA 0x47; PHA; // n
  LDA 0x11; PHA; // m

  JSR(sub);

  PLA;
  RTS;

 sub: // 2 byte params on stack n,m (12b, 33c)
  PHA; TXA; PHA; // save X (to save X we save A)

  TSX; // points after save

  PHA; PHA; // alocate 2 local bytes
  
  int L0= 0x101, L1= 0x102;
  int _X= 0x103, _A= 0x104;
  int Pm= 0x105, Pn= 0x106;

 // ... do work

  TXS; // remove locals
  PLA; TAX; PLA; // restore X,A

  PLP; PLP; // remove parameters
}

#ifdef FOO

// from asm.js lol
void SAVE() {
  PHP;
  PHA;
  TXA;
  PHA;
  TYA;
  PHA;
}

void RESTORE() {
  PLA;
  TAY;
  PLA;
  TAX;
  PLA;
  PLP;
}

void PARAM(int n) {
  // dummy
}

void LOCAL(int n) {
  // dummy
}

void test_LOCALs() {
  

  // assumption: all routines restore any
  // register they may have used!

 callsub: // 13 cycles overhead, 4 bytes
  SAVE();

  LDA 0x47; PHA; // n
  LDA 0x11; PHA; // m

  JSR(sub);

  RESTORE();
  RTS;

 sub: // 2 byte params on stack n,m (12b, 33c)
  SAVE(); // => saved _A _X _Y
  TSX; // points after save

  PARAM(n); // creates n, allocate PHA
  PARAM(m); // creates m, allocate PHA

  LOCAL(g);
  LOCAL(h);

  // ... do work

  TXS; // remove locals
  RESTORE();

  PLP; PLP; // remove parameters


 gsub:
  int gsub_params = 0;
  int gsub_locals = 0;
  // save (3 bytes)
  PHA; TXA; PHA; TYA; PHA;
  TSX;

  int p_n = gsub_params+= 1; // x107
  int p_m = gsub_params+= 1; // x106
  // _A x105
  // _X x104
  // _Y x103
  int l_g = gsub_locals++ 1; // x102
  int l_h = gsub_locals++ 1; // x101

  int n() { return 0x100+gsub_locals+3+p_n; }
  int m() { return 0x100+gsub_locals+3+p_m; }
  
  int g() { return 0x100+l_g; }
  int h() { return 0x100+l_h; }
  
  // ... do work

  TXS; // remove locals
  // restore (3 bytes)
  PLA; TAY; PLA; TAX; PLA;

  // remove parameters
  while(gsub_params--) {
    PLP;
  }
}

#endif

void test_stack_fib() {
  
 callfib:
  PHA;

  LDA 0x7;
  JSR(fib);

  PLA;
  RTS;

 fib:
  PHA; TXA; PHA;

  


  PLA; TAX; PLA;
}
