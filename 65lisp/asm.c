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


// lisp.c:    19394 bytes
// lisp-vmal: 25535 bytes => (- 25535 19394)            = +6141 bytes
// lisp-asm:  33254 bytes
//            30407 bytes, no DASM
//            29036 bytes, no DISASM => (- 29036 25535) = +3501 bytes

// 9789 bytes w all: DISASM,APRINT,MATCHER,RULES
// 9192 bytes w/o DISASM
// 8468 OPT
// 7892 NO OPT  OPT= (- 8468 7892)        =  576 bytes OPT
// 8437 bytes w/o APRINT  (- 8437 4712)   = 3725 bytes MATCHER = code-gen+OPT
// 4712 bytes w/o MATCHER (- 4712 3654)   = 1058 bytes RULES
// 3654 bytes w/o RULES                   == empty program


// 6808 bytes... (no DEBASM no APRINT)
// (- 6803 3578) == 3225 BYTES optimizer code!!! (incl rules)
// (- 4499 3578) === 921 bytes, 70ish rules! (-100B REND) (/ 921 70.0) = 13.16B/R
//
// nothing: 3578, rules NO-OPT: 4002 bytes, OPT: 4499 bytes (rule no-opt: +424, opt: + 497)
// NO-OPT fac => 87 bytes, OPT: 45 bytes, with delay-pushax it would be 40 bytes...

// "EMTPY PROGRAM       //  3677 bytes  ... with nothing 3677 bytes
#define RULES         //  1070 bytes  .... wihout rules 9140 bytes
#define MATCHER       //  5463 bytes  ...  with all 10210 bytes


// uncomment to get DISASM
#define DISASM

#ifdef DISASM
  #undef DISASM
  #include "disasm.c"
#else
  #undef DISASM
  #define DISASM(a,b,i)
#endif // DISASM

// very high details of try matching each rule
#define DEBASM(a)
//#define DEBASM(a) do { a; } while (0)

// into about the matched rule and code-gen
#define APRINT(...) do { if (verbose) printf(__VA_ARGS__); } while(0)
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

#ifdef TEST
  #define PROGSIZE
  #include "progsize.c"
#endif

#include <stdint.h>



#ifdef TEST
  typedef int (*F1)(int);
  typedef int (*F0)();
  typedef void (*F)();

  typedef int16_t L;
  typedef uint16_t uint;
  typedef unsigned uchar;

  static unsigned int bench= 50000L;

  #include "extern-vm.c"

  // These needs to be constants during AMS code-gen
  extern unsigned int T=42; // TODO: constant

  // this isn't recognized if used in another constant by cc65
  //extern const unsigned int nil=1; 
 // TODO: if this is ever changed, need to change codegen "[9=I" and "UI"
 const unsigned int nil=1;


 // dummys
 #define verbose 0


 #define NIL (1)
 #define NUM(a) ((a)>>1)

 L cons(L a, L d) { return NIL; }

 // patchup
#ifdef MATCHER
 void machinecompile(char* la);
 L genrun();

 L al(char* bc) {
   machinecompile(bc);
   return genrun();
 }
#endif

#endif


// Poor Mans Assembler
// 
// Generates strings from MNOMICS and arguments,
// see how it's used. Inline constants need to be
// proper C strings. Like "\041" (== "A", lol)
//
// We use this for runtime codegen, so cannot use the
// built-in cc65 asm.
//
// Since these are expanded next to each other they form
// a single string. Parameters are passed either as:
// - "\xbe\xef" - inline string constant, 1 bytes, or 2 bytes
//
// (the following is somewhat ambigious! TODO:detect/warn)
//
// - "#"  - take low  byte from last matching "%d" in rule
// - "\"" - take high byte from last matching "%d" in rule
//
// - "w?" - take argument from after rule length in array
// - "ww" - take word argument     from last %d match
// - "w+" -      word argument + 1 from last %d match
//
//
// The string generated may contain 0:oes, thus, after
// the string comes a length word.
//
// The string contains a mix of assembly 6502 macro instructions
// for codegen and tracking of side-effects, such as:
// - ":" ";" "/"  - labeling IF-THEN-ELSE and patching
// - "w?" "ww"... - picking parameters from constants (typically for JSR), or bytecode
// - "s-" "s+"    - stack depths changes (data stack)
// - "<"          -move stack instructions. TODO: "s<" ?
//
// See below for details

#define  O(op)    op
#define O2(op, b) op b
#define O3(op, w) op w


#define NOP()    O("\xEA")

#define LDAn(n) O2("\xA9",n)
#define LDXn(n) O2("\xA2",n)
#define LDYn(n) O2("\xA0",n)


#define LDA(w)  O3("\xAD",w)
#define LDX(w)  O3("\xAE",w)
#define LDY(w)  O3("\xAC",w)
                             //    m mm
#define STA(w)  O3("\x8D",w) // 1000 1101
#define STX(w)  O3("\x8E",w) // 1000 1110
#define STY(w)  O3("\x8C",w) // 1000 1100
                             // ccc    ii
#define ANDn(b) O2("\x29",b)
#define ORAn(b) O2("\x09",b)
#define EORn(b) O2("\x49",b)

#define ASL()   O("\x0A")
#define ROL()   O("\x2A")

#define LSR()   O("\x4A")
#define ROR()   O("\x6A")

#define CMPn(b) O2("\xC9",b)
#define CPXn(b) O2("\xE0",b)
#define CPYn(b) O2("\xC0",b)

#define ADCn(b) O2("\x69", b)
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

#define CLD()   O("\xD8")
#define SED()   O("\xF8")

#define INY()   O("\xC8")
#define INX()   O("\xE8")

#define DEY()   O("\x88")
#define DEX()   O("\xCA")

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

// TODO: not used
//#define ASM(x,...) (x),U (sizeof(x)-1),__VA_ARGS__,REND

// Typecast constants to this
#define U (void*)

// TODO: instead of 2 bytes here, could have length inside hibyte of Z, but difficult to get right?
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

#ifdef TEST
  int print(int a) {
    printf("\n%d ", a/2);
    return a;
  }

  int princ(int a) {
    printf("%d ", a/2);
    return a;
  }

#endif // TEST



// OPTIMIZATION IDEAS
// ==================

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

// ASCII that isn't 6502 instructions!
// -----------------------------------
//   "  % '()                   >?
//   B EFGH J LMNO Q S  VX    \  _
// `          lmnopqrstuvwxyz    
//
// Used:
//   ww w+ w' w? - from constants (typically global var/ c/asm-function)
//   # " - from byte code


// PAX means AX value is unchanged after the rule!
// PAX = Peace AX if you will :-D
#define PAX 0x0100

char* rules[]= {
//  "&", JSR("w?"), U 3, U tosandax, REND
//  "|", JSR("w?"), U 3, U tosorax, REND
//  "~", JSR("w?"), U 3, U tosnot, REND
//  "%", JSR("w?"), U 3, U tosmodax, REND

  OPT("[0+", "", U(PAX+0), REND)
//  OPT("[1+", CLC() ADCn("\x02") TAY() TXA() ADCn("\0") TAX() TYA(), U 9, REND) // 9 bytes // SLOWER THAN JSR!
//OPT("[1+", CLC() ADCn("\x02") BCC("\x01") INX(), U 6, REND) // 6 bytes // SLIGHLY FASTER than JSR
//OPT("[1+", CLC() ADCn("\x02") BCC("\x01") INX(), U 6, REND)
  OPT("[1+", JSR("w?"), U 3, U incax2, REND)                             // 3 bytes
  OPT("[2+", JSR("w?"), U 3, U incax4, REND)
  OPT("[3+", JSR("w?"), U 3, U incax6, REND)
  OPT("[4+", JSR("w?"), U 3, U incax8, REND)
  //"[%b+", LDYn("#") JSR("w?"), U 5, U incaxy, 0, REND // TODO: add byte
  "+", JSR("w?") "s-", U 5, U tosaddax, REND


  OPT("[0-", "", U(PAX+0), REND)
  OPT("[1-", SEC() SBCn("\x02") BCS("\x01") DEX(), U 6, REND) // 6 bytes // fib 9% faster
//  OPT("[1-", JSR("w?"), U 3, U decax2, REND)
  OPT("[2-", SEC() SBCn("\x04") BCS("\x01") DEX(), U 6, REND) // 6 bytes // fib 9% faster
//  OPT("[2-", JSR("w?"), U 3, U decax4, REND)
  OPT("[3-", JSR("w?"), U 3, U decax6, REND)
  OPT("[4-", JSR("w?"), U 3, U decax8, REND)
  // OPT("[%b-", LDYn("#") JSR("w?"), U 5, U decaxy, REND) // TODO: subtract byte
  "-", JSR("w?") "s-", U 5, U tossubax, REND

  // ][ conflicts with this, hmmmm, TODO: check IF

  // TODO: make safe value?
  OPT("[0*", LDAn("\0") TAX(), U 3, REND)
  OPT("[1*", "", U(PAX+0), 0,)
//OPT("[2*", ASL() TAY() TXA() ROL() TAX() TYA(), U 6, REND) // slower than JSR?
//OPT("[2*", STXz("\x00") ASL() ROLz("\x00") LDXz("\x00"), U 7, REND) // inline aslax1/shlax1
  OPT("[2*", JSR("w?"), U 3, U aslax1, REND) // 18B
  OPT("[3*", JSR("w?"), U 3, U mulax3, REND)
  OPT("[4*", JSR("w?"), U 3, U aslax2, REND)
  OPT("[5*", JSR("w?"), U 3, U mulax5, REND)
  OPT("[6*", JSR("w?"), U 3, U mulax6, REND)
  OPT("[7*", JSR("w?"), U 3, U mulax7, REND)
  OPT("[8*", JSR("w?"), U 3, U aslax3, REND)
  OPT("[,Z\x09*", JSR("w?"), U 3, U mulax9, REND)
  OPT("[,Z\x0a*", JSR("w?"), U 3, U mulax10, REND)
  //"[%b*", LDA("#") JSR("w?"), U 5, U tosmula0, REND // TODO: multiply by byte
  "*", JSR("w?") "s-", U 5, U ffmul, REND // 3 bytes, TODO: too unsafe?
//  "*", TAY() TXA() LSR() TAX() TYA() ROR() JSR("w?") "s-", U 11, U tosmulax, REND // 9 bytes, TODO: too unsafe?
//  "*", JSR("w?") JSR("w?") ANDn("\xfe") "s-", U 10, U asrax1, U tosmulax, REND    // 6 bytes slow

  // TODO: make safe value?
  //OPT("[2/", TAY() TXA() LSR() TAX() TYA() ROR() ANDn("\xfe"), U 8, REND) // 8 bytes
//  OPT("[1/", "", U(PAX+0), REND)
  OPT("[2/", JSR("w?") ANDn("\xfe"), U 5, U asrax1, REND) // 5 bytes // TODO: make safe ANDn("\xfe")
  OPT("[4/", JSR("w?") ANDn("\xfe"), U 5, U asrax2, REND)
  OPT("[8/", JSR("w?") ANDn("\xfe"), U 5, U asrax3, REND)
  OPT("[,Z\x10/", JSR("w?") ANDn("\xfe"), U 5, U asrax4, REND)
  // OPT(",Z\x80/", JSR("w?"), U 3, U asrax7, REND)  // doesn't exist?
  // OPT("%b/", LDAn("#") JSR("w?"), U 5, U pushax, U tosdiva0, REND) // TODO: load byte
//  "/", JSR("w?") JSR("w?") ANDn("\xfe") "s-", U 10, U tosdivax, U aslax1, REND

  "#I", TAY() LSR() TYA() BCS("\x00") ":", U(PAX+6), REND // Number?
  "KI", TAY() LSR() BCC("\x01") LSR() TYA() BCC("\x00") ":", U(PAX+9), REND // Kons?
  "KI", TAY() LSR() ANDn("\x01") ADCn("\xfe") TYA() BCC("\x00") ":", U(PAX+10), REND // ok alt?
  "$I", TAY() LSR() ANDn("\x01") SBCn("\x00") TYA() BCC("\x00") ":", U(PAX+10), REND // ?? ok alt????
//  "$I", TAY() LSR() BCC("\x03") XORn("\x01") LSR() TYA() BCC("\x00") ":", U(PAX+11), REND // Atom?/String? // TODO: smaller?
//  "$I", TAY() ANDn("\x03") CMPn("\x01") BNE("\x00") ":", U(PAX+8), REND // Atom/String?
  // OPT("%aI", ...                         REND) // TODO: if (boolvar) ...
  // TODO: if minsize: JSR() & BNE => 5 bytes... slow...
  OPT("UI",   CMPn("\x01") BNE("\x02") CPXn("\x00") BNE("\0") ":", U(PAX+9), REND) // NIL nil address inline...
  OPT("[9=I", CMPn("\x01") BNE("\x02") CPXn("\x00") BNE("\0") ":", U(PAX+9), REND) // NIL nil address inline...
  // TODO: "U" generate "bool" -1/0

  OPT("[0=I",  TAY()     BNE("\x02") CPXn("\0") BNE("\0") ":", U(PAX+8), REND) // v==0, less code
  OPT("I",     TAY()     BNE("\x02") CPXn("\0") BEQ("\0") ":", U(PAX+8), REND) // v!=0 kindof... // TODO: should !U?
  OPT("[%d=I", CMPn("#") BNE("\x02") CPXn("\"") BNE("\0") ":", U(PAX+9), REND) // generic == test

  "=", JSR("w?") "s-", U 5, U toseqax, REND // TODO: make it a number? TODO: make my own generic CMP

  // Unsigned Int
  // OPT("[%a<", ... - local
  // OPT("[%g<", ... - global
  OPT("[%d<I", TAY() CMPn("#") TXA() SBCn("\"") TYA() BCS("\x00") ":", U(PAX+10), REND)

  "<", JSR("w?"), U 3, U toseqax, REND
  // TODO: signed int - maybe use "function argument"
  //"%d<", mTAY() mEORn("\x80") mCMPn("#") mTXA() mEORn("\x80") mSBCn("\"") mBCS("\0") mTYA() mBCS("\0"), U 12, REND

//  "A", JSR("w?"), U 3, U ffffcar, REND // 2% FASTER
  // UNSAFE: 2% faster
  //OPT("A", JSR("w?"), U 3, U ldaxi, REND)
  "A", JSR("w?"), U 3, U ffcar, REND
//  "D", JSR("w?"), U 3, U ffffcdr, REND
  // UNSAFE: 3% faster
  //OPT("D", LDYn("\x03") JSR("w?"), U 5, U ldaxidx, REND)
  "D", JSR("w?"), U 3, U ffcdr, REND
  "C", JSR("w?") "s-", U 5, U cons, REND // TODO: make more efficient one?

  "!", JSR("w?") "s-", U(PAX+5), U staxspidx, REND
  "@", JSR("w?"), U 3, U ldaxi, REND
  ".", JSR("w?"), U(PAX+3), U princ, REND
//"W", JSR("w?"), U(PAX+3), U prin1, REND
  "P", JSR("w?"), U(PAX+3), U print, REND
//"T", JSR("w?"), U(PAX+3), U terpri, REND

//"Y", JSR("w?"), U 3, U lread, REND

  ":%d", STA("ww") STX("w+"),  U(PAX+6), REND // store variable at address
  ";%d", LDA("ww") LDX("w+"),  U 6, REND // read variable from address
  "_%d", JSR("ww"),            U 3, REND // call address (eval?)

  // TODO: lastparam
  "[a%0",    "", U 0, REND // TODO: this is not right...

  OPT("][", 0, U(PAX+0), REND) // 3 zeroes! lol
  "]", "s-" JSR("w?"), U 5, U popax,  REND // TODO: useful to actually pop value?
  // TODO: if ax is 0 then dont? (no specific value worth saving, or just prefix with ']'
  "[%d", "s+" JSR("w?") LDAn("#") LDXn("\""), U 9, U pushax, REND
  "[", "s+" JSR("w?"), U(PAX+5), U pushax, REND


//OPT("0^%0", JMP("w?"), U 3, U push0, REND)   // return 0 (if no need clean stack) // 1 byte savings, slower
//OPT("1^%0", JMP("w?"), U 3, U push2, REND)   // return 1 (if no need clean stack) // 2 byte savings
//OPT("2^%0", JMP("w?"), U 3, U push4, REND)   // return 2 (if no need clean stack) // 2 
//OPT("9^%0", JMP("w?"), U 3, U retnil, REND)  // return nil (if no need clean stack) // 
// TODO: optimize return nil? very common...
//"9",        JSR("w?"), U 3, U retnil, REND   // load nil 
  "9",        LDAn("\x01") LDXn("\x00"), U 4, REND // load nil
  OPT("0",    LDAn("\0") TAX(), U 3, REND)     // load 0
  ",%d",      LDAn("#") LDXn("\""), U 4, REND
  "%d",       LDAn("#") LDXn("\""), U 4, REND

  // TODO: %a relateive stack...
  // TODO: keep track of stack! [] enough?
  // TODO: if request ax_
  // TODO: if request => w==1 then JSR(ldax0sp)
  // TODO: use %1357 to indicate depth on stack?
  //"[a", JSR("w?"), U 3, U ldax0sp, REND // TODO: ?? parameters/locals // TODO: how to keep value/name
  //OPT("%a%1", JSR("w?"), U 3, U ldax0sp, REND) // TODO: ?? parameters/locals
  "%a",  LDYn("#") JSR("w?"), U 5, U ldaxysp, REND // TODO: ?? parameters/locals

  // TODO: more than 4 ... LDY ...
  "^%4", "s^" JMP("w?"), U 5, U incsp8, REND
  "^%3", "s^" JMP("w?"), U 5, U incsp6, REND
  "^%2", "s^" JMP("w?"), U 5, U incsp4, REND
  "^%1", "s^" JMP("w?"), U 5, U incsp2, REND
  "^%0", "s^" RTS(),     U 3, REND

  //"X^^",   "<" JMP("ww"),   U 4, REND // ERROR (need popstack first/move)
  OPT("R^", "<" JMP("\0\0") "s^", U 6, REND) // SelfTailRecursion
  "R",      JSR("\0\0"),      U 3, REND // SelfRecursion // TODO: param count/STK?
  "Z",  "<" JMP("\0\0") "s^", U 6, REND // LOOP/SelfTailRecursion/loop/Z

  // CALL = "Xcode" - would prefer other prefix?
  //"X^^",    "<" JMP("ww"),     U 4, REND // ERROR (need popstack first/move)
  // TODO: rename "<" to "s<" ???
  OPT("%dX^", "<" JMP("ww") "s^",  U 6, REND) // TailCall other function
  OPT("%dX",  "<" JSR("ww"),       U 4, REND) // Call other function // TODO: param/STK?
  OPT("X^",   "<" JMP("ww") "s^",  U 6, REND) // TailCall other function
  // TODO: this is to call lisp/VM/or we don't know!
  "X",            JSR("w?"),       U 3, U callax, REND // Call using atom name? maybe collapse with _
  
  // TODO: not complete yet
  //   patching ops=="immediate": :=save ;=patch /=swap
  // TODO: how aobut balancing stack, recurse on compiler?
  //   pop to same level?
  //   if return stack ... 64 lol
  // TODO: this is solved outside?
  //OPT("I", ":", ?U(PAX+1), REND)
  //"I", BCS("\0") ":", U(PAX+1), REND // TODO: not correct, what does the generic <, or = do?

  OPT("{}", ";", U(PAX+1), REND) // gen by (AND ...) or (if EXP THEN)
  OPT("{%^", "z" "/" ";", U 3, REND) // push z, no need to resolve/patch! after return no need jmp endif!
  "{", SEC() BCS("\0") ":" "/" ";", U 6, REND // TODO: restore IF stk, lol need save TODO: handle long jmp?

  // TODO: if "{%^" before, then no patch!
  "}", ";", U 1, REND

  0};

#else
  #define rules 0
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
unsigned char lastvar= 'a'; // TODO: update to actual last parameter at fundef // TODO: nested fundef?

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
//   Z     == 0 byte match (hmm, clash if used as byte code?) TODO: fix
//   %d    == match ",xxxx" or "3" (digit) sets "ww"
//            used by ww, w+, w? and #, and "
//   %b    == TODO: match "byte value" (< 256)
//   %a    == match 'a'-'z' TODO: store last var if val in AX
//   %0-9  == match only if STK is 0-9
//   %^    == match if STK is 60+ == after RETURN (no gen)
char matching(char* bc, char* r) {
  char c, nc, b, pb= 0;
  charmatch= ww= whi= 0;
  DEBASM(printf("\tRULE: '%s' STK=%d\n", r, stk));
  c= *r;
  while(c) {
    nc= r[1];
    pb= b;
    b= *bc;

    DEBASM(printf("\t  matching: '%c' '%c' of '%s' '%s' STK=%d\n", b, c, bc, r, stk));

    // -- Test matching rules
    if (c=='Z') { if (b) break; } // match \0
    else if (c=='%') {
      if (nc=='d') {
        if (b==',' || pb==';' || pb==':' || pb=='_') { ww= *(L*)(bc+1); whi= ww>>8; charmatch+= 2; }
        //if (b==',') { ww= *(L*)(++bc); whi= ww>>8; charmatch+= 2; }
        //else if (pb==';' || pb==':' || pb=='_') { ww= *(L*)(++bc); whi= ww>>8; charmatch+= 2; }
        else if (isdigit(b) && b<='8') { ww= 2*(b-'0'); whi= 0; }
        else return 0;
      } else if (islower(nc)) { // TODO:
        // TODO: if request ax?
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

    ++charmatch; // initial byte
    ++bc;
    c= *++r;
  }
  // got to end of rule == match!
  return !c;
}

unsigned int bytes= 0; // char would save 50 bytes, but very limited
char* bc, saveax;
char np= 1; // number of parametres to current function being compiled

// Compiles ByteCode to asm in gen[]
//
// Returns bytes (length)

extern int compile() {
  // register: (/ 1137712 766349.0) 49% slower without register
  // (however, no function below here can use it, as it'll trash/copy too much!)

  register char **p, *r;

  // TODO: ax and saved and lastvar tracking... [-delay
  // TODO: can't this be done before here, in byte code gen?

  char *pc, c, nc, z, changeax;

  if (verbose) printf(">>>>>COMPILED called: %s\n", bc);

  // process byte code
  while(*bc) {
    APRINT("\n\n- %-30s[%d]\tSTK=%d AX=%c (saveax=%d) bytes=%d\n", bc, strlen(bc), stk, ax, saveax, bytes);

    // Search all rules for first match
    // TODO: move out

    // for each rule
    p= rules;
    while(*p) {
      r= *p; ++p;

      // get action/asm of rule, and length in bytes
      pc= *p; z= 0x00ff & (uint)*++p; changeax= !(PAX & (uint)*p); ++p;

      // find matching prefix - PEEP-HOLE CODE-GEN/OPT
      if (matching(bc, r)) {
        int start= bytes;

        APRINT("  %s\t", r);

        // if variable and already inAX, done!
        if (islower(*bc) && *bc==ax) {
          APRINT(" parameter requested is already in AX!\n");
          break;
        }

        // -- need to save AX?
        if (saveax) {
          APRINT("saveax?");
          if (changeax) { // YES - it'll be changed
            APRINT(" SAVED AX\n");
            // JSR pushax
            gen[bytes]= 0x20; ++bytes; 
            *(int*)(gen+bytes)= U pushax; bytes+= 2;
            ++stk;
            saveax= 0;
          }
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
          // TODO: switch better?
          if (c=='#')      { APRINT(" # =>$%02x  ", ww & 0xff); gen[bytes]= ww & 0xff; }
          else if (c=='"') { APRINT(" \" =>$%02x  ", ww>>8); gen[bytes]= ww>>8; }
          // -- use a word from matched data/parameters
          // TODO: is *(uint)gen+bytes better than *(uint)&gen[bytes]?
          else if (c=='w') {
            uint* pi= (uint*)(gen+bytes);

            // from last %d matched
            if (nc=='w')      { APRINT("  ww =>$%04X  ", ww);   *pi= ww;  }
            else if (nc=='+') { APRINT("  w+ =>$%04X  ", ww+1); *pi= ww+1; }

            // take extra word parameter from rules
            else if (nc=='?') { APRINT("  w? =>$%04X  ", *p);   *pi= (uint)*p; ++p; }
            //else assert(!"BAD nc!");

            --z;++pc;
            ++bytes;

          } else if (c=='<') {
            void* popper;
            char n= (stk-(1-saveax)-np)*2; // TODO: +- 1?
            // TODO: ? number of arguments of func called?

            assert(!saveax); // TODO: special case, need load ax again?
            assert(n==0); // TODO: code not working yet - make subroutine?
            if (n>0) {
#ifdef SHIFT
              // -- move np elements of the stack down stack-np
              // TODO: make call to shift routine
              LDY #[ n ];
              JSR shift_stack_y;

              // TODO: remove and make shiff_stack_y
              
              // save a copy of sp in tmp1
              LDY sp;
              STY tmp1;
              LDY sp+1;
              STY tmp2;

              // -- JSR shrink stack (update sp)
              // TODO: array less code?
              gen[bytes]= 0x20; ++bytes;
              switch(n) {
              case 0: break;
              case 1: popper= U incsp2; break;
              case 2: popper= U incsp4; break;
              case 3: popper= U incsp6; break;
              case 4: popper= U incsp8; break;
              default: error("Stack too big", MKNUM(stack));
              }
              *(int*)(gen+bytes)= U popper;
              bytes+= 2;

              // save A
              STA tmp3;

              // init loop
              LDY #[ n ];
  loop:
              LDA (sp),Y;
              STA (tmp1),Y;

              DEY;
              BNE loop;

              // restore A
              LDA tmp3;

#endif // SHIFT
              //stk= 0;
            }
            if (!saveax) { // JSR "drop" (a if saved)
              APRINT("(<drop %d NP=%d) ", n, np);
              gen[bytes]= 0x20; ++bytes; 
              *(int*)(gen+bytes)= U incsp2; bytes+=1; // TODO: 1? hmmm
              stk= 0;
            }
//            --z;++pc; // TODO: ????
          }
          // -- actions to track stack changes
          else if (c=='s') {
            if      (nc=='+') { APRINT("(stack+) "); ++stk; }
            else if (nc=='-') { APRINT("(stack-) "); --stk; }
            else if (nc=='^') { APRINT("(stack^) "); stk=64; }

            --z;++pc; // no code gen
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

        if (verbose) DISASM(gen+start, gen+bytes, 9);

        ++p;
        break;
      } // if match

      // skip remaining parameters (assuming none zero)
      while(*p) { DEBASM(printf("\n\t: CONSUME PARAM %04x", *p)); ++p; }
      DEBASM(printf("\n\n"));

      // go to next rule
      ++p;
    } // while do next rule


    // --- AFTER APPLYING RULES

    // TODO: somehow 'C' isn't found if this code is here? hmmmm?
    // TODO: if this code not here, then loop forever if no match... lol
    if (1 && !*p) { // no more rules
      if (stk>=64) {
        printf("SKPPING: bc: %s\n", bc);
        ++bc;
//        if (b==',' || b==':' || b==';' || b=='_') bc+= 2;
//        continue;
      } else {
        printf("%% NO MATCH! Can't compile: bc='%s'\n", bc);
        exit(3);
      }
    }

    // -- update ax
    if (islower(*bc)) ax= *bc; // TODO: not fully correct...
    else if (changeax) ax= '?';
    // TODO: capture value: 0-8, nil, T
    // TODO: capture if hibyte/lobyte 0

    // -- handle IF by recursion
    // TODO: maybe make part of GENRULE?
    // 
    if ('I'==bc[charmatch-1]) { // TODO: hmmm?
      // TODO: if have more, is it better to do struct?
      int i_stk= stk; char i_ax= ax, i_sax= saveax;
      bc+= charmatch;
      printf("\n-------------IF--------------\n");

      // -- THEN
      compile();
      assert(*bc=='{');
      bc+= charmatch;
      //if (bc[1]!='}') {
      {
        int t_stk= stk; char t_ax= ax, t_sax= saveax;
        stk= i_stk; ax= i_ax;

        printf("BC=%s\n", bc);

        // -- ELSE
        compile();
        //assert(*bc=='}');
        // no inc, as '}' wil be eaten later

        // ENDIF: resolve THEN and ELSE branch states
        if (t_ax != ax) ax= '?';

        APRINT("BEFORE %IF i_stk=%d, t_stk=%d, e_stk=%d\n", i_stk, t_stk, stk);
        if (stk>60) stk= t_stk;
        else if (stk<60 && t_stk<60 && stk != t_stk) {
          APRINT("%%IF i_stk=%d, t_stk=%d, e_stk=%d\n", i_stk, t_stk, stk);
          APRINT("%%IF i_sax=%d, t_sax=%d, e_sax=%d\n", i_sax, t_sax, saveax);
          // TODO: inject pushax in THEN or ELSE
          //   OR: make preprocessing to pushax... "]"
          assert(t_sax==saveax);
          assert(t_stk==stk);
        }
      }
    }

    // TODO: worth storing *bc in char var?
    if (!*bc) break; // hmmm... 

    if (*bc=='{' || *bc=='}') break;

    // TODO: seems unsafe? (can match ,XX ;XX ;XX _XX ???)
    if (bc[charmatch-1]=='}' || bc[charmatch-1]=='{') {
      bc+= charmatch;
      break;
    }
    bc+= charmatch;
  }

  if (verbose) printf("\n\nASM...bytes: %d\n", bytes);

  return bytes;
}

void relocate(char* code, int n, char* to) {
  unsigned char i= 0, c;
  ++n;
  while (--n) {
    c= code[i]; ++i;
    if (c==0x20 || c==0x4c || c==0x6c) {
      int* p= (int*)(code+i);
      if (*p==0) *p= (int)to;
      i+= 2;
    }
  }
}

// "I... {... }^"  =>  "I...^{...^} "
#define FIND " }^"
void promoteReturn(char* bc) {
  // TODO: if 0 inside... changechange! 
  // TODO: need len of code...
  char *r= strstr(bc, FIND);
  while(r) {
    char d= 1;
    printf("PR: '%s'\n", bc);
    printf(" R:   '%s'\n", r);
    // ELSE^
    *r= '^';
    // remove ^ at }^
    r[2]= ' ';
    while(d && r>bc) {
      printf("%dR:   '%s'\n", d, r);
      if (*r=='}') ++d;
      if (*r=='{') --d;
      --r;
    }
    if (r!=bc) {
      // THEN^
      //--r;
      *r= '^';
    } else assert(0);
    r= strstr(bc, FIND);
  }
}

#endif // MATCHER


#ifdef MATCHER

// JIT compile and run! Just-In-Time compilation
//
// Takes AL compiled bytecode and compiles to 6502 machine code.
//
// Result: in gen[], end at gen[bytes]

// TODO: take fun descriptor / no args?
void machinecompile(L la) {
  bc= malloc(BINLEN(la));
  memcpy(bc, BINSTR(la), BINLEN(la));
  promoteReturn(bc);

  // generate machine code
  // input : char* bc
  // output: gen[bytes]
  bytes= 0;
  compile();
  
  if (stk<60) {
    // IF doesn't have RETURN in both branches...
    // TODO: this isn't right.... add ^ at end?
    gen[bytes++]= 0x60; // RTS
  }
  if (verbose) DISASM(gen, gen+bytes, 0);

  free(bc); bc= NULL;
}

L machinecompilefunction(L la) {
  char* code; L r;

  np= 1; 
  stk= 0; ax= 'a'; saveax= 1;
  machinecompile(la);

  r= mkcode(gen, bytes);
  // TODO: mkcode should prefix with JMP xxxx == x+5+3 below
  code= r+5; // Atom.code offset? LOL
  relocate(code, bytes, code);
  //relocate(code, bytes, x+3); // TODO: the indirection "JMP code"

  return r;
}

void machinecompilecode(L la) {
  np= 0;
  stk= 0; ax= 0; saveax= 0;
printf("--------HERE WE GO!\n");
  machinecompile(la);

  // "dummy" - this can only be run once in top, never save
  relocate(gen, bytes, gen);
}

// Sum up dummy return values, otherwise an optimizing
// c-compiler might just remove the loop!
long sum= 0;

// Run machine code in gen[] bench times.
//
// Returns: value of last invokation.
//
// Warning: can't be nested
// TODO: remove, so inefficient.... lol 40% more costly than genrun()
L coderun(char* code) {
  int stackcheck= 4711;
  L r= nil;
  static unsigned int n;
  static void* cd= NULL;
  cd= code;

  n= bench+1;

  // Actually call, bench times (n)
  while(--n>0) { // (--n) doesn't work! it jumps out early!
    if (0) { // 50k noopt- 1579794, opt: 5207599
      3;
    } else if (1) { // 25% overhead cmp next...
      // 39.32s
      //r= ((F1)gen)(i); // one argument, one result
      r= ((F0)cd)(); // no argument, one result, hmmmm works?
    } else { // 50k RTS - 2179807 (/ (- 2179807 1579794) 50000.0) = 12 = JSR+RTS!
      // 38.98s instead of 39.32s (/ 39.32 38.98) = 0.88% savings
      __AX__= 8;
      // TODO: this doesn't work?
      assert(!"can't call");
      //asm(" jsr %v", cd);
      r= __AX__;
      
      // TODO: why doesn't it work - loops forever!
      //__AX__= i;
      //((F)gen)();
    }
    
    //printf("one %d => %d %ld \n", n, NUM(r), sum);
    sum+= NUM(r);

    // DEBUG
    if (0 && stackcheck!=4711) {
      // TODO:doesn't work
      //   ERROR: ./65jit -E -v -e "(+ 3 4)" -e "(+ 2 5)"
      //   FINE:  (echo "(+ 3 4)"; echo "(+ 2 5)") | ./65jit -v
      printf("STACK MESSED UP: xx!=4711 x==%d\n", stackcheck);
      exit(1);
    }

  }

  // If not print, maybe didn't happen...
  printf("SUM=%ld\n", sum);

  // TODO: bad hack, lisp.c expects bench to be counted
  bench= 0;

  //print(r);

  return r;
}

L genrun() {
  int stackcheck= 4711;
  L r= nil;
  static unsigned int n;

  n= bench+1;

  // Actually call, bench times (n)
  while(--n>0) { // (--n) doesn't work! it jumps out early!
    if (0) { // 50k noopt- 1579794, opt: 5207599
      3;
    } else if (0) { // 25% overhead cmp next...
      // 39.32s
      r= ((F0)gen)(); // no argument, one result, hmmmm works?
    } else { // 50k RTS - 2179807 (/ (- 2179807 1579794) 50000.0) = 12 = JSR+RTS!
      // 38.98s instead of 39.32s (/ 39.32 38.98) = 0.88% savings
      __AX__= 8;
      asm(" jsr %v", gen);
      r= __AX__;
      
      // TODO: why doesn't it work - loops forever!
      //__AX__= i;
      //((F)gen)();
    }
    
    //printf("one %d => %d %ld \n", n, NUM(r), sum);
    sum+= NUM(r);

    // DEBUG
    if (0 && stackcheck!=4711) {
      // TODO:doesn't work
      //   ERROR: ./65jit -E -v -e "(+ 3 4)" -e "(+ 2 5)"
      //   FINE:  (echo "(+ 3 4)"; echo "(+ 2 5)") | ./65jit -v
      printf("STACK MESSED UP: xx!=4711 x==%d\n", stackcheck);
      exit(1);
    }

  }

  // If not print, maybe didn't happen...
  printf("SUM=%ld\n", sum);

  // TODO: bad hack, lisp.c expects bench to be counted
  bench= 0;

  //print(r);

  return r;
}
#endif // MATCHER

#ifdef TEST

int main(void) {
  static unsigned int n;
//  unsigned int bench= 50000, n;
//  static unsigned long bench= 50000, n; // 11 130 491 counting RTS using long    11 630 463 static!
//    static unsigned int bench= 50000, n;  //  7 629 927 counting RTS using int        387 260 static!
//  unsigned int bench= 3000, n= bench+1;
//  unsigned int bench= 3000, n= bench+1;
//  unsigned int bench= 100, n= bench+1; // for fib21
//  unsigned int bench= 1, n= bench+1;
//  unsigned int bench= 100, n= bench+1;
  int r, i;

  n= bench+1;

#ifdef MATCHER
  bc= "[3[3+"; // works
  //bc= "a[0=I]^0{][a[1=I]^0{][a[1-R[a[2-R+^1}}"; // from memory

  // ./65vm -v -e "(if (< a 2) a (+ (recurse (- a 1)) (recurse (- a 2))))"
  //bc= "[a[2<I][a{][a[1-R[a[2-R+}";

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

  // fib - crash?
  bc= "[a[2<I][a^{][a[1-R[a[2-R+^}"; // 41 bytes - 0k 44 now
  bc= "a[2<I][a^{][a[1-R[a[2-R+^}"; // 41 bytes - 0k 39 now

  bc= "a[2<I][a{][a[1-R[a[2-R+}^"; // 41 bytes - 0k 39 now - FAIL, THEN/ELSE different stack...

  bc= "a[2<I][a {][a[1-R[a[2-R+ }^"; // 39 - promoteReturn avoids unbalanced THEN/ELSE!

  // For simulating function call with 1 parameter
  saveax= 1; // TODO: now assume compile: fun(a), generlize to lastvar

//  bc= "][1[2+[1[1[1+[1++[2**^"; saveax= 0; ax= '?'; // oh, default is foldr  - 47.6s

  // * -> 31s ... 4 035 340  using static int counter! INLINE MAX 2 620 576
  //bc= "][2[1+[1[1+[1+[1+*[2*^"; saveax= 0; ax= '?'; // if it was foldl...    - 42.7s (and (* (+ 2 1) ...
  // (/ (- 21600535 1539248) 50000.0) = 401c without overhead (no print, 0.3s compile
  // (/ (* 14 50000) 21.600535) 32Kops/s (w overhaad)
  // (* 14 (/ 1000000 401.0)) = 34.912Kops/s

  // (/ (- 18617878 1567789) 50000.0) = 341c
  // (* 14 (/ 1000000 341.0)) = 41.055Kops/s

  // 50k inline    - (/ (- 22202029 5207599) 50000.0) = 339c only (/ 445 339.0) 31% overhead of JSR?
  // 50k jsrjsrjsr - (/ (- 23832181 1579794) 50000.0) = 445c

  // (/ (- 26291286 1641196) 50000.0) = 493c non-ops no overhead mult
  // (* 14 (/ 1000000 493.0)) = 28.397 kops
  // (/ (- 12638985 1538897) 50000.0) = 222c non-ops no overhead plus
  // (* 14 (/ 1000000 222.0)) = 63.063 kops


  // === plus instead...
  // (/ (- 9655717 1555627) 50000.0) = 162c
  // (* 14 (/ 1000000 162.0)) = 86.419 kops

  //bc= "][2[1+[1[1+[1+[1++[2*^"; saveax= 0; ax= '?'; // if it was foldl...    - 42.7s (and (+ (+ 2 1) ...
  // got rid of multiplication, still 1 push and 1 add jsr
  // (/ (- 13241255 5210158) 50000.0) = 160c (45B) (/ (- 160 (* 2 12)) 29) = 4c/B (29i)
  // (/ (- 15259565 7230009) 50000.0) = 160c but NON-STATIC ovhread 2s! (/ 7230009 5210158.0) 39% overhead
  // (/ (- 7230009 5210158) 50000.0) = 40c overhead of local var! (12c call, +indirect)
  // DEUBUG INFO OFF: (/ (- 9606087 1555944) 50000.0) = 161c
  // (/ (- 12639388 1539248) 50000.0) = 222c (+ 161 (* 5 12)) = 221c !!!
  // compiling cost: (- 1539248 1263750) = 275 498us, 0.3s
  // (/ 1263750 50000.0) 25c loop overhead

  // + -> 22s ... 4 010 564 -> 4s using static int counter!
  //  bc= "][2[1+[1[1+[1+[1++[2*^"; saveax= 0; ax= '?'; // if it was foldl...    - 42.7s (and (* (+ 2 1) ...

  // 50k X => 11 130 491  using long
  //bc= "[2*[2*^"; // 11 cycles extra? lol
  //bc= "[2*^"; // 11 cycles extra? lol
  //bc= "^";

  //bc= "[a[2<I][a[3<I][5 {][6 } {][4 }^"; // just test of promoteReturn two levels
  // copy because we modify! (if not copy strstr finds matches after change!)

  // TODO: just call al for all during test...

  r= al(bc);

  printf("bench: %u times - FIB(%d)=%d (%04X)\n", bench, i/2, r/2, r);

#endif // MATCHER

  PROGSIZE;
  return 0;
}

#endif
