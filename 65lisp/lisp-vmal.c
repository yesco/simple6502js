// ----------------= Alphabetical Lisp VM
// EXPERIMENTIAL BYTE CODE VM

// AL: 23.728s instead of EVAL: 38.29s => 38% faster
//   now 27.67s... why? cons x 5000= 16.61s 



#define NEXT goto next

static L *s, *frame, *params;

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

// just including the cod
#ifdef ASM
  #define GENASM
#endif

#ifdef GENASM
  #include "lisp-asm.c"
#else
  #define asmpile(a) 0
#endif


// 2883 Bytes for the bytecode interpreter!
#ifndef GENASM

//#if 0

#ifdef GENASM
extern L runal(char* la) {
#else
extern L al(char* la) {
#endif

  char n=0, *orig;

#ifndef JMPARR
  static void* jmp[127]= {(void*)(int*)42,0};
#endif

#ifndef JMPARR
  #define JMPARR(a) a:

  if (*((int*)jmp)==42) {
    if (verbose) printf("JMPARR inited\n");
    memset(jmp, (int)&&gerr, sizeof(jmp));
    
    jmp[0]=&&g0;

    jmp['A']=&&gA; jmp['D']=&&gD; jmp['U']=&&gU; jmp['K']=&&gK; jmp['@']=&&gat; jmp[',']=&&gcomma; jmp['C']=&&gC;
    jmp['+']=&&gadd; jmp['*']=&&gmul; jmp['-']=&&gsub;
    jmp['/']=&&gdiv; jmp['=']=&&geq;
    jmp['?']=&&gcmp;
    jmp['P']=&&gP;
    jmp['Y']=&&gY;
    jmp['!']=&&gset;
    //jmp[':']=&&gsetq;
    jmp[';']=&&gsemis;
    
    //printf("FISH\n");

    jmp['[']=&&gbl;
    jmp[']']=&&gbl;

    for(c='0'; c<='9'; ++c) jmp[c]= &&gdigit;
    for(c='a'; c<='h'; ++c) jmp[c]= &&gvar;

    jmp[' ']=jmp['\t']=jmp['\n']=jmp['\r']=&&gbl;

    jmp['9']= &&gnil; // lol

    // play
    jmp['i']= &&ginc;
    jmp['j']= &&ginc2;

    jmp['z']= &&gZ;
  }
#endif // JMPARR

  top= nil; // global 10% faster!
  orig= pc= la; // global 10% faster
  s= stack-1; frame= s; params= s; // global yet 10% faster!!!

  // TODO: remove?
  // pretend we have some local vars (we've no been invoked yet)
  *++s= (L)NULL;   // top frame
  frame= s;
  *++s= (L)NULL;   // orig
  *++s= (L)NULL;   // p
  *++s= (L)NULL;   // no prev stack
  // args for testing
  *++s= MKNUM(11); // a
  params= s;
  *++s= MKNUM(22); // b
  *++s= MKNUM(33); // c
  *++s= MKNUM(44); // d // lol
  *++s= MKNUM(4);  // argc // TODO: maybe useful

  *++s= MKNUM(8);  // for fib
  // can't access 4 as e? hmmm?

  top= *s;

  // HHMMMM>?
  if (!pc) return ERROR;

  #define PARAM_OFF 4

 
 call:
  params= frame+PARAM_OFF;
  if (s<params) s= params; // TODO: hmmm... TODO: assert?
  --pc; // as pre-inc is faster in the loop

  if (verbose>2) printf("FRAME =%04X PARAMS=%04X d=%d\n", frame, params, params-frame);
  if (verbose>2) printf("PARAMS=%04X STACK =%04X d=%d\n", params, s, s-params);

 next:
  //assert(s<send);
  // cost: 13.50s from 13.11s... (/ 13.50 13.11) => 3%

  if (verbose>1) { printf("al %c : ", pc[1]); prin1(top); NL; }

  // caaadrr x5K => 17.01s ! GOTO*jmp[] is faster than function call and switch

// inline this and it costs 33 byters extra per time... 50 ops= 1650 bytes... 

#define NNEXT NOPS(++nops;);c=*++pc;goto *jmp[c]

  NOPS(++nops;);
  c=*++pc;
  goto *jmp[c];

  // 16.61s => 13.00s 27% faster, 23.49s => 21.72s 8.3% faster

  // using goto next instead of NNEXT cost 1% more time but saves 365 bytes!

  switch(*++pc) {

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
JMPARR(geq)case '=':
    if (*s==top)
         { --s; settrue: top= T; }
    else { --s; setnil:  top= nil; }
    NNEXT;
         
JMPARR(gnil)case '9': *++s= top; goto setnil;

JMPARR(gset)case '!': setval(*s, top, nil); --s; goto next;

JMPARR(gU)case 'U': if (null(top)) goto settrue; goto setnil;
JMPARR(gK)case 'K': if (iscons(top)) goto settrue; goto setnil;

JMPARR(gat)case '@': top= ATOMVAL(top); goto next; // same car 'A' lol

JMPARR(gcomma)case ',': *++s= top; top= *(L*)++pc; pc+= sizeof(L)-1; goto next;
JMPARR(gsemis)case ';': *++s= top; top= *(L*)++pc; top= ATOMVAL(top); pc+= sizeof(L)-1; goto next;

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
  // not so common so move down... linear probe!
  case ' ': case '\t': case '\n': case '\r': case 12: goto next; // TODO: NNEXT loops forever?

JMPARR(gcmp)
  case '?': top= top==*s? MKNUM(0): (isatom(*s)&&isatom(top))?
      mknum(strcmp(ATOMSTR(*s), ATOMSTR(top))): mknum(*s-top); goto next; // no care type!

  // TODO: need a drop?

JMPARR(gP)case 'P': print(top); goto next;
JMPARR(gY)case 'Y': top= sread(ISSTR(top)? ATOMSTR(top): 0);

  // calling user compiled AL or normal lisp

#ifdef CALLONE // a b c ,FF@X
  // stack layout at call (top separate)
  
  //stack  : ... <new a> <new b> <new c> (@new frame) <old frame> <old orig> <old p> ... | call in top
  //return : ... <new a> <new b> <new c> <old frame> <old orig> <old p> ... | ret in top

  case'\\': n=0; frame=s; while(*pc=='\\'){pc++;n++;frame--;} goto next; // lambda \\\ = \abc (TODO)
  case 'R': ax= '?'; memmove(frame+PARAM_OFF, s-n+1, n-1); pc= orig+n; goto call;
  case 'X': // "apply" TODO: if X^ make tail-call
    // late binding: (fac 42) == 42  \ a3<I{a^}{a a1- ,FF@X *^}^
    // or fixed:                     \ a3<I{a^}{a a1= ,PPX  *^}^
    *++s=(L)frame; *++s=(L)orig; *++s=(L)pc; *++s=(L)n; // PARAM_OFF
    frame= s; pc= orig= ATOMSTR(top); n= 0; goto call;
  case '^': ax= '?'; n=(L)*s--; pc=(char*)*s--; orig=(char*)*s--; frame=(L*)*s--; s=frame+PARAM_OFF; NNEXT;
    // top contains result! no need copy
  // parameter a-h (warning need others for local let vars!)
  case 'a':case'b':case'c':case'd':case'e':case'f':case'g':case'h':
    *s++= top; top= frame[*pc-('a'-PARAM_OFF)]; goto next;

#endif // CALLONE

#define CALLTWO
#ifdef CALLTWO 
  // stack layout at call (top separate)

  // require extra variable: keep track of current params
  // late binding: (fac 42) == 42  \ a3<I{a}{ a ( a1- ,FF ) *}^
  
  // stack  : @frame= <prev frame> <prev orig> <prev p> <prev n> a b c ...
  //          @(=     <old frame>  <old orig>  <old p>  <n>      <new a> <new b> <new c> ...
  //          @)=     | call in top
  // return :  

  case'\\': n=0; while(*++pc=='\\')++n; --pc; goto next; // lambda \\\ = \abc (TODO)
  case 'R': memmove(frame+PARAM_OFF, s-n+1, n-1); pc= orig; goto call; // TOOD: pc= orig+n ???
  case '(': { L* newframe= frame;
      *++s=(L)frame;
      *++s=(L)orig;
      *++s=(L)pc;
      //*++s=(L)n; // TODO: save s ???
      *++s=(L)n; // save stack pointer

      frame= newframe; goto next; } // TODO: NNEXT dumps core?


  case ')': // "apply" TODO: if X^ make tail-call, top == address
    pc= orig= ATOMSTR(top); goto call;

  case '^':
    params= (L*)(frame[0]); // tmp
    orig=(char*)(frame[1]);
    pc=(char*)(frame[2]);
    //n=(int)(frame[3]); // TODO: n is not needed!
    s=(L*)(frame[3]); // restore stack

    frame= params; goto call; // lol, return is call
    // top contains result! no need copy

  // parameter a-h
JMPARR(gvar)
  case 'a':case'b':case'c':case'd':case'e':case'f':case'g':case'h':
    *s++= top; top= params[*pc-'a']; goto next;

#endif // CALLTWO

  // single digit, small number, very compact (27.19s, is faster than isdigit in default)
JMPARR(gdigit)
  case '0':case'1':case'2':case'3':case'4':case'5':case'6':case'7':case'8'://case'9':
    *++s= top; top= MKNUM(*pc-'0'); goto next;

JMPARR(g0)
  case 0:
    if (verbose) { printf("\n\nRETURN="); prin1(top); NL; }
    return top; // all functions should end with ^ ?

// 26.82s
//  default : ++s; *s= MKNUM(*p-'0'); NEXT; 

// 30.45s
//  default : if (isdigit(*pc)) { ++s; *s= MKNUM(*pc-'0'); NEXT; }
//   printf("%% AL: illegal op '%c'\n", *pc); return ERROR;
JMPARR(gerr)default:
    printf("%% AL: illegal op '%c'\n", *pc); return ERROR;
  }
}

#endif // GENASM

// using generic fixed buffer of fixed size and char index
// generates 8 bytes instead of ... ... Saved 194 bytes
// TODO: use in more places...
unsigned char b;
char buff[250];

#define ALC(c) do { buff[b]=(c); ++b; } while(0)
#define ALW(n) do { ALC((n)&0xff); ALC(((unsigned int)n) >> 8); } while(0)

// reads lisp program s-exp from stdin
// returning atom string containing AL code
void alcompile() {
  char c, extra= 0, *nm; int n= 0; L x= 0xbeef, f;

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
    // determine function, try get a number
    //skipspc();
    f= nextc(); unc(f); // peek
    // TODO: ,..X inline lambda? or evaluate function to call
    if (f=='(') error("ALC: TODO: computed function", 0);

    x= lread();
    //printf("ALC.read fun: "); prin1(x);
    if (!isnum(x) && !isatom(x)) { prin1(x); printf(" => need EVAL: %04X ", f); prin1(f); NL; error("ALC: Need to do eval", 0); }

    if (isatom(x)) f= ATOMVAL(x);
    if (!f || !isnum(f)) { prin1(x); printf("\t=> TODO: funcall.... X ?? ATOMVAL: %04X ", f); prin1(f); NL; error("ALC: Need funcall", 0); }

    // get the byte code token
    f= NUM(f);

    if (f=='\'') goto quote;
    else if (f=='L') f= -'C'; // foldr // TODO: who gives a?
    else assert(f<255);

    if (verbose>2) { printf("\n%% compile: "); prin1(x); printf("\t=> '%c' (%d)\n\n", f, f); }
 
    // IF special => EXPR I THEN { ELSE } ' '
    if (x==IF) {
      alcompile(); ALC('I'); // EXPR I
      ALC(']'); alcompile(); ALC('{'); // DROP THEN
      ALC(']'); alcompile(); ALC('}'); // DROP ELSE
      c= skipspc();
      if (c!=')') goto expected;
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
      if (c!=')') goto expected;
      return;
    }

    // GENERIC argument compiler
    while((c=nextc())!=')') {
      ++n;
      alcompile();
      // implicit FOLDL of nargs + - L ! LOL
      if (f>0 && n>2 && f<255 && f!='R' && f!='Z') {ALC(f);--n;}
    }
    if (f>0 && f<255 && n>0) { ALC(f); n-=2; break; }

    // foldr?
    while(f<0 && --n > 0) ALC(-f); 
    if (f<255) break; // FOLD R/L

    // it's a user defined function/compiled
    assert(isatom(f)); // TODO: handle lisp/s-exp

    extra= ')';
    unc(c);
    x= 0xbeef;
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

 expected: // used twice
  error("ALC.expected ) got", c);
}

L alcompileread() {
  // use global buffer, and index b -- much less code and faster!
  memset(buff, 0, sizeof(buff));
  buff[sizeof(buff)-1]= 255; // end marker
  b= 0;
  alcompile();
  if (!b) return eof;
  if (buff[b]) return ERROR; // out of buffer TODO: fix assert in ACL
  return mkbin(buff, b+1);
}  
