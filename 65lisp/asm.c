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


// OPT
// TODO: compare to vbcc - https://forums.nesdev.org/viewtopic.php?t=20226&p=251509
//   (their example is a byte sized memcopy that takes 3 parameters in "registers" (zp)


// 6808 bytes... (no DEBASM no APRINT)
// (- 6803 3578) == 3225 BYTES optimizer code!!! (incl rules)
// (- 4499 3578) === 921 bytes, 70ish rules! (-100B REND) (/ 921 70.0) = 13.16B/R
//
// nothing: 3578, rules NO-OPT: 4002 bytes, OPT: 4499 bytes (rule no-opt: +424, opt: + 497)
// NO-OPT fac => 87 bytes, OPT: 45 bytes, with delay-pushax it would be 40 bytes...

#define RULES
#define MATCHER


// uncomment to get DISASM
#define DISASM

#ifdef DISASM
  #undef DISASM
  #include "disasm.c"
#else
  #undef DISASM
  #define DISASM(a,b) 
#endif // DISASM

#include "disasm.c"


#define DEBASM(a)
//#define DEBASM(a) do { a; } while (0)

#define APRINT(...) printf(__VA_ARGS__)
//#define APRINT(...) 


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

// These needs to be constants during AMS code-gen
extern unsigned int T=42; // TODO: constant

// this isn't recognized if used in another constant by cc65
//extern const unsigned int nil=1; 
// TODO: if this is ever changed, need to change codegen "[9=I" and "UI"
const unsigned int nil=1;

#define NIL (1)


// Poor Mans Assembler
// 
// Generates strings from MNOMICS and arguments,
// see how it's used. Inline constants need to be
// proper C strings. Like "\041" (== "A", lol)
//
// Since these are expanded next to eachaother they form
// a single string. Parameters are passed either as:
// - "\xbe\xef" - inline string constant, 1 bytes, or 2 bytes
// - "#" - take low byte from last matching "%d" in rule
// - "\"" - take high byte from last matching "%d" in rule
// - "w?" - take argument from after rule length in array
// - "ww" - take word argument from last %d match
// - "w+" - word argument + 1 from last %d match
//
//
// The string may contain 0:oes, thus, after the string comes a length word.
//
// The string contains a mix of instructions for codegen and tracking of
// side-effects, such as:
// - "s-" "s+" stack depths changes (data stack)
// - instructions for labelleing in IF-THEN-ELSE and patching
// - and a "<" move stack instructions.


#define  O(op)    op
#define O2(op, b) op b
#define O3(op, w) op w

#define LDAn(n) O2("\xA9",n)
#define LDXn(n) O2("\xA2",n)
#define LDYn(n) O2("\xA0",n)


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

#define CMPn(b) O2("\xC9",b)
#define CPXn(b) O2("\xE0",b)
#define CPYn(b) O2("\xC0",b)

#define SBCn(b) O2("\xE9", b)

#define CMP(w)  O3("\xCD", w)
#define CPX(w)  O3("\xEC", w)
#define CPY(w)  O3("\xCC", w)


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


#define JSR(a)  O3("\x20",a)
#define RTS(a)  O("\x60")

#define JMP(a)  O3("\x4c",a)
#define JMPi(a) O3("\x6c",a)

#define BRK(a)  O("\0")

// END ASSEMBLY DEF

#define ASM(x,...) (x),U (sizeof(x)-1),__VA_ARGS__,REND

#define U (void*)

// TODO: instead of 2 bytes here, could have length inside hibyte of Z, but difficult to get right?
//        macro?
#define REND 0, // cost 70rules x 2 bytes= 140 bytes, needed unless have count inside bytelen...

#ifdef RULES

// Rules
//
// Format:
//   
//    MATCH, ASM...ASM, U byteasm, REND
//
// There are about 70 rules, these takes maybe (* 70 20)

// TODO: how to make different rules char, integer, byte, word?
//   -- simplify
//   -- how to indicate a varaible's type?
//
// (+ a:B

// One letter atom names, bytes
// (* (* 26 2) (+ 11)) = 572 bytes (only few will use JSR stuff)

//IDEA:
//  - ATOM: (val, ptr)
//  -   ptr = 0x00?? => one letter inline, or offset into array
//        avg names 5 chars? (/ 256 5) = 51 names...

// Maybe: 
// - (de foo - normal lisp function (lambda)...
// - (df foo - nlambda...
// - (db foo - byte code compiled...
// - (dc foo - code compiled to asm...

#define OPT

#ifdef OPT 
  #undef OPT
  #define OPT(...) __VA_ARGS__
#else
  #undef OPT
  #define OPT(...)
#endif

int print(int a) {
  printf("\n%d ", a/2);
  return a;
}

int princ(int a) {
  printf("%d ", a/2);
  return a;
}

// Consider only positive integers, anything else is boxed!
// (gives 0--32767, almost good, now only - 16383)

// General rule (for LISP), try to make most operators (< = prinX pushax ...)
// work on value in AX and "another value", while retaining the value in AX.
//
// Example:
//   Typical pattern (if (eq a 3) a) ... (if (< a 3) (return a) ...)

// TODO: add rewrites of AL, use negative length? (not U 3, lol)

// "{(.*)}^" (or zero) => "^{\1^}" this solves the implicit PROGN issue!
// "^^*" -> "^" or just ignore anything after "^" till "{"...
// DELAY-pushax A: "[...I...{...}" if no return inside if, stk may be unbalanced:
// - previous fix, insert pushax just before '{', or '}'...
// - too late to resolve at ENDIF ... as ';' as patch action already been performed, needs to be done before rule actions... (but doesn't it have access to value? no... DAMN...

// TODO: how to integrate BigNum without, or keep as separate type and ops?
//       + - * / needs efficient tests, without overhead
//       "[1+" = ... BMI overflow 
//       "[1-" = ... BMI means underflow!
//       "[,xx+/-" = same, if %I otherwise already go generic routine
//       + * / = go generic routine? can waste tests before...

// TODO: have generic filter/reduce operator, can be specialized on operator +=sum, *=prod can upgrade ->long->BigNum !

// TODO: track constant types? and also value in "ax" from constants?
// TODO: track variable AX types, can do after Kons,nUll,etc.
//       generate specific code without type checks, especially after/inside IFs!
//       match ax: %I=inlinenum %N=number %D=digit %U=nil %A=atom %K=Kons good for car/cdr opt

// TOOD: track constant value of Y, cc65 is good at reusing it (iny/dey)

// TODO: for func >1 params, NOT calling other UDF just primitives, meaning it's a bottom function,
//       it could compile using "registers", slightly more efficient as no pushax before call
//       also, no cleanup at exit, 
//
//       - also see - https://www.cc65.org/doc/cc65-8.html (probably can't use them, as need saving)

char* rules[]= {
  OPT("[0+", "", 0, 0,)
  OPT("[1+", JSR("w?"), U 3, U incax2, REND)
  OPT("[2+", JSR("w?"), U 3, U incax4, REND)
  OPT("[3+", JSR("w?"), U 3, U incax6, REND)
  OPT("[4+", JSR("w?"), U 3, U incax8, REND)
  // TODO: only <255
  //"[%b+", LDYn("#") JSR("w?"), U 5, U incaxy, 0,

  "+", JSR("w?") "s-", U 5, U tosaddax, REND


  OPT("[0-", "", 0, REND)
  OPT("[1-", JSR("w?"), U 3, U decax2, REND)
  OPT("[2-", JSR("w?"), U 3, U decax4, REND)
  OPT("[3-", JSR("w?"), U 3, U decax6, REND)
  OPT("[4-", JSR("w?"), U 3, U decax8, REND)
  // TODO: only <255
  // OPT("[%b-", LDYn("#") JSR("w?"), U 5, U decaxy, REND)

  "-", JSR("w?") "s-", U 5, U tossubax, REND

  // ][ conflicts with this, hmmmm, TODO: check IF

  // TODO: make safe value?
  OPT("[0*", LDAn("\0") TAX(), U 3, REND)
  OPT("[1*", "", 0, 0,)
  OPT("[2*", JSR("w?"), U 3, U aslax1, REND) // 18B
  OPT("[3*", JSR("w?"), U 3, U mulax3, REND)
  OPT("[4*", JSR("w?"), U 3, U aslax2, REND)
  OPT("[5*", JSR("w?"), U 3, U mulax5, REND)
  OPT("[6*", JSR("w?"), U 3, U mulax6, REND)
  OPT("[7*", JSR("w?"), U 3, U mulax7, REND)
  OPT("[8*", JSR("w?"), U 3, U aslax3, REND)
  // TODO: how to match? \0 lol Z match \0?
  OPT("[,Z\x09*", JSR("w?"), U 3, U mulax9, REND)
  // TODO: how to match?
  OPT("[,Z\x0a*", JSR("w?"), U 3, U mulax10, REND)
  // TODO: only <255
  //"[%b*", LDA("#") JSR("w?"), U 5, U tosmula0, REND

  "*", JSR("w?") JSR("w?") ANDn("\xfe") "s-", U 10, U asrax1, U tosmulax, REND

  // TODO: make safe value?
  OPT("[2/", JSR("w?"), U 3, U asrax1, REND)
  OPT("[4/", JSR("w?"), U 3, U asrax2, REND)
  OPT("[8/", JSR("w?"), U 3, U asrax3, REND)

  OPT("[,Z\x10/", JSR("w?"), U 3, U asrax4, REND)
  // OPT(",Z\x80/", JSR("w?"), U 3, U asrax7, REND)  // doesn't exist?
  // TODO: only <255
  // OPT("%b/", LDAn("#") JSR("w?"), U 5, U pushax, U tosdiva0, REND)

  "/", JSR("w?") JSR("w?") ANDn("\xfe") "s-", U 10, U tosdivax, U aslax1, REND

  // OPT("[0=", STXzp(tmp1) ORAzp(tmp1) BNE("\0"), U 6, REND) // TODO: destructive...
  // often followed by TAX then JSR incspN to RETURN 0, but if not destructive, then SAME bytes!
  //  TODO: rewrite "[9=I" => "UI" ???
  // TODO: 8 instructions is a lot because AX?
  // TODO: how about from var? (but don't we typically return exactly same value?)
  // TODO: JSR() & BNE => 5 bytes... slow...
  OPT("UI",   CMPn("\x01") BNE("\x02") CPXn("\x00") BNE("\0") ":", U 9, REND) // NIL nil address inline...
  OPT("[9=I", CMPn("\x01") BNE("\x02") CPXn("\x00") BNE("\0") ":", U 9, REND) // NIL nil address inline...

  OPT("[0=I", TAY() BNE("\x02") CPXn("\0") BNE("\0") ":", U 8, REND) // save once instruction using TAY
  OPT("[%d=I", CMPn("#") BNE("\x02") CPXn("\"") BNE("\0") ":", U 9, REND)

  "=", JSR("w?") "s-", U 5, U toseqax, REND // TODO: make it a number? TODO: make my own generic CMP

  // Unsigned Int
  // OPT("[%a<", ... - local
  // OPT("[%g<", ... - global
  OPT("[%d<I", TAY() CMPn("#") TXA() SBCn("\"") TYA() BCS("\x00") ":", U 10, REND)

  "<", JSR("w?"), U 3, U toseqax, REND
  // TODO: signed int - maybe use "function argument"
  //"%d<", mTAY() mEORn("\x80") mCMPn("#") mTXA() mEORn("\x80") mSBCn("\"") mBCS("\0") mTYA() mBCS("\0"), U 12, REND

  "A", JSR("w?"), U 3, U ffcar, REND
  "D", JSR("w?"), U 3, U ffcdr, REND
//"C", JSR("w?") "s-", U 5, U cons, REND

  "!", JSR("w?") "s-", U 5, U staxspidx, REND
  "@", JSR("w?"), U 3, U ldaxi, REND
  ".", JSR("w?"), U 3, U princ, REND
//  "W", JSR("w?"), U 3, U prin1, REND
  "P", JSR("w?"), U 3, U print, REND

  ",", LDAn("#") LDXn("\""), U 4, REND
  ":", STA("ww") STX("w+"), U 6, REND
  ";", LDA("ww") LDX("w+"), U 6, REND

  OPT("][", 0, U 0, REND) // 3 zeroes! lol
  "]", "s-" JSR("w?"), U 5, U popax, REND // TODO: useful?

  "[", "s+" JSR("w?"), U 5, U pushax, REND

  //"0[", JSR("w?"), U3, U pushzero, REND // TODO: need for local var? keep ax?
  //"9[", JSR("w?"), U3, U pushnil, REND // TODO: need for local var? keep ax?
  OPT("0", LDAn("\0") TAY(), U 3, REND)
  OPT("9^%0", JMP("w?"), U 3, U retnil, REND) // redundant? auto opt...
  "9",  JSR("w?"), U 3, U retnil, REND

  "%d", LDAn("#") LDXn("\""), U 4, REND

  // TODO: %a relateive stack...
  // TODO: keep track of stack! [] enough?
  // TODO: if request ax?
  // TODO: if request => w==1 then JSR(ldax0sp)
  // TODO: use %1357 to indicate depth on stack?
  //"[a", JSR("w?"), U 3, U ldax0sp, REND // TODO: ?? parameters/locals
  //OPT("%a%1", JSR("w?"), U 3, U ldax0sp, REND) // TODO: ?? parameters/locals
  "%a",  LDYn("#") JSR("w?"), U 5, U ldaxysp, REND // TODO: ?? parameters/locals

  // TODO: more than 4 ...
  "^%4", "s^" JMP("w?"), U 5, U incsp8, REND
  "^%3", "s^" JMP("w?"), U 5, U incsp6, REND
  "^%2", "s^" JMP("w?"), U 5, U incsp4, REND
  "^%1", "s^" JMP("w?"), U 5, U incsp2, REND
  "^%0", "s^" RTS(),     U 3, REND

  //"X^^",   "<" JMP("ww"),   U 4, REND // ERROR (need popstack first/move)
  OPT("R^", "<" JMP("\0\0") "s^", U 6, REND) // SelfTailRecursion
  "R",      JSR("\0\0"),      U 3, REND // SelfRecursion // TODO: param count/STK?
  "Z",  "<" JMP("\0\0") "s^", U 6, REND // SelfTailRecursion/loop/Z

  // CALL = "Xcode" - would prefer other prefix?
  //"X^^",    "<" JMP("ww"),     U 4, REND // ERROR (need popstack first/move)
  OPT("%dX^", "<" JMP("ww") "s^",  U 6, REND) // TailCall other function
  OPT("%dX",  "<" JSR("ww"),       U 4, REND) // Call other function // TODO: param/STK?
  OPT("X^",   "<" JMP("ww") "s^",  U 6, REND) // TailCall other function
  "X",            JSR("w?"),       U 3, U callax, REND // Call other function // TODO: param/STK?
  
  // TODO: not complete yet
  //   patching ops=="immediate": :=save ;=patch /=swap
  // TODO: how aobut balancing stack, recurse on compiler?
  //   pop to same level?
  //   if return stack ... 64 lol
  //OPT("I", ":", U 1, REND)
  //"I", BCS("\0") ":", U 1, REND // TODO: not correct, what does the generic <, or = do?

  OPT("{}", ";", U 1, REND) // Typically output by (and ...) or (if EXP THEN)
  OPT("{%^", "z" "/" ";", U 3, REND) // push z, no need to resolve/patch! after return no need jmp endif!
  "{", SEC() BCS("\0") ":" "/" ";", U 6, REND // TODO: restore IF stk, lol need save

  // TODO: if "{%^" before, then no patch!
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
// z   = IF push 0 (no need to patch)
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
        else if (isdigit(b) && b<='8') { ww= 2*(b-'0'); whi= 0; }
        else return 0;
      } else if (islower(nc)) { // TODO:
        // TODO: if request ax?
        char lastvar= 'a'; // TODO: fix, lol
        if (!islower(b)) return 0;
        assert(b==lastvar); // TODO: fix, lol
        ww= 2*(lastvar-b+stk)-1;
      } else if (isdigit(nc)) {
        // stack depth match
        // TODO: this is manipulated during matching, lol so all wrong!
        if (stk!=nc-'0') return 0;
        --charmatch;
      } else if (nc=='^') {
        printf("HERE %^ stk=%d\n", stk);
        if (stk<60) return 0;
        printf("--HERE passed\n");
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

unsigned char changesAX(char* rule) {
  // TODO: get first char?
  if (0==strcmp(rule, "[%d<") || 0==strcmp(rule, "[%d=") || 0==strcmp(rule, "[%d>") || 0==strcmp(rule, "][")) return 0;
  if (strchr("I[{}^", *rule)) return 0;
  // all other ops changes AX
  return 1;
}

// Compiles ByteCode to asm in gen[]
//
// Returns bytes (length)

unsigned int bytes= 0; // char would save 50 bytes, but very limited
char* bc;

int compile() {
  // register: (/ 1137712 766349.0) 49% slower without register
  // (however, no function below here can use it, as it'll trash/copy too much!)

  register char **p, *r;

  // TODO: ax and saved and lastvar tracking... [-delay
  // TODO: can't this be done before here, in byte code gen?

  char *pc, c, nc, z;

  // print ax arg first thing
  //gen[bytes++]= 0x20;
  //gen[bytes++]= ((int)print) & 0xff;
  //gen[bytes++]= ((int)print) >> 8;

  ax= 'a';

  printf(">>>>>COMPILED called: %s\n", bc);

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
        int start= bytes;

        //APRINT("---MATCH: '%s'\ton '%s'\n", *p, bc);
        APRINT("  %s\t", r);

        // if variable and ax alread contains, done!
        if (islower(*bc) && *bc==ax) {
          APRINT(" parameter requested is already in AX!\n");
          break;
        }

        APRINT(" [%d] -- ", z);

        // TODO: keep or remove?
//    if (*r=='I') *--patch= stk;
//    if (*r=='{' && stk>60) stk= patch[1]; // TODO: who pops it?

        // LOL, need to find next matching rule to decide if pushax! GRRRRR

        // Parse ASM and ACTION of single rule
        // (also consumes parameters from p)
        // (we need z as \0 might occur inside string!)
        while(z) {
          //APRINT(" --%d--", z);
          gen[bytes]= c= *pc; ++pc;
          nc= *pc;

          // TODO: These are "arguments", the have no matching OP-codes, BUTT
          //       they aren't safe substitutions(?)... lol, "WORKS FOR NOW".
          // WARNING: may give totally random bugs, depending on memory locs of data!

          // -- use a byte from last %d matched valuie (low/high)
               if (c=='#') { APRINT(" # => $%02x  ", ww & 0xff); gen[bytes]= ww & 0xff; }
          else if (c=='"') { APRINT(" \" => $%02x  ", ww>>8); gen[bytes]= ww>>8; }
          // -- use a word from matched data/parameters
          // TODO: is *(uint)gen+bytes better than *(uint)&gen[bytes]?
          else if (c=='w') {
            uint* pi= (uint*)(gen+bytes);

            // from last %d matched
            if (nc=='w')      { APRINT("  ww => $%04X  ", ww);   *pi= ww;  }
            else if (nc=='+') { APRINT("  w+ => $%04X  ", ww+1); *pi= ww+1; }

            // take extra word parameter from rules
            else if (nc=='?') { APRINT("  w? => $%04X  ", *p);   *pi= (uint)*p; ++p; }
            //else assert(!"BAD nc!");

            --z;++pc;
            ++bytes;
          }
          // -- actions to track stack changes
          else if (c=='s') {
            if      (nc=='+') { APRINT("(stack+) "); ++stk; }
            else if (nc=='-') { APRINT("(stack-) "); --stk; }
            else if (nc=='^') { APRINT("(stack^) "); stk=64; }

            --z;++pc;
          }
          // TODO: unsigned...
          //else if (c=='\'') lastbyte ^= 0x80; // TODO: when gen to buffer...

          // -- actions for IF : = push label, z = push 0=notpatch, ; = patch (if !0), / = swap
          else if (c=='z') { APRINT("(push:zero) "); *--patch= 0; }
          else if (c==':') { APRINT("(push:label) "); *--patch= bytes-1; }
          else if (c==';') {
            if (*patch) {
              int rel= bytes-*patch-1;
              APRINT("(patch[%d]=%+d) ", *patch, rel);
              if (rel < -126 || rel > 127) {
                printf("%%Compile: relative jump too far! %d\n", rel);
              }
              gen[*patch]= rel;
            } else APRINT("(patch:zero) ");

            // TODO: look back, see if have Bxx *patch-1, if so, patch it to same, if same Bxx?
            // (hmmm rather complicated, maybe easier to forward patch?)
            ++patch;
          } else if (c=='/') { char t= *patch; APRINT("(swap labels) "); *patch= patch[1]; patch[1]= t; }
          else APRINT("$%02x ", c); // we don't know, for now

          // TODO: more efficient?
          if (c!='s' && c!=':' && c!=';' && c!='/' && c!='z') ++bytes;
          --z;
        } // end while action/asm

        disasm_indent= 9; DISASM(gen+start, gen+bytes); disasm_indent= 0;

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

    // -- update ax
    if (islower(*bc)) ax= *bc;
    else if (changesAX(r)) ax= '?';  
    // TODO: pushax?


    // handle IF by recursion
    if ('I'==bc[charmatch-1]) { // TODO: hmmm?
      // TODO: if have more, is it better to do struct?
      int i_stk= stk; char i_ax= ax;
      bc+= charmatch;
      printf("\n-------------IF--------------\n");

      // THEN
      compile();
      assert(*bc=='{');
      bc+= charmatch;
      //if (bc[1]!='}') {
      {
        int t_stk= stk; char t_ax= ax;
        stk= i_stk; ax= i_ax;

        printf("BC=%s\n", bc);

        // ELSE
        compile();
        //assert(*bc=='}');
        // no inc, as '}' wil be eaten later

        // ENDIF: resolve THEN and ELSE branch states
        if (t_ax != ax) ax= '?';

        printf("BEFORE %IF i_stk=%d, t_stk=%d, e_stk=%d\n", i_stk, t_stk, stk);
        if (stk>60) stk= t_stk;
        else if (stk<60 && t_stk<60 && stk != t_stk) {
          printf("%%IF i_stk=%d, t_stk=%d, e_stk=%d\n", i_stk, t_stk, stk);
          assert(0);
        }
      }
    }

    // TODO: worth storing *bc in char var?
    if (!*bc) break; // hmmm... 

    if (*bc=='{' || *bc=='}') break;
    if (bc[charmatch-1]=='}' || bc[charmatch-1]=='{') {
      bc+= charmatch;
      break;
    }
    bc+= charmatch;
  }

  printf("\n\nASM...bytes: %d\n", bytes);

  return bytes;
}
#endif // MATCHER

void relocate(int n, char* to) {
  unsigned char i= 0, c;
  ++n;
  while (--n) {
    c= gen[i]; ++i;
    if (c==0x20 || c==0x4c || c==0x6c) {
      int* p= (int*)(gen+i);
      if (*p==0) *p= (int)to;
      i+= 2;
    }
  }
}

typedef int (*F1)(int);
typedef void (*F)();

int main(void) {
//  unsigned int bench= 3000, n= bench+1;
//  unsigned int bench= 3000, n= bench+1;
//  unsigned int bench= 100, n= bench+1; // for fib21
  unsigned int bench= 1, n= bench+1;
  int r, i;

#ifdef MATCHER
  bc= "[3[3+"; // works
  //bc= "a[0=I]^0{][a[1=I]^0{][a[1-R[a[2-R+^1}}"; // from memory

  // ./65vm -v -e "(if (< a 2) a (+ (recurse (- a 1)) (recurse (- a 2))))"
  bc= "[a[2<I][a{][a[1-R[a[2-R+}";

  // ./65vm -v -e "(if (< a 2) (return a) (return (+ (recurse (- a 1)) (recurse (- a 2)))))"
  bc= "[a[2<I][a^{][a[1-R[a[2-R+^}"; // 59 bytes

  //bc= "b";

  // debug
  //bc= "[a[a+[a+^";
  //bc= "[a[a+[a+^";
  //bc= "[a[a+[a+[a+^";

  //nil= 1; // address 1 (0-5 used for "SPECIAL: NIL") car(nil)=nil, cdr(nil)=nil
  bc= "[9P";
  bc= "[8[9=P"; // works! -1, lol should crash?
  bc= "[8[9=P";

  bc= "[a[2<I][a^{][a[1-R[a[2-R+^}"; // 59 bytes

  // OR - works!
  //  //doesn't resolve all OR! {}{}{}...
  bc= "[9UI][9UI][3UI{}{}{}^";

  // AND - works!
  bc= "][1UI{][9UI{][3UI{}}}^";

  //bc= "[9^";

  bytes= 0;
  // implicit return, only takes one expression
  // TODO: PROGN... (how about lambda)
  compile(); // etc bc... lol

  // need add the implicit return?
  if (stk<60) {
    // IF doesn't have RETURN in both branches...
    // TODO: this isn't right.... add ^ at end?
    gen[bytes++]= 0x60; // RTS
  }

  DISASM(gen, gen+bytes);

  relocate(n, gen);
  relocate(n, (char*)0xABBA); // testing, lol
  printf("GEN= %04X\n", gen);
  DISASM(gen, gen+bytes);

  printf("incsp8= %04x\n", incsp8);
  printf("incsp6= %04x\n", incsp6);
  printf("incsp4= %04x\n", incsp4);
  printf("incsp2= %04x\n", incsp2);
  printf("\nprint= %04x\n\n", print);
  i= 0; // ok
  i= 1; // ok
  i= 2; // recurse already - ok
  i= 21; // largest we can do, lol
  i= 8; // ok

  // 3000x fib8 ... 38.5s - (- 39.3 3.9) 35.4s RUNNING (not incl compile, and printing overhead)
  // 3000x emtpy loop overhead: with print and compile overhead 3.9s! (removed gen() call...
  // 100x  fib21 ... 617s

  i*= 2; // TODO: this generates code knowing what i is!!! (so if small may do INX!!!!?)

while(--n) {
  if (1) {
    // 39.32s
    r= ((F1)gen)(i);
  } else {
    // 38.98s instead of 39.32s (/ 39.32 38.98) = 0.88% savings
    __AX__= i;
    asm(" jsr %v", gen);
    r= __AX__;

    // TODO: why doesn't it work - loops forever!
    //__AX__= i;
    //((F)gen)();
    //r= __AX__;
  }
}

printf("bench: %d times - FIB(%d)=%d (%04X)\n", bench, i/2, r/2, r);

    // TODO: allocate, copy ...


#endif // MATCHER

  PROGSIZE;
  return 0;
}
