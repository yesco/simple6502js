#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

//#include <conio.h>

#include <assert.h>

#define PROGSIZE
#include "progsize.c"

#include <stdint.h> // cc65 uses 29K extra memory???

typedef int16_t L;
typedef uint16_t uint;
typedef unsigned uchar;

#include "extern-vm.c"

extern unsigned int T=42;
extern unsigned int nil=0;

#define mO(op) op
#define mO2(op, b) op b
#define mN2(name, op, b) mO2(op,b)

#define mO3(op, w) op w
#define mN3(name, op, w) mO3(op,w)

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

#define ASM(x, ...) addasm((x), sizeof(x)-1,__VA_ARGS__)

// poor mans argv, LOL
#define ARG(n) (*((uint*)(&len-2*n)))

void __cdecl__ addasm(char* x, uchar len, ...) {
  uchar c, n= 1;
  uint* p= (uint*)&len;
  //va_list ap;
  //va_start(ap, fmt);
  //for(c=1; c<15; ++c) printf("%04X = %04x\t", ARG(c), *--p);   putchar('\n');

  printf("ASM[%d]:  \"%s\"\n", len, x);
  for(bi=0 ;bi<len; ) {
    c= x[bi];

    if (c=='#') { buff[bz]= *--p; ++n; }
    else if (c=='?') { buff[bz]= *--p; ++bz; ++bi; buff[bz]= *p >> 8; ++n; }
    else buff[bz]= c;
 
    ++bz;
    buff[bz]= 0; // BRK, haha

    ++bi;
  }
  printf("ASM[%d]=> \"%s\"\n", len, buff);
}


char mc[120]= {0};
char* mcp= mc;

/*

#define DASM(x)

void B(char b)  { DASM(printf("%02x ", b)); *mcp++= (b)&0xff; }
void O(char op) { DASM(printf("\n\t")); B(op); }
void W(void* w) { *((uint*)mcp)++= (uint)(w); DASM(printf("%04x", w)); }

#define O2(op, b) do { O(op);B(b); } while(0)
#define O3(op, w) do { O(op);W(w); } while(0)
#define N3(opn, op, w) do { O(op);W(w); DASM(printf("\t\t%-4s %s", opn, #w)); } while(0) 
#define N2(opn, op, b) do { O(op);B(b); DASM(printf("\t\t%-4s %02x", opn, b)); } while(0) 
*/

// cc65 can't do this:
//#define MAKE_WORD(x,y) x,y
//#define MAKE_STR(...) ((char[]){__VA_ARGS__, 0})

#define U (void*)

// TODO: we don't need end 0 on each line
#define REND 0, // cost 100 bytes, only for consistency
//#define REND

#define RULES
#define MATCHER

#ifdef RULES

char* rules[]= {
  "0+", "", 0, 0,
  "1+", mJSR("??"), U 3, U incax2, REND
  "2+", mJSR("??"), U 3, U incax4, REND
  "3+", mJSR("??"), U 3, U incax6, REND
  "4+", mJSR("??"), U 3, U incax8, REND
  // TODO: only <255
  //"[%b+", mLDYn("#") mJSR("??"), U 5, U incaxy, 0,

  "+", mJSR("??") "s-", U 5, U tosaddax, REND


  "0-", "", 0, REND
  "1-", mJSR("??"), U 3, U decax2, REND
  "2-", mJSR("??"), U 3, U decax4, REND
  "3-", mJSR("??"), U 3, U decax6, REND
  "4-", mJSR("??"), U 3, U decax8, REND
  // TODO: only <255
  //"[%b-", mLDYn("#") mJSR("??"), U 5, U decaxy, REND

  "-", mJSR("??") "s-", U 5, U tossubax, REND

  // ][ conflicts with this

  "0*", mLDAn("\0") mTAX(), U 3, REND
  "1*", "", 0, 0,
  "2*", mJSR("??"), U 3, U aslax1, REND
  "3*", mJSR("??"), U 3, U mulax3, REND
  "4*", mJSR("??"), U 3, U aslax2, REND
  "5*", mJSR("??"), U 3, U mulax5, REND
  "6*", mJSR("??"), U 3, U mulax6, REND
  "7*", mJSR("??"), U 3, U mulax7, REND
  "8*", mJSR("??"), U 3, U aslax3, REND
  // TODO: how to match? \0 lol Z match \0?
  ",Z\x09*", mJSR("??"), U 3, U mulax9, REND
  // TODO: how to match?
  ",Z\x0a*", mJSR("??"), U 3, U mulax10, REND
  // TODO: only <255
  //"[%b*", mLDA("#") mJSR("??"), U 5, U tosmula0, REND

  "*", mJSR("??") mJSR("??") mANDn("\xfe") "s-", U 10, U asrax1, U tosmulax, REND


  "2/", mJSR("??"), U 3, U asrax1, REND
  "4/", mJSR("??"), U 3, U asrax2, REND
  "8/", mJSR("??"), U 3, U asrax3, REND

  ",Z\x10/", mJSR("??"), U 3, U asrax4, REND
  //",Z\x80/", mJSR("??"), U 3, U asrax7, REND  // doesn't exist?
  // TODO: only <255
  //"%b/", mLDAn("#") mJSR("??"), U 5, U pushax, U tosdiva0, REND

  "/", mJSR("??") mJSR("??") mANDn("\xfe") "s-", U 10, U tosdivax, U aslax1, REND


  "0=", mTAY() mBNE("\x02") mCPXn("\0") mBNE("\0"), U 7, REND
  "%d=", mCMPn("_") mBNE("\x02") mCPXn("\"") mBNE("\0"), U 8, REND

  "=", mJSR("??") "s-", U 5, U toseqax, REND

  // Unsigned Int
  "%d<", mTAY() mCMPn("_") mTXA() mSBCn("\"") mTYA() mBCS("\0"), U 9, REND

  "<", mJSR("??"), U 3, U toseqax, REND
  // TODO: signed int - maybe use "function argument"
  //"%d<", mTAY() mEORn("\x80") mCMPn("_") mTXA() mEORn("\x80") mSBCn("\"") mBCS("\0") mTYA() mBCS("\0"), U 12, REND

  "A", mJSR("??"), U 3, U ffcar, REND
  "D", mJSR("??"), U 3, U ffcdr, REND
//"C", mJSR("??") "s-", U 5, U cons, REND

  "!", mJSR("??") "s-", U 5, U staxspidx, REND
  "@", mJSR("??"), U 3, U ldaxi, REND
//".", mJSR("??"), U 3, U princ, REND
//"W", mJSR("??"), U 3, U prin1, REND
//"P", mJSR("??"), U 3, U print, REND

  ",", mLDAn("#") mLDXn("#"), U 4, REND
  ":", mSTA("ww") mSTX("w+"), U 6, REND
  ";", mLDA("ww") mLDX("w+"), U 6, REND

  "][", 0, U 0, REND
  "]", "s-" mJSR("??"), U 5, U popax, REND // TODO: useful?

  "[", "s+" mJSR("??"), U 5, U pushax, REND

  //"0[", mJSR("??"), U3, U pushzero, REND // TODO: need for local var? keep ax?
  //"9[", mJSR("??"), U3, U pushnil, REND // TODO: need for local var? keep ax?
  "0", mLDAn("\0") mTAY(), U 3, REND
  "9^%0", mJMP("??"), U 3, U retnil, REND // redundant? auto opt...
  "9",  mJSR("??"), U 3, U retnil, REND

  "%d", mLDAn("_") mLDXn("\""), U 4, REND

  // TODO: %a relateive stack...
  // TODO: keep track of stack! [] enough?
  // TODO: if request ax?
  // TODO: if request => w==1 then JSR(ldax0sp)
  // TODO: use %1357 to indicate depth on stack?
  "%a%1", mJSR("??"), U 3, U ldax0sp, REND
  "%a",  mLDYn("_") mJSR("??"), U 5, U ldaxysp, REND

  // TODO: more than 4 ...
  "^4%4", mJMP("??"), U 3, U incsp8, REND
  "^3%3", mJMP("??"), U 3, U incsp6, REND
  "^2%2", mJMP("??"), U 3, U incsp4, REND
  "^1%1", mJMP("??"), U 3, U incsp2, REND
  "^0%0", mRTS(),     U 1, REND

  //"X^^",   "<" mJMP("ww"),   U 4, REND // ERROR (need popstack first/move)
  "R^",    "<" mJMP("\0\0"), U 4, REND // SelfTailRecursion
  "R",         mJSR("\0\0"), U 3, REND // SelfRecursion
  "Z",     "<" mJMP("\0\0"), U 4, REND // SelfTailRecursion/loop/Z

  // CALL = "Xcode" - would prefer other prefix?
  //"X^^",    "<" mJMP("ww"),     U 4, REND // ERROR (need popstack first/move)
  "X^",     "<" mJMP("ww"),  U 4, REND // TailCall other function
  "X",          mJSR("ww"),  U 3, REND // Call other function
  
  // TODO: not complete yet
  //   patching ops=="immediate": :=save ;=patch /=swap
  // TODO: how aobut balancing stack, recurse on compiler?
  //   pop to same level?
  //   if return stack ... 64 lol
  "I", ":", U 1, REND
  "{", mSEC() mBCS("\0") ":" "/" ";", U 6, REND
  "}", ";", U 1, REND
  0};
#endif // RULES

// No OP:
//   ^B^C^D ^G ^K^L ^O   ^R^S^T ^W ^Z^[^\ ^_   
//  "# ' + / : ; < ?     234 7 : Z[\ _  rst w z{| 
//
// "   = hi byte from %d
// #   = inline (lo) byte from code 
// '   = 0x80 for signed... hmmm... _'  hmmmm: TODO: EOR last byte gen!
// w+  = same word from code + 1
// /   = swap
// :   = push loc
// ;   = patch loc to here
// <   = move n params of function for tailrec
// ??  = inline word from param
// 234 7
// Z
// [n  = stack == n
// \\
// _   = %d match (limit to 255?) (== lo byte)
// r
// s
// t 
// ww  = word from code
// z
// {
// |

#ifdef MATCHER
uint  ww;  // _ ww
uchar whi; // " // TODO: redundant? we have ww?
char  charmatch; 
int   stk= 0;

char matching(char* bc, char* r) {
  charmatch= ww= whi= 0;
  while(*r) {
    //printf("matching: '%c' '%c' of '%s' '%s' STK=%d\n", *bc, *r, bc, r, stk);
    if (*r=='Z') { if (*bc) break; } // match \0
    // TODO: %b match only 0 <= x <= 255
    else if (*r=='%' && r[1]=='d') {
      ++r;
      if (*bc==',') { ww= *(L*)(bc+1); whi= ww>>8; charmatch+= 2; }
      else if (isdigit(*bc) && *bc<='8') { ww= *bc-'0'; whi= 0; }
      else return 0;
    } else if (*r=='%' && r[1]=='a') {
      // TODO: if request ax?
      char lastvar= 'a'; // TODO: fix, lol
      if (!islower(*bc)) return 0;
      assert(*bc==lastvar); // TODO: fix, lol
      ++r;
      if (islower(*bc)) { ww= 2*(lastvar-*bc+stk)+1; }
      else return 0;
    } else if (*r=='%' && isdigit(r[1])) {
      // stack depth match
      // TODO: this is manipulated during matching, lol so all wrong!
      //if (stk!=r[1]) return 0;
      ++r;
    } else if (*bc != *r) return 0;
    ++charmatch;
    ++bc; ++r;
  }
  // got to end of rule == match!
  return !*r;
}
#endif // MATCHER

//int main(int argc, char** argv) {
int main(void) {

/*
  bz=0; ASM(mTYA() mTXA() mLDAn("#"), 0);
  bz=0; ASM(mTYA() mTXA() mLDAn("#"), 65, 0);
  bz=0; ASM(mTYA() mTXA() mLDAn("#") mLDA("??"), 65, 256*65+66);
  bz=0; ASM(mTYA() mTXA() mLDAn("#") mLDA("??"), 65, 256*65+66); // 28 bytes...
  //TYA(); TXA(); LDAn(65); LDA(256*65+66); // (- 3365 3333) 32 bytes...

  //printf("foo: %s\n", MAKE_STR(65, 66, 67, 68));

#define ABCD ((unsigned int)printf)
#define HXS(a,s) ("0123456789abcdef"[(((unsigned int)a)>>s) & 0x0f])

#define STR(a) #a
#define FOO(a) STR(a)
#define BAR(a) FOO((a>>0))

#define HEX(a) STR(HXS(a,12)) STR(HXS(a,8)) STR(HXS(a,4) HXS(a,0))
  printf("%04x<FISH\n", printf);
  printf("%c<FISH\n", "0123456789abcdef"[(ABCD>>12) & 0x0f]);
  printf("%c<FISH\n", "0123456789abcdef"[(ABCD>>8) & 0x0f]);
  printf("%c<FISH\n", "0123456789abcdef"[(ABCD>>4) & 0x0f]);
  printf("%c<FISH\n", "0123456789abcdef"[(ABCD>>0) & 0x0f]);

  printf("%c<ABBA\n", HXS(printf,12));
  printf("%c<ABBA\n", HXS(printf,8));
  printf("%c<ABBA\n", HXS(printf,4));
  printf("%c<ABBA\n", HXS(printf,0));
  printf("\n%s<STR\n", STR(ABCD));
  printf("\n%s<FOO\n", FOO(ABCD));
  printf("\n%s<FOO\n", BAR(ABCD));
//  printf("%s<ABBA\n", HXS(printf,12) HXS(printf,8) "\0");

//  printf("%s", HEX(printf) "\n");

*/

  // 7131 bytes... TOTAL 3K?
  #ifdef MATCHER // (- 6292 4965) == 1327 BYTES optimizer code!!!
  // (- 4863 4214) === 649 bytes rules!
  {

  char* bc= "[3[3+"; // works
  bc= "a[0=I]^0{][a[1=I]^0{][a[1-R[a[2-R+^1}}";

  // TODO: ax and saved and lastvar tracking... [-delay
  // TODO: can't this be done before here, in byte code gen?
  while(*bc) {
    // Search all rules for first match
    // TODO: move out
    char **p= rules, *r= 0;
    char i, *pc, c; int z;
    char match= 0;

    printf("\n\n- %s\n", bc);

    while(*p) {
      if (matching(bc, *p)) {
        //printf("---MATCH: '%s'\ton '%s'\n", *p, bc);
        match= 1;
      }
      r= *p++;
      if (match) printf("  %s\t", r);
      pc= *p++; z= (uint)*p++;
      if (match) printf(" [%d] ", z);
      while(z-- > 0) { // *pc) {
        c= *pc;
        if (c==0x20) { if (match) printf(" JSR "); }
        else if (c==0x4c) { if (match) printf(" JMP "); }
        else if (c==0x6c) { if (match) printf(" JPI "); }
        else if (c==0x60) { if (match) printf(" RTS "); }
        // TODO: These are "arguments", the have no matching OP-codes, BUTT
        //       they aren't safe substitutions... lol, "WORKS FOR NOW".
        // WARNING: may give totally random bugs, depending on memory locs of data!
        else if (c=='#') { z--; if (match) printf("#$%02x ", ww & 0xff); }
        else if (c=='"') { z--; if (match) printf("#$%02x ", ww>>8); }
        else if (c=='?' && pc[1]=='?') { z--;++pc; if (match) printf("$%04X ", *p); ++p; }
        else if (c=='w' && pc[1]=='w') { z--;++pc; if (match) printf("$%04X ", ww); }
        else if (c=='w' && pc[1]=='+') { z--;++pc; if (match) printf("$%04X ", ww+1); }
        else if (c=='s' && pc[1]=='+') { z--;++pc; ++stk; }
        else if (c=='s' && pc[1]=='-') { z--;++pc; --stk; }
        //else if (c=='\'') lastbyte ^= 0x80; // TODO: when gen to buffer...
        else if (c==':') ; // TODO: push loc
        else if (c==';') ; // TODO: patch loc
        else if (c=='/') ; // TODO: swap loc
        else { if (match) printf(" %02x ", *pc); } // we don't know, for now
        ++pc;
      }
      //while(*p) printf("\n\t: %04x", *p++);
      //assert(!*p);
      p++;
      if (match) break;
    }

    // TODO: move bc forward almost length of rule, but %d... %a...
    if (!match) {
      printf("%% NO MATCH! Can't compile: bc='%s'\n", bc);
      exit(3);
    }

    bc+= charmatch;
    //printf(">>> bc='%s' r='%s' bc='%s'\n", bc, r, bc);
    // TODO: %d %a???
  }

  }
  #endif // MATCHER

  PROGSIZE;
  return 0;
}
