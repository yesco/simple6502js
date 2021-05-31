// Just an experiement in using labels for
// goto and implementing a stack by storing them
#include <stdio.h>
#include <assert.h>

#define MERGE_(a,b)  a##b
#define LABEL_(a) MERGE_(unique_name_, a)
#define UNIQUE_NAME LABEL_(__COUNTER__)

typedef unsigned char byte;
typedef unsigned short word;

// doesn't fit inside 2 bytes (32 bit pointers)
void* stack[128] = {0};

#define push stack[((s-=2)+2)/2] = (void*)
#define pop_ stack[(s+=2)/2]
#define pop ((byte) pop_)

#define PHA push a
#define PLA a = pop

// TODO: p is not set correctly yet
//#define PHP push p
//#define PLP p = pop()


#define JSR_(L, U) { push &&U; goto L; U: (void)0; }
#define JSR(L) JSR_(L, UNIQUE_NAME)
#define RTS { goto *pop_; }
#define JMP goto

#define BRK { goto brk; }

//#define LDA _ = a = (_z=-1, 0) +
//#define LDX _ = x = (_z=-1, 0) +
//#define LDY _ = y = (_z=-1, 0) +

#define LDA *(after(&a, 0, __LINE__)) = __ =
#define STA *(after(&a, 1, __LINE__)) = __ =

#define LDX *(after(&x, 0, __LINE__)) = __ =
#define STX *(after(&x, 1, __LINE__)) = __ =

#define LDY *(after(&y, 0, __LINE__)) = __ =
#define STY *(after(&y, 1, __LINE__)) = __ =

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



#define MEM_MODE (0x30de)
#define MEM(A) ((A) | 0x30de0000)

#define abs(A) MEM(A)
#define imm(V) ((V) & 0xff)

#define zp(A) MEM((A) & 0xff)
#define zpx(A) zp((A)+x)
#define zpy(A) zp((A)+y)

#define word(A) (__A=(A) & 0xfff, mem[__A]+256*mem[(__A+1)&0xffff])

#define zpxi(A) MEM(word( (A)+x) )
#define zpiy(A) MEM(word( A )+y)

byte a = 0, x = 0, y = 0, s = 0, mem[65536] = {0};
byte z = 0, n = 0, v = 0, c = 0; // flags

int _z = -1, _n = -1, _v = 0, _c = 0,  _, __, __A; // to update flags

void UpdateFlags() {
  // TODO: other flags?
}

int* after(byte *r, int ST, int line) {
  static int _;

  if ((v >> 16) == MEM_MODE) {
    // OK!
  } else if (v < 0 || v >= 0xff) {
      fprintf(stderr, "\n\n%% Line %d: value is out of range for immediate mode, please use 'STA/LDA <MODE>(0x0501);' to give address: 0x04x (%d).\n", line, a, a);
      exit(0);
  }

  int a = __ & 0xffff;
  byte v;

  if (!ST) { // LD? - READ
    if (0 <= a && a <= 0xff) { // immediate
      v = *r = a & 0xff;
    } else {
      v = *r = mem[a];
    }
  } else { // ST? - WRITE
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


#define BNE if (UpdateFlags(), !z) JMP
#define BEQ if (UpdateFlags(), z) JMP

int main()
{
  assert(sizeof(byte)==1);
  assert(sizeof(word)==2);
  assert(sizeof(int)==4);


reset:
  s = 0xff;

start:


  LDA 0xff;

  goto printfibs;

testbne:
  LDA 1;
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
  if (a < 1) {
    x = 0;
    goto fibreturn;
  }
     
  if (a < 2) {
    x = 1;
    goto fibreturn;
  }

  a--;

  push a;
  JSR(fib);
  TAX;
  PLA; //   PLA;

  a--;

  push x;
  push a;
    
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
