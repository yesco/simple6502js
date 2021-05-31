// Just an experiement in using labels for
// goto and implementing a stack by storing them
#include <stdio.h>

#define MERGE_(a,b)  a##b
#define LABEL_(a) MERGE_(unique_name_, a)
#define UNIQUE_NAME LABEL_(__COUNTER__)

typedef unsigned char byte;

// doesn't fit inside 2 bytes (32 bit pointers)
void* stack[128] = {0};

#define push stack[((s-=2)+2)/2] = (void*)
#define pop_ stack[(s+=2)/2]
#define pop ((byte) pop_)

#define JSR_(L, U) { push &&U; goto L; U: (void)0; }
#define JSR(L) JSR_(L, UNIQUE_NAME)
#define RTS { goto *pop_; }
#define JMP goto

#define BRK { goto brk; }

#define LDA _ = a = (_z=-1, 0) +
#define LDX _ = x = (_z=-1, 0) +
#define LDY _ = y = (_z=-1, 0) +

#define TAX LDX a
#define TXA LDA x

#define TAY LDY a
#define TYA LDA y

#define TSX _ = x = (_z=-1, 0) + s
#define TXS _ = s = (_z=-1, 0) + x

#define abs(A) mem[A]
#define imm(V) V

#define zp(A) mem[(A) & 0xff]
#define zpx(A) zp((A)+x)
#define zpy(A) zp((A)+y)

#define word(A) (__=(A) & 0xfff, mem[A]+256*mem[(A+1)&0xffff])
#define zpxi(A) (__= (A)+x, mem[word(A)])
#define zpiy(A) (__= (A),   mem[word(A)+y])

byte a = 0, x = 0, y = 0, s = 0, mem[65536] = {0};
byte z = 0, n = 0, v = 0, c = 0; // flags
int _z = -1, _n = -1, _v = 0, _c = 0, _, __; // to update flags

void UpdateFlags() {
  if (_z < 0) _z = z = _ ? 0 : 1;
  if (_n < 0) _n = n = _ & 0x80;
  // TODO: other flags?
}

#define bne if (UpdateFlags(), !z) JMP
#define beq if (UpdateFlags(), z) JMP

int main()
{

reset:
  s = 0xff;

start:

  goto printfibs;

testbne:
  LDA 1;
  bne not;
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
  a = pop;

  a--;

  push x;
  push a;
    
  JSR(fib);
  TAY;

  a = pop;
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
