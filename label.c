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

#define lda _ = a = (_z=-1, 0) +
#define ldx _ = x = (_z=-1, 0) +
#define ldy _ = y = (_z=-1, 0) +

#define tax ldx a
#define txa lda x

#define tay ldy a
#define tya lda y

#define tsx _ = x = (_z=-1, 0) + s
#define txs _ = s = (_z=-1, 0) + x

byte a = 0, x = 0, y = 0, s = 0, mem[256] = {0};
byte z = 0, n = 0, v = 0, c = 0; // flags
int _z = -1, _n = -1, _v = 0, _c = 0, _; // to update flags

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
  lda 1;
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
  tax;
  a = pop;

  a--;

  push x;
  push a;
    
  JSR(fib);
  tay;

  a = pop;
  x = pop;
  
  x += y;

fibreturn:
  printf(".");

  txa;
  RTS;

brk:
  printf("BRK!\n");

  return 0;
}
