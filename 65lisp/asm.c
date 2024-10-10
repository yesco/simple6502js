#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

//#include <conio.h>

#include "progsize.c"

#define mO(op) op
#define mO2(op, b) op "#"
#define mN2(name, op, b) mO2(op, b)

#define mO3(op, w) op "??"

#define mLDAn(n) mN2("LDAn","\xA9",n)
#define mLDXn(n) mN2("LDXn","\xA2",n)
#define mLDYn(n) mN2("LDYn","\xA0",n)


#define mLDA(w)  mO3("\xAD",w)
#define mLDX(w)  mO3("\xAE",w)
#define mLDY(w)  mO3("\xAC",w)

#define mSTA(w)  mO3("\x8D",w)
#define mSTX(w)  mO3("\x8E",w)
#define mSTY(w)  mO3("\x8C",w)


#define mANDn(b) mO2("\x29",b)
#define mORAn(b) mO2("\x09",b)
#define mEORn(b) mO2("\x49",b)

#define mASL()   mO("\x0A")
#define mCMPn(b) mN2("CMPn","\xC9",b)
#define mCPXn(b) mN2("CPXn","\xE0",b)
#define mCPYn(b) mN2("CPYn","\xC0",b)

#define mSBCn(b) mN2("SBC","\xE9", b)

#define mPHP()   mO("\x08")
#define mCLC()   mO("\x18")
#define mPLP()   mO("\x28")
#define mSEC()   mO("\x38")

#define mPHA()   mO("\x48")
#define mCLI()   mO("\x58")
#define mPLA()   mO("\x68")
#define mSEI()   mO("\x78")

#define mDEY()   mO("\x88")
#define mTYA()   mO("\x98")
#define mTAY()   mO("\xA8")
#define mCLV()   mO("\xB8")

#define mINY()   mO("\xC8")
#define mCLD()   mO("\xD8")
#define mINX()   mO("\xE8")
#define mSED()   mO("\xF8")

#define mTXA()   mO("\x8A")
#define mTAX()   mO("\xAA")

#define mBMI(b)  mO2("\x30", b)
#define mBPL(b)  mO2("\x10", b)

#define mBNE(b)  mO2("\xD0",b)
#define mBEQ(b)  mO2("\xF0",b)

#define mBCC(b)  mO2("\x90",b)
#define mBCS(b)  mO2("\xB0",b)

#define mBVC(b)  mO2("\x50",b)
#define mBVS(b)  mO2("\x70",b)


#define mJSR(a)  mN3("JSR","\x20",a)
#define mRTS(a)  mO("\x60")

#define mJMP(a)  mN3("JMP", "\x4c",a)
#define mJMPi(a) mN3("JPI", "\x6c",a)

#define mBRK(a)  mO("\x00")

unsigned char bi=0, bz=0, buff[255];

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

    if (c=='#') { buff[bz]= ARG(n); ++n; }
    else if (c=='?') { buff[bz]= ARG(n); ++bz; ++bi; buff[bz]= ARG(n) >> 8; ++n; }
    else buff[bz]= c;
 
    ++bz;
    buff[bz]= 0; // BRK, haha

    ++bi;
  }
  printf("ASM[%d]=> \"%s\"\n", len, buff);
}

// CC65 can't do this...
#define MAKE_WORD(x,y) x,y
#define MAKE_STR(...) ((char[]){__VA_ARGS__, 0})

int main(int argc, char** argv) {
  printf("Hello " "\n\"22:\x22 \n#23:x23 \n27:\x27 \n+2B:\x2B \n/2F:\x2F \n32:\x32 \n33:\x33 \n34:\x34 \n37:\x37 \n:3a:\x3a \n;3b:\x3b \n<3c:\x3c \n?3f:\x3f World!\n");
  bz=0; ASM(mTYA() mTXA() mLDAn(41), 0);
  bz=0; ASM(mTYA() mTXA() mLDAn(41), 65, 0);
  bz=0; ASM(mTYA()
      mTXA()
      mLDAn(41)
      mLDA(??)
      , 65, 256*65+66);

  //printf("foo: %s\n", MAKE_STR(65, 66, 67, 68));

  PROGSIZE;

  return 0;
}
