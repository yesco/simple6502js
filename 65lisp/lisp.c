// 65LISP02 - an lisp interpeter for 6502 (oric)

// An highly efficent and optimized lisp for the 6502.
// It's a scheme-style lisp with full closures and
// lexical bindings. No macros.

// Features:
// - full closures
// - lexical scoping
// - highly optimized
// - 

// TODO:
// - closures
// - GC of cons cells
// - TODO: strings?
// - TODO: bignums? wrote a bignum.c

// NO WAY:
// - no macros, using NLAMBDA and DE


// IMPLEMENTION DETAILS
//
// Data Representation
//
// - iiii iiii  iiii iii0  INT : limited ints -16K to +16K 15 bits
// - cccc cccc  cccc cc11  CONS: not aligned! step 4B, 16K cons, 64K ram
// - oooo oooo  oooo o101  ATOM: constants/offset in arena up to 8K ram

// FUTURE:
//
// - pppp pppp  pppp p001  HEAP-OBJ: 8 bytes aligned (+1) total 64K

// Here is the fun: for variables sized objects:
//
// - malloc doesn't align
// - (neitehr does compiler of int[]! - can be on odd address)
// - malloc may waste memory, at least 4 bytes overhead
// - cc65 malloc(1) smallest chunk is 6 bytes, if alloc 1 adds 5

// Memory System:
//
// =  64K address
// - 256 ZeroPage
// - 256 Stack Page 1
// -  16K ROM (rest is RAM)
//           LISP PROGRAM:
// -  16K code = 7969 bytes currently, need GC, strings, bignum, etc
// - 654 RODATA
// -  26K allocated data, 26285 bytes, 1709
// 


// CHANGES
//
// - started with a reader and writer of S-EXP.
// - nil was 0, easy test, but not flexible...
// - ...0 = int was [0..32768-1-1], only positives
// - ..11 = cons required various costly arith 
// - changing cons/num represenation (big change)
//   - ...0 = int now [-16K, 16K], simple test => 25-33% FASTER!
//   - ..11 = cons, actual pointer, no arith except for CDR
//   - ..01 = atom, ok still index, maybe split to object ptr?
//   - cons-terst (actually CAR/CDR) 64s instead of 82 => 22% FASTER!

// Alterntive names:
// - 02lisp 
// Alread used names by others:
// - lisp65 lisp/8 lisp02

#include <stdint.h> // cc65 uses 29K extra memory???
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>

//#include <conio.h>

// ---------------- CONFIG

// Number of cells (2 makes a cons)
//   can't be bigger than 32K
//   should be dynamic, allocate page by page?
//   DECREASE if run out of memory. LOL
//#define MAXCELL 25*1024/2 // ~ 12K cells

//#define MAXCELL 4096*2
#define MAXCELL 4096*3
//#define MAXCELL 4096*2

// Arena len to store symbols/constants (and global ptr)
#define ARENA_LEN 1024

// Defined to use hash-table (with Arena
#define HASH 256

// ---------------- Lisp Datatypes
typedef int16_t L; // requires #include <stdint.h> uses 26K more!

// special atoms
//const L nil= 0;
//#define nil 0 // slightly faster 0.1% !
L nil= 0, T;
L error, eof, quote=0;

#define null(x) (x==nil) // crazy but this is 81s instead of 91s!
//#define null(x) (!x) // slight, faster assuming nil=0...

// Encoding of lisp values:
//
// 7654 3210  7654 3210
// ---------  ---------
// 0000 0000  0000 0000
// iiii iiii  iiii iii0 = mini-int
// cccc cccc  cccc cc11 = cons 16K index
//                   01 = -
//                 0001 = neg int
//                 0101 = allocated int
//                 0101 = atom
//                 1101 = string

// 000 0 mint ...
// 001 0
// 010 0
// 011 0   [0..32K[
// 100 0
// 101 0
// 110 0
// 111 0 ... mint

// 00 01
// 01 01
// 10 01
// 11 01 

// 00 11 = cons
// 01 11 = floats/double
// 10 11 = strings
// 11 11 = nil, atoms

// 0--32+2=       34K ints (+2048 haha!)
// 34--48 = 16-2= 14K string/atom/wfsh
// 48--64 =       16K cons cells

//       0 miniint 32K
//
//  00 0 1 -microint
//  01 0 1 *int

//  10 0 1 atom
//  11 0 1 string

//     1 1 cons

// 16 bits === 5*3

// 0 0   positive small numbers
// 0 1   cons
// 1 0   negative numbers
// 1 1   cons

// (/ 65536 4) = 16K cons max
//
// -- Cons

int ncell= 0;
//L cell[MAXCELL]= {0};
L cell[MAXCELL];
L* cnext= 0;

L prin1(L); // forward TODO: remove

// smaller!
#define terpri() putchar('\n')

// cons(1,2) gives wrong CONS values at 4092 4096-ish
// works fine up till then if have 2*4096 cells

// (* 4096 2 2)

// macro takes less code than funcall, and is faster
#define iscons(c) (((c)&3)==3)
//#define iscons(c) ((((c)&3)==1) && (c>=(L)cell) && (c<(L)(cell+MAXCELL)))
//#define iscons(c) ((((c)&3)==1) && (c>=(L)cell) && (c<(L)(cell+MAXCELL)))

// unsafe macro 10% faster,but uses 80 bytes more
// make sure it's iscons first (in loop)!
//#define CAR(c) (cell[ (c)>>2   ])
//#define CDR(c) (cell[((c)>>2)+1])
#define CAR(c) (*((L*)(c)))
#define CDR(c) (((L*)(c))[1])

L print(L x); // forward

L cons(L a, L d) {
  // remove one more... because 00001 bits...
  //assert(ncell<MAXCELL+2); // 0.4% cost

  // 4090 is fine?
  // starts failing at 4096!!! ???
  // (* 4096 2 2) 16384 bytes addressed? 32K I'd understand

  L r;
  //printf("CONS... %x\n", cnext);
  *++cnext= a;
  //printf("CAR: "); print(*cnext);

  r= (L)cnext;
  //printf("CAR: "); print(CAR(r));

  *++cnext= d;
  //printf("CDR: "); print(((L*)r)[1]);
  //printf("CDR: "); print(CDR(r));

  //printf("CONS: "); prin1(a); putchar('.'); prin1(d); terpri();
  //printf("L= %04x\n", r);
  //printf("iscons: %d %x %d\n", iscons(r), r, r);
  //printf("=>: "); print(r);
  //printf("=>: "); prin1(CAR(r)); putchar('.'); prin1(CDR(r)); terpri();
  //terpri();
  return r;

  // optimial order...
#ifdef foo
  cell[ncell]= a; ++ncell;
  cell[ncell]= d; ++ncell;
  return ((ncell-2)<<2)+3; // ENC
#endif
  // 1.2% faster!
  /// also fits better with free list? hmmm?

  // TODO: how about freelist etc?

  // TODO: what if enc of CONS == 01 ?? just add 4, no manipulation
  // TODO: what if consptrs were actual pointers w offset?
  //printf("%04x\n", cnext+1);
  assert(!(ncell&4)); // bit iii011 always zero... hmmm
  return ncell+= 8; // 1.8% faster than ncell+2 .., 2.4% faster th ptr
  //ncell+= 2; return ((ncell-2)<<2)+3; // ENC // faster! than ptr (unsafer..)
  //return ((cnext-cell-1)<<2)+3; // ENC // ptr arith cost
}

// returning nil is faster than 0! (1%)
L car(L c)         { return iscons(c)? CAR(c): nil; }
L setcar(L c, L a) { return iscons(c)? CAR(c)= a: nil; }
L cdr(L c)         { return iscons(c)? CDR(c): nil; }
L setcdr(L c, L d) { return iscons(c)? CDR(c)= d: nil; } 

// --- Atoms / Symbols / Constants
// 
// An atom is a constant string, that is interned.
// This means 'foo is always eq to 'foo .

// Operations needed on symbols:
//  - fast lookup from string => atom
//  - fast global var value: set, get
//  - FAST from atom get global val

// Options how to store:
//  a) HEAPOBJ: if stored on heap, need linked list
//  a) OFFSET:  arena of constants, store offset (resize?)
//  b) INDEX:   array of ptrs to mallocs + array of vals
//  c) HASH:    need linked list anyway...

#define MAXSYMLEN 32

#ifdef HASH
  void* syms[HASH]= {0}; // 512 bytes! + ARENA_LEN...

  char hash(char* s) {
    int c= 4711;
    // TODO: find better hash function?
    while(*s) {
      c^= (c<<3) + 3* *s++;
    }
    return c & 0xff;
  }

  // Arena - simple for now
  char arena[ARENA_LEN]= {0}, *arptr= arena, *arend= arena+ARENA_LEN;

#endif

char isatomchar(char c) {
  return (char)(int)!strchr(" \t\n\r`'\"\\()[]{}", c);
}

#define isatom(x) ((x&3)==1)

char* atomstr(L x) {
  if (!isatom(x)) return NULL;
  return arena + 4 + (x>>2); //ENC
}

// 3% cost of isatom()
#define ATOMVAL(x) (arena[2+((x)>>2)]) // ENC
//#define atomval(x) (isatom(x)?arena[2+((x)>>2)]:nil)

L atomval(L x) {
  // TODO: whcih is faster?
  // TODO: return isatom(x)? ATOMAL(x): nil;
  if (!isatom(x)) return nil;
  return ATOMVAL(x);
}

L setatomval(L x, L v) {
  if (null(x) || !isatom(x)) return nil;
  return *(L*)(arena+2+(x>>2))= v;
}

L print(L); // forward TODO: remove

#ifdef DEBUG
void printarena() {
  char* a= arena;
  printf("ARENA: ");
  while(a<arptr) {
    if (isprint(*a)) putchar(*a);
    else if (!*a) putchar('_');
    else putchar('#');
    a++;
  }
  putchar('\n');
}

// search arena, this could save next link...
void* searchatom2(char* s) {
  char* a= arena;
  a= arena;
  // TODO: more efficient
  while(*s && a<arptr) {
    if (0==strcmp(s, a+4)) return a;
    a+= 4+1+strlen(a+4); // TODO: should be 1???
  }
  return NULL;
}

// slower, lol!
void* searchatom(char* s) {
  char *a= arena, *p, *aa;
  while(a<arptr) {
    aa= a;
    a+= 4;
    p= s;
    //printf("\t%d '%s'\n", aa-arena, a);
    while(*a && *a==*p) {
      ++p; ++a;
    }
    if (!*a && *a==*p) return aa;
    while(*a) ++a;
    ++a;
  }
  return NULL;
}
#endif

// search linked list
void* findatom(char* a, char* s) {
  while(a) {
    if (0==strcmp(s, a+4)) return a;
    a= *(char**)(L**)a;
  }
  return NULL;
}

// TODO: optimize for program constants!
//   (just store \0 + pointer!)
// TODO: should use nil() test everywhere?
//   and make "nil" first atom==offset 0!
//   (however, I think increase codesize lots!)
L atom(char* s) {
  L r;
  char h, *p;
  void **pi;

  //assert(sizeof(void*)==2); // cc65, see below ptr

#ifdef HASH
  h= hash(s);
  //p= searchatom(s);  // slower 24s for 4x150.words
  //p= searchatom2(s); // slower 32s for 4x150.words
  p= findatom(syms[h], s); // fast 14s for 4x150.words
  if (!p) {
    p= arptr;
    pi= (void**)p;
    arptr+= 4+1+strlen(s);
    assert(arptr<=arend);
    // TODO: memcpy safer? other arch
    pi[0]= syms[h]; // prev ptr (maybe use offset for portability?)
    pi[1]= (void*)nil; // global val
    strcpy(p+4, s);
    syms[h]= p;
  }

  // TODO: change to actual pointer?
  r= ((p-arena)<<2)+1; // ENC
  
#endif

  return r;
}

// --- Strings

// There are two type of strings:
//  - constant strings part of program
//  - strings read and processed

// How to distinguish?
// TODO: if read-eval => "program"

// 3 % faster and smaller code
#define isstr(x) (0)

// --- Numbers

// With number just being *2 ... 
// sum 50 x 1 takes 179s instead of 137s => 39% faster
// mul 50 x 1 takes 206s instead of 253s => 18% faster
//   (if test num   sum: 186s   mul: 255s  LOL
// and save 30b code too! LOL

// macro smaller code and 10% faster
#define isnum(x) (!((x)&1))

// simple now, but can often avoid if + -, if / need/2
#define NUM(x)   ((x)/2)
#define MKNUM(n) ((n)*2)

int num(L x) {
  // TODO: one line? one return, less code?
  if (!isnum(x)) return 0; // "safe"
  return NUM(x);
}

// no need inline/macro
L mknum(int n) {
  // TODO: large numbers... bignums?
  assert(abs(n)<=16384);
  return MKNUM(n);
}


// ---------------- IO for parsing

int _nc= 0;

void unc(char c) {
  assert(!_nc); // can't do twice!
  _nc= c;
}

char nextc() {
  int r;
  if (_nc) { r= _nc; _nc= 0; } else r= getchar();
  if (r==-1) r=0;
  return r;
}

char spc() {
  char c= nextc();
  while (c && isspace(c)) c= nextc();
  return c;
}

L lread(); // forward

// read a list of type: '(' '{' '['
L lreadlist(char t) {
  L r;
  char c= spc();
  if (!c || c==')' || c=='}' || c==']') return nil;
  unc(c);
  r= lread();
  // TODO: how deep/long? make iterative, need setcdr!
  return cons(r, lreadlist(t));
}

// read anything return sexp ()={}=[] !
// TODO: maybe 1,2,3= (1 2 3) ? implicit by comma?
L lread() {
  // TODO: skip single "," for more insert nil? [1 2,3 ,, 5]
  char c= spc();
  if (!c) return eof;
  if (c=='(' || c=='{' || c=='[') return lreadlist(c);
  if (isdigit(c)) { // number
    // TODO: negative numbers... large numbers? bignum?
    int n= 0;
    while(c && isdigit(c)) {
      n= n*10 + c-'0';
      c= getchar();
    }
    unc(c);
    return mknum(n);
  }
  if (c=='|' || isatomchar(c)) { // symbol
    char q=(c=='|'), n= 0, s[MAXSYMLEN+1]= {0};
    if (q) c= nextc();
    do {
      s[n++]= c;
      c= nextc();
      // TODO: breaking chars: <spc>'"()
    } while(c && ((q && c!='|') || (!q && isatomchar(c))) && n<MAXSYMLEN);
    if (!q) unc(c);
    return atom(s);
  }
  if (c=='\'') return cons(quote, cons(lread(), nil));

  printf("%%ERROR: unexpected '%c' (%d)\n", c, c);
  return error;
}

// ---------------- 
// TODO: princ? prin1?

// print unquoted value without space before/after
L prin1(L x) {
  L i= x;
  //printf("%d=%d=%04x\n", num(x), x, x);
  if (null(x)) printf("nil");
  else if (isnum(x)) printf("%d", num(x));
  else if (isatom(x))  printf("%s", atomstr(x));
  else if (iscons(x)) { // printlist
    putchar('(');
    do {
      prin1(car(i));
      i= cdr(i);
      if (!null(i)) putchar(' ');
    } while (!null(i) && iscons(i));
    if (!null(i)) {
      printf(". ");
      prin1(i);
    }
    putchar(')');
  } else printf("LISP: Unknown data %04x\n", x);
  return x;
}

L print(L x) {
  L r= prin1(x);
  terpri();
  return r;
}


// ---------------- Variables

L assoc(L x, L l) {
  L p;
  while(iscons(l)) {
    p= CAR(l);
    if (car(p)==x) return p;
    l= CDR(l);
  }
  return nil;
}

L setval(L x, L v, L e) {
  L p= assoc(x, e);
  if (!null(p)) return setcdr(p, v);
  // TODO: optimize as assoc() call is expensive (e==nil)
  return setatomval(x, v); // GLOBAL
}

L getval(L x, L e) {
  L p= assoc(x, e);
  if (!null(p)) return cdr(p);
  // TODO: optimize as assoc() call is expensive (e==nil)
  return atomval(x); // GLOBAL
}


// ---------------- Lisp Functions

L eval(L x, L e); // forward
L apply(L f, L a, L e); // forward

L de(L args) {
  //assert(!"NIY: de");
  return error;
}

L df(L args) {
  //assert(!"NIY: df");
  return error;
}

// TODO: progn?

// tailrecursion?
L iff(L args, L env) {
  //assert(!"NIY: iff");
  return error;
}

L lambda(L args, L env) {
  return cons(args, env);
}

L evallist(L args, L env) {
  //assert(!"NIY: evallist");
  return error;
}

L evalappend(L args) {
  //assert(!"NIY: append");
  return nil;
}

L length(L a) {
  int n= 0;
  while(iscons(a)) {
    n++;
    a= CDR(a);
  }
  return mknum(n);
}

L member(L x, L l) {
  while(iscons(l))
    if (CAR(x)==x) return l;
  return l;
}

L mapcar(L f, L l) {
  return (null(l) || !iscons(l))? nil:
    cons(apply(f, CAR(l), nil), mapcar(f, CDR(l)));
}
  
// TODO: nthcdr
L nth(L n, L l) {
  n= num(n);
  while(n-- > 0) if (!iscons(l)) return nil; else l= CDR(l);
  return CAR(l);
}


// ---------------- EVAL/APPLY

L apply(L fn, L args, L env) {
  L a=2, b; // 2 used by '*' and '-' LOL
  L f= NUM(isnum(fn)? fn: ATOMVAL(fn));

  // TODO: trace
  //terpri();
  //printf("F= "); print(f);
  //printf("A= "); print(a);
  //printf("E= "); print(e);

  //printf("--> primop %c (%d) ", f, f); prin1(args); terpri();

  // 58.983 - opt/inline using num      = 8.9% FASTER!
  // 61.462 - opt/inline using atom     = 5.03% fastere
  // 63.051 - optimized using num       = 2.6% speedup
  // 64.714 - using atom no opt         = 1 === BASE
  // 65.129 - overhead w opt using atom = 0.6% slowdown
  // 65.602 - overhead primop using int, F=int
  // 67.714 - overhead primpo using int, F=atom

  // AL - Alphabetical Lisp (a byte VM)
  //
  // simple primitive function dispatcher
  
  // Based on
  // - https://github.com/yesco/parsie/blob/main/al.c

  // --- nargs
  switch(f) {
    // - nlambda - no eval
  case ':': return de(args);
  case ';': return df(args);
  case 'I': return iff(args, env);
  case 'R': return lread();
  case '\'':return car(args); // quote
  case '\\':return lambda(args, env);

    // - nargs - eval many args
  case '+': a-=2;
  case '*':
    while(iscons(args)) {
      // TODO: do we care if not number?
      b= eval(CAR(args), env);
      //if (!isnum(b)) b= 0; // takes away most of savings...
      //assert(isnum(b)); // 1% overhead
      args= CDR(args);
      //if (f=='*') a*= b; else a+= b;
      if (f=='*') a*= b/2; else a+= b;
    } return a;
  case 'L': return evallist(args, env);
  case 'H': return evalappend(args);
  }

  // --- one arg
  if (!iscons(args)) return error;
  a= eval(CAR(args), env);
  args= CDR(args);

  switch(f) {
  case '!': return isatom(a)? T: nil; // TODO: issymbol ???
  case '#': return isnum(a)? T: nil;

  case 'A': return car(a);
  case 'D': return cdr(a);
  case 'K': return iscons(a)? T: nil;
  case 'O': return length(a);
  case 'P': return print(a);
  case 'T': terpri(); return nil;
  case 'U': return a? mknum(1): nil;
  case 'W': return prin1(a);
  }


  // --- two args
  if (!iscons(args)) return error;
  b= eval(CAR(args), env);
  args= CDR(args);

  switch(f) {
  case '%': return mknum(num(a) % num(b));
  case '&': return mknum(num(a) & num(b));
  case '-': return mknum(num(a) - num(b));
  case '/': return mknum(num(a) / num(b));
  case '|': return mknum(num(a) | num(b));

  case 'C': return cons(a, b);
  case 'B': return member(a, b);
  case 'G': return assoc(a, b);
  case 'M': return mapcar(a, b);
  case 'N': return nth(a, b);

  default: return error;
  }

  // assert(!"UDF?"); // TODO:
  return error;
}

L eval(L x, L e) {
  // 56.771s if isconst first ./cons-test => 3.76% SPPEDUP
  //   2.5% slowdown for (+ (* ... old: 43.80s
  // 58.98s old way, 
  // 42.20s return x FOR (+ (* ...  => 3.7% SPEEDUP
  if (iscons(x)) return apply(car(x), cdr(x), e);
  if (isatom(x)) return getval(x, e);
  return x;
}

// ---------------- Register Functions

void regc(char* name, char n) {
  L a= atom(name);
  setatomval(a, mknum(n)); // TODO: overhead
}

void reg(char* charspacename) {
  char c= *charspacename;
  regc(charspacename+2, c);
}

// TODO: point to these from arena?
char* names[]= {
  // nargs
  ": de", ": define", ": defun",
  "; df",
  "I if",
  "R read",
  "\' quote",
  "\\ lambda",

  "* *",
  "+ +",
  "L list",
  "H append",
  
  // one arg
  "A car",
  "D cdr",
  "K consp",
  "O length",
  "P print",
  "T terpri",
  "U null",
  "W prin1",

  // two args
  "% %",
  "& &",
  "- -",
  "/ /",
  "| |",

  "C cons",
  "B member",
  "G assoc",
  "M mapcar",
  "N nth",
  NULL};

void initlisp() {
  char** s= names;

  // Align lower bits == xx01, CONS inc by 4!
  L x= (L)cell;
  while(!iscons(x)) x++;
  //printf("x   = %04x %d\n", x, x);
  cnext= (L*)x;
  cnext--;
  //printf("next= %04x\n", cnext);
  assert(x&1);

  // important assumption for cc65
  // (supress warning: error is set later, now 0)
  assert(sizeof(L)+error==2); 
  assert(sizeof(void*)+error==2); // used in atom function

  // special symbols
    nil= atom("nil");
      T= atom("T");
  quote= atom("quote");
  error= atom("ERROR");
    eof= atom("*EOF*");

  // register function names
  while(*s) {
    reg(*s);
    ++s;
  }
}

//#define PERFTEST
#ifdef PERFTEST
#include "perf-test.c"
#endif

int main(int argc, char** argv) {
  char echo= 0, noeval= 0, quiet= 0;
  int i;
  L r, x, env= nil;

  // TODO: define way to test, and measure clocks ticks
  int n= 1;

  #ifdef PERFTEST
  perftest();
  exit(1);
  #endif

  initlisp();

  // - read args
  while (--argc) {
    ++argv;
    //printf("ARG: %s\n", *argv);
    if (0==strcmp("-t", *argv)) {
      n= atoi(argv[1]);
      if (n) --argc,++argc; else n= 10000;
      echo= 1; quiet= 1;
    } else
    if (0==strcmp("-q", *argv)) quiet= 1; else
    if (0==strcmp("-E", *argv)) echo= 1; else
    if (0==strcmp("-N", *argv)) noeval= 1;
// TODO: read from memory...
//    if (0==strcmp("-e", *argv)) {
//      --argc,++argc;
//      x= lread();
//    }
  }

  //clrscr(); // in conio but linker can't find (in sim?)

  // set some for test
  setval(atom("bar"), mknum(33), nil);
  env= cons(cons(atom("foo"), mknum(42)), env);

  if (!quiet)
    printf("65LISP>02 (>) 2024 Jonas S Karlsson, jsk@yesco.org\n");

  do {
    if (!quiet) printf("65> ");
    x= lread();
    if (x==eof) break;
    if (echo) printf("\n> "),print(x);
    if (!noeval) {
      for(i=n; i>0; --i) // run n tests
        r= eval(x, env);
      print(r); terpri();
    }
  } while (!feof(stdin));
  if (!quiet) terpri();

  //{clock_t x= clock(); } // TODO: only on machine?
  return 0;
}

// ENDWCOUNT
