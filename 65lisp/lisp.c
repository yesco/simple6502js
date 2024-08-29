// 65LISP02 - an lisp interpeter for 6502 (oric)

// An highly efficent and optimized lisp for the 6502.
// 
// Written using in C using CC65 it has readable source
// but performance may suffer compared to a hand-written
// lisp in assembly... (not too many of them, though).
//
// 65LISP is a scheme-style lisp with full closures and
// lexical bindings. No macros.

// FEATURES
// - highly optimized (for being in CC65)
// - int15:   efficient inline in pointer, minimal overhead
// - atoms:   foo bar fie\ fum |fish crap| fie\nfush
// - conss:   (cons 1 2) TODO: (cons 1 . 2)
// - strings: "foo" "bar fie" "fish\ngurka"
// - dec28:   TODO: int: [0,2^20[ 
//            TODO: dec: +- [0,999999ish] E +- [0,125]
//                  NaN, -inf, +inf
// - lexical scoping
// - full closures
// - TODO: tail-recursion using "immediates"
// - no funcall => use ('f ...) instead (see EVAL)
// - \A gives ascii-code in reader
// - ({[]}) it doesn't care which char, only need to match, all gives list
//   TODO: {} - could give assoc-list, [] - could give vector
// - code ; comement
// - |atom with spaces| - basically a constant string
// - (+ 1 2 3 (* 4 5 6)) - vararg

// FUNCTIONS
//
// - math:  + - * / %   & | ^   = cmp
// - test:  null atomp numberp consp
// - list:  cons car cdr consp list length assoc member mapcar(TODO) nth
// - I/O:   print (prin1) terpri read prinx
// - atoms: foo |with space| cmp

// NO WAY:
// - no macros, using NLAMBDA and DE!

// EVAL
//
// Eval is the main function of a lisp.
//
// - Constants
//
// 35 nil T ERROR *EOF* (lambda ...)
//   -> all those evaluates to themselves
//      (the symbols are set to themselves)
//
// - primtive ops
//
// They are all listed above in the Functions: section
// Only + - and list are varargs
// 
// - evaluate function fixpoint
//
// The CAR, the first argument, the function to call,
// is evaluated *until* it's a NUMBER or a LAMBDA.
// If it reaches an fixpoint, as in that same value
// is repated at last, like (nil 3 4). Then the
// evaluation is aborted with an error.
//
// (+ 3 4) ('+ 3 4) (\+ 3 4) (43 3 4) ((+ 42 1) 3 4)
//   -> 7 7 7 7 7
//
// In each of the cases the CAR (and subvalues) evaluates:
//    0       2         1        0        3   times
//
// -- A number is the ALphabetical Lisp's byte code
//
// Once a number is reached the function is dispatched.
//
//   > +
//   43     ; actuall the ASCII of '+'
//   > \A
//   43
//
// We can then call the function by the byte code:
// 
//   > (+ 3 4)
//   7
//   > (43 3 4)
//   7

// -- Indirection to other names:
//
// (setq foo 'bar) (setq bar '+) ('foo 3 4)
//
// -- If we

// FUNCALL problem
//
// The number is a Alphabetical Lisp byte code.
// It's actually the character '+', in ASCII.
// See the lisp.c source code in the EVAL functions for docs.
//
// Now, consider:
//
//    ((lambda (car c) (car c)) cdr (cons 42 666))
//
// This function; does it return 42 or 666?
//
// As implied: 42. As 666 is bad ;) .
//
// Hey, wait? What?
//
// It looks scheme-style without the FUNCALL.
//
// 6502 is quite a weak machine, to squeeze the last cycles out of
// it, and the CC65 C Compiler, this is a common optimization of an
// LISP 2, as COMMON LISPs..
//
// It means any function call assumes you're calling global functions.
// This avoids the costly searching local environment.
//
// In COMMON LISP you'd write:
//
//    ((lambda (car c) (funcall car c)) cdr (cons 666 42))
//
// which is ugly
//
// Instead in 65LISP we do the following.
//
//    ((lambda (car c) ('car c)) cdr (cons 666 42))
//
// 

// TODO:
// - closures
// - GC of cons cells
// - Functions: getc putc setcar setcdr recons
// - strings?
// - bignums? wrote a bignum.c use as strings/vector?
// - ORIC functions, like graphics/5 byte floats?


// IMPLEMENTION DETAILS
//
// Data Representation

// - iiii iiii  iiii iii0  INT : limited ints -16K to +16K 15 bits
// - cccc cccc  cccc cc11  CONS: actual ptr, step 4B, 16K cons, 64K ram
// - oooo oooo  oooo o101  ATOM: actual ptr, const into ARENA of 1K

// FUTURE:
//
// - pppp pppp  pppp p001  HEAP-OBJ: 8 bytes aligned (+1) total 64K
//                  however, requires atoms to do this too
//                  waste avg 4 bytes per atom/alloc

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

void startprogram() {}
char firstvar= 42;
char firstbss;


#include <stdint.h> // cc65 uses 29K extra memory???
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include <setjmp.h>

//#include <conio.h>

// +2376 bytes! (a little much?)
//#define BIGMAX 100

#ifdef BIGMAX
  #include "bignum.c"
#endif // BIGMAX

//#define DEBUG(x) do{if(debug)x;}while(0)
#define DEBUG(x) 
#define TRACE(x)

// comment to enable EVAL TRACE
#define ETRACE(x) ;


// ---------------- CONFIG

// Number of cells (2 makes a cons)
//   can't be bigger than 32K
//   should be dynamic, allocate page by page?
//   DECREASE if run out of memory. LOL
//#define MAXCELL 25*1024/2 // ~ 12K cells

#define MAXCELL 8192*2

// Arena len to store symbols/constants (and global ptr)
#define ARENA_LEN 2048

// Defined to use hash-table (with Arena
// must be power of two!

//#define HASH 128
//#define HASH 256 // erh number of atoms => 137
//#define HASH 64 //            noatoms => 170 ???
#define HASH 32 //           blocked?
//#define HASH 1

// max length of atom and constant strings
#define MAXSYMLEN 32

// --- Statisticss
unsigned int natoms= 0, ncons=0, nalloc= 0, neval= 0, nmark= 0;

int debug= 0, verbose= 1;

void* zalloc(size_t n) {
  nalloc+= n;
  return calloc(n, 1);
}


// ---------------- Lisp Datatypes

typedef int16_t L;
typedef uint16_t uint;

// special atoms
//const L nil= 0;
//#define nil 0 // slightly faster 0.1% !
L nil, T, FREE, ERROR, eof, lambda, closure, quote= 0;

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

unsigned int ncell= 0;
L *cell, *cnext, *cstart, *cend;

L prin1(L); // forward TODO: remove

// smaller!
#define terpri() putchar('\n')
#define NL terpri()

// Type number to identify Heap OBJ
#define HFREE  0xFE
#define HATOM  0xA7
#define HARRAY 0xA6
#define HSLICE 0x51 // do you get it? ;-)

// TODO: not happy, too much code add 550 bytes!?


// --- ERROR

jmp_buf toploop= {0};

void error(char* msg, L a);

#define HTYP(x) (*((char*)(((L)x)-1)))

//#define HEAP
#ifdef HEAP
// ---------------- HEAP
// TODO: Too much code === 550 bytes!!!!
//
// Heap of various variable size data for lisp types.

// The OBJ are linked for use by mark() during GC.
// Code needs to be added per type to the
// mark() and sweep().
//
// Use 

#define isobj(x) (((x)&0x03)==1)

typedef struct OBJ {
  // We put twolisp values first, this makes it
  // safe to use CAR/CDR on the pointer
  L info; // CAR: a link to used other lisp val
  struct OBJ* next; // CDR: enumeration of all OBJ for GC marking
  struct OBJ* prev; // to be able to unlink it from list :-(
  void* origptr; // for free! :-(
  char data[];
} OBJ;

OBJ* objList= NULL;

// similar to isatom, actually atom is "subtype"
// but little special.

// Test if x lisp value is a OBJ of TYP.
// 
// If TYP is 0, then test not HFREE
// This function is expensive, so last test?
// if typ==0 return 
char isTyp(L x, char typ) {
  if (!isobj(x)) return 0;
  return typ? HTYP(x)==typ: HTYP(x)!= HFREE;
}

OBJ* newObj(char typ, void* s, size_t z) {
  // We add 4 bytes, one extra for type, and 3 to align
  // If this is considered wasteful: don't use for small!
  char *orig= (char*)malloc(z+sizeof(OBJ)+4), *p= orig;
  OBJ *prev= objList, *o;

  // Prepend at least one type byte
  do {
    *p++= typ;
    // align to 0x01
  } while(!isobj((L)p));

  o= (OBJ*)p;
  o->origptr= orig;
  o->info= nil;

  // Hook it up
  o->prev= NULL;
  o->next= objList;
  if (objList) {
    assert(objList->prev);
    objList->prev= o;
  }
  
  memcpy(o->data, s, z);
  
  return o;
}

void forgetObj(L x) {
  // TODO: verify valid obj?

  // Unlink
  OBJ *o= (OBJ*)x;
  if (o->prev) o->prev->next= o->next;
  if (o->next) o->next->prev= o->prev;
  o->next= NULL;
  o->prev= NULL;

  HTYP(x)= HFREE;
}

#endif // HEAP


//
// cons(1,2) gives wrong CONS values at 4092 4096-ish
// works fine up till then if have 2*4096 cells

// (* 4096 2 2)

#define iscons(c) (((c)&3)==3)

// unsafe macro 10% faster,but uses 80 bytes more
// make sure it's iscons first (in loop)!
#define CAR(c) (*((L*)(c)))
#define CDR(c) (((L*)(c))[1])

L print(L x); // forward

L cons(L a, L d) {
  L r;
  //if (cnext+1 < cend) { // 10% extra cost
  if (ncell>0) { // slightly faster

    // TODO: use only one?
    ++ncons;
    ncell-= 2;

    *++cnext= a;
    r= (L)cnext; // misalign it to where CAR was stored
    *++cnext= d;
    DEBUG(printf("CONS: "); prin1(r); NL);
    return r;
  }

  error("Run out of conses", nil);
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

typedef struct Atom {
  // TODO: move val to first pos...
  // - val first saves 40 bytes code
  // - but not faster, 0.01% slower...?
  // echo "foo" | ./run -t ==> 0.01% faster LOL
  L val;
  struct Atom* next;
  char name[];
} Atom;

L* syms;

char hash(char* s) {
  int c= 4711;
  // TODO: find better hash function?
  while(*s) {
    c^= (c<<3) + 3* *s++;
  }
  return c & 0xff;
}

// Arena - simple for now
char* arena, *arptr, *arend;

char isatomchar(char c) { //test for non-chars
  return (char)(int)!strchr(" \t\n\r.;`'\"()[]{}", c);
}

//  57 bytes extra for ptr % 3 ==  01
// 141 bytes extra for ptr % 7 == 101

#define isatom(x) (((x)&3)==1) 
//#define isatom(x) (((x)&7)==(4+1)) // HEAP align 101

#define ATOMSTR(a) (((Atom*)a)->name)
#define ATOMVAL(x) (((Atom*)x)->val)

// no faster? but 10 bytes less code... lol
//#define atomval(x) (isatom(x)? ATOMVAL(x): nil)

L atomval(L x) {
  return !isatom(x)? nil: ATOMVAL(x);
}

L setatomval(L x, L v) {
  if (null(x) || !isatom(x)) return nil;
  return ATOMVAL(x)= v;
}

#define PRINTARENA() ;
#ifndef PRINTARENA
  #define PRINTARENA printarena

void printarena() {
  
  char* a= arena;
  printf("ARENA: ");
  while(a<arptr) {
    if (*a==HATOM) NL;
    if (*a==' ') printf("_  ");
    else if (*a>' ' && *a<127) printf(" %c ", *a);
    else printf("%X%X ", (*a)>>4, (*a)&0xf);
    ++a;
  }
  putchar('\n');
}

// search arena, this could save next link...
// TODO: won't work, as aligned ptr now
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
// TODO: won't work, as aligned ptr now
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
#endif // PRINTARENA

// search linked list
Atom* findatom(Atom* a, char* s, unsigned char typ) {
  while(a && (L)a!=nil) { // LOL
    if (HTYP(a)==typ && 0==strcmp(s, a->name)) return a;
    a= a->next;
  }
  return NULL;
}

// TODO: optimize for program constants!
//   (just store \0 + pointer!)
// TODO: should use nil() test everywhere?
//   and make "nil" first atom==offset 0!
//   (however, I think increase codesize lots!)
//
// Looks up an atom of NAME and returns it
// 
// If already exists, return that
// Otherwise create it.
//
// TYP: use this type code to match and create
// (This means an ATOM and "ATOM" could both exist)
L atomstr(char* s, unsigned char typ) {
  char h;
  Atom *a;

  h= hash(s) & (HASH-1);
  //p= searchatom(s);  // slower 24s for 4x150.words
  //p= searchatom2(s); // slower 32s for 4x150.words
  a= findatom((Atom*)syms[h], s, typ); // fast 14s for 4x150.words
  if (!a) {
    // create atom
    ++natoms;

    // WHATIF: heap object x01, point at attr value
    //    char type;
    // -> L val;

    // put type byte "before" pointer
    do {
      *arptr++= typ; // HTYP
      // align as: not cons: == x01
      //   (filling with extra type info, lol)
    } while (!isatom((int)arptr));

    a= (Atom*)arptr;
    arptr+= sizeof(Atom)+strlen(s)+1;
    // TODO: better test? LOL this crashes
    assert(arptr<=arend);

    a->val= nil;               // CAR
    a->next= (Atom*)(syms[h]); // CDR
    strcpy(a->name, s);
    syms[h]= (L)a;
  }

  // -- but 120 bytes more storage used
  // 41.47s ret actual pointer FASTER: 5.2%, BYTES; -120b !!
  // 43.75s returning complex index
  return (L)a;
}

// TODO: measure code size overhead?L
L atom(char* s) { return atomstr(s, 0xA7); }

// --- Strings

// There are two type of strings:
//  - constant strings part of program
//  - strings read and processed

// How to distinguish?
// TODO: if read-eval => "program"

#define ISSTR(x) (isatom(x)&&HTYP(x)==0x57)
#define isstr(x) ISSTR(x) // unsafe

// TODO: measure code size overhead?
L mkstr(char* s) { return atomstr(s, 0x57); }

// --- Numbers

// With number just being *2 ... 
// sum 50 x 1 takes 179s instead of 137s => 39% faster
// mul 50 x 1 takes 206s instead of 253s => 18% faster
//   (if test num   sum: 186s   mul: 255s  LOL
// and save 30b code too! LOL

// macro smaller code and 10% faster than C function
#define notisnum(x) ((x)&1)      // faster
#define isnum(x) (!notisnum(x))

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
  if(abs(n)>16382) {
    printf("\n%% ERROR: too big num: %d\n", n);
    return ERROR;
  }

  return MKNUM(n);
}


// ---------------- GC Garbage Collector
// just do a simple mark and sweep

// one bit per cell[]
char* cused;

#define BIT(arr, n) (((arr)[(n)/8])&(1<<((n)&7)))

char gcdeep= 0;

void printmap() {
  int n, i; char b;
  L *a= cstart;
  printf("\nUSED: ");
  do {
    // TODO: measure cost of extra vars?
    n= a-cstart, i= n/8;
    b= 1<<(n&7);

    printf("%d", !!(cused[i] & b));
  } while (++a <= cnext+2);
  printf("\n");
}

void mark(L a) {
  // TODO: BUG: somehow, 42 doesn't get marked. It's the CDR
  // yeah, it's on a non cons address, but the addition
  // below below should handle it?

  //if (isatom(a)) return; // this deletes 42...
  // TODO: but somehow last nil in env get's replaced by *FREE*
  if (null(a)) return;
  if (isnum(a)) return;

  DEBUG(printf("\n=>MARK: %d ", ((L*)a)-cstart); prin1(a); NL);

  ++nmark;
  if (iscons(a)) {
    // TODO: measure cost of extra vars?
    unsigned int n= ((L*)a)-cstart, i= n/8;
    char b= 1<<(n&7);
    if (cused[i] & b) { DEBUG(printf(" [used %d %d] ", i, b)); return; }

    // TODO: what's the maxdepth? check w stack option
    //   then, limit it, but link to "next" TODO...
    //if (BIT(cused, n)) return;

    ++gcdeep;
    DEBUG(printf(" [%d/MARK: %d]", gcdeep, n); princ(a); putchar(' '));
    // TODO: need to pass address?
    mark(CAR(a)); //mark(CDR(a)); // hmmm
    mark(a+2); // hmmm
    --gcdeep;

    cused[n/8]|= (1<<(n&7));
    return;
  }

  // <= cnext is important! lol (for CDR)
  if (((L*)a)>=cstart && ((L*)a) <= cnext) {
    // TODO: measure cost of extra vars?
    unsigned int n= ((L*)a)-cstart, i= n/8;
    char b= 1<<(n&7);
    if (cused[i] & b) { printf(" [used %d %d] ", i, b); return; }
    DEBUG(printf(" [%d/mark: %d]", gcdeep, n); princ(a); putchar(' '))
    cused[n/8]|= (1<<(n&7));
  }

  // TODO: strings, or anything heap allocated reclaimable
}

void sweep() {
  unsigned int n, i;
  char b;
  L *a= cstart-1, *cend= cstart+MAXCELL;
  DEBUG(printf("\n-->sweep\n"));
  DEBUG(printmap());
  do {
    // TODO: measure cost of extra vars?
    n= a-cstart, i= n/8;
    b= 1<<(n&7);

    //printf("%04x %d= ", a, a-cstart); print(*a);

    if (!(cused[i] & b)) {

      // FREE:
      DEBUG(printf("UNUSED[%d]= ", a-cstart); prin1(*a); NL);

      // TODO: freelist

      // TODO: what if free CDR but not CAR? 
      // TODO: test

      *a= FREE;
    }

  } while (++a <= cnext+2);
  DEBUG(printf("--sweep\n"));
}

void GC(L env, L alvals) {
  int i;
  Atom* a;
  // TODO: anything on the stack if called deeply is problem!!!
  //   (worst case not marked and then deallocated => corruption)

  // -- clear
  memset(cused, 0, MAXCELL/(sizeof(L)*8));

  // -- enumerate all variables in program, like env
  mark(env);
  mark(alvals);

  // -- walk through all globals, in symbols table
  for(i=0; i<HASH; ++i) {
    a= (Atom*)syms[i];
    while(a) {
      mark(a->val);
      a= a->next;
    }
  }

  // -- free some
  sweep();

  //if (!quiet)
  DEBUG(NL);
}


// ---------------- IO for parsing

// next character, buffer for unc()
int _nc= 0;

// read from string
char* _rs= 0;

// ungetc
void unc(char c) {
  assert(!_nc); // can't do twice!
  _nc= c;
}

char nextc() {
  int r;
  if (_nc) { r= _nc; _nc= 0; }
  else if (_rs) { r= *_rs; if (r) ++_rs; }
  else r= getchar();

  return r>=0? r: 0;
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
  char c= spc(), q= 0;
  if (!c) return eof;
  if (c=='(' || c=='{' || c=='[') return lreadlist(c);
  if (isdigit(c)) { // number
    // TODO: negative numbers... large numbers? bignum?
    int n= 0;
    while(c && isdigit(c)) {
      n= n*10 + c-'0';
      c= nextc();
    }
    unc(c);
    return mknum(n);
  }
// Need bigger nums as address
// But this crashes!
#ifdef HEX
  if (c=='#') { // read hex
    int n= 0;
    c= nextc();
    c= nextc();
    while(isxdigit(c)) {
      c= toupper(c);
      if (c>='A') c= c-'A'+10;
      n= n*16 + c;
    }
    unc(c);
    return n; }
  }
#endif // HEX
  if (c=='\\') return MKNUM(nextc()); // \A before
  q= (c=='|' || c=='"')? c: 0;
  if (q || isatomchar(c)) { // symbol/stringconst
    // TODO: handle larger string const?
    char n= 0, s[MAXSYMLEN+1]= {0};
    if (q) c= nextc();
    do {
      // TODO: handle \t \n \r \e \007 ???
      if (c=='\\') { char *s;
        c= nextc();
        s= strchr("t\tn\nr\re", c);
        c= s? s[1]: c;
      }
      s[n]= c; ++n;
      c= nextc();
      // TODO: breaking chars: <spc>'"()
    } while(c && ((q && c!=q) || (!q && isatomchar(c))) && n<MAXSYMLEN);
    if (!q) unc(c);
    return q=='"'? mkstr(s): atom(s);
  }
  if (c=='\'') return cons(quote, cons(lread(), nil));
  if (c==';') { while((c=nextc()) && c!='\n' && c!='\r'); return lread(); }

  printf("%%ERROR: unexpected '%c' (%d)\n", c, c);
  return ERROR;
}

// Read from string, gives *EOF* internally until pointer reset;
L lreads(char* x) {
  char* saved= _rs; L r; // could be recursive?
  _rs= x; r= lread();
  _rs= saved;
  return r;
}

// print unquoted value without space before/after
//   no quotes for strings, except inside list? hmmm
L princ(L x) {
  L i= x;
  //printf("%d=%d=%04x\n", num(x), x, x);
  if (null(x)) printf("nil");
  else if (isnum(x)) printf("%d", num(x));
  //TODO: printatom as |foo bar| isn't written readable...
  else if (isatom(x)) printf("%s", ATOMSTR(x));
  else if (iscons(x)) { // printlist
    putchar('(');
    do {
      princ(car(i));
      i= cdr(i);
      if (!null(i)) putchar(' ');
    } while (!null(i) && iscons(i));
    if (!null(i)) {
      printf(". ");
      princ(i);
    }
    putchar(')');
  } else printf("LISP: Unknown data %04x\n", x);
  return x;
}

// TODO: supposed to print in readable format:
//   quote strings, and |atom w spaces|
L prin1(L x) {
  L r; char str= isstr(x);
  if (str) putchar('"');
  r= princ(x);
  if (str) putchar('"');
  return r;
}

//void prinx(L x) { printf("#%04u", (num)x); } 

// LOL: emacs-lisp does "\n$x\n" !!!
L print(L x) {
  NL; // lol,always though it was after..
  return prin1(x);
}

#define PRINTARRAY(a,b,c,d) ; 
#ifndef PRINTARRAY
  #define PRINTARRAY printarray

void printarray(L* arr, int n, char printnil, char ishash) {
  int i;
  // just print symbols per slot
  for(i=0; i<n; ++i) {
    L a= arr[i];
    if (!printnil && (a==nil || !a)) continue;
    printf("\n%2d: ", i);
    while (a && a!=nil) {
      princ(a); putchar(' ');
      if (!ishash) break;
      a= (L)(((Atom*)a)->next);
    }
  }
  NL;
}
#endif // PRINTARRAY

// TODO: instead of a "format" do my own "printf"

// Printf like unix but for lisp objects
//   %L - use princ for value
//   %Q - use prin1 for value (quote strings/atoms)
//   %F - flatten TODO: don't print () of list
// Returns a list of objects
void lprintf(char* f, L a) {
  L x;
  do {
    while(*f && *f!='%') putchar(*f++);
    if (!*f) break;
    if (null(a)) continue; // ran out of args, print rest
    else { // got % arg
      char fmt[10]={0}, *p= fmt, *e= f;
      // find end
      while(*e && !strchr("diouxXeEcsp", *e)) *p= *e++;
      x= car(a); a= cdr(a);
      if (e-f==1 || (e[-1]=='L')) princ(x); // %L
      if (e-f==1 || (e[-1]=='Q')) prin1(x); // %Q
      else printf(fmt, x); // dispatch to system
    }
  } while (1);
}

void error(char* msg, L a) {
  printf("%%ERROR: %s - ", msg);
  prin1(a); NL;
  if (toploop) longjmp(toploop, 1);
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
  L p= e? assoc(x, e): nil;
  //printf("SETVAL: "); prin1(x); putchar(' '); prin1(v); NL;
  if (!null(p)) return setcdr(p, v);
  // TODO: optimize? as assoc() call is expensive (e==nil)
  return setatomval(x, v); // GLOBAL
}

// TODO: get rid of?
// only should be used in eval?
//
// might as well use eval(x, e) !!!

#ifdef notused
// inlined in eval, just eval atom X instead?
L getval(L x, L e) {
//  L p;
  L p= assoc(x, e);
  return null(p)? atomval(x): cdr(p);

#ifdef foo
  // inline assoc (/ 5.29 6.21) => 14.8% faster
  while(iscons(e)) {
    p= CAR(e);
    if (car(p)==x) break;
    e= CDR(e);
  }

  return iscons(e)? cdr(p): atomval(x);
#endif // foo
}
#endif // notused

// ---------------- Lisp Functions

// ETRACE

#ifndef ETRACE
  #define ETRACERUN
  #define ETRACE(x) do { x; } while(0)
  #define eval(a,b) evalTrace(a,b)
int ind= 0;
void indent() {
  int i;
  for(i=ind;i;--i)printf("  ");
}

L eval(L,L);
#else
L evalX(L,L);
  #define eval(a,b) evalX(a,b)
  #define indent() ;
#endif // ETRACE

//L apply(L f, L a, L e); // forward

L de(L args) {
  //assert(!"NIY: de");
  return args?ERROR:ERROR;
}

L df(L args) {
  //assert(!"NIY: df");
  return args?ERROR:ERROR;
}

// TODO: progn?

// tailrecursion?
L iff(L args, L env) {
  if (null(eval(car(args), env)))
    return eval(car(cdr(cdr(args))),env);
  else
    return eval(car(cdr(args)),env);
}

L evallist(L args, L env) {
  return iscons(args)? cons(eval(CAR(args),env), evallist(CDR(args),env)): nil;
}

L evalappend(L args) {
  //assert(!"NIY: append");
  return args?ERROR:ERROR;
}

L length(L a) {
  int n= 0;
  while(iscons(a)) {
    ++n;
    a= CDR(a);
  }
  return mknum(n);
}

L member(L x, L l) {
  while(iscons(l)) if (CAR(x)==x) return l;
  return l;
}

L mapcar(L f, L l) {
  return f&&l&&l?ERROR:ERROR;
// TODO: lol, how to do without apply?
//  return (null(l) || !iscons(l))? nil:
//    cons(apply(f, CAR(l), nil), mapcar(f, CDR(l)));
}
  
// TODO: nthcdr
L nth(L n, L l) {
  n= num(n);
  while(--n >= 0) if (!iscons(l)) return nil; else l= CDR(l);
  return CAR(l);
}


// ---------------- EVAL/APPLY

// TODO: no apply function anymore? lol
//return apply(car(x), cdr(x), env);

// TODO: remove?
#define islambda(x) (iscons(x)&&(car(x)==lambda))

typedef L (*FUN1)(L);
typedef L (*FUN2)(L,L);

// TODO: inline, safe many function calls!
L bindevlist(L fargs, L args, L env, L evalenv) {
  if (null(fargs)) return env;
  // TODO: fargs= (foo . bar) == &rest
  return cons( cons(car(fargs),eval(car(args),evalenv)),
               bindevlist(cdr(fargs), cdr(args), env, evalenv) );
}

L evalX(L x, L env) {
  ++neval;
  // other: 42.20s return x FOR (+ (* ...  => 3.7% SPEEDUP
  
  // TOTAL 38% improvemnts by inliniing apply... LOL

  // 41.54s cons-test remove fn reuse f, init a later!
  // 42.03s cons-test REMOVING "args" var, reuse X!
  // 49.73s cons-test if inline apply in eval  (how to do apply?) - not pick... because:
  //   but numbers slowdown... 10% MORE
  // 51.07s NUMCALL if use local var inside iscons => 10% FASTER
  //   ./plus-test is slightly faster 3%    8.4% for (*(+
  // 53.584 ATOMCALL but w opt for number in
  // 56.771s if isconst first ./cons-test => 3.76% SPPEDUP
  //   2.5% slowdown for (+ (* ... old: 43.80s
  // ===BASE===
  // 58.98s old way, lookup atom

  TRACE(printf("EVAL: "); prin1(x); NL);

  if (iscons(x)) {
    L f, a, b;
    //b= x;
    f= CAR(x);
    // 0.2% cost (* (+ but LAMBDA time/2 !
    if (f==lambda) return cons(closure, cons(CDR(x), env));
    // TODO: needed?
    if (f==closure) return x;

    // TODO: bad assumption it's an ATOM, lambda?
    //f= NUM(eval(f, env)); double time!
    // TODO: CHEAT! bad assumption it's an ATOM, lambda?

    // first assume it's a global function
    if (isatom(f)) f= ATOMVAL(f);

//           OLD     NEW      ORG   ORG/NUM
// ./lambda 41.20s  41.92s   65.73  !!!!!!!
// ./plus   43.76s  43.785s  43.56 
// ./cons-t 49.22s  51.10s   48.77s 49.79s (using addr)
//            ^--------^-------^---- uses car/cdr addr
//   num    49.92   52.25    49.86s no-addr for car/cdr
//   name   53.31   55.67    53.30s lookup name->num
//
// two arg calling
//  CONS    27.56   27.59    45.82s (cons 1 2)x8000
//            addr: 
// CONCLUSION: faster:  name/addr << num << name/num
//    ORIG was slower for lambda

// moved OLD down
//   addr   49.18
//   num    50.02
//   name   53.31   
//        fun=addr for cons   ^-----(bytecode)
//          
//   WHY IS OLD FASTER?????
//
#define OLD 
#ifdef OLD
    x= CDR(x);
#endif

    // 5% slower for ./cons-test even if number
    // TODO: why is the non-entered loop costly?
    // ----------------- no loop, no isatom      43.95s, 42.09s BEFORE
    //while(!isnum(f)) { // merry go-around?     45.03s, 44.22s
    //while((f&1)==1) { // merry go-around?       44.20s, 43.38s  

    // slowdown:     (/ 44.13 43.95) = 0.4%  (/ 43.31 42.09) = 2.9%
    // Fine for doing the right thing!
    // TODO: +1KB CODE though - see if can minimize bytes???
    // merry go-around?         44.13s, 43.31s - acceptable
    while(notisnum(f)) {
      ETRACE(printf("f= "); prin1(f); NL);

      // follow chain of atoms => "local" or global value
      while(isatom(f)) {
        ETRACE(printf("ATOM again: "); prin1(f); NL);
        a= f; // avoid self loop nil/T etc
        f= ATOMVAL(f);
        if (isnum(f)) break;
        if (f==a) error("eval.loop", a);
      }
      if (null(f)) error("nofunc", a);

      // evaluate any cons until it's not...
      // lambda 66s => 37s by reordering tests!
      while(iscons(f) && CAR(f)!=closure) {
        ETRACE(printf("EVAL again: "); prin1(f); NL);
        a= f; // avoid self loop
        f= eval(f, env);
        if (isnum(f)) break;
        if (f==a) error("eval.loop", a); // can happen?
      }
      if (null(f)) error("nofunc", a);

      // TODO: really needed? or put limit on it?
      if (isatom(f)) continue;

      // A closure let's APPLY
      if (CAR(f)==closure) {
        ETRACE(printf("CLOSURE: "); prin1(f); NL);
        // APPLY
        f= CDR(f); // now contains (((n) (+ n n)) ENV)
        ETRACE(printf("FARGS: "); prin1(CAR(CAR(f)));  NL);
#ifdef OLD
        env= bindevlist(CAR(CAR(f)), x, CDR(f), env);
#else
        env= bindevlist(CAR(CAR(f)), a, CDR(f), env);
#endif
        ETRACE(printf("   ENV: "); prin1(env); NL);
        // PROGN
        f= CDR(CAR(f));
        while(iscons(f)) {
          ETRACE(printf("PROGN: "); prin1(CAR(f)); NL);
          a= eval(CAR(f), env);
          f= CDR(f);
        }
        return a;
      }
    }

    TRACE(printf("f => "); prin1(f); NL);

    // Yeah, now we do have a number!

    //f= NUM(isnum(f)? f: ATOMVAL(f)); // original
    f= NUM(f);

    // OVERALL: slightly faster, 
    // 44.33s using atom name, and no CALL just eval->letter
    // 41.82s using letter num no CALL

    // 43.94s atom name but have call code
    // 43.59s letter num but have call code
    // 40.57s num CALL -- 10% faster!

    // BUG: if f => atom (not num) it'll call random stuff!

    // CALL direct address of function
    // (test highbyte this was is "cheaper" 1%)
#ifdef OLD
    if (f & 0xff00) return ((FUN1)f)( eval(car(x), env) );
#else

#ifndef GURKA
  if (f & 0xff00) return ((FUN1)f)( eval(car(cdr(x)), env) );
#else
  if (f & 0xff00) {
    b= CDR(x); // args

    // one arg
    a= eval(car(b), env); // eval first arg
    //indent(); printf("CALL  %04X on ", f); prin1(a); printf(" x="); prin1(x); NL;

    // only one arg?
    b= cdr(b);

    // NAME 61.9s ??? NUM 52.=22s 
    if (null(b)) return ((FUN1)f)(a);

    // Two args: NUM => 45.95s  ADDR => 46.87s

    //indent(); printf("CALL2 %04X on ", f);prin1(a); putchar(' '); prin1(b); NL;
    // two args
    b= eval(car(b), env);
    // (46.87s => 48.80s) for (cons 1 2)
    //if (!null(cdr(b))) error("too many args", x);
    return ((FUN2)f)(a,b);
  }
#endif // GURKA
#endif

    // TODO: ADDR NUM in lisp is 10% faster,
    //    do we replace in the orig code?


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

    // LETTERS FREE:
    //    "     ()  , . 0123456789     
    //  @                         Z[ ] 
    //  `abcdefghijklmnopqrstuvwxyz{ }

    // TOOD:'<' '>'   '(' is <=   ')' is >=
    // TODO: @=peek !=poke
    // TODO: (setcar 42 4711) - write a word to memory
    // TODO: (setcdr 42 \A) - write a byte to memory
    // TODO: (setcar array word) - write a word to array pos
    // TODO: (=getc )=putc
    // TODO: [=aref or just use nth? ]=arrayp
    // TODO: Z=
    // TODO: V=and _=or Z=not??? lol
    // TODO: "=string

    // --- nargs
#ifdef OLD
    a= 2;
    switch(f) {
    // - nlambda - no eval
    case ':': return setval(car(x), eval(car(cdr(x)), env), env); 
    // TODO: if it allows local defines, how to
    //   extend the env,setq should not, two words?
    case ';': return df(x);
    case 'I': return iff(x, env);
    //case 'X': return TODO: FUNCALL! eXecute
    case 'Y': return lread();
      // TODO: non-blocking getchar (0 if none)
    case '\'': return car(x); // quote
    //case '\\':return o;
    case 'S': return setval(car(x), eval(car(cdr(x)), env), env); // TODO: set local means update 'env' here...
    //case '@': return TODO: apply J or @
    //case 'J': return TODO: apply J or @

    // - nargs - eval many x
    //case 'V': TODO: or ???
    //case '_': TODO: and ???
    case '+': a-=2;
    case '*':
      while(iscons(x)) {
        // if is num: 43.76 => 38.44 if only num
        //b= CAR(x);
        // if is atom: => 96s !!!
        //if (!isatom(b)) b= getval(b, env);
        // if if still no num, eval => 80s
        //if (!isnum(b)) b= eval(CAR(x), env);
        // num => 43.76s 'num => 64.7hs
        b= eval(CAR(x), env);

        // don't care if => not num
        //if (!isnum(b)) b= 0; // takes away most of savings...
        x= CDR(x);
        if (f=='*') a*= b/2; else a+= b;
      } return a & 0xfffe; // make sure safe num!
    case 'L': return evallist(a, env);
    case 'H': return evalappend(a);
    }
#else
    a= CDR(x); // a is list of args (unevalled)
    //printf("FFFFFFFFFFF: '%c' x= ", f); prin1(x); NL;
    b= 2;      // b=mknum(1), used by + * for temporary
    //            x is still orig
    switch(f) {
    // - nlambda - no eval
    case ':': return setval(car(a), eval(car(cdr(a)), env), env); 
    // TODO: if it allows local defines, how to
    //   extend the env,setq should not, two words?
    case ';': return df(a);
    case 'I': return iff(a, env);
    //case 'X': return TODO: FUNCALL! eXecute
    case 'Y': return lread();
      // TODO: non-blocking getchar (0 if none)
    case '\'':return car(a); // quote
    //case '\\':return o;
    case 'S': return setval(car(a), eval(car(cdr(a)), env), env); // TODO: set local means update 'env' here...
    //case '@': return TODO: apply J or @
    //case 'J': return TODO: apply J or @

    // - nargs - eval many x
    //case 'V': TODO: or ???
    //case '_': TODO: and ???
    case '+': b-=2; // -1 for number!
    case '*':
      while(iscons(a)) {
        x= eval(CAR(a), env); // don't care if !num !!!
        //if (!isnum(b)) b= 0; // takes away most of savings...
        a= CDR(a);
        if (f=='*') b*= x/2; else b+= x;
      } return b & 0xfffe; // make sure safe num!
    case 'L': return evallist(x, env);
    case 'H': return evalappend(x);
    }
#endif

    // --- one arg
#ifdef OLD
    if (!iscons(x)) return ERROR;
    a= eval(CAR(x), env);
#else
    if (!iscons(a)) return ERROR;
    b= a;
    a= eval(CAR(a), env);
#endif

    // slightly more expensive, passed a switch...
    //if (f & 0xff00) return ((FUN1)f)(a);

    x= CDR(x);

    switch(f) {
    // TODO: add this to dictionary!
    case '!': return isatom(a)? T: nil; // TODO: issymbol ???
    case '#': return isnum(a)? T: nil;
    //case '$': return isstr()? T: nil;

    case 'A': return car(a);
    case 'D': return cdr(a);
    case 'K': return iscons(a)? T: nil;
    case 'O': return length(a);
    case 'P': return print(a);
    //case 'R' TODO: Recurse/Reduce?
    case 'T': NL; return nil;
    case 'U': return a? mknum(1): nil;
    case 'W': return prin1(a);
    case '.': return princ(a);
    case '~': return mknum(num(~a));
    }

    // a contains first arg
    // b rest of args
    // x orig

    // --- two args
    if (!iscons(x)) return ERROR;
#ifdef OLD
    b= eval(CAR(x), env); // just get second arg
#else
    // a contains first arg
    // b rest of args
    // x orig

    // b will be second eval arg
    b= eval(CAR(CDR(b)), env);
#endif
    //indent(); printf("TWO ARGS, f='%c'(%d) a=", f,f); prin1(a); putchar(' '); prin1(b); printf(" x="); prin1(x); NL;
    switch(f) {
    case '-': return mknum(num(a) - num(b));
    case '/': return mknum(num(a) / num(b));
    case '%': return mknum(num(a) % num(b));

    case '&': return mknum(num(a) & num(b));
    case '|': return mknum(num(a) | num(b));
    case '^': return mknum(num(a) ^ num(b));
      
    case '=': return a==b? T: nil;
    case '<': case '>':
    case '?': if (a==b) x= 0; // use x as temp
      else if (isatom(a) && isatom(b)) x= strcmp(ATOMSTR(a), ATOMSTR(b));
      else x= mknum(a-b); // no care type!
      return (f=='<'? x<0: f=='>'? x>0: mknum(x))? T: nil;

    case 'E': return eval(a, b);
    //case 'F': TODO: Filter/Fold
    //case 'Q': TOOD: eQual
    case 'C': return cons(a, b);
    case 'B': return member(a, b);
    case 'G': return assoc(a, b);
    case 'M': return mapcar(a, b);
    case 'N': return nth(a, b);

    default: error("NO such FUN, or too many args", x);
    }

    // If three args need to use narg !

    assert(!"Can't get here");
  }

  if (isatom(x)) { // getval inlined
    // 4.56s insteadof 8s?
    L p;
    // TODO: make @var be global, no search, or just *var*?
    //if (isglobalatom(x)) return ATOMVAL(x);
    while(iscons(env)) {
      p= CAR(env);
      if (car(p)==x) break;
      env= CDR(env);
    }
    if (ISSTR(x)) return x;
    //return iscons(env)? cdr(p): atomval(x);
    // 9.95s => 9.28s using ATOMVAL
    return iscons(env)? cdr(p): ATOMVAL(x);
  }


  // TODO: if we assumed all atoms global:
  //   2.29s same as number, instead of 6.7s
  //if (isatom(x)) return ATOMVAL(x);

  return x;

  // assert(!"UDF?"); // TODO:
  //return ERROR;
}

#ifdef ETRACERUN
L evalTrace(L x, L env) {
  L r;
  NL;
  indent(); printf("-->EVAL "); prin1(x); NL;

  ++ind; r= evalX(x, env); --ind;

  indent(); printf("<--EVAL "); prin1(r); printf(" <= "); prin1(x); NL;
  return r;
}
#endif // ETRACERUN

// ----------------= Alphabetical Lisp VM
// EXPERIMENTIAL BYTE CODE VM

// AL: 23.728s instead of EVAL: 38.29s => 38% faster
//   now 27.67s... why?

// define to test...

//#define AL

#ifndef AL
  #define STACKSIZE 1
#else
  #define STACKSIZE 255
#endif // AL

L stack[STACKSIZE]= {0}, *s= stack, *send;
L alvals= 0;

#ifdef AL
#define NEXT goto next

// ./cons-test AL: 23.74s EVAL: 43.38s (/ 23.74 43.38) => 43% faster!
//  24.47s added more oops, switch slower?
L al(char* p) {
  if (!p) return ERROR;
  //printf("\nAL.run: %s\n", p);
  p--;

  s= stack;
 next:
  //assert(s<send);
  //printf("al %c : ", p[1]); print(*s);

  switch(*++p) {
  case 0  : return *s--;
  case '+': --s; *s+= s[1]; NEXT; // TODO: fix
  case '*': --s; *s*= s[1]; *s/=2; NEXT; // TODO: fix
  case '-': --s; *s= mknum(num(*s)-num(s[1])); NEXT;
  case '/': --s; *s= mknum(num(*s)/num(s[1])); NEXT;

  case '=': return s[0]==s[1]? T: nil;
  case '?': if (*s==s[1]) return 0;
    else if (isatom(*s) && isatom(s[1])) return strcmp(ATOMSTR(*s), ATOMSTR(s[1]));
    else return mknum(*s-s[1]); // no care type!

  case 'A': *s= car(*s); NEXT;
  case 'D': *s= cdr(*s); NEXT;
  case 'C': --s; *s= cons(*s, s[1]); NEXT;

  case ',': ++s; *s= *(L*)++p; p+= sizeof(L)-1; NEXT;

// 27.19s
  case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9': ++s; *s= MKNUM(*p-'0'); NEXT; 


// 26.82s
//  default : ++s; *s= MKNUM(*p-'0'); NEXT; 

// 30.45s
//  default : if (isdigit(*p)) { ++s; *s= MKNUM(*p-'0'); NEXT; }
//   printf("%% AL: illegal op '%c'\n", *p); return ERROR;
  default:
    printf("%% AL: illegal op '%c'\n", *p); return ERROR;
  }
}

// reads lisp program s-exp from stdin
// returning atom string containing AL code
#define ALC(c) do { if (!p || *p) return NULL; *p++= (c); } while(0)

char* alcompile(char* p) {
  char c; int n= 0; L x, f;

 again:
  switch((c=nextc())) {
  case 0  : return p;
  case ' ': case '\t': case '\n': case '\r': goto again;
  case'\'': quote:
    ALC(',');
    {
      L* pi= (L*)p;
      if (*pi) return NULL; // overflow?
      *pi= lread();
      p+= sizeof(L);
      // make sure not GC:ed!
      alvals= cons(*pi, alvals);
    }
    return p;

  case '(': 
    //spc();
    f= nextc(); unc(f); // peek
    if (f=='(') return NULL;
    x= lread();
    //printf("ALC.read fun: "); prin1(x);
    // TODO: handle to do eval?
    if (!isatom(x)) return NULL;
    f= ATOMVAL(x);
    if (!isnum(f)) return NULL;
    f= NUM(f);
    if (f=='L') f= 'C';
    if (f=='\'') goto quote;
    assert(f<255); // TODO:? handle inline address and 'X' ?
    printf("=> %c\n", f);
   
    while((c=nextc())!=')') {
      ++n;
      p= alcompile(p);
      // implicit FOLDL of nargs + - L
      if (n>2) ALC(f);
//      spc();
    }
    ALC(f); break;
  default: ALC(c); break;
  //default : // parse number
    //n= 0;
    //while(isdigit(c)) {
    //c= nextc();
  //}
  }
  return p;
}

L alcompileread() {
  char al[MAXSYMLEN+2]= {0}, *p= al;
  al[MAXSYMLEN]= 255; // end marker
  p= alcompile(p);
  return (p && *p!=255)? atom(al): ERROR;
}  

#endif // AL

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
  ": de",
  ": setq",
  //"; df",
  "I if",
  "Y read",
  "\' quote",
  "\\ lambda",

  "* *",
  "+ +",

  "L list",
  "H append",
  
  // one arg
  "! atom", // "! symbolp", // or symbol?
  "# numberp", // "# intp"
  //"$ stringp", 
  "A car",
  "D cdr",
  "K consp", // listP
  "O length",
  "T terpri",
  "U null",
  "P print", "W prin1", ". princ",

  // two args
  "% %",
  "& &",
  "- -",
  "/ /",
  "| |",
  "~ ~",
  "= eq", "= =",
  "? cmp",
  "< <",
  "> >",
  "C cons",
  "B member",
  "G assoc",
  "M mapcar",
  "N nth",
  NULL};

void initlisp() {
  L x;
  char** s= names;

  // important assumption for cc65
  // (supress warning: error is set later, now 0)
  assert(sizeof(L)+ERROR==2); 
  assert(sizeof(void*)+ERROR==2); // used in atom function

  // allocate memory
  arptr= arena= zalloc(ARENA_LEN); arend= arena+ARENA_LEN;
  syms= (L*)zalloc(HASH*sizeof(L));
  cstart= cell= (L*)zalloc(MAXCELL*sizeof(L)); ncell= MAXCELL-2;
  cused= (char*)zalloc((MAXCELL+1)/(sizeof(L)*8));

  send= stack+STACKSIZE-1;

  // Align lower bits == xx01, CONS inc by 4!
  x= (L)cell;
  while(!iscons(x)) ++x;
  //printf("x   = %04x %d\n", x, x);
  cstart= cnext= (L*)x;
  --cnext; // as we inc before assign!
  //printf("next= %04x\n", cnext);
  assert(x&1);
  cend= cstart+MAXCELL;

  // statistics
  natoms= ncons= nalloc= 0;

  // special symbols
    nil= atom("nil");   ATOMVAL(nil)= nil; // LOL
      T= atom("T");     setval(T, T, nil);
  FREE= atom("*FREE*"); setval(FREE, FREE, nil);
  quote= atom("quote");
 lambda= atom("lambda");
closure= atom("closure");
  ERROR= atom("ERROR"); setval(ERROR, ERROR, nil);
    eof= atom("*EOF*"); setval(eof, eof, nil);

  // register function names
  while(*s) {
    reg(*s);
    ++s;
  }
}

//#define PERFTEST
#ifdef PERFTEST
#include "perf-test.c"
#endif // PREFTEST

// TODO: maybe smaller as macro?
void report(char* what, unsigned int now, unsigned int *last) {
  if ((*last)!=now) printf("%% %s: +%d  ", what, now-*last);
  *last= now;
}

void statistics(int level) {
  int cused= cnext-cell+1, hslots= 0, i;
  static unsigned int latoms, lcons, lalloc, leval, lmark; // TODO: arean?

  for(i=0; i<HASH; ++i) if (syms[i]) ++hslots;

  if (level>1) {
    printf("%% Heap: max=%d mem=%d\n", _heapmaxavail(), _heapmemavail());
    printf("%% Cons: %d/%d  Hash: %d/%d  Arena: %d/%d  Atoms: %d\n",
      ncons, MAXCELL/2,  hslots, HASH,  arptr-arena, ARENA_LEN, natoms);
  }

  if (level) {
    report("Eval", neval, &leval);
    report("Cons", ncons, &lcons);
    report("Atom", natoms, &latoms);
    report("Alloc", nalloc, &lalloc);
    report("Marks", nmark, &lmark);
    NL;
  }
}

int mainmain(int argc, char** argv, void* main) {
  char echo=0,noeval=0,quiet=0,gc=1,stats=1,test=0;
  int i= 0;
  int n= 1;

  L r, x, env;

  #ifdef BIGMAX
  btest(); return 0;
  #endif // BIGMAX

  initlisp();
  env= nil; // must be done after initlisp();

  // TODO: define way to test, and measure clocks ticks
  #ifdef PERFTEST
  perftest();
  #endif // PERFTEST

  // - read args
  while (--argc) {
    ++argv;
    //if (verbose) printf("--ARGC=%d *ARGV=%s\n", argc, *argv);
    if (0==strcmp("-b", *argv)) { // BENCH 5000 times
      n= atoi(argv[1]);
      if (n) --argc,++argv; else n= 5000;
      echo= 1; quiet= 1;
    } else
    if (0==strcmp("-q", *argv)) quiet=1,echo=stats=0; else
    if (0==strcmp("-E", *argv)) echo=1; else
    if (0==strcmp("-N", *argv)) noeval=1; else
    if (0==strcmp("-g", *argv)) gc=0; else
    if (0==strcmp("-d", *argv)) debug=1; else
    if (0==strcmp("-v", *argv)) ++verbose; else
    if (0==strcmp("-s", *argv)) ++stats; else
    if (0==strcmp("-t", *argv)) echo=1,quiet=test=1;
    else printf("%% ERROR.args: %s\n", *argv),exit(1);
// TODO: read from memory...
//    if (0==strcmp("-e", *argv)) {
//      --argc,++argc;
//      x= lread();
//    }
  }

  //clrscr(); // in conio but linker can't find (in sim?)

  // set some for test
  setval(atom("bar"), mknum(33), nil);
  setval(atom("bar"), mknum(11), nil);
  env= cons(cons(atom("foo"), mknum(42)), env);

  // nearly 10% faster... but little dangerous
  #ifndef AL
    setval(atom("car"), mknum((int)(char*)car), nil);
    setval(atom("cdr"), mknum((int)(char*)cdr), nil);
    // only for ... TODO: remove
    //setval(atom("cons"), mknum((int)(char*)cons), nil);

    // TODO: remove, because -b doesn't have onerun?
    setval(atom("one"), mknum(1), nil);
    setval(atom("two"), mknum(2), nil);

    eval(lreads("(de clos (lambda (n) (+ n n)))"), env);
  #endif // AL

  PRINTARRAY(syms, HASH, 0, 1);
  PRINTARENA();

  if (!quiet)
    printf("\n65LISP>02 (>) 2024 Jonas S Karlsson, jsk@yesco.org\n\n");

  if (stats) statistics(3);

  r= ERROR;
  if (setjmp(toploop)) printf("%% Recovering...\n");
  do {
    if (!quiet) printf("65> ");
    #ifndef AL
      x= lread();
    #else
      x= alcompileread();
      printf("AL.compiled: "); prin1(x); NL;
    #endif // AL
    if (echo) { printf("\n> "); prin1(x); NL; }
    if (!noeval) {
      for(i=n; i>0; --i) // run n tests
      #ifndef AL
        r= eval(x, env);
      #else
        r= al(isatom(x)? ATOMSTR(x): NULL);
      #endif // AL
    }
    if (echo || !quiet || test) { prin1(r); NL; }
    if (gc) GC(env, alvals); // TODO: only if needed?
    if (!quiet & stats) {NL; statistics(stats); }
    if (x==eof) break;
  } while (!feof(stdin));
  NL;

  PRINTARRAY(syms, HASH, 0, 1);
  if (stats || test) statistics(255);
  printf("Program size: %u bytes(ish) %04x-%04x %04x %04x\n", ((uint)&firstbss)-((uint)startprogram), (uint)startprogram, (uint)main, (uint)&firstvar, (uint)&firstbss);

  //{clock_t x= clock(); } // TODO: only on machine?
  return 0;
}

int main(int argc, char** argv) {
  return mainmain(argc, argv, main);
}

// ENDWCOUNT
