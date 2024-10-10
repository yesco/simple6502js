#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

//#include <conio.h>

#define O(op) op
#define O2(op, b) op "#"
#define N2(name, op, b) O2(op, b)

#define O3(op, w) op "??"

#define LDAn(n) N2("LDAn","\xA9",n)
#define LDXn(n) N2("LDXn","\xA2",n)
#define LDYn(n) N2("LDYn","\xA0",n)


#define LDA(w)  O3("\xAD",w)
#define LDX(w)  O3("\xAE",w)
#define LDY(w)  O3("\xAC",w)

#define STA(w)  O3("\x8D",w)
#define STX(w)  O3("\x8E",w)
#define STY(w)  O3("\x8C",w)


#define ANDn(b) O2("\x29",b)
#define ORAn(b) O2("\x09",b)
#define EORn(b) O2("\x49",b)

#define ASL()   O("\x0A")
#define CMPn(b) N2("CMPn","\xC9",b)
#define CPXn(b) N2("CPXn","\xE0",b)
#define CPYn(b) N2("CPYn","\xC0",b)

#define SBCn(b) N2("SBC","\xE9", b)

#define PHP()   O("\x08")
#define CLC()   O("\x18")
#define PLP()   O("\x28")
#define SEC()   O("\x38")

#define PHA()   O("\x48")
#define CLI()   O("\x58")
#define PLA()   O("\x68")
#define SEI()   O("\x78")

#define DEY()   O("\x88")
#define TYA()   O("\x98")
#define TAY()   O("\xA8")
#define CLV()   O("\xB8")

#define INY()   O("\xC8")
#define CLD()   O("\xD8")
#define INX()   O("\xE8")
#define SED()   O("\xF8")

#define TXA()   O("\x8A")
#define TAX()   O("\xAA")

#define BMI(b)  O2("\x30", b)
#define BPL(b)  O2("\x10", b)

#define BNE(b)  O2("\xD0",b)
#define BEQ(b)  O2("\xF0",b)

#define BCC(b)  O2("\x90",b)
#define BCS(b)  O2("\xB0",b)

#define BVC(b)  O2("\x50",b)
#define BVS(b)  O2("\x70",b)


#define JSR(a)  N3("JSR","\x20",a)
#define RTS(a)  O("\x60")

#define JMP(a)  N3("JMP", "\x4c",a)
#define JMPi(a) N3("JPI", "\x6c",a)

#define BRK(a)  O("\x00")

char bi=0, buff[255];

typedef unsigned char uchar;
typedef unsigned int uint;

#define ASM(x, ...) addasm((x), sizeof(x)-1,__VA_ARGS__)

void __cdecl__ addasm(char* x, uchar len, ...) {
  uchar c, n= 1;
  //va_list ap;
  //va_start(ap, fmt);
#define ARG(n) (*((uint*)(&len-2*n)))
  for(c=1; c<15; ++c)
    printf("%04X\t", ARG(c));
  putchar('\n');

  printf("ASM[%d]:  \"%s\"\n", len, x);
  for(bi=0 ;bi<len; ) {
    c= x[bi];

    if (c=='#') { buff[bi]= ARG(n); ++n; }
    else if (c=='?') { buff[bi++]= ARG(n); buff[bi]= ARG(n) >> 8; ++n; }
    else buff[bi]= c;

    buff[++bi]= 0; // BRK, haha
  }
  printf("ASM[%d]=> \"%s\"\n", len, buff);
}

// CC65 can't do this...
#define MAKE_WORD(x,y) x,y
#define MAKE_STR(...) ((char[]){__VA_ARGS__, 0})

int main(int argc, char** argv) {
  printf("Hello " "\n\"22:\x22 \n#23:x23 \n27:\x27 \n+2B:\x2B \n/2F:\x2F \n32:\x32 \n33:\x33 \n34:\x34 \n37:\x37 \n:3a:\x3a \n;3b:\x3b \n<3c:\x3c \n?3f:\x3f World!\n");
  ASM(TYA() TXA() LDAn(41), 0);
  ASM(TYA() TXA() LDAn(41), 65, 0);
  ASM(TYA() TXA() LDAn(41) LDA(99), 65, 256*65+66);
  ASM(TYA() TXA() LDAn(41) LDA(99), 1,2,3,4,5,6,7,0xabcd,0xdeadbeef);

  //printf("foo: %s\n", MAKE_STR(65, 66, 67, 68));
  return 0;
}
