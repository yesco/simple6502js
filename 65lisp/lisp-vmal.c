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

// For each user/machine code function call we recurse
// The function need to know how many parameters from the
// stack it uses, and it needs to clear that up!

#ifdef GENASM
extern L runal(char* la) {
#else
extern L runal(char* la) {
#endif

  char n=0;
#ifndef JMPARR
  static void* jmp[127]= {(void*)(int*)42,0};
#endif

  char* orig= la; // global 10% faster
  pc= la;

#ifndef JMPARR
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
    //jmp[':']=&&gsetq;
    jmp[';']=&&gsemis;
    
    jmp['I']=&&gif; jmp['{']==&&gelse; jmp['}']==&&gendif;

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

  // cut from here 

 call:
  --pc; // as pre-inc is faster in the loop

  if (verbose>2) printf("FRAME =%04X\n", frame);

 next:
  //assert(s<send);
  // cost: 13.50s from 13.11s... (/ 13.50 13.11) => 3%

  if (verbose>1) { printf("%02d:al %c : ", pc-orig+1, pc[1]); prin1(top); NL; }

  // caaadrr x5K => 17.01s ! GOTO*jmp[] is faster than function call and switch

// inline this and it costs 33 byters extra per time... 50 ops= 1650 bytes... 

#define NNEXT NOPS(++nops;);c=*++pc;goto *jmp[c]

//#undef NNEXT
//#define NNEXT goto next

  //NOPS(++nops;);c=*++pc;goto *jmp[c];
  NNEXT;

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

// TODO: replace by jmps? This doesn't nest, lol
JMPARR(gif)   case 'I': if (null(top)) while(*pc!='{') ++pc;  goto next;
JMPARR(gelse) case '{': while(*pc!='}') ++pc; goto next;
JMPARR(gendif)case '}': goto next;

  // single digit, small number, very compact (27.19s, is faster than isdigit in default)
JMPARR(gdigit)case '0':case'1':case'2':case'3':case'4':case'5':case'6':case'7':case'8'://case'9':
    *++s= top; top= MKNUM(*pc-'0'); goto next;

// TODO: does this stay the same?
JMPARR(gret)case'^': return top;
JMPARR(g0)case 0:
    if (verbose) { printf("\n\nRETURN="); prin1(top); NL; }
    return top; // all functions should end with ^ ?


// --- Recursion, TailCall, Iterate, Function Call
JMPARR(grec)case'R': if (pc[1]!='^') {
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
    *s++= top; top= frame[*pc-'a']; goto next;

// 26.82s
//  default : ++s; *s= MKNUM(*p-'0'); NEXT; 

// 30.45s
//  default : if (isdigit(*pc)) { ++s; *s= MKNUM(*pc-'0'); NEXT; }
//   printf("%% AL: illegal op '%c'\n", *pc); return ERROR;
JMPARR(gerr)default:
    printf("%% AL: illegal op '%c'\n", *pc); return ERROR;
  }

}

L al(char* la) {
  top= nil;
  s= stack-1;
  frame= s;

  // TODO: remove?
  // pretend we have some local vars (we've no been invoked yet)
  frame= s;
  top= MKNUM(8); // a (last parameter)

  top= *s;

  // HHMMMM>?
  if (!pc) return ERROR;

  return runal(la);
}

#endif // GENASM



// using generic fixed buffer of fixed size and char index
// generates 8 bytes instead of ... ... Saved 194 bytes
// TODO: use in more places...
unsigned char b;
char buff[250];

#define ALC(c) do { buff[b]=(c); ++b; } while(0)
#define ALW(n) do { c= (n)&0xff; ALC(c); c= ((unsigned int)n) >> 8; ALC(c); } while(0)

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
    if (f=='(') error("ALC: TODO: computed function");

    x= lread();
    //printf("ALC.read fun: "); prin1(x);
    if (!isnum(x) && !isatom(x)) { prin1(x); printf(" => need EVAL: %04X ", f); prin1(f); NL; error("ALC: Need to do eval"); }

    if (isatom(x)) f= ATOMVAL(x);
    if (!f || !isnum(f)) { prin1(x); printf("\t=> TODO: funcall.... X ?? ATOMVAL: %04X ", f); prin1(f); NL; error("ALC: Need funcall"); }

    // get the byte code token
    f= NUM(f);

    if (f=='\'') goto quote;
    else if (f=='L') f= -'C'; // foldr // TODO: who gives a?
    else assert(f<255);
    // TODO: how to handle non-foldable arguemnts
    //   TODO: look at number of arguments the function expects? if n>2

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
  error1("ALC.expected ) got", c);
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
