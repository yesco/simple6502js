// Just an experiement in using labels for
// goto and implementing a stack by storing them
#include <stdio.h>
#include <assert.h>

typedef unsigned char byte;
typedef unsigned short word;

// registers
byte a = 0, x = 0, y = 0, s = 0;
byte mem[65536] = {0};
// flags
byte z = 0, n = 0, v = 0, c = 0;

// we're not really simulating very accurately
// the stack is just a figment of our imagination
//
// TODO: this won't work with return address
// manipulations... Also, JMPI (indirect)  is
// also not going to work.
void* stack[128] = {0};

#define push stack[((s-=2)+2)/2] = (void*)
#define pop_ stack[(s+=2)/2]
#define pop ((byte) pop_)

// lot this will take two slots
// 
#define PHA push a
#define PLA a = pop

// TODO: p is not set correctly yet
//#define PHP push p
//#define PLP p = pop

// sneaky stuff!
// generates unique label name
// - https://stackoverflow.com/questions/1132751/how-can-i-generate-unique-values-in-the-c-preprocessor
#define MERGE_(a,b)  a##b
#define LABEL_(a) MERGE_(unique_name_, a)
#define UNIQUE_NAME LABEL_(__COUNTER__)

#define jsr_(L, U) { push &&U; goto L; U: (void)0; }
#define JSR(L) jsr_(L, UNIQUE_NAME)

#define RTS { goto *pop_; }
#define JMP goto

#define BRK { goto brk; }

// branches
#define BNE if (!z) JMP
#define BEQ if (z) JMP
#define BCC if (!c) JMP
#define BCS if (c) JMP
#define BVC if (!v) JMP
#define BVS if (v) JMP
#define BPL if (!n) JMP
#define BMI if (n) JMP

// flags
#define CLC c = 0
//#define CLD d = 0
//#define CLI i = 0
#define CLV v = 0

#define SEC c = 1
//#define SED d = 1
//#define SEI i = 1

// temporary storage (for macros)
int  _, __, __A, __skip;

// load and store, inc/dex, transfer
// (after enables "LDA 0x44;" syntax!)=
#define LDA *(after(&a, 1, __LINE__, 0)) = __ =
#define STA *(after(&a, 2, __LINE__, 0)) = __ =

#define LDX *(after(&x, 1, __LINE__, 0)) = __ =
#define STX *(after(&x, 2, __LINE__, 0)) = __ =

#define LDY *(after(&y, 1, __LINE__, 0)) = __ =
#define STY *(after(&y, 2, __LINE__, 0)) = __ =

#define ADC *(after(&a, 4, __LINE__, 0)) = __ =

#define TAX LDX a
#define TXA LDA x

#define TAY LDY a
#define TYA LDA y

#define TSX _ = x = (_z=-1, 0) + s
#define TXS _ = s = (_z=-1, 0) + x

#define INX LDX ((x+1) & 0xff)
#define DEX LDX ((x-1) & 0xff)

#define INY LDY ((y+1) & 0xff)
#define DEY LDY ((y-1) & 0xff)

#define CMP *(after(&_, 3, __LINE__, a)) = __ =
#define CPX *(after(&_, 3, __LINE__, x)) = __ =
#define CPY *(after(&_, 3, __LINE__, y)) = __ =

// addressing modes
// (mark address as "authentic")
#define MEM_MODE (0x30de0000)
#define MEM(A) ((A) | MEM_MODE)

#define imm(V) ((V) & 0xff)
#define abs(A) MEM(A)

#define zp(A) MEM((A) & 0xff)
#define zpx(A) zp((A)+x)
#define zpy(A) zp((A)+y)

#define word(A) (__A=(A) & 0xfff, mem[__A]+256*mem[(__A+1)&0xffff])

#define zpxi(A) MEM(word( (A)+x) )
#define zpiy(A) MEM(word( A )+y)

#define STAZ STA MEM_MODE |
#define ADCZ ADC MEM_MODE |

// after is a magical routine being called by assignement!
// This is what enables the no parenthesis syntax:
// General principle:
//     *(foo(&reg, op)) = __ =  $0x0aff
//     <======== LDA/STA ====>  <= ARG=>$
// The Lvalue is (maybe/hopefully/guranteed) to be invoked
// after the RHS...
//
// ops:
//  1: LD? 3: CP? 4: ADC
//   0: ST?
int* after(byte *r, int rwc, int line, byte cmp) {
  static int _;

  int isAddress = (__ & 0xffff0000) == MEM_MODE;
  if (!isAddress && (v < 0 || v >= 0xff)) {
      fprintf(stderr, "\n\n%% Line %d: value is out of range for immediate mode, please use 'STA/LDA <MODE>(0x0501);' to give address: 0x04x (%d).\n", line, a, a);
      exit(0);
  }

  int a = __ & 0xffff;
  byte v;

  if (rwc==1 || rwc==3 || rwc==4) { // LD? - READ
    if (isAddress) {
      v = mem[a];  
    } else { // immediate
      v = a;
    }

    if (rwc==4) { // adc
      c = (*r + v > 255);
      *r += v + c;
    } else {
      *r = v;
    }

    if (rwc==3) { // compare, set C
      c = !!(cmp >= v);
      v = cmp - v;
    }

  } else if (rwc==2) { // ST? - WRITE
    if (isAddress) {
      v = mem[a] = *r;
    } else {
      // no immediate mode
      printf("__=%x", __);
      fprintf(stderr, "\n\n%% Line %d: STA/STX/STY doesn't have immediate mode, please use 'STA <MODE>(0x501) for value: %x (%d)\n", line, a, a);
      exit(0);
    }
  }

  // update flags
  z = !v;
  n = v & 0x80;

  // return dummy so we get called!
  return &_;
}

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
