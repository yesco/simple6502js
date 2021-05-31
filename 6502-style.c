// Just an experiement in using labels for
// goto and implementing a stack by storing them
#include <stdio.h>
#include <assert.h>

typedef unsigned char byte;
typedef unsigned short word;

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

#ifndef SKIP
  #define jsr_(L, U) { push &&U; goto L; U: (void)0; }
  #define JSR(L) jsr_(L, UNIQUE_NAME)
#endif

#ifdef SKIP
  #define jsr_(L, U) { U: push &&U + 4; goto L;}
  #define JSR(L) jsr_(L, UNIQUE_NAME)
#endif

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

// load and store, inc/dex, transfer
#define LDA *(after(&a, 1, __LINE__, 0)) = __ =
#define STA *(after(&a, 2, __LINE__, 0)) = __ =

#define LDX *(after(&x, 1, __LINE__, 0)) = __ =
#define STX *(after(&x, 2, __LINE__, 0)) = __ =

#define LDY *(after(&y, 1, __LINE__, 0)) = __ =
#define STY *(after(&y, 2, __LINE__, 0)) = __ =

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
#define MEM_MODE (0x30de)
#define MEM(A) ((A) | 0x30de0000)

#define imm(V) ((V) & 0xff)
#define abs(A) MEM(A)

#define zp(A) MEM((A) & 0xff)
#define zpx(A) zp((A)+x)
#define zpy(A) zp((A)+y)

#define word(A) (__A=(A) & 0xfff, mem[__A]+256*mem[(__A+1)&0xffff])

#define zpxi(A) MEM(word( (A)+x) )
#define zpiy(A) MEM(word( A )+y)

// registers
byte a = 0, x = 0, y = 0, s = 0;
byte mem[65536] = {0};
// flags
byte z = 0, n = 0, v = 0, c = 0;

// temporary storage (for macros)
int  _, __, __A, __skip;

int* after(byte *r, int rwc, int line, byte cmp) {
  static int _;

  if ((v >> 16) == MEM_MODE) {
    // OK!
  } else if (v < 0 || v >= 0xff) {
      fprintf(stderr, "\n\n%% Line %d: value is out of range for immediate mode, please use 'STA/LDA <MODE>(0x0501);' to give address: 0x04x (%d).\n", line, a, a);
      exit(0);
  }

  int a = __ & 0xffff;
  byte v;

  if (rwc==1 || rwc==3) { // LD? - READ
    if (0 <= a && a <= 0xff) { // immediate
      v = *r = a & 0xff;
    } else {
      v = *r = mem[a];
    }

    if (rwc==3) { // compare, set C
      c = !!(cmp >= v);
      v = cmp - v;
    }

  } else if (rwc==2) { // ST? - WRITE
    if (0 <= a && a <= 0xff) {
      // no immediate mode
      fprintf(stderr, "\n\n%% Line %d: STA/STX/STY doesn't have immediate mode, please use 'STA/LDA <MODE>(0x501) for value: %x (%d)\n", line, a, a);
      exit(0);
    } else {
      v = mem[a] = *r;
    }
  }

  // update flags
  z = !v;
  n = v & 0x80;

  // return dummy to have reason to be called
  return &_;
}

int main()
{
  assert(sizeof(byte)==1);
  assert(sizeof(word)==2);
  assert(sizeof(int)==4);

  // admin stuff
  
  if (1) {
    void* after = (void*) &&unique_after;
  unique_before:
    // Assuming there is constant difference!
    goto unique_go;
  unique_after:
    (void)0;

  unique_go:

    __skip = (int)&&unique_after - (int)&&unique_before;
    //printf("SKIP=%d\n", __skip);
  }
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
    a = i;
    JSR(fib);
    printf("\nfib(%d) = %d\n", i, a);
  }
  BRK;

fib: // in: a, out: a=fib
  TAX;
  CMP 0x02;
  BCC fibreturn;  

  // fib -1 
  DEX; 
  TXA;

  PHA;
  JSR(fib);
  TAX;
  PLA;

  a--;

  push x;
  PHA;
    
  JSR(fib);
  TAY;

  PLA;
  x = pop;
  
  x += y;

fibreturn:
  printf(".");

  TXA;
  RTS;

brk:
  printf("BRK!\n");

  return 0;
}
