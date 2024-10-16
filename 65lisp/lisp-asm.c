// Define DASM on compilation to DebugASM !!!!
#ifdef DASM
  #undef DASM
  #define DASM(a) do { a; } while(0)
#else
  #undef DASM
  #define DASM(a)
#endif

char mc[120]= {0};
char* mcp= mc;
 
// compile AL bytecode to simple JSR/asm

/* Byte codes that are compiled

   ' ' \t \r \n - skip
   !    - store (val, addr) => val
   "	
// #    - (isnum)    = LOL cc65 preprocessor runs inside comments?
   $	- (isstr)
   %    - (mod)
   &    - (bit-and)
   '    
   ()
   *    - mul
   +    - add
   ,    - literal word
   -    - (sub)
   .    - princ
   /    - (div)
   012345678 - literal single digit number
   9    - nil
   :    - setq
   ;    - ;BEEF read value at BEEF
   <    - (lt)
   =    - (eq)
   >    - (gt)
   ?    - (cmp)
   @    - read value at addr from stack (use for array)
   A    - cAr
   B    - (memBer)
   C    - Cons
   D    - cDr
   E    - (Eval)
   F    - (Filter?)
   G    - (Gassoc)
   H    - (evalappend?) ???
   I    - If
   J    - (Japply)
   K    - (Kons)
   L    - (evallist?)
   M    - (Map)
   NO   - (Nth)
   P    - Print
   Q
   R    - Recurse
   S    - (Setq local/closure var)
   T    - Terpri (newline)
   U    - (null)
   V
   W    - princ
   X    - prin1
   Y    - read
   Z    - loop/tail-recurse
   [    - pushax, as new value comes
   \    - (lambda?)
   ]    - popax? ( "][" will do nothing! )
   ^    - return
   _
   `    - (backquote construct)
   abcdefgh - (local stack variables)
   ijklmnop - (local/closure frame variables)
   qrstuvw
   x    - AX lol
   yz
   {    - forth ELSE (starts THEN part, lol)
   |    - (bit-or)
   }    - forth THEN (ends if-else-then)
   ~    - (bit-not)
      - ermh?

*/

// PROGSIZE: 31358 bytes ... => 27552 bytes no macros 
//    19102 bytes for EVAL !!!!! HMMMM
//    25401 bytes for VM
//    27969 bytes for ASM
//    29611 bytes for OPT MATH
//    30154 bytes for OPT emitEQ, return, ax tracking jmp endif
//    31945 bytes for OPT DELAY-AX TODO: reduce inline...
//   
// byte code compiler... + byte interpreter = 6299
//                             asm-compiler = 2152 bytes


void B(char b)  { DASM(printf("%02x ", b)); *mcp++= (b)&0xff; }
void O(char op) { DASM(printf("\n\t")); B(op); }
void W(void* w) { *((L*)mcp)++= (L)(w); DASM(printf("%04x", w)); }

#define O2(op, b) do { O(op);B(b); } while(0)
#define O3(op, w) do { O(op);W(w); } while(0)
#define N3(opn, op, w) do { O(op);W(w); DASM(printf("\t\t%-4s %s", opn, #w)); } while(0) 
#define N2(opn, op, b) do { O(op);B(b); DASM(printf("\t\t%-4s %02x", opn, b)); } while(0) 

  #define LDAn(n) N2("LDAn",0xA9,n)
  #define LDXn(n) N2("LDXn",0xA2,n)
  #define LDYn(n) N2("LDYn",0xA0,n)


  #define LDA(w)  O3(0xAD,w)
  #define LDX(w)  O3(0xAE,w)
  #define LDY(w)  O3(0xAC,w)

  #define STA(w)  O3(0x8D,w)
  #define STX(w)  O3(0x8E,w)
  #define STY(w)  O3(0x8C,w)


  #define ANDn(b) O2(0x29,b)
  #define ORAn(b) O2(0x09,b)
  #define EORn(b) O2(0x49,b)

  #define ASL()   O(0x0A)
  #define CMPn(b) N2("CMPn",0xC9,b)
  #define CPXn(b) N2("CPXn",0xE0,b)
  #define CPYn(b) N2("CPYn",0xC0,b)

  #define SBCn(b) N2("SBC",0xE9, b)

  #define PHP()   O(0x08)
  #define CLC()   O(0x18)
  #define PLP()   O(0x28)
  #define SEC()   O(0x38)

  #define PHA()   O(0x48)
  #define CLI()   O(0x58)
  #define PLA()   O(0x68)
  #define SEI()   O(0x78)

  #define DEY()   O(0x88)
  #define TYA()   O(0x98)
  #define TAY()   O(0xA8)
  #define CLV()   O(0xB8)

  #define INY()   O(0xC8)
  #define CLD()   O(0xD8)
  #define INX()   O(0xE8)
  #define SED()   O(0xF8)

  #define TXA()   O(0x8A)
  #define TAX()   O(0xAA)

  #define BMI(b)  O2(0x30, b)
  #define BPL(b)  O2(0x10, b)

  #define BNE(b)  O2(0xD0,b)
  #define BEQ(b)  O2(0xF0,b)

  #define BCC(b)  O2(0x90,b)
  #define BCS(b)  O2(0xB0,b)

  #define BVC(b)  O2(0x50,b)
  #define BVS(b)  O2(0x70,b)


  #define JSR(a)  N3("JSR",0x20,a)
  #define RTS(a)  O(0x60)

  #define JMP(a)  N3("JMP", 0x4c,a)
  #define JMPi(a) N3("JPI", 0x6c,a)

  #define BRK(a)  O(0x00)

// Codegen generates "inline cc65 bytecode".
//
// In principle the generated code will be almost as fast as cc65's
// C-code! cc65 isn't a byte-code interpreter, but the code generated
// is heavily depending on an asm sub-routine library that is JSR:ed
// into for almost all operations. This saves code, compared to inlining
// all. For more compact representation, it could have used byte-code.
//
// But a byte-code interpreter is about 15x slower!
//
// So, for lisp, we choose to have:
// - EVAL : a simple, but generic, EVAL/APPLY
// - AL   : Alphabetical Lisp byte-code interpreter. 2x-3x faster
// - ASM  : simplistic inline asm using JSR for most primitives
//
// Challanges:
// - (Real) Closures in compiled code, need copy vars, hmmm, grrr, maybe not?
// - generic Tail-recursion optimization (can be done) (move vars, adjust stack, jmp)
//   (both cases, need count args)

// =================================================
// O P T I M I Z A T I O N S   I M P L E M E N T E D
//
// - tail-call JSR+RTS => JMP
// - using RTS/JMP insp2/4/6/8
//
// - getting last variable of parameters if not down
//
// - use that AX is preserved by many ops in cc65 runtime
//   - DELAY-pushAX
//   - (return EXP) - much more efficient
//   - (IF ... (return THE) (return ELSE)) - no JMP ENDIF!
//
// - AX  + -  CONST 2,4,6,8
// - AX  + -  0
// - AX  + -  y
// - AX  * /  1,2,3,4,5,6,7,8,9,10
// - AX  * /  0
// - AX  * /  -1
// - AX  * /  2,4,8,16,32,64,128,256,512,1K,2K,4K,8K,16K...
//
// - AX == CONST 8 bytes test incl IF cc65: 9 bytes
// - AX <  CONst *unsigned* => 9 bytes incl IF
// - return optimzied: 0, nil, T   also at end \0


// --TODO----TODO----TODO----TODO----TODO----TODO----TODO--
// ------ OPT -------- OPT -------- OPT -------- OPT ------
// TODO: access var0, var1, var2, var3 just do jump!
// TODO: access var0 LAST should popax it? instead of 'a' use 'A'...
//          difficult to generalize, especialy in if branches, return, etc, slices?
// TODO: write an lisp interpreter in lisp and compile it... what size/performance?
// TODO: write this compiler in lisp? lol
// TODO: 38 b0 XX == ELSE 5 cycles, change to JMP 3 cycles!
// TODO: ret2 optimization? retA is implicit JSR+RTS
// TODO: RTS can reuse! remember last, reverse Bxx... save one byte, lol
// TODO: avoid pushax if last use of lastarg and didnt push before!
// TODO: match all end of "THENs{" and insert ^ before { if "}...\0"
//       and if that location is }...} do again... lol
//       i.e. don't require user to insert RETURN!
//
//


// ASM OPTIMIZATION, fib 8 x 3000 (top post!)    ./fib-asm 30
//    ASM      TIME    PROGSIZE  OPT
//     65      45.2s     -               fib.c
// CC  54 B    41.53           ltfib.c (unsigned LT<2 etc)
//                 --- 38% B  42% slower ---
//

//     43 B     31.8    36004 B <2 SIGNED (no cheating)
//                              emitCONST '0' - 3 bytes
//                                if ax already '0'..'8'
//                              emitEQ: 0 -> 7B, 8 other
//
//     39 B     30.95s  35359 B after ret, no gen jmp at end!
//                              to restore A, just TYA no PHP/PLA
//           (/ 39 24.0) asm is 62.5% more bytes than BYTECODE
//           (/ 39.0 50) LISP uses 28% more byte than asm
//
//     41 B     32.33s  35370 B lol... <2 ... return...
//     57 B     39.02s  34034 B incl poor disam
//        maybenot so good? LOL
//        better off using (ret xx) => less code, faster
//
//     51 B                      loop forever... lol something wrong.... 
//            +4 bytes extra for relative jmp, instead of RTS
//     47 B     31.6s   31845 B .TO.. cleanup ... (/ 45.2 31.6) cc65 43% slower! (/ 65 47.0) cc65 38% more code
//                      30589 !!!! BAD.... no inline IAX!
//     51 B     38.1s   30154 B   +       using return and removing jmp to endIF => 21% smaller than fib.c
//     57 B     38.2s   30106?B           using return
//     51 B     38.5s   30161 B  +550 B   emitEQ and "ax tracking"! WTF! I'm better!
//     78 B    101.0s   29611 B   +35 B   ldax0sp for "a" varible
//     88 B    101.1s   29576 B  +607 B   emitMATH (sub)      LOTS OF CODE to OPT 
//    102 B    120.7s   27969 B           emitEXIT
//    105 B    123.1s                     - start -
//
//     30 B      -        --- VM --- effective CODE used to generate ASM!
//     30 B                cleaned [a[0=I  a{  a[1=I  a{  a[1-R[a[2-R+ } } \0 - saved 4x (drop+push ][) 
//     38 B                byte code with push/pop [a[0=I][a{][a[1=I][a{][a[1-R[a[2-R+ } } \0 
//  !  24 B                plain byte code:  a 0=I  a{  a 1=I  a{  a 1-R a 2-R+ } } \0
//
//  !  50 B     25 cells         LISP w RETURN and <2 ...
//  !  62 B     31 cells         LISP w RETURN
//  !  56 B     28 cells         LISP if if..
// drop 0-4 values from stack, JSR=drop, JMP=return
void* incspARR[]= {(void*)0xffff, incsp2, incsp4, incsp6, incsp8};

// TODO: jsr ldax0sp, jsr incsp2 == jmp ldax0sp !

void emitEXIT(signed char stk) {
  if (stk>64) return; // can't get here!
  if (stk==0) RTS();
  else if (stk>4) { LDYn(stk*2); JMP(addysp); }
  else JMP(incspARR[stk]);
}

void emitCONST(L w, char ax) {
  // TODO: track value of ax? axv
  // cc65 as clever and knows all A X Y values!
  // it'll reuse A is 0 and transfer to X, or from Y to A
  // after test it knows axv and if load same can use

  if (ax-'0'==w) return; // 0B !

  if (w==0) { LDAn(0); TAX(); } // 3B
  else { LDAn(w & 0xff); LDXn(((uint)w) >> 8); }
}


void* incARR[]= {(void*)0xffff, incax2, incax4, incax6, incax8};
void* decARR[]= {(void*)0xffff, decax2, decax4, decax6, decax8};

uchar emitADD(L w) {
  if (w==0) return 1;
  if (w>0 && w<=MKNUM(4)) JSR(incARR[NUM(w)]); // just *deref and add? lol
  else if (w & 0xff00) return 0;
  else { LDYn((char)w); JSR(incaxy); }  // 0--255
  return 1;
}

uchar emitSUB(L w) {
  if (w==0) return 1;
  if (w>0 && w<=MKNUM(4)) JSR(decARR[NUM(w)]);
  else if (w & 0xff00) return 0;
  else { LDYn((char)w); JSR(decaxy); }
  return 1;
}

void* mulARR[]= {(void*)0xffff, (void*)0xffff, aslax1, mulax3, aslax2, mulax5, mulax6, mulax7, aslax3, mulax9, mulax10};

// TODO: code or array?
//void* aslARR[]= {(void*)0xffff, aslax1, aslax2, aslax3, aslax4, 0, 0, aslax7};
//void* asrARR[]= {(void*)0xffff, asrax1, asrax2, asrax3, asrax4, 0, 0, asrax7};

// TODO: how many bytes? It's quite a lot of code - is it worth it?
uchar emitMUL(L w, uchar shifts) {
  w= NUM(w);

  if (w>1 && w<=10) JSR(mulARR[w]);
  //  else if (shifts==4) JSR(aslax4); // 1111: 28765 bytes, remove 1111: 28586 == (- 28765 28586) == 179B!
  //else if (shifts==7) JSR(aslax7); // doesn't exist?
  else if (shifts>0) { LDYn(shifts); JSR(aslaxy); }
  //  else if (w==1) ; // nothing! // 1111
  // else if (w==0) { LDAn(0); LDXn(0); } // TODO: replace prev ',' or digit... // 1111
  // else if (w==-1) JSR(negax); // 1111
  // TODO: stk cannot be accessed
  //else if (!(w >> 8)) { JSR(pushax); ++stk; LDAn((char)w); JSR(tosmula0); }
  else return 0; // failed: use the generic

  return 1;
}

// TODO: how many bytes? It's quite a lot of code - is it worth it?
uchar emitDIV(L w, uchar shifts) {
  w= NUM(w);
  // if (shifts==4) JSR(asrax4); // 1111
  //else if (shifts==7) JSR(asrax7); // doesn't exist?
  //else
  if (shifts>0) { LDYn(shifts); JSR(asraxy); }
  // else if (w==1) ; // nothing! // 1111
  else if (w==0) { LDAn(0xff); LDXn(0x7f); } // TODO: overflow... // TODO: replace prev ',' or digit...
  // else if (w==-1) JSR(negax); // 1111
  //else if (!(w >> 8)) { JSR(pushax); ++stk; LDAn((char)w); JSR(tosdiva0); }
  else return 0;
  // TODO: make it return to compile "normal"
  //else JSR(tosdivax); // TODO: need push value
  return 1;
}

// ==0 -> 7B, otherwise 8B
// cc65: ==0 -> 9B  ==1 -> 11B
uchar emitEQ(L w) {
  if(w) CMPn(w&0xff); else TAY();   BNE(+2);
        CPXn(((uint)w) >> 8);       BNE(0);
  return 1;
}

// 9B 13c cc65: 15 B !!!
uchar emitULT(L w) {
  TAY(); CMPn(w & 0xff);
  TXA(); SBCn(((uint)w) >> 8);
  TYA(); BCS(0); // restore A
  return 1;
}

// 13B 17c
// signed => unsigned by add $80 !
uchar emitSLT(L w) {
  // TODO: can we do better for 0 <= w <= 255 => 10B
    
  TAY(); EORn(0x80); CMPn((w & 0xff)^0x80);
  TXA(); EORn(0x80); SBCn((((uint)w) >> 8)^0x80);
  TYA(); BCS(0); // restore A
  return 1;
}

// 14B 20c 
// TODO: merge w ULT? use if...
uchar emitXLT(L w) {
  TAY();   CMPn(w & 0xff);
  TXA();   SBCn(((uint)w) >> 8);
  BVS(+2); EORn(0x80); ASL(); // unsigned fix...
  TYA();   BCS(0); // restore A
  return 1;
}

char* la= 0;

// TODO: (between a XX XX)
// - https://www.nesdev.org/wiki/Synthetic_instructions
//
// Test whether A is in range [min, max]
// Test whether A (unsigned), A is destroyed.[4]

// Set carry flag if A is in range, otherwise clear carry:
//
// clc
// adc #$ff-max
// adc #max-min+1

// Clear carry flag if A is in range, otherwise set carry:
//
// sec
// sbc #min
// sbc #max-min+1

typedef struct AsmState {
  signed char stk;
  char ax;
  char savelast;
  char *fix;
} AsmState;

// These ops don't change AX
uchar axsameop(char c) { return c==0 || strchr("<=>~^", c); }

// optimize pattern: CONST OP
uchar emitMATH(L w, uchar d, AsmState *s) {
  L x= w;
  uchar shifts= 0;
  uchar r= 0;

  // * / use shift if only one bit set
  // TODO: optimize % mod
  if ((la[d]=='*' || la[d]=='/') && !(x & (x-1))) while(x>=4) { x>>= 1; ++shifts; }

  switch(la[d]) {
  case '+': r= emitADD(w); break;
  case '-': r= emitSUB(w); break;
  case '*': r= emitMUL(w, shifts); break;
  case '/': r= emitDIV(w, shifts); break;

  case '=': r= emitEQ(w); break;
  // 10B slow/generic: JSR pushax, LDA+LDX, JSR icmp
//  case '<': r= emitULT(w); break; //  9B C N unsigned
  case '<': r= emitSLT(w); break; // 13B C N (I think)
//case '<': r= emitXLT(w); break; // 14B C N
    // TODO:   ax >! w     ax <= w    ===    ax < w+1
    // TODO:   ax <! w     ax >= w    ===    ax > w-1

  case '^': case 0: x= 1;
    DASM(printf("\n----emitRETURN: "); prin1(w); NL);
    if (s->stk==0) {
      if      (w==0)   JMP(return0);
      else if (w==nil) JMP(retnil);
      else if (w==T)   JMP(rettrue);
      else x= 0;
    } else x= 0;
    if (!x) { emitCONST(w, s->ax); emitEXIT(s->stk); }

    s->stk= 100; s->ax= '?';
    r= 1; break;
  }
  DASM(printf("\n\t--emitMATH(%d, %d) '%c' shifts=%d ===> %d '%s'", NUM(w), d, la[d], shifts, r, la));

  // -- sorry, no match
  if (!r) return 0;

  // -- ok, we did it!

  // Make "boolean" (<=>! code gen is optimized for IF !)
  if (strchr("<=>~", la[d]) && la[d+1]!='I') {
    // convert to T/NIL
    mcp-= 2; // remove test
    switch (la[d]) {
    case '=': JSR(istrue); break;
    case '<': JSR(iscarry); break;
    }
    // TODO: much more, and ! inv...
  }

  la+= d; return 1;
}

// Closure is dynamically generated code with data storage
//
//                                        init: JSR enterclosure   ;; 53c
// CLOSURE/ARRAY:                               <on stack point to CLOSURE-1!>
//   	nparams	0x20	CLOS1                   JMP init
//   	nslots	0 1 2 3 4 5 ... nslots-1	nslots	0 1 2 3 4 5 ... nslots-1
//
//    CLOS1:
//      ;; enter closure - 14B                enterclosure:        ;; 48c
//      TAY				        TAY   STX tmp1   TSX
//      LDA self	PHA		        LDA 102,X   STA self+1
//      LDA self+1      PHA                     LDA 101,X   STA self
//      LDA #<CLOSURE  	STA frame		LDA 104,X   STA 102,X
//      LDA #>CLOSURE   STA frame+1	        LDA 103,X   STA 101,X
//      TYA				        LDX tmp1    TYA
//      ;;				        RTS ; return to caller of init!
//      JSR machinecode				(remain on stack is reinit itself)
//      ;; exit closure - 9B			
//      TAY                                   exitclosure:         ;; 39c
//      PLA	STA frame+1                     TAY   STX tmp1   TSX
//      PLA	STA frame                       LDA 102,X   STA 104,X
//      TYA                                     LDA 101,X   STA 103,X
//      RTS                                     DEX DEX          TXS
//                                              TYA   LDX tmp1 
//                                              RTS ; prev closure reinstall!
//
// The second solution has the frame re-install itself by

L makeClosure(char* code, char* clos) {
  return code || clos ? ERROR : ERROR;
}

void emitMakeClosure() {
}

// TODO: asmpile fix these...
// TODO: take arglist...
char lastvar, lastarg, lastop;


// Operator stackeffect:
// +1  [ 
// -1  ] =< C +-*/% !
// N   ^RZ

// - These use one vale and give one back (only AX)
// 0   @AD.WPx : I {}

// - These sets AX overwriting previous, thus are prefixed w [
//   This allows a preceeding ] to null out [!
// 0   AD.WPx , 012345678 9 ;

// 93.24s ./run | 6.69 "c3a4d,"  (/ 98.24 6.69) = 14.7x 

void iax(AsmState *s, char a) {
  if (s->savelast && (a)!=lastarg) {
    //assert(s->ax==lastarg);
    JSR(pushax); ++(s->stk);
    s->savelast= 0;
    DASM(printf("\n\t----- PUSHED initial AX to %c------\n", lastarg));
  }
  s->ax= a;
}

#define IAX iax(s, '?')
#define AX(a) iax(s, a)

  // invalidate AX
  // TODO: don't inline... and can we test/do this not at ever CASE but instead at one place?

extern char* genasm(AsmState *s) {
  // TODO:
  //   (+ (if (...) a 7) a) who saves ax?

 next:
  lastop= *la;

  // TailCall? JSR xxxx RTS  -> JMP xxxx
  if (mcp>mc+3 && *(mcp-1)==0x60 && *(mcp-4)==0x20) {
    *(mcp-4)= 0x4c; *--mcp= 0;
    DASM(printf("\n\n====== TAIL CALL %04X", mcp));
  }
  // TODO: jsr ldax0sp, jsr incsp2 == jmp ldax0sp !

  // TODO: skip gen?
  if (s->stk>64) DASM(printf("\n===== NO CODE GENERATE (after return)\n"));

  DASM(printf("\n\nGENASM: '%c' (%d %02x) %04X stk=%d ax='%c' val=", la[1], la[1], la[1], *(L*)(la+2), s->stk, s->ax));
  if (strchr(",:;X", la[1])) prin1(*(L*)(la+2));

  switch(*++la) {

  // return may be followed by 0 which is return...  ^}\0
  case '^': case 0: emitEXIT(s->stk); s->stk=100;s->ax='?'; if (!*la) return mcp; else goto next;

  case ' ': case '\t': case '\n': case '\r': goto next;

  // -- These are safe functions with no stack effect
  case '@': IAX; JSR(ldaxi); goto next; // read var at addr/global var 3+4+3 = push,lda+ldx,ldaxi = 13 bytes!
  case 'A': IAX; JSR(ffcar); goto next;
  case 'D': IAX; JSR(ffcdr); goto next;

  case '.': JSR(princ); goto next;
  case 'W': JSR(prin1); goto next;
  case 'P': JSR(print); goto next;

    // ./65vm-asm -e "(recurse (print (+ x 1)))" -- LOL!
  case 'R': IAX; JSR(mc); goto next; // Recurse - TODO: 0x0000 and patch later!

  // Tail-recurse: move up lastarg-'a' parameters, JMP beginning
  // TODO: move N parameters! now only works for one/AX !
  case 'Z': if (s->stk<64) { LDYn((s->stk-(lastarg-'a'))*2); JSR(addysp); }  s->stk=100;s->ax='?'; JMP(mc); goto next;
  case 'x': goto next; // LOL, it's just AX! // TODO: hmmmm, ax verify?

  // SETQ: ax=val ':' addr => ax still val
  case ':': ++la; STA((void*)(*(L*)la)); STX((void*)(1+*(L*)la)); ++la; goto next; // 6 bytes = write val at addr/var

  // TODO: JSR(pushax); probably not neede, should be it's own token and generated, we might have a drop before!
  // that'd cancel out having to push..., most likely from prev statement discard result! (in tos/AX)

  // TODO: handle [1- !!!!
    // hmmmmm, if ax[] ?
  case ']': if (la[1]=='[') ++la; else { IAX; JSR(popax); --(s->stk); }  goto next; // ][ drop-push cancels!

  // TODO: un-duplicate with +-*/ ...
  case '[':
    // make this mean save any value/register as it's a cache! some would write it back
    if (s->savelast) {
      if ( (la[1]==',' && axsameop(la[4])) ) DASM(printf("\n-------11111: \"%s\"\n", la));
      else if ( (isdigit(la[1]) && axsameop(la[2])) ) DASM(printf("\n-------222222\n"));
      else if ( (la[1]==lastarg && lastarg==s->ax && la[2]=='[' && isdigit(la[3]) && axsameop(la[4])) ) DASM(printf("\n-------333 \"%s\"\n", la));
      //else if (la[1]!=s->ax || s->ax!=lastarg) IAX;
      //else AX(la[1]);
      // TODO: this is all wrong with 'b' ???
      else IAX;
    }
    if (la[1]==',' && emitMATH(*(L*)(la+2), 4, s)) goto next;
    // TODO: too much...
    if (isdigit(la[1]) && la[1]!='9' && emitMATH(MKNUM(la[1]-'0'), 2, s)) goto next;
    if (la[1]=='9' && (la[2]=='^' || !la[2]) && emitMATH(nil, 2, s)) goto next;
    // FAILE => else no math
    //if (ax==lastarg && !savelast) goto next; // IAX did it already
//    if (s->ax==lastarg) { la+= 2; goto next; } // no need do anything
//    if (s->ax==lastarg && la[1]==lastarg) { goto next; } // no need do anything

// TODO: this is all wrong with 'b' ???
    if (la[1]==lastarg && s->ax==lastarg) { la+= 2; goto next; } // no need do anything

    // TODO: if want same, maybe need dup?
    // TODO: distinguish between "have right value" but need to save,
    //       or have right value, but is waste?
    DASM(printf("\n--- NEW: want '%c' ax='%c' \n", la[1], s->ax));
    //goto next;
    //assert(!s->savelast);
    if (s->savelast) {AX('?'); s->savelast= 0;}
    // JSR(pushax); ++(s->stk);

    s->savelast= 1;
    goto next;

  case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': 
    // TODO: we come, here? always [ before? no?
    // TODO: IAX; needed for emitMATH?
    AX('?');
    if (!emitMATH(MKNUM(*la-'0'), 1, s)) { emitCONST(MKNUM(*la-'0'), s->ax); AX(*la); }
    goto next;

  case ',': ++la; IAX; if (emitMATH(*(L*)la, 2, s)) goto next;
    emitCONST(*(L*)la, s->ax); ++la; goto next;

  // read address from var/address
  // TODO: optimize for MATH?    
  case ';': ++la; IAX; LDA((void*)(*(L*)la)); LDX((void*)((*(L*)la)+1)); ++la; goto next; // 9 bytes = read var

  case '9': AX('9'); JMP(retnil); goto next;
 
  // -- All these routine (may) change the stack
  //  case '=': IAX; JSR(toseqax); --stk; goto next; // TODO: V cmp I => ... TODO: toseqax => 1 or 0, not T or nil...
  // not correct ...
  case '=': IAX; JSR(toseqax); CMPn(0); --(s->stk); goto next; // TODO: V cmp I => ... TODO: toseqax => 1 or 0, not T or nil...

 //case '<': IAX; JSR(tosltax); CMPn(0); --(s->stk); goto next;

  case 'C': IAX; JSR(cons); --(s->stk); goto next; // WORKS!

    // TODO: add/sub/mul by constant - inline/special jsr
    // TODO: add/sub by variable - inline: global/local?
  case '+': IAX; JSR(tosaddax); --(s->stk); goto next; // prove not need ANDn for neg?
  case '-': IAX; JSR(tossubax); --(s->stk); goto next; // prove not need ANDn for neg?
  case '*': IAX; JSR(asrax1); JSR(tosmulax); ANDn(0xfe); --(s->stk); goto next; // prove not need ANDn for neg?
  case '/': IAX; JSR(tosdivax); JSR(aslax1); ANDn(0xfe); --(s->stk); goto next; // need ANDn for neg, yes!

  // SET: setting global variable: address on stack, value in AX (opposite SETQ
  case '!': JSR(staxspidx); --(s->stk); goto next; // total 23 bytes...

  // COND I { THEN } { ELSE } ' ' => COND  CMP 0  BNE xx  THEN  SEC  BCS yy  xx:  ELSE  yy:
  //                                         I        fix     {          fix          }
  // TODO: AX not just A, lo, and TODO: test nil
//  case 'I': CMPn(0); BEQ(0); *++fix= mcp-1; goto next; // save relative xx to fix of 'I', THEN follows
//  case 'I': BNE(0); *++fix= mcp-1; goto next; // save relative xx to fix of 'I', THEN follows
  case '{': case '}': return mcp;
  case 'I':
    {
      AsmState thn, els;
      char *xx= mcp-1, *yy= 0;
      char* insertHere= 0;
      thn= *s; els= *s;

      genasm(&thn);

      // '{'
      assert(*la=='{');
      ++la;

      // if last op in THEN was jmp/tail rec/return, no need jmp endIF!/
      if (thn.stk < 64) { // ^ or Z
        if (thn.savelast && thn.ax=='a')//
          insertHere= mcp; // where to insert pushax, lol
// TDOO: assembler thinks this becoms CLV ???? WTF patching?
        SEC(); BCS(0); yy= mcp-1; // addr of rel Bxx to endIF
      }

      DASM(printf("\n======> THEN.stk: T %d ax=%c / E %d ax=%c\n", thn.stk, thn.ax, els.stk, els.ax));

      *xx= mcp-xx-1; // patch IF to jump yy ELSE

      genasm(&els);
      DASM(printf("\n======> ELSE.stk: T %d ax=%c / E %d ax=%c\n", thn.stk, thn.ax, els.stk, els.ax));

      // '}'
      assert(*la=='}');

      // TODO? just because savelast ....
      s->stk= thn.stk;
      if (s->stk>=64) s->stk= els.stk;

      // do the THEN ELSE have same in AX?
      s->ax= thn.ax;
      if (s->ax != els.ax) s->ax= '?';

      // correctness
      if (thn.stk < 64 && els.stk < 64) {
        int err= 0;

        // same stacks
        if (thn.stk != els.stk) {
          printf("\n%% Stack mismatch: IF THEN (%d) ELSE (%d)\n", thn.stk, els.stk);
          err= 5+els.stk-thn.stk;
        }

        // same "saved" - it's same thing? lol
        if (thn.savelast != els.savelast) {
          printf("\n%% SaveLast mismatch: IF THEN (%d) ELSE (%d)\n", thn.savelast, els.savelast);
          err+= 2000 + 100*thn.savelast + 10*els.savelast;
          // THEN 1 ELSE 0
          // we don't know if need "a" later
          // -- we could force-push before IF :-(
          //    but that defaults space and time saving...
          // -- can't drop stack because AX may be needed
          //    if return, it's already noted/optimized
          // -- "insert pushax" BEFORE "{" LOL
          //    only feasable? LOL
        }

        if (err==2014) {
          printf("\nTRYING TO FIX MISMATCH... INSERTING...\n");
          // insert "puashax" before "{"
          JSR(pushax); ++els.stk; els.savelast= 0; els.ax= 'a';
          assert(thn.stk==els.stk);
          s->savelast= 0; s->stk= thn.stk; s->ax= (thn.ax==els.ax)? thn.ax: '?';
          err= 0;
        } else if (err==2106) {
          printf("\nTRYING TO FIX MISMATCH... INSERTING...\n");
          // insert "puashax" before "{"
          if (!insertHere) printf("\nINSERTHERE: can't!\n");
          else {
            char* tmp= mcp;
            memmove(insertHere+3, insertHere, mcp-insertHere);
            mcp= insertHere; JSR(pushax);
            assert(mcp-insertHere==3);
            mcp= tmp+3; *xx+= 3; yy+= 3; *yy+= 3; // adjust jmps LOL
            s->ax= '?'; s->savelast= 0; s->stk= els.stk;
            err= 0;
          }
        }
        if (err) printf("\n\nERR=%d\n", err);
        assert(!err);
      }
        
      if (yy) *yy= mcp-yy-1; // patch THEN if needed to jmp endIF

    } goto next; 

  // Subroutine caller and misc and 0..8 digit
  case '(':
  case ')':
  default:
    // local variables on stack
    // TODO: handle let, even inline let: (let ((a 3) (b 4)) (+ 3 (let ((c 4)(d (+ a b))) (+ a c d))))
    //                                        probably have to keep track of what where " dc ba" spc is 1stk
    if (*la>='a' && *la<='h') {
      char i= 2*(lastvar-*la+s->stk-1)+1;
      if (s->ax==*la) goto next; // ax IS *la 'a' !
      DASM(printf("\n\t===== VAR ax '%c' => '%c'\n", s->ax, *la));
      assert(*la <= lastvar);
      s->ax= *la;
      if (i==1) { JSR(ldax0sp); goto next; } // TODO: add more variants?
      LDYn(i); JSR(ldaxysp); goto next; }
    // TODO: closure variables ijkl mnop

    // inline constant 7 bytes, hmmmm... TODO: compare generated code?
    //if (*la>='0' && *la<='8') { LDAn(MKNUM(*la-'0')); LDXn(0); goto next; }

    error1("%% genasm.error: unimplemented code", *la);
  }
}

char* asmpile(char* pla) {
  AsmState s= {};
  s.ax= 'a'; s.savelast= 1;

  mcp= mc;
  memset(mc, 0, sizeof(mc));
  lastvar= 'a'; lastarg= lastvar; lastop= 0;
  la= pla-1; // using pre-inc
  if (!genasm(&s)) return 0;

  // TODO: a test with 00..FF codes andn params 11 22 33 to verify all.... 
  //       and verify length...

  // poor man disasm (- 34634 33339) 1295 bytes! (one is asm is 970 B?)
#ifdef DISASM
  #define BRANCH "PLMIVCVSCCCSNEEQ"
  #define X8     "PHPCLCPLPSECPHACLIPLASEIDEYTYATAYCLVINYCLDINXSED" // verified
  #define XA     "ASL-1aROL-3aLSL-5aROR-7aTXATXSTAXTSXDEX-daNOP-fa" // verified duplicaet ASL...
  #define CCIII  "-??BITJMPJPISTYLDYCPYCPXORAANDEORADCSTALDACMPSBCASLROLLSRRORSTXLDXDECINC" // ASL...
  #define JMPS   "BRKJSRRTIRTS"

  { char* p= mc;
    printf("\n---CODE[%d]:\n",mcp-mc); p= mc;
    while(p<mcp) {
      uchar i= *p++, m= (i>>2)&7;
      printf("%04X:\t", p);

      if      (i==0x20) printf("JSR %04x",*((L*)p)++);
      else if (i==0x4c) printf("JMP %04x",*((L*)p)++);
      else if (i==0x6c) printf("JPI (%04x)",*((L*)p)++);
      else if ((i&0x1f)==0x10) 
        printf("B%.2s %+d\t=> %04X", BRANCH-1+(i>>4), *p, p+2+(signed char)*p++);
      else if ((i&0xf)==0x8 || (i&0xf)==0xA) printf("%.3s",(i&2?XA:X8)+3*(i>>4));
      else if (!(i&0x9f)) printf("%.3s", JMPS+3*(i>>5));
      else {
        uchar cciii= (i>>5)+((i&3)<<3);
        if (cciii<0b11000) printf("%.3s", CCIII+3*cciii);
        else printf("%02x ??? ", i);
        switch(m) {
        case 0b000: printf(i&1?" (%02x,X)":" #%02x", *p++); break;
        case 0b001: printf(" %02x ZP", *p++); break;
        case 0b010: printf(i&1?" #%02x":" A", *p++); break;
        case 0b011: printf(i&1?" %04x":" A", *((L*)p)++); break;
        case 0b100: printf(" (%02x),Y", *p++); break;
        case 0b101: printf(" %02x,X", *p++); break;
        case 0b110: printf(" %04x,%c", m&1?'Y':'X', *((L*)p)++); break;
        }
      }
      NL;
    } NL;
  }
#endif // DISASM

  return mc;
}

// takes compiled bytecode and compiles to asm,
// then runs bench times
L al(char* la) {
  char *m= 0;

  top= MKNUM(8);

  // TODO: implement real function call...

  if (verbose) printf("\nVMAL.run: %s\n", pc);

  // TODO: move OUT
  m= asmpile(la);

  if (m) {
    // Run machine code
    { L x= top; L check= ERROR, ft= MKNUM(42);

      // Bench cut all overhead, run form there...
      // TODO: not fair to VM... lol
      for(; bench>0; --bench) top= ((FUN1)m)(x);

      if (ft!=MKNUM(42) || check!=ERROR) {
        // TODO: calculate how much? lol
        printf("\n%% ASM: STACK MISALIGNED: %d\n", -666); // get and store SP
        printf("top="); prin1(top);
        printf(" ft="); prin1(ft);
        printf(" check="); prin1(check); NL;
        exit(99);
      }
      //top= ((FUN1)m)(x);
      if (verbose) printf("RETURN: %04x == ", top); prin1(top);NL;
      // TODO: need to balance the stack!
      return top;
    }
  }
  return ERROR;
}
