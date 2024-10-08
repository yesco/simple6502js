// 6502 Simulator
//
// Provide a 'running' 6502 cpu inside C by simulation.
// It may provide fast prototyping, while retaining full power of C.

// It does this by clever macros and using somewhat decent syntax.
//
// The instructions are "run" when then are encountered.
// They modify global variables a,x,y,s,mem and flags (znvc)

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

// Just an experiement in using labels for
// goto and implementing a stack by storing them
void* stack[128] = {0};

#define push stack[((s-=2)+2)/2] = (void*)(long)
#define pop_ stack[(s+=2)/2]
#define pop ((byte)(long) pop_)

// lot this will take two slots
// 
#define PHA push a
#define PLA a = pop

int p; // dummy
// TODO: need to construct p and destruct at pop

// TODO: p is not set correctly yet
#define PHP push p
#define PLP p = pop

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
byte _;
int  __, __A, __skip;

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

int _z; // dummy, Trr doesn't set z flag

#define TSX _ = x = (_z=-1, 0) + s
#define TXS _ = s = (_z=-1, 0) + x

#define INX LDX ((x+1) & 0xff)
#define DEX LDX ((x-1) & 0xff)

#define INY LDY ((y+1) & 0xff)
#define DEY LDY ((y-1) & 0xff)

#define INC *(after(&_, 5, __LINE__, a)) = __ =
#define DEC *(after(&_, 6, __LINE__, a)) = __ =
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
//  1: LDx 3: CPx 4: ADC
//  0: STx
//  5: INC 6: DEC
int* after(byte *r, int rwc, int line, byte cmp) {
  static int _;

  int isAddress = (__ & 0xffff0000) == MEM_MODE;
  if (!isAddress && (v < 0 || v >= 0xff)) {
      fprintf(stderr, "\n\n%% Line %d: value is out of range for immediate mode, please use 'STA/LDA <MODE>(0x0501);' to give address: 0x04x (%d).\n", line, a);
      exit(0);
  }

  int a = __ & 0xffff;
  byte v;

  // memory operation
  if (rwc==1 || rwc==3 || rwc==4 || rwc==5 || rwc==6) {
    if (isAddress) {
      v = mem[a];  
    } else { // immediate
      v = a;
    }

    if (rwc==5) v++; // inc
    else if (rwc==6) v=v-1+256; // dec
    else if (rwc==4) { // adc
      c = (*r + v > 255);
      *r += v + c;
    } else {
      *r = v & 0xff;
    }

    if (rwc==3) { // compare, set C
      c = !!(cmp >= v);
      v = cmp - v;
    }

  } else if (rwc==2) {
    // Write operation STx INC DEC
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

