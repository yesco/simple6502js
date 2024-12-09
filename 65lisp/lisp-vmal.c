// ----------------= Alphabetical Lisp VM
// EXPERIMENTIAL BYTE CODE VM

// AL: 23.728s instead of EVAL: 38.29s => 38% faster
//   now 27.67s... why? cons x 5000= 16.61s 



#define NEXT goto next

static L *s, *frame;

// ./cons-test AL: 23.74s EVAL: 43.38s (/ 23.74 43.38) => 43% faster!
//  24.47s added more oops, switch slower? now use goto jmp[] => 13s.. !!! lol

// global vars during interpretation: 30% faster


// +5.0% faster with zero page vars!!!
// BUT: it overflows it, need config file to allcocate more?
//#define ZEROPAGE

#ifdef ZEROPAGE
#pragma bss-name (push,"ZEROPAGE")
#pragma data-name(push,"ZEROPAGE")
#endif // ZEROPAGE

static L top;
static char c, *pc;

#ifdef ZEROPAGE
#pragma bss-name (pop)
#pragma data-name(pop)
#endif // ZEROPAGE

// ignore JMPARR usage, uncomment to activate
//#define JMPARR(a) 

// just including the code
#ifdef ASM
  #define GENASM
#endif

#ifdef GENASM
  #ifdef JIT
    #include "asm.c"
  #else
    #include "lisp-asm.c"
  #endif
#else
  #define asmpile(a) 0
#endif


// 2883 Bytes for the bytecode interpreter!
#ifndef GENASM

//#if 0

// For each user/machine code function call we recurse
// The function need to know how many parameters from the
// stack it uses, and it needs to clear that up!

void alcall(char nparams, char* la);

#ifdef GENASM
extern L runal(char* la) {
#else
extern L runal(char* la) {
#endif

  char n=0;
#ifndef JMPARR
  //static void* jmp[127]= {(void*)(int*)42,0};
  static void* jmp[127]= {
/*
    // 00-07
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,
    // 08-0F
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,

    // 10-07
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,
    // 18-1F
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,

    // 20-27: > !"#$%&'<
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,
    //&&gbl,&&gft,
    // 28-2F: >()*+,-./<
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,

    // 30-37: >01234567<
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,
    // 38-3F: >89:;<=>?<
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,

    // 40-47: >@ABCDEFG< 
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,
    // 48-4F: >HIJKLMNO<
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,
    
    // 50-57: >PQRSTUVW<
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,
    // 58-5F: >XYZ[\]^_<
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,

    // 60-67: >`abcdefg<
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,
    // 68-6F: >hijklmno<
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,

    // 70-77: >pqrstuvw<
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,&&gbl,
    // 78-7F: >xyz{|}~/<
    &&gbl,&&gbl,&&gbl,&&gbl, &&gbl,&&gbl,&&gbl,//&&gbl, // MAX: 127!
*/
    (void*)(int)42,
//    &&gA,&&gD,0,
    //&&gbl,
  };
#endif

  char* orig= la; // global 10% faster
  pc= la;

#ifndef JMPARR
  // TODO: static allocation, less code!
  #define JMPARR(a) a:

  if (*((int*)jmp)==42) {
    if (verbose) printf("JMPARR inited\n");
    memset(jmp, (int)&&gerr, sizeof(jmp));
    
    //jmp['R']=&&grec;
    //jmp['Z']=&&gloop;

    jmp[0]=&&g0;
    jmp['^']=&&gret;

    jmp['A']=&&gA; jmp['D']=&&gD; jmp['U']=&&gU; jmp['K']=&&gK; jmp['@']=&&gat; jmp[',']=&&gcomma; jmp['C']=&&gC;
    jmp['+']=&&gadd; jmp['*']=&&gmul; jmp['-']=&&gsub;
    jmp['/']=&&gdiv; jmp['=']=&&geq; jmp['<']=&&glt;
    jmp['?']=&&gcmp;
    jmp['P']=&&gP;
    jmp['Y']=&&gY;
    jmp['!']=&&gset;
    jmp[':']=&&gsetq;
    jmp[';']=&&gsemis;
    
    jmp['I']=&&gif;
// TOOD: compiler failure!
    jmp['{']=&&gelse;
// TOOD: compiler failure!
//    jmp['}']=&&gendif;
    jmp['}']=&&next;

    jmp['[']=&&next;
    jmp[']']=&&next;

    for(c='0'; c<='9'; ++c) jmp[c]= &&gdigit;
    for(c='a'; c<='h'; ++c) jmp[c]= &&gvar;

// TOOD: compiler failure! - Can't handle label/call that is optimimized away cc65 bug!
//    jmp[' ']=jmp['\t']=jmp['\n']=jmp['\r']=&&gbl;
    jmp[' ']=jmp['\t']=jmp['\n']=jmp['\r']=&&next;

    jmp['9']=&&gnil; // lol

    // play
    jmp['i']= &&ginc;
    jmp['j']= &&ginc2;

    jmp['z']= &&gZ;
  }
#endif // JMPARR

  // cut from here 

 call:
  --pc; // as pre-inc is faster in the loop

  //if (verbose>2) printf("FRAME =%04X\n", frame);

 next:
  //assert(s<send);
  // cost: 13.50s from 13.11s... (/ 13.50 13.11) => 3%

  //if (verbose>1) { printf("%02d:al %c stk=%d top=", pc-orig+1, pc[1], s-(stack-1)); prin1(top); NL; }
  if (verbose>1) { L* x= stack;
    printf("%02d:al %c    STK[%d]: ", pc-orig+1, pc[1], s-(stack-2));
    while(x<=s) { prin1(*x++); putchar(' '); }  prin1(top); NL; }

  // caaadrr x5K => 17.01s ! GOTO*jmp[] is faster than function call and switch

// inline this and it costs 33 byters extra per time... 50 ops= 1650 bytes... 

#define NNEXT NOPS(++nops;);c=*++pc;goto *jmp[c]
//#define NNEXT goto next;

//#undef NNEXT
//#define NNEXT goto next

  //NOPS(++nops;);c=*++pc;goto *jmp[c];
  //printf("\t\tTOP="); prin1(top); NL;

// TODO: hmm, needed for VM with JMP?
//  NNEXT;

  // 16.61s => 13.00s 27% faster, 23.49s => 21.72s 8.3% faster

  // using goto next instead of NNEXT cost 1% more time but saves 365 bytes!

  c= *++pc;
  switch(c) {

  // inline AD cons-test: 14% faster, 2.96s with isnum => safe,
  // otherwise 2.92s (/ 2.96 2.92)=1.5% overhead
//JMPARR(gA)case 'A': top= isnum(top)? nil: CAR(top); NNEXT; // 13.00s
//JMPARR(gA)case 'A': top= isnum(top)? nil: CAR(top); goto next; // 13.10s
//JMPARR(gA)case 'A': if (isnum(top)) goto setnil; top= CAR(top); NNEXT; // 12.98s (/ 13.10 12.98) < 1%
JMPARR(gA)case 'A': if (isnum(top)) goto setnil; top= CAR(top); goto next; // 13.06 (/ 13.06 12.98) < 0.7%
JMPARR(gD)case 'D': if (isnum(top)) goto setnil; top= CDR(top); goto next;

JMPARR(gZ)case 'z':
    { int i=5000; static L x; x= top;
      // nair fair, EVAL: ./run -b 10000 => 92.38s !!!!    
      for(;i;--i) {
        //top=CAR(CAR(CAR(CDR(CDR(CDR(cdr(x))))))); // 2.98s
        //top=car(car(car(cdr(cdr(cdr(cdr(x))))))); // 6.41s
        //__AX__= x;  fcdr();fcdr();fcdr();fcdr();fcar();fcar();fcar();  top= __AX__; //  NOT: x optimized away lol
        //top= fc3a4dr(x); // 3.09s 22564ops/s !!! (2.83s UNSAFE)
        //NL;
        top= ffcar(ffcar(ffcar( ffcdr(ffcdr(ffcdr(ffcdr( x))))))); // 2.24s => 29537ops/s
      }
    }
    goto next; // last can't be CDR loll

//JMPARR(geq)case '=': top= (*s-- == top)? T: nil; NNEXT;
//JMPARR(geq)case '=': if (*s--== top) goto settrue; else goto setnil; // OLD LABEL
//JMPARR(geq)case '=': if (*s--==top) goto setnil; goto settrue; // error if have else!
//JMPARR(geq)case 7: if (*s==top) goto droptrue; else goto dropnil; goto droptrue; // error if have else!
//JMPARR(geq)case 7: --s; if (s[1]==top) goto settrue; goto setnil; .. not too bad
JMPARR(glt)case '<': if (*s<top) goto settrue; goto setnil;
JMPARR(geq)case '=':
    if (*s==top)
         { --s; settrue: top= T; }
    else { --s; setnil:  top= nil; }
    goto next;
    //NNEXT; // TODO: some problem?
         
JMPARR(gnil)case '9': *++s= top; goto setnil;
JMPARR(gU)case 'U': if (null(top)) goto settrue; goto setnil;
JMPARR(gK)case 'K': if (iscons(top)) goto settrue; goto setnil;

JMPARR(gset)case '!': setval(*s, top, nil); --s; goto next;

JMPARR(gat)case '@': top= ATOMVAL(top); goto next; // same car 'A' lol

JMPARR(gcomma)case ',': *++s= top; top= *(L*)++pc; pc+= sizeof(L)-1; goto next;
JMPARR(gsemis)case ';': *++s= top; top= *(L*)++pc; top= ATOMVAL(top); pc+= sizeof(L)-1; goto next;
JMPARR(gsetq)case ':': setval(*(L*)++pc, top, nil); pc+= sizeof(L)-1; goto next;
JMPARR(gcall)case '_': {
      L a, b;
      char n= 1; // TODO: extract number of arguments from function
      void* f= (void*)*(L*)++pc; pc+= sizeof(L)-1;
      // move elements to C call stack:
      if (n==0) { top= ((F0)f)();          goto next; }
      if (n==1) { top= ((F1)f)(top);       goto next; } else a= *s; --s;
      if (n==2) { top= ((F2)f)(a, top);    goto next; } else b= *s; --s;
      if (n==3) { top= ((F3)f)(b, a, top); goto next; }
      // TODO: ... n==8 ??? lots of code, lol
      error1("AL.gexec too many args", mknum(n));
    }
JMPARR(gexec)case'X': {
    L f= top; top= *s; --s;
    if (verbose) { printf("al.GEXEC ptr=%04x %s ", f, ISBIN(f)?"ISBIN":""); prin1(f); NL; }
      
    if (iscons(f)) { // LAMBDA
      // pop enough elements from stack
      L args= nil, *p= &args;
      char n= 1; // number of arguments
      while(n-->0) {
        *p= cons(top, nil); top= *s; s--;
        p= (void*)CDR(*p);
      }
      top= eval(cons(f, args), nil);
      goto next;

    } else if (ISBIN(f)) {
      char* fp= BINSTR(f);
      char n= 1; // TODO: extract number of arguments from function
      alcall(n, fp); // TOOD: tailrecursion?
      goto next;

    } else error1("AL.gcall: how to run", f);
    }

// make sure at least safe number, correct if in bounds and all nums
#define NUM_MASK 0xfffe
JMPARR(ginc)case 'i': __AX__= top; asm("jsr incax2"); top= __AX__; goto next;
JMPARR(ginc2)case 'j': top+= 2; goto next;

JMPARR(gadd)case '+': top+= *s; --s; top&=NUM_MASK; goto next;
JMPARR(gmul)case '*': top*= *s; --s; top/=2; top&=NUM_MASK; goto next;

JMPARR(gsub)case '-': top= *s-top; --s; top&=NUM_MASK; goto next;
JMPARR(gdiv)case '/': top= *s/top*2; --s; top&=NUM_MASK; goto next;

JMPARR(gC)case 'C': top= cons(*s, top); --s; goto next;

JMPARR(gbl)
  case '[': case ']': // TODO: hmmm, simiulate the opt ax of asm?
  // not so common so move down... linear probe!
  case ' ': case '\t': case '\n': case '\r': case 12: goto next; // TODO: NNEXT loops forever?

JMPARR(gcmp)
  case '?': top= top==*s? MKNUM(0): (isatom(*s)&&isatom(top))?
      mknum(strcmp(ATOMSTR(*s), ATOMSTR(top))): mknum(*s-top); goto next; // no care type!

  // TODO: need a drop?

JMPARR(gP)case 'P': print(top);  goto next;
JMPARR(gY)case 'Y': top= sread(ISSTR(top)? ATOMSTR(top): 0);

// TODO: replace by jmps? This doesn't nest, lol
JMPARR(gif)   case 'I': if (null(top)) while(*pc!='{') ++pc;  goto next;
// TODO: it goes very badly wrong here, onlyi works if THEN==(return ....) !!!!
JMPARR(gelse) case '{':
    pc+= 0; // LOL, without this line, cc65 optimizes away this bracnh and gives error for gelse!!! cc65 bug!
    while(*pc!='}') ++pc;  goto next; // TODO: doesn't work for NESTED!!!!???

JMPARR(gendif)case '}': goto next;

  // single digit, small number, very compact (27.19s, is faster than isdigit in default)
JMPARR(gdigit)case '0':case'1':case'2':case'3':case'4':case'5':case'6':case'7':case'8'://case'9':
    *++s= top; top= MKNUM(*pc-'0'); goto next;

// TODO: these are the same... always?
JMPARR(gret)case'^': return top;
JMPARR(g0)case 0:
    if (verbose) { printf("\n\nRETURN="); prin1(top); NL; }
    return top; // all functions should end with ^ ?


// --- Recursion, TailCall, Iterate, Function Call
JMPARR(grec)case'R':
    alcall(1, orig);
    goto next;
    
// not working correctly...
 if (pc[1]!='^') {
      // Self recursion
      // (parameters already on stack)
      { L *saveframe= frame, *savestk= s; char* savepc= pc;
        frame= s-n+1;

        runal(orig); // TODO: pass in the BINOBJECT!

        frame= saveframe; s= savestk-n+1; pc= savepc;
      }
      goto next;
    }

    // Tail Recursion
    if (n>1) memmove(frame, s+1-n, n-1); // fall through
JMPARR(gloop)case'Z': pc= orig; goto call;

  // parameter a-h (warning need others for local let vars!)
JMPARR(gvar)case 'a':case'b':case'c':case'd':case'e':case'f':case'g':case'h':
    *++s= top; top= frame[*pc-'a']; goto next;

// 26.82s
//  default : ++s; *s= MKNUM(*p-'0'); NEXT; 

// 30.45s
//  default : if (isdigit(*pc)) { ++s; *s= MKNUM(*pc-'0'); NEXT; }
//   printf("%% AL: illegal op '%c'\n", *pc); return ERROR;
JMPARR(gerr)default:
    printf("%% AL: illegal op '%c'\n", *pc); return ERROR;
  }
}

// function to recursively call an alfunction, storing state
// and restoring after call, and cleaning stack
void alcall(char nparams, char* la) {
  L *new_s= s-nparams+1, *old_frame= frame;
  char old_c= c, *old_pc= pc;

  //L old= top;

  //if (verbose) printf("\n>>>> CALLING AL top $%04X = ", top); prin1(top); NL;
  frame= new_s+1;
  runal(la); // lol, it returns top, 
  //if (verbose) printf("<<<< RETURNED FROM AL top $%04X = ", top); prin1(top); NL; NL;

  //printf("!!!!! FIB("); prin1(old); printf(") => "); prin1(top); NL;
  frame= old_frame;
  c= old_c;
  pc= old_pc;
  s= new_s;
}



// TODO: do we recurse over differnt LA?

L al(char* la) {
  top= nil;
  s= stack-1;

  // TODO: remove?
  // pretend we have some local vars (we've no been invoked yet)
  frame= s;
  top= MKNUM(8); // a (last parameter)

  // TODO: hmmm....
  //top= *s;

  return runal(la);
}

#endif // GENASM



// using generic fixed buffer of fixed size and char index
// generates 8 bytes instead of ... ... Saved 194 bytes
// TODO: use in more places...
unsigned char b;
char buff[250];

//#define ALC(c) do { buff[b]=(c); ++b; printf("\n>>>> %c\n", (c)); } while(0)
#define ALC(c) do { buff[b]=(c); ++b; } while(0)

// 25857 -> 25793 (- 25793 25857) = 64 bytes saved
//#define ALW(n) do { c= (n)&0xff; ALC(c); c= ((unsigned int)n) >> 8; ALC(c); } while(0)
void ALW(int n) { c= (n)&0xff; ALC(c); c= ((unsigned int)n) >> 8; ALC(c); }

char compileDC= 0;

// reads a single lisp function s-exp from stdin
// LIMITATIONS: can only compile one "function" at a time
void alcompile() {
  static char depth;
  char c, extra= 0, *nm, bf; int n= 0; L x= 0xbeef, f;

 again:
  switch((c=nextc())) {
  case 0  : return;
  case ' ': case '\t': case '\n': case '\r': goto again;

  case'\'': quote:
    // TODO: make subroutine compile const
    //printf("QUOTE: %d\n", x);
    x= x==0xbeef? lread(): x;

    // short constants
    if (null(x)) { ALC('['); ALC('9'); return; }

    ALC('['); // push
    ALC(','); // reads next value and compiles to put it on stack
    ALW(x);
    alvals= cons(x, alvals);
    if (extra) ALC(extra);
    return;

  // TODO: function call... of lisp
  case '(': 
    ++depth;
    // determine function, try get a number
    //skipspc();
    f= nextc(); unc(f); // peek
    // TODO: ,..X inline lambda? or evaluate function to call
    if (f=='(') error("ALC: TODO: computed function");

    x= lread();
    //printf("ALC.read fun: "); prin1(x);
    if (!isnum(x) && !isatom(x)) { prin1(x); printf(" => need EVAL: %04X ", f); prin1(f); NL; error("ALC: Need to do eval"); }

    if (isatom(x)) f= ATOMVAL(x);
    if (!f || !isnum(f)) { // 0== not primtive?
      if (verbose) { printf("\n%%TODO: funcall: "); prin1(x); printf(" => ATOMVAL $%04X = ", f); prin1(f); NL; }
      if (iscons(f) && car(f)==lambda) {
        printf("LAMBDA!...\n");
      } else {
        if (ISBIN(f)) { // AL bytecode

          n= 0;
          while((c=nextc())!=')') {
            alcompile();
            ++n;
          }

          // one more...
          // TODO: ?
          //c= skipspc();
          //if (c!=')') goto expectedparen;

          // TODO: very check arguments
          //printf("NNNN arguments=%d\n", n);
          assert(n==1);

          // TODO: for now assume bytecode, otherwise asm...
          extra= 'X';
          x= f; // TODO: should be atom? no?
          goto quote;
          // TODO: hmmm...
        //} else if (isasm(x)) {
          //ALC('_');
          //ALW(asmaddress(x));
          //if (skipspc()!='(') goto expectedparen;
        } else error1("HOW TO FUNCALL - non bin", f);
      }
      bf= 0;
    } else {
      // get the byte code token
      bf= NUM(f);
      if (bf=='\'') { --depth; goto quote; }
      else if (bf=='L') bf= -'C'; // foldr // TODO: who gives a?
      else assert(bf<255);
    }

    // TODO: how to handle non-foldable arguemnts
    //   TODO: look at number of arguments the function expects? if n>2

    if (verbose>2) { printf("\n%% compile: "); prin1(x); printf("\t=> '%c' (%d)\n\n", bf, bf); }
 
    // DefineCompile to al bytecode
    if (x==DC) {
      L name;

      assert(!compileDC);
      
      // - read name
      name= lread();
      assert(isatom(name));
      printf("DEFINING: "); prin1(name); NL;
      
      // - parse (count) parameters
      compileDC= 1;

      // TODO: handle catchall?
      if (skipspc()!='(') goto expectedparen;
      do {
        x= lread();
        assert(isatom(x));
        printf("  PARAM %d: >", n); prin1(x); putchar('<'); NL;
        { char* p= ATOMSTR(x);
          assert(strlen(p)==1);
          assert(*p=='a'+compileDC-1);
        }
        ++compileDC;
      } while(skipspc()!=')'); // TODO: eof?
      assert(compileDC<=1+8); // max 8 params (?)

      // - parse body
      // (remove ], why is it there?) TODO:
      b= 0;
      buff[0]= 0;

      // TODO: should this just be a funciton of parsing a (n expliecit) lambda?
      // TOOD: this is duplicated from alcompileread
      alcompile();
      assert(b);
      ALC('^');
      x= mkbin(buff, b+1);

      printf("  BODY= "); prin1(x); NL;
      b= 0;

      // end DC
      c= skipspc();
      if (c!=')') goto expectedparen;
      
      // - define and store function
      setval(name, x, nil);
      return;
    }

    // IF special (if EXPR THEN ELSE) => EXPR I ] THEN { ] ELSE }
    if (x==IF) {
      // inserts spaces at end of THEN and ELSE to allow promote implicit RETURN
      // we don't know if it's return until come to end of LAMBDA sequence or PROGN
      alcompile(); ALC('I'); // EXPR I
      ALC(']'); alcompile(); ALC(' '); ALC('{'); // DROP THEN
      // THEN, optional
      c= skipspc(); unc(c);
      ALC(']'); // DROP
      if (c!=')') alcompile(); // ELSE
      ALC(' '); ALC('}');
      if (skipspc()!=')') goto expectedparen;
      --depth;

      //// It's last expr in lambda/progn
      //c= skipspc();
      //if (depth==1 && (!c || c==')')) {
      //printf("DEPTH==1 => RETURN!\n");
      //buff[bThen]= '^';
      //buff[bElse]= '^';
      //}
      //unc(c);

      --depth;
      return;
    }

    // (and A B) == (if A B nil)
    // (or A B)  == (if A T B) --- or should return A, hmmm, let?

    // (or A B) == (if (null A) B)
    if (x==OR) {
      int d= 0;
      printf("--------------OR---------------\n");
      c= skipspc();
      while(c != ')') {
        if (d) ALC(']');
        unc(c); alcompile(); ALC('U'); ALC('I');
        ++d;
        c= skipspc();
      }
      unc(c);
      while(--d>=0) { ALC('{'); ALC('}'); }

      --depth;
      return;
    }

    // (and A B) == (if (null A) nil B)
    if (x==AND) {
      int d= 0;
      printf("--------------AND---------------\n");
      c= skipspc();
      while(c != ')') {
        unc(c);
        if (d) ALC(']');
        alcompile(); ALC('U'); ALC('I');
        ALC('{');
        c= skipspc();
        ++d;
      }
      unc(c);
      while(--d>=0) { ALC('}'); }

      --depth;
      return;
    }

    // SETQ special => VAL : ADDR
    if (x==SETQ) {
      L n= lread();
      assert(isatom(n));

      // generate eval of valuie
      alcompile();
      // prefix as ,
      ALC(':');
      ALW(n);

      c= skipspc();
      if (c!=')') goto expectedparen;

      --depth;
      return;
    }

    // GENERIC argument compiler
    if (verbose) printf("F='%c' (%d)\n", bf, bf);
    {
      char calledF= 0;
      while((c=nextc())!=')') {
        ++n;
        //printf("--->COMPILE %c\n", bf);
        alcompile();
        //printf("<---COMPILE %c\n", bf);
        // implicit FOLDL of nargs + - L ! LOL
        // TODO: handle non isnum
        if (bf=='+' || bf=='-' || bf=='*' || bf=='/' || bf=='C')
          if (bf>0 && n>=2 && bf<255 && bf!='R' && bf!='Z') {
            ALC(bf);--n;
            calledF=1;
          }
      }

      // TODO: Fix this mess, lol because we don't know nparam... yet!
      if (!calledF && bf>0) ALC(bf);
      else if (bf>0 && bf<255 && n>1) { ALC(bf); n-=2; break; }

    }
    // TODO: merge with quote?
    if (!isnum(f)) {
      printf("Compile: call lambda: "); prin1(f); NL;
      ALC('_'); ALW(f);
      return; 
    }

    // foldr?
    while(f<0 && --n > 0) ALC(-f); 
    if (f<255) break; // FOLD R/L

    // it's a user defined function/compiled
    assert(isatom(f)); // TODO: handle lisp/s-exp

    // ??? ')'
    extra= ')';
    unc(c);
    x= 0xbeef;

    --depth;
    goto quote;

  default:
    // 0-9: inline small int, a-z: local variable on stack
    //printf("\nDFAULT: '%c'\n", c);

    if (isdigit(c) || c=='.' || c=='-' || c=='+') {
      //printf("READNUM: ");
      x= readdec(c, base); // x use by quote if !0
      //printf("... is %d\n", x);
      // result is single digit, compile as is
      // NOTE: '9' isn't 9 but nil :-D :-D (const 9 not common...?)
      if (isnum(x) && x>=0 && NUM(x)<9) { ALC('['); ALC(NUM(x)+'0'); return; }
      goto quote;
    }

    // atom name
    unc(c); x= lread(); // x use by quote if !0
    assert(isatom(x));
    // local variable a-w (x y z special)
    nm= ATOMSTR(x);
    if (!nm[1] && islower(*nm) && *nm<'x') { ALC('['); ALC(c); return; }
 
    // x==self lol?
    if (x==nil || x==T || x==ERROR) goto quote;

    // allow for inline read
    ALC('['); // push
    ALC(';'); // 55 bytes about! => 13 bytes without macro
    ALW(x);
    return;
  }
  return;

 expectedparen: // used twice
  error1("ALC.expected ')' got lisp", c);
}

L alcompileread() {
  // use global buffer, and index b -- much less code and faster!
  memset(buff, 0, sizeof(buff));
  buff[sizeof(buff)-1]= 255; // end marker
  b= 0;

  // if not function
  ALC(']'); // TODO: is this the right way to say ax contains nothing of value?

  compileDC= 0;
  alcompile();
  if (!b || b==1) return eof; // TODO: b==1 for ']' above
  if (buff[b]) return ERROR; // out of buffer TODO: fix assert in ACL
  ALC('^'); // all need to return & cleanup
  return mkbin(buff, b+1); // add one to additionally zero-terminate?
}  
