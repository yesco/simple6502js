// ./run-asm to compile and run this...

// This is a prototype of a "PEEP-HOLE CODE GENERATOR/OPTIMIZER"
//
// It works by looking at successive prefixes of AL byte-code
// by ./65vm and then taking that as input.
//
// Rules are tested in order, so longest match needs to be first.
// When a rule matches, it's "action" is run. This generates 
// an assembly string, taking static parameters such as addresses,
// and runs inline actions, such as keeping track of stack depth.
//
// A rule may also have pre/post-conditions, or special matchers.
// These relates to conditions of stackdepths (%0 %3 %^),
// and matching and extracting numbers on any form (,xxxx or '3').
//
// The code is about 50% of what the ./65asm hard-coded rules were,
// which frankly was a code-mess.
//
// Speed is somewhat slower, but coming closer...


// 6808 bytes... (no DEBASM no APRINT)
// (- 6808 3905) == 2903 BYTES optimizer code!!! (incl rules)
// (- 4823 3905) === 918 bytes, 70ish rules! (-100B REND)

#define RULES
#define MATCHER

#define DEBASM(a)
//#define DEBASM(a) do { a; } while (0)

//#define APRINT(...) printf(__VA_ARGS__)
#define APRINT(...) 


//  bc= "[a[2<I][a^{][a[1-R[a[2-R+^}";
//

// TODO: make variant that pushes params on R stack with PHA, return becomes PLA
//   potentially less code! and 30% faster!

// 45 bytes, lol
// - (/ 1137712 674346.0) 69% slower if not use register
//   also removed match var, z is now byte, moved vars out of scope...
// - PROG: 6808 bytes, RULES: 918 bytes, +ASM: 2903 bytes

// 42 bytes, but optimized code...
// - PROG: 7702 bytes, RULES: 918 bytes, +ASM: 3279 bytes
//   (why did RULES increase?)

// 42 bytes, LOL
// - corrected gen etc, counted -z wrongly at '#' and '"'
// - PROG: 8180 bytes, RULES: 414 bytes, +ASM: 4K
// 37 bytes (!) I think it's wrong as it ends with RTS, lol STK wrong after IF...
// - simplify skip rule
// - "^{" ELSE no generate skip ELSE part if ended with RETURN ^
// - should be 39 bytes I think end with JMP INCSP2
// - PROG: 7275 bytes, RULES: 414 bytes, +ASM: 3061 bytes !!!
//   (so much less; maybe it's reduced by no "if (match)" etc...)

// 43 bytes
// - don't load a var if already in AX
// - count bytes
// - PROG: 7577 bytes, RULES: 926 bytes, +ASM: 3896 (lisp-asm: 6330 bytes) ???

// 50 bytes
// - track ax, no clever reuse
// - [1+ etc... no need pushax
// - 7131 bytes... TOTAL 3K?

// 59 bytes first GEN no opt Not working?
// - just generate first non-optimized
// - PROG: 6737 bytes, RULES: 878 bytes, +ASM: 2523 bytes


// NOT OPTIMIZED:
// - ax push delay
// - I ..^{ ..^} doesn't know stack depth from before, recurse?
// - JMP/JSR 0 0 needs to post substitute to actual address
// - actually call it!
// - last usage of lastvar, can do popax instead, cheaper/less stack adjustment? (unless have locals)
// - cc65 is clever about tracking Y register value, not sure if really doable, lol
// - track RETURNS generated, (value and how, JMP there!)
//   RETURN 0, RETURN 1, esp because of JMP INCSP7...
// - ++c very efficient INC c
// 
// ; ++r;                                  // 9 bytes!
// ; 
// L0207:  ldy     #$03
//         ldx     #$00
//         lda     #$01
//         jsr     addeqysp
// VERY COMMON? why not LDY 3   jsr WINCYSP // 5 bytes
//
// - possile, read bytecode from fixed array buffer -> more simple code on "bc"
// - look at gen[bytes]= ... is it optimal code gen? 

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

//#include <conio.h>

#include <assert.h>

#define PROGSIZE
#include "progsize.c"

#include <stdint.h>

typedef int16_t L;
typedef uint16_t uint;
typedef unsigned uchar;

#include "extern-vm.c"

extern unsigned int T=42;
extern unsigned int nil=0;

#define O(op) op
#define O2(op, b) op b
#define N2(name, op, b) O2(op,b)

#define O3(op, w) op w
#define N3(name, op, w) O3(op,w)

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

#define BRK(a)  O("\0")

#define ASM(x,...) (x),U (sizeof(x)-1),__VA_ARGS__,REND

#define U (void*)

// TODO: instead of 2 bytes here, could have length inside hibyte of Z, but difficult to get right?
//        macro?
#define REND 0, // cost 70rules x 2 bytes= 140 bytes, needed unless have count inside bytelen...

#ifdef RULES

char* rules[]= {
  "[0+", "", 0, 0,
  "[1+", JSR("w?"), U 3, U incax2, REND
  "[2+", JSR("w?"), U 3, U incax4, REND
  "[3+", JSR("w?"), U 3, U incax6, REND
  "[4+", JSR("w?"), U 3, U incax8, REND
  // TODO: only <255
  //"[%b+", LDYn("#") JSR("w?"), U 5, U incaxy, 0,

  "+", JSR("w?") "s-", U 5, U tosaddax, REND


  "[0-", "", 0, REND
  "[1-", JSR("w?"), U 3, U decax2, REND
  "[2-", JSR("w?"), U 3, U decax4, REND
  "[3-", JSR("w?"), U 3, U decax6, REND
  "[4-", JSR("w?"), U 3, U decax8, REND
  // TODO: only <255
  //"[%b-", LDYn("#") JSR("w?"), U 5, U decaxy, REND

  "-", JSR("w?") "s-", U 5, U tossubax, REND

  // ][ conflicts with this

  "[0*", LDAn("\0") TAX(), U 3, REND
  "[1*", "", 0, 0,
  "[2*", JSR("w?"), U 3, U aslax1, REND
  "[3*", JSR("w?"), U 3, U mulax3, REND
  "[4*", JSR("w?"), U 3, U aslax2, REND
  "[5*", JSR("w?"), U 3, U mulax5, REND
  "[6*", JSR("w?"), U 3, U mulax6, REND
  "[7*", JSR("w?"), U 3, U mulax7, REND
  "[8*", JSR("w?"), U 3, U aslax3, REND
  // TODO: how to match? \0 lol Z match \0?
  "[,Z\x09*", JSR("w?"), U 3, U mulax9, REND
  // TODO: how to match?
  "[,Z\x0a*", JSR("w?"), U 3, U mulax10, REND
  // TODO: only <255
  //"[%b*", LDA("#") JSR("w?"), U 5, U tosmula0, REND

  "*", JSR("w?") JSR("w?") ANDn("\xfe") "s-", U 10, U asrax1, U tosmulax, REND


  "[2/", JSR("w?"), U 3, U asrax1, REND
  "[4/", JSR("w?"), U 3, U asrax2, REND
  "[8/", JSR("w?"), U 3, U asrax3, REND

  "[,Z\x10/", JSR("w?"), U 3, U asrax4, REND
  //",Z\x80/", JSR("w?"), U 3, U asrax7, REND  // doesn't exist?
  // TODO: only <255
  //"%b/", LDAn("#") JSR("w?"), U 5, U pushax, U tosdiva0, REND

  "/", JSR("w?") JSR("w?") ANDn("\xfe") "s-", U 10, U tosdivax, U aslax1, REND


  // "[0=", STXzp(tmp1) ORAzp(tmp1) BNE("\0"), U 6, REND // TODO: destructive...
  // often followed by TAX then JSR incspN to RETURN 0, but if not destructive, then SAME bytes!
  "[0=", TAY() BNE("\x02") CPXn("\0") BNE("\0"), U 7, REND
  "[%d=", CMPn("#") BNE("\x02") CPXn("\"") BNE("\0"), U 8, REND

  "=", JSR("w?") "s-", U 5, U toseqax, REND

  // Unsigned Int
  "[%d<", TAY() CMPn("#") TXA() SBCn("\"") TYA() BCS("\x00"), U 9, REND

  "<", JSR("w?"), U 3, U toseqax, REND
  // TODO: signed int - maybe use "function argument"
  //"%d<", mTAY() mEORn("\x80") mCMPn("#") mTXA() mEORn("\x80") mSBCn("\"") mBCS("\0") mTYA() mBCS("\0"), U 12, REND

  "A", JSR("w?"), U 3, U ffcar, REND
  "D", JSR("w?"), U 3, U ffcdr, REND
//"C", JSR("w?") "s-", U 5, U cons, REND

  "!", JSR("w?") "s-", U 5, U staxspidx, REND
  "@", JSR("w?"), U 3, U ldaxi, REND
//".", JSR("w?"), U 3, U princ, REND
//"W", JSR("w?"), U 3, U prin1, REND
//"P", JSR("w?"), U 3, U print, REND

  ",", LDAn("#") LDXn("#"), U 4, REND
  ":", STA("ww") STX("w+"), U 6, REND
  ";", LDA("ww") LDX("w+"), U 6, REND

  "][", 0, U 0, REND // 3 zeroes! lol
  "]", "s-" JSR("w?"), U 5, U popax, REND // TODO: useful?

  "[", "s+" JSR("w?"), U 5, U pushax, REND

  //"0[", JSR("w?"), U3, U pushzero, REND // TODO: need for local var? keep ax?
  //"9[", JSR("w?"), U3, U pushnil, REND // TODO: need for local var? keep ax?
  "0", LDAn("\0") TAY(), U 3, REND
  "9^%0", JMP("w?"), U 3, U retnil, REND // redundant? auto opt...
  "9",  JSR("w?"), U 3, U retnil, REND

  "%d", LDAn("#") LDXn("\""), U 4, REND

  // TODO: %a relateive stack...
  // TODO: keep track of stack! [] enough?
  // TODO: if request ax?
  // TODO: if request => w==1 then JSR(ldax0sp)
  // TODO: use %1357 to indicate depth on stack?
  //"[a", JSR("w?"), U 3, U ldax0sp, REND // TODO: ?? parameters/locals
  "%a%1", JSR("w?"), U 3, U ldax0sp, REND // TODO: ?? parameters/locals
  "%a",  LDYn("#") JSR("w?"), U 5, U ldaxysp, REND // TODO: ?? parameters/locals

  // TODO: more than 4 ...
  "^%4", "s^" JMP("w?"), U 5, U incsp8, REND
  "^%3", "s^" JMP("w?"), U 5, U incsp6, REND
  "^%2", "s^" JMP("w?"), U 5, U incsp4, REND
  "^%1", "s^" JMP("w?"), U 5, U incsp2, REND
  "^%0", "s^" RTS(),     U 3, REND

  //"X^^",   "<" JMP("ww"),   U 4, REND // ERROR (need popstack first/move)
  "R^", "<" JMP("\0\0") "s^", U 6, REND // SelfTailRecursion
  "R",      JSR("\0\0"),      U 3, REND // SelfRecursion // TODO: param count/STK?
  "Z",  "<" JMP("\0\0") "s^", U 6, REND // SelfTailRecursion/loop/Z

  // CALL = "Xcode" - would prefer other prefix?
  //"X^^",    "<" JMP("ww"),     U 4, REND // ERROR (need popstack first/move)
  "X^", "<" JMP("ww") "s^",  U 4, REND // TailCall other function
  "X",      JSR("ww"),       U 3, REND // Call other function // TODO: param/STK?
  
  // TODO: not complete yet
  //   patching ops=="immediate": :=save ;=patch /=swap
  // TODO: how aobut balancing stack, recurse on compiler?
  //   pop to same level?
  //   if return stack ... 64 lol
  "I", ":", U 1, REND
  "{%^", ":" "/" ";", U 3, REND // after return no need jmp endif!
  "{", SEC() BCS("\0") ":" "/" ";", U 6, REND // TODO: restore IF stk, lol need save
  "}", ";", U 1, REND
  0};
#endif // RULES

// No OP:
//   ^B^C^D ^G ^K^L ^O   ^R^S^T ^W ^Z^[^\ ^_   
//  "# ' + / : ; < ?     234 7 : Z[\ _  rst w z{| 
//
// _   = %d match (limit to 255?) (== lo byte)
// "   = hi byte from %d
// #   = inline (lo) byte from code 
// '   = 0x80 for signed... hmmm... _'  hmmmm: TODO: EOR last byte gen!
// ww  = word from code
// w+  = same word from code + 1
// w?  = inline word from param
// /   = IF swap
// :   = IF push loc
// ;   = IF patch loc to here
// <   = move n params of function for tailrec
// 234 7
// Z
// [
// \\
// r
// s
// t 
// z
// {
// |

#ifdef MATCHER
uint  ww;  // _ ww
uchar whi; // " // TODO: redundant? we have ww?
char  charmatch; 
int   stk= 0;
char  ax= 0;
#define MAXIF 10
char  patchstk[MAXIF], *patch= patchstk+MAXIF;
char  gen[255]; // generate asm bytes

// Rule maching understands following "tests":
//   c     == match literal char (if none of the following:)
//   Z     == 0 byte
//   %d    == match ",xxxx" or "3" (digit) sets "ww"
//            used by ww, w+, w? and #, and "
//   %a    == match 'a'-'z'
//   %0 -9 == match only if STK is 0-9
//   %^    == match if STK is 60+ == after RETURN
char matching(char* bc, char* r) {
  char c, nc, b;
  charmatch= ww= whi= 0;
  DEBASM(printf("\tRULE: '%s' STK=%d\n", r, stk));
  c= *r;
  while(c) {
    nc= r[1];
    b= *bc;

    DEBASM(printf("\t  matching: '%c' '%c' of '%s' '%s' STK=%d\n", b, c, bc, r, stk));
    if (c=='Z') { if (b) break; } // match \0
    else if (c=='%') {
      if (nc=='d') {
        // TODO: actually, do we care if it's number? Hmmm... (, case)
        if (b==',') { ww= *(L*)(bc+1); whi= ww>>8; charmatch+= 2; }
        else if (isdigit(b) && b<='8') { ww= b-'0'; whi= 0; }
        else return 0;
      } else if (islower(nc)) { // TODO:
        // TODO: if request ax?
        char lastvar= 'a'; // TODO: fix, lol
        if (!islower(b)) return 0;
        assert(b==lastvar); // TODO: fix, lol
        ww= 2*(lastvar-b+stk)+1;
      } else if (isdigit(nc)) {
        // stack depth match
        // TODO: this is manipulated during matching, lol so all wrong!
        if (stk!=nc-'0') return 0;
        --charmatch;
      } else if (nc=='^') {
        printf("HERE %^ stk=%d\n", stk);
        if (stk<60) return 0;
        --charmatch;
      }
      ++r;
    } else if (b != c) return 0; // simple char exact match
    ++charmatch;
    ++bc;
    c= *++r;
  }
  // got to end of rule == match!
  return !c;
}
#endif // MATCHER

unsigned char changesAX(char* rule) {
  // TODO: get first char?
  if (0==strcmp(rule, "[%d<") || 0==strcmp(rule, "[%d=") || 0==strcmp(rule, "[%d>")) return 0;
  if (strchr("I]{}^", *rule)) return 0;
  // all other ops changes AX
  return 1;
}

//void compile(register char* bc) {
void compile(char* bc) {
  int bytes= 0;

  // register: (/ 1137712 766349.0) 49% slower without register
  // (however, no function below here can use it, as it'll trash/copy too much!)

  register char **p, *r;

  // TODO: ax and saved and lastvar tracking... [-delay
  // TODO: can't this be done before here, in byte code gen?

  char i, *pc, c, nc, z;

  ax= 'a';

  // process byte code
  while(*bc) {
    APRINT("\n\n- %-30s\tSTK=%d AX=%c bytes=%d\n", bc, stk, ax, bytes);

    // Search all rules for first match
    // TODO: move out

    // for each rule
    p= rules;
    while(*p) {
      r= *p; ++p;

      // get action/asm of rule, and length in bytes
      pc= *p; z= (uint)*++p; ++p;

      // find matching prefix ("peep-hole code-gen/optimizer")
      if (matching(bc, r)) {
        //APRINT("---MATCH: '%s'\ton '%s'\n", *p, bc);
        APRINT("  %s\t", r);

        // if variable and ax alread contains, done!
        if (islower(*bc) && *bc==ax) {
          APRINT("  parameter requested is already in AX!\n");
          break;
        }

        APRINT(" [%d] ", z);

        if (*r=='I') *--patch= stk;
        if (*r=='{' && stk>60) stk= patch[1]; // TODO: who pops it?

        // LOL, need to find next matching rule to decide if pushax! GRRRRR

        // Parse ASM and ACTION of single rule
        // (also consumes parameters from p)
        // (we need z as \0 might occur inside string!)
        while(z) {
          //APRINT(" --%d--", z);
          gen[bytes]= c= *pc; ++pc;
          nc= *pc;

          // LOL, wtf, turning into a mini disasm... lol
          if (c==0x20) { APRINT(" JSR "); }
          else if (c==0x4c) { APRINT(" JMP "); }
          else if (c==0x6c) { APRINT(" JPI "); }
          else if (c==0x60) { APRINT(" RTS "); }
          else if (c==0xa9 || c==0xad) { APRINT(" LDA "); }
          else if (c==0xa2 || c==0xae) { APRINT(" LDX "); }
          else if (c==0xa0 || c==0xac) { APRINT(" LDY "); }
          else if (c==0xa8) { APRINT(" TAY "); }
          else if (c==0x98) { APRINT(" TYA "); }
          else if (c==0x8a) { APRINT(" TXA "); }
          else if (c==0xaa) { APRINT(" TAX "); }
          // TODO: These are "arguments", the have no matching OP-codes, BUTT
          //       they aren't safe substitutions... lol, "WORKS FOR NOW".
          // WARNING: may give totally random bugs, depending on memory locs of data!
          // -- use last %d matched valuie
          // (take low/high)
          else if (c=='#') { APRINT("#$%02x ", ww & 0xff); gen[bytes]= ww & 0xff; }
          else if (c=='"') { APRINT("#$%02x ", ww>>8); gen[bytes]= ww>8; }
          // (take word)
          // TODO: is *(uint)gen+bytes better than *(uint)&gen[bytes]?
          else if (c=='w') {
            uint* pi= (uint*)(gen+bytes);
            if (nc=='w')      { APRINT("$%04X ", ww);   *pi= ww;   }
            else if (nc=='+') { APRINT("$%04X ", ww+1); *pi= ww+1; }
            // take extra word parameter from rules
            else if (nc=='?') { APRINT("$%04X ", *p);   *pi= (uint)*p; ++p; }
            //else assert(!"BAD nc!");
            --z;++pc;
            ++bytes;
          }
          // -- actions to track stack changes
          else if (c=='s') {
            if      (nc=='+') ++stk;
            else if (nc=='-') --stk;
            else if (nc=='^') stk=64;
            --z;++pc;
          }
          // -- actions for IF
          //else if (c=='\'') lastbyte ^= 0x80; // TODO: when gen to buffer...

          else if (c==':') { *--patch= bytes; }                          // label=push
          else if (c==';') { gen[bytes]= *patch; ++patch; }              // patch=pop
          else if (c=='/') { c= *patch; *patch= patch[1]; patch[1]= c; } // swap
          else { APRINT(" %02x ", c); } // we don't know, for now

          // TODO: more efficient?
          if (c!='s' && c!=':' && c!=';' && c!='/') ++bytes;
          --z;
        } // end while action/asm

        break;
      } // if match

      // skip remaining parameters (assuming none zero)
      while(*p) { DEBASM(printf("\n\t: CONSUME PARAM %04x", *p)); ++p; }
      DEBASM(printf("\n\n"));

      // go to next rule
      ++p;
    } // while do next rule

    if (!*r) { // no more rules
      printf("%% NO MATCH! Can't compile: bc='%s'\n", bc);
      exit(3);
    }

    // restore stk to THEN.stk after ELSE if ELSE returned...
    // TODO:
    //if (*r=='}' && stk>60) assert(!"TODO: THEN.stk");

    // -- update ax
    if (islower(*bc)) ax= *bc;
    else if (changesAX(r)) ax= '?';
    // TODO: pushax?

    bc+= charmatch;
  }

  printf("\n\nASM...bytes: %d\n", bytes);
}


int main(void) {

#ifdef MATCHER
  char* bc= "[3[3+"; // works
  //bc= "a[0=I]^0{][a[1=I]^0{][a[1-R[a[2-R+^1}}"; // from memory

  // ./65vm -v -e "(if (< a 2) a (+ (recurse (- a 1)) (recurse (- a 2))))"
  bc= "[a[2<I][a{][a[1-R[a[2-R+}";

  // ./65vm -v -e "(if (< a 2) (return a) (return (+ (recurse (- a 1)) (recurse (- a 2)))))"
  bc= "[a[2<I][a^{][a[1-R[a[2-R+^}"; // 59 bytes

  //bc= "b";

  compile(bc);

#endif // MATCHER

  PROGSIZE;
  return 0;
}
