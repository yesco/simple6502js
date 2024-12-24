// WARNING: this file is in complete flux,
// as it's being EXPERIMENTED ON
//
// ...


// current tasks:
//  - ./65vm       make VM be           able to call lisp         - done
//  - ./65lisp     make lisp/EVAL/APPLY able to call VM/AL        -   TODO
//  - ./65lisp     make LISP            able to call ASM          - 
//  - ./65vm       make VM              able to call ASM          - 

//  - ./65asm/jit  make ASM able to compile DA code and call ASM  -
//  - ./65asm/jit  make AMS able to call VM/lisp                  -

// ------------------------------------------------------------
// Current Performance:

// ==== C3A4DR-test 2024-10-04 (1MHz not 1024*1024 lol)
//
// VARIANT SIZE    FREE    SECONDS
// ------- ----    ----    -------
// 65lisp   20K     24K     50.29s  1x
// 65vm     26K     17K     17.03s  2.95x
// 65asm    29K     14K      5.70s  8.82x faster!x (sz w/o DISASM)
// singl..   6K       ?     42.14s  1.19x faster!

// ==== fib8-test 
// VARIANT SIZE    FREE    SECONDS
// ------- ----    ----    -------
// cc65 i    63B            43.31s
// cc65 lt   54B            41.53s
// cc65 ult  39B            29.17s (asmfib)
// cc65 pha  39B            18.00s (pha)
//
// 65lisp   20K     24K       
// 65vm     26K     17K    
// 65asm    29K     14K     40.08s
// singl..   6K       ?    


// PROGSIZE
// --------
// emacs      -  4552 bytes TODO: rewrite inlisp! run bytecode!
// 65lisp     - 19542 bytes TODO: eval/apply too big cmp singlisp.c
// 65vm       - 25541 bytes TODO: separate out the case/jmp?
// 65asm      - 28788 bytes TODO: template code gen?
// singl..    -  6252 bytes

// (outdated)
// vmcompiler -  3989 bytes
// vm         -  2883 bytes (al function)
// asmcompiler-  6330 bytes 
// asm-runtime-   ??? bytes


// ============================================================
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

// NO WAY
// - no macros, using NLAMBDA and DE!

// PROGRAM OPTIONS
// -q          quiet, no echo, no stats, no results
// -b [N]      bench mark (default 5000 times) (turns on -E)
// -p "str"    print str\n used by bench.pl
// -e "expr"   evaluate expression and print
// -x "expr"   just evaluate
// -E          echo on (show what evaluate and response)
// -i          interactive from terminal, can use several times
//               end with *EOF* or bye
// -N          noeval
// -d          debug on (may need to recompile)
// -v          verbose increase
// -s          increase statistics, print it
// --nogc      turn off GC (otherwise run after every expr)


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
// Only + - and list are varargs (unless VM)
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

// it's implicitly optional, only enabled with -DPROGSIZE
#include "progsize.c" // "first"

// for included files, enable lisp extensions
#define LISP

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
#include "simconio.c"

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

// counts ops
//#define NOPS

#ifndef NOPS
  #define NOPS(a) ;
#else
  #undef NOPS
  #define NOPS(a) do {a;} while (0)
#endif NOPS

// ---------------- CONFIG

// Number of cells (2 makes a cons)
//   can't be bigger than 32K
//   should be dynamic, allocate page by page?
//   DECREASE if run out of memory. LOL
//#define MAXCELL 25*1024/2 // ~ 12K cells

// (+ (* 8192 2 2) (* 32 2) (* 2048 1)) = 34880 bytes!

//#define MAXCELL 8192*2
#define MAXCELL 4096*2

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
#define MAXSYMLEN 120

// ---------------- Lisp Datatypes
typedef int16_t L;
typedef uint16_t uint;
typedef unsigned uchar;

typedef L (*F0)();
typedef L (*F1)(L a);
typedef L (*F2)(L a, L b);
typedef L (*F3)(L a, L b, L c);
typedef L (*FN)(void* fp, L f, L args, L env);



// --- Statisticss
uint natoms= 0, ncons=0, nalloc= 0, neval= 0, nmark= 0;
long nops= 0;

int debug= 0, verbose= 0;

void* zalloc(size_t n) {
  void* r= calloc(n, 1);
  assert(r);
  nalloc+= n;
  return r;
}


//#define UNSAFE // doesn't save much 3.09s => 2.83 (/ 3.09 2.83) 9.2%

char docompile=0; // switch argument

#include "extern-vm.c"


// --- special atoms
//const L nil= 0;
//#define nil 0 // slightly faster 0.1% !
L nil, T, FREE, ERROR, eof, lambda, closure, bye, SETQ, IF, AND, OR, DE,DA,DC;
L  quote= 0;

#define notnull(x) (x!=nil) // faster than !null
#define null(x) (x==nil)    // crazy but this is 81s instead of 91s!
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

uint ncell= 0;
L *cell, *cnext, *cstart, *cend;



L prin1(L); // forward TODO: remove

// --- MACROS - smaller!
#define terpri() putchar('\n')
#define NL terpri()



// --- ERROR
jmp_buf toploop= {0};

void error(char* msg);
void error1(char* msg, L a);



// --- Type number to identify Heap OBJ
#define HFREE   0xFE
#define HATOM   0xA7
#define HARRAY  0xA6
// TODO: +HCONST string for program read
#define HSTRING 0x57 // dynamica alloc, may need to be GC:ed
#define HSLICE  0x51 // do you get it? ;-)
// All Bin object hi nibble == 'B', ISBIN, BINSTR
#define HBIN    0xB0 // BinObject
#define HAL     0xBA //   BinAl
#define HCODE   0xBC //   BinCode/asm

#define HTYP(x) (*((char*)(((L)x)-1)))

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



// ---------------- CONS
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

  error("Run out of conses");
}

// returning nil is faster than 0! (1%)
L car(L c)         { return iscons(c)? CAR(c): nil; }
L cdr(L c)         { return iscons(c)? CDR(c): nil; }
L setcar(L c, L a) { return iscons(c)? CAR(c)= a: nil; }
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

// TODO: go towards using singlisp style atoms!
// array then heap allocated? no hash? hmmm...
typedef struct Atom {
  // - val first saves 40 bytes code
  // - but not faster, 0.01% slower...?
  // echo "foo" | ./run -t ==> 0.01% faster LOL
  L val;
  struct Atom* next; // IF symbol it's next sym

  char nargs;  // number of argumnets
  char code[3]; // machine code       // TODO: ...

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
//   TODO: what do when run out?
char* arena, *arptr, *arend; // arptr is "next arena pointer"

char isatomchar(char c) { return (char)(int)!strchr(" \t\n\r.;`'\"()[]{}", c); }

//  57 bytes extra for ptr % 3 ==  01
// 141 bytes extra for ptr % 7 == 101

// TODO: really should be named issym()
//   number is an atom, lol
#define isatom(x) (((x)&3)==1) 

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

// search linked list
Atom* findatom(Atom* a, char* s, uchar typ) {
  while(a) { // lol not nil...
    if (HTYP(a)==typ && 0==strcmp(s, a->name)) return a;
    a= a->next;
  }
  return NULL;
}


// Looks up an atom of NAME and returns it
// 
// If already exists, return that
// Otherwise create it.
//
// TYP: use this type code to match and create
//   (This means an ATOM and "STRING" could both exist)
// LEN: if len==0 is ATOM or STRING, otherwise mallocced
//
// Also used for binary arrays/alcode/asmcode
// see atom(), funatom(), mkstr(), mkbin()


// TODO: optimize for program constants!
//   (just store \0 + pointer!)
// TODO: should use nil() test everywhere?
//   and make "nil" first atom==offset 0!
//   (however, I think increase codesize lots!)
//
L atomstr(char* s, uchar typ, size_t len) {
  char h;
  Atom *a;

  // TODO: hash gone bad!!! for ARRAY LEN!!!!
  h= (len?len:hash(s)) & (HASH-1);
  if (typ==HATOM || typ==HSTRING || !len) {
    a= findatom((Atom*)syms[h], s, typ); // fast 14s for 4x150.words
    if (a) return (L)a; // found
  }

  // create atom
  ++natoms;

  // WHATIF: heap object x01, point at attr value
  //    char type;
  // -> L val;

  // MIS-align: put at least one type byte "before" pointer
  do {
    *arptr++= typ; // HTYP
  } while (!isatom((L)arptr));

  a= (Atom*)arptr;
  arptr+= sizeof(Atom)+(len?len: strlen(s))+1;
  // TODO: better test? LOL this crashes
  assert(arptr<=arend);

  // CAR bytes len if !atom
  a->val= MKNUM(typ==HSTRING? strlen(s): len);

  // store a letter like '1' '2', or '-' or 'n'...
  //a->nargs= 0;  / TDOO: arena is \0 already...

  // copy name/data, alt, store pointer?
  a->name[0]= 0; // for safety (HBIN)
  if (len) memcpy(a->name+1, s, len); else strcpy(a->name, s);
  // CDR link it up
  // TODO: add specific cdr? could be the maxsize for array?
  a->next= (Atom*)(syms[h]);
  syms[h]= (L)a;

  // -- but 120 bytes more storage used
  // 41.47s ret actual pointer FASTER: 5.2%, BYTES; -120b !!
  // 43.75s returning complex index
  return (L)a;
}

// TODO: measure code size overhead?L
L atom(char* s) { return atomstr(s, HATOM, 0); }

// snn= '+2plus" for functions
L funatom(char* snn, char* code, int len) {
  // TODO:
  return atomstr(snn, HATOM, 0);
}

// --- Strings

// There are two type of strings:
//  - constant strings part of program
//  - strings read and processed

// How to distinguish?
// TODO: if read-eval => "program"

// unsafe eval twice
#define ISSTR(x) (isatom(x)&&HTYP(x)==HSTRING)

// TODO: measure code size overhead?
L mkstr(char* s) { return atomstr(s, HSTRING, 0); }


#define ISBIN(x) (isatom(x)&&((HTYP(x)&0xf0)==HBIN))
#define ISAL(x)  (isatom(x)&&HTYP(x)==HAL)
#define ISCODE(x) (isatom(x)&&HTYP(x)==HCODE)
#define BINSTR(x) (ISBIN(x)? ATOMSTR(x)+1: 0)
#define BINLEN(x) (ISBIN(x)? NUM(ATOMVAL(x)): 0)

// TODO: provide alternative
L mkbin(char* s, size_t len)  { return atomstr(s, HBIN,  len); }
L mkal(char* s, size_t len)   { return atomstr(s, HAL,   len); }
L mkcode(char* s, size_t len) { return atomstr(s, HCODE, len); }

// ---------------- GC Garbage Collector
// just do a simple mark and sweep

// one bit per cell[]
char* cused;

#define USED(arr, n) (((arr)[(n)/8])&(1<<((n)&7)))

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

// mark object at a
// TODO: recursive, can run out of stack... reverse pointer?
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
    uint n= ((L*)a)-cstart, i= n/8;
    char b= 1<<(n&7);
    if (cused[i] & b) { DEBUG(printf(" [used %d %d] ", i, b)); return; }

    // TODO: what's the maxdepth? check w stack option
    //   then, limit it, but link to "next" TODO...
    //if (USED(cused, n)) return;

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
    uint n= ((L*)a)-cstart, i= n/8;
    char b= 1<<(n&7);
    if (cused[i] & b) { printf(" [used %d %d] ", i, b); return; }
    DEBUG(printf(" [%d/mark: %d]", gcdeep, n); princ(a); putchar(' '))
    cused[n/8]|= (1<<(n&7));
  }

  // TODO: strings, or anything heap allocated reclaimable
}

void sweep() {
  uint n, i;
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

  // -- TODO: mark stack, just not sure what alignment stack is...
  // (should prev be same as cons for mark etc to work?)

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

// read from string if set
char* _rs= 0;

// ungetc
void unc(char c) {
  assert(!_nc); // can't do twice!
  _nc= c;
}

char echo;

char nextc() {
  int r;
  if (_nc) { r= _nc; _nc= 0; }
  else {
    if (_rs) { r= *_rs; if (r) ++_rs; } else r= getchar();
   if (echo) putchar(r);
  }

  return r>=0? r: 0;
}

// skip spaces, return next char
char skipspc() {
  char c= nextc();
  while (c && isspace(c)) c= nextc();
  return c;
}


// ---------------- DEC30 - floating point decimals!
// (optional) 3.8KB extra CODE!

//#define DEC

#ifdef DEC
#include <limits.h>
#include "dec30.c"
#else
  L readdec(char c, char base) {
    int r= 0;
    while(isdigit(c)) {
      r= r*base + c-'0';
      c= nextc();
    }
    unc(c);
    return MKNUM(r);
  }
#endif // DEC


// ---------------- LISP READER

char base= 10;

L lread(); // forward

// read a list of type: '(' '{' '['
L lreadlist(char t) {
  L r= nil, *last= &r;
  char c= t; // lol

  do {
    c= skipspc();
    if (!c || c==')' || c=='}' || c==']') break;

    if (c=='.') {
      c= nextc();
      if (c==' ') { *last= lread(); continue; }
      if (isdigit(c)) { unc(c); *last = cons(readdec('.', 10), nil); continue; }
      printf("GOT '.' and '%c'\n", c); assert(!"lreadlist"); // .lol symbol?
      // can't stuff it back... only one char
    }

    unc(c); *last= cons(lread(), nil);
    last= &CDR(*last);

  } while (1);
  return r;
}

// read anything return sexp ()={}=[] !
// TODO: maybe 1,2,3= (1 2 3) ? implicit by comma?
L lread() {
  // TODO: skip single "," for more insert nil? [1 2,3 ,, 5]
  char c= skipspc(), q= 0;
  if (!c) return eof;
  if (c=='(' || c=='{' || c=='[') return lreadlist(c);

  #ifdef DEC
    // TODO: base prefixes...
    if (isdigit(c)) return readdec(c, 10);
  #else

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
#endif // DEC

  if (c=='\\') return MKNUM(nextc()); // \A before
  q= (c=='|' || c=='"')? c: 0;
  if (q || isatomchar(c)) { // symbol/stringconst
    // TODO: handle larger string const?
    char n= 0, s[MAXSYMLEN+1]= {0};
    if (q) c= nextc();
    do {
      if (c=='\\') { char *s;
        c= nextc();
        s= strchr("t\tn\nr\re", c);
        c= s? s[1]: c;
      }
      s[n]= c; ++n;
      c= nextc();
    } while(c && ((q && c!=q) || (!q && isatomchar(c))) && n<MAXSYMLEN);
    // TODO: if run out of length, will read garbage - fix
    if (!q) unc(c);
    return q=='"'? mkstr(s): atom(s);
  }
  // quoted
  if (c=='\'') return cons(quote, cons(lread(), nil));
  // comment
  if (c==';') { while((c=nextc()) && c!='\n' && c!='\r'); return lread(); }

  printf("%%ERROR: unexpected '%c' (%d)\n", c, c);
  return ERROR;
}

// This will read *one* value/s-exp from S
L sread(char* s) { L r;
  char* saved= _rs;
  _rs= s; r= lread();
  _rs= saved;
  return r;
}

// print XSTRING in readable format unless QUOTED
// if QUOTED<0 then lists are written without 
L prinq(L x, signed char quoted) {
  L i= x;
  //printf("%d=%d=%04x\n", num(x), x, x);
  if (null(x)) printf("nil");
  else if (isnum(x)) printf("%d", num(x));
  //TODO: printatom as |foo bar| isn't written readable...
  else if (isatom(x)) {
    if (ISBIN(x)) { char* p= BINSTR(x); size_t z= BINLEN(x);
      (quoted>=0) && printf("#%02X[%d]=\"", HTYP(x), z);
      while(z-->0) if (quoted<0) putchar(*p++);
        else if (*p>=32 && *p<=126 &&* p!='"') putchar(*p++);
        else { revers(1); printf("%02x", *p++); revers(0); }
      (quoted>=0) && printf("\"");
    } else printf((ISSTR(x) && quoted>0)?"\"%s\"": "%s", ATOMSTR(x));
  } else if (iscons(x)) {

    // speical case of (num . num) if DEC!
    #ifdef DEC
    if (isdec(x)) { dputf((dec30*)x); return x; }
    #endif // DEC

    // printlist
    for((quoted>=0) && putchar('('); ; putchar(' ')) {
      prinq(car(i), quoted); i= cdr(i); if (!iscons(i)) break;
    }
    if (notnull(i)) { (quoted>=0) && printf(" . "); prinq(i, quoted); }
    (quoted>=0) && putchar(')');

  } else printf("LISP: Unknown data %04x\n", x);
  return x;
}

L princ(L x) { return prinq(x, 0); }
L prin1(L x) { return prinq(x, 1); }
//L prinflattenL x) { return prinq(x, -1); }

//void prinx(L x) { printf("#%04u", (num)x); } 

L print(L x) { NL; return prin1(x); }

#define PRINTARRAY(a,b,c,d) ; // debug
#ifndef PRINTARRAY // debug
  #define PRINTARRAY printarray // debug

void printarray(L* arr, int n, char printnil, char ishash) { // debug
  int i; // debug
  // just print symbols per slot // debug
  for(i=0; i<n; ++i) { // debug
    L a= arr[i]; // debug
    if (!printnil && (null(a) || !a)) continue; // debug
    printf("\n%2d: ", i); // debug
    while (a && a!=nil) { // debug
      princ(a); putchar(' '); // debug
      if (!ishash) break; // debug
      a= (L)(((Atom*)a)->next); // debug
    } // debug
  } // debug
  NL; // debug
} // debug
#endif // PRINTARRAY // debug

// TODO: instead of a "format" do my own "printf"

// Printf like unix but for lisp objects
//   %L - use princ for value
//   %Q - use prin1 for value (quote strings/atoms)
//   %F - flatten TODO: don't print () of list
// Returns a list of objects
// TODO: use? 'F' - Format printF
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

void error1(char* msg, L a) {
  printf("\n%%ERROR: %s: ", msg);
  if (num(a)>31 && NUM(a)<128) printf(" '%c' (%d) ptr=%04x", NUM(a), NUM(a), a);
  else { printf(" ptr=%04x %s ", a, ISBIN(a)?"ISBIN":""); prin1(a); }
  NL;
  // TODO: have arg opt to quit on error?
  if (toploop) longjmp(toploop, 1);
}
  
void error(char *msg) { error1(msg, 0); }

// ---------------- Variables

L assoc(L x, L l) {
  while(iscons(l)) if (car(CAR(l))==x) return CAR(l); else l= CDR(l);  return l;
}

L setval(L x, L v, L e) {
  L p= e? assoc(x, e): nil;
  if (notnull(p)) return setcdr(p, v);
  // TODO: optimize? as assoc() call is expensive (e==nil)
  return setatomval(x, v); // GLOBAL
}


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

extern L runal(char* la);

L de(L args) { return args?ERROR:ERROR; } // TODO:
L df(L args) { return args?ERROR:ERROR; } // TODO:
L evalappend(L args) { return args?ERROR:ERROR; } // TODO:


// TODO: tailrecursion?
L iff(L args, L env) {
  if (null(eval(car(args), env)))
    return eval(car(cdr(cdr(args))),env);
  else
    return eval(car(cdr(args)),env);
}

L evallist(L args, L env) {
  return iscons(args)? cons(eval(CAR(args),env), evallist(CDR(args),env)): nil;
}

L length(L a) {
  int n= 0;
  if (ISSTR(a)) return CAR(a);
  while(iscons(a)) ++n,a= CDR(a);
  return mknum(n);
}

L member(L x, L l) {
  while(iscons(l)) if (CAR(l)==x) return l; else l= CDR(l);  return l;
}

L mapcar(L f, L l) {
  return f&&l&&l?ERROR:ERROR;
// TODO: lol, how to do without apply?
  /// create and modify a special allocate cons!
//    cons(apply(f, CAR(l), nil), mapcar(f, CDR(l)));
}
  
// TODO: nthcdr
L nth(L n, L l) { n= num(n);
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
    // TODO: this isn't working if call inside AL or JIT..
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
        if (f==a) error1("eval.loop", a);
      }
      if (null(f)) error1("nofunc", a);

      // evaluate any cons until it's not...
      // lambda 66s => 37s by reordering tests!
      while(iscons(f) && CAR(f)!=closure) {
        ETRACE(printf("EVAL again: "); prin1(f); NL);
        a= f; // avoid self loop
        f= eval(f, env);
        if (isnum(f)) break;
        if (f==a) error1("eval.loop", a); // can happen?
      }
      if (null(f)) error1("nofunc", a);

      // TODO: really needed? or put limit on it?
      if (isatom(f)) continue;

      // Handle AL/code call
      if (ISBIN(f)) {
        // TODO: implement
        printf("evalX: BINARY? f= "); prin1(f); NL;
        assert(!"note implemented yet!");
      }

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
    // TODO: handle more parameters, see applyN in call-x.c
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
    //if (notnull(cdr(b))) error("too many args", x);
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

    if (a)
    // --- nargs
#ifdef OLD
    a= 2; // num 1, used by +* loop for accumulation
    switch(f) {
    case ':': return setval(car(x), eval(car(cdr(x)), env), env);  // no-eval
    case '!': return setval(eval(car(x),env), eval(car(cdr(x)), env), env); 
    // TODO: if it allows local defines, how to
    //   extend the env,setq should not, two words?
    //case ';': return df(x); // TODO: wrong
    case 'I': return iff(x, env);
    //case 'X': return TODO: FUNCALL! eXecute
      // TODO: non-blocking getchar (0 if none)
    case '\'': return car(x); // quote
    //case '\\':return o;

    case 'Y': x= eval(car(x), env); return sread(ISSTR(x)? ATOMSTR(x): 0);

    case 'S': return setval(car(x), eval(car(cdr(x)), env), env); // TODO: set local means update 'env' here...
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
    case ':': return setval(car(x), eval(car(cdr(x)), env), env);  // no-eval
    case '!': return setval(eval(car(x),env), eval(car(cdr(x)), env), env); 
    // TODO: if it allows local defines, how to
    //   extend the env,setq should not, two words?
    //case ';': return df(a); // TODO: wrong
    case 'I': return iff(a, env);
    //case 'X': return TODO: FUNCALL! eXecute
      // TODO: non-blocking getchar (0 if none)

    case 'Y': x= eval(car(x), env); return sread(ISSTR(x)? ATOMSTR(x): 0);

    case '\'':return car(a); // quote
    //case '\\':return o;
    case 'S': return setval(car(a), eval(car(cdr(a)), env), env); // TODO: set local means update 'env' here...
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
    case '$': return ISSTR(a)? T: nil;

    case 'A': return car(a);
    case 'D': return cdr(a);
    case 'K': return iscons(a)? T: nil;
    case 'O': return length(a);
    case 'P': return print(a);
    //case 'R' TODO: Recurse/Reduce?
    case 'T': NL; return nil;
    case 'U': return notnull(a)? T: nil; // faster than null
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

    default: error1("NO such FUN, or too many args", x);
    }

    // If three args need to use narg !

    assert(!"Can't get here");
  }

  if (isatom(x)) { // getval inlined 4.56s insteadof 8s
    L p;

    //if (ISSTR(x)) return x;
    if (ISSTR(x)) return x;
    if (ISBIN(x)) return x;

    // TODO: make @var be global, no search, or just *var*?
    //if (isglobalatom(x)) return ATOMVAL(x);

    // assoc inlined
    while(iscons(env)) {
      p= CAR(env);
      if (iscons(p) && CAR(p)==x) break;
      env= CDR(env);
    }
    return iscons(env)? cdr(p): atomval(x);
    // 9.95s => 9.28s using ATOMVAL
    //return iscons(env)? CDR(p): ATOMVAL(x);
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


#ifndef AL
  #define STACKSIZE 1
  L al(char* code) {
    error("Not compiled with AL or JIT\n");
  }
#else
  #ifndef ASM
    #define STACKSIZE 255
  #else
    #define STACKSIZE 1
  #endif
#endif // AL

// TODO: move to ZP
static L stack[STACKSIZE]= {0};
static L *send, alvals= 0;

unsigned long bench=1;

#ifdef AL
  #include "lisp-vmal.c"
#else
  extern L runal(char* la) { error("Not compiled with AL/ASM-compiler\n"); return nil; }
#endif // AL

// ---------------- Register Functions

// TODO: point to these from arena?

// FORMAT:
//   1st char: ';' symbol for dispatch, single AL alphabetical byte-code
//   2nd char: '0' - no args
//             '1' - takes one arg
//             '2' - 2...
//             '-' - non-eval, context known
//             'n' - counted as in vararg? set Y register to count?
//   ...rest   "name" of function
//   \0
//
//   \0: if 1st char is \0 then it means end of defines.

// NOTE: all primitives are either: - n 0 1 2 ...
//       user funcs may be more, up to 8 (?)


// SEE: x-call.c for test/discussion

// nargs  	lisp		al		asm

// '0' -	jsr lisp0	jsr al0		jmp code
// '1' -        jsr lisp1	jsr al1		jsr

char* names[]= {
  // nargs
  ":-de",   // DEfine var/lambda       TODO: implicit progn?
  ":-dc",   // Define Compile bytecode TODO: implicit progn?
  ":-da",   // Define compile Assembly TODO: implicit progn?
  ":2setq", // TODO: not right for "VM" // TODO: 2xN for multiple assigments?
  "!2set",
  //"; df",

  "R-recurse",
  "^1return",

  "I-if",
  "I-and", // TODO: dummy
  "I-or",  // TODO: dummy
  "Y1read",
  "\'1quote",
  "\\-lambda",

  "Lnlist",
  "H2append",
  
  // one arg
  "!1atom", // "! symbolp", // or symbol? // TODO: change... lol
  "#1numberp", // "# intp"
  //"$ stringp", 
  "A1car",
  "D1cdr",
  "K1consp", // listP
  "O1length",
  "T0terpri",
  "U1null",
  "P1print", "W1prin1", ".1princ", // swap 'W' and '.'??? '.' should be "pretty"
  "~1~", // bit neg

  // two args
  "%2%",
  "&2&",
  "-2-", // vararg?
  "+2+", // vararg?
  "*2*", // vargarg?
  "/2/", // vararg?
  "|2|", // bitor vararg
  "=2eq", "=2=",
  "?2cmp",
  "<2<",
  ">2>",
  "C2cons",
  "B2member",
  "G2assoc",
  "M2mapcar",
  "N2nth",

  "R-rec", // recurse on self

  "Z-loop",

  //"i1inc", // TODO: remove, only used for testing
  //"j1jnc", // TODO: remove, only used for testing

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

  // MIS-align lower bits == xx01, CONS inc by 4!
  x= (L)cell;
  while(!iscons(x)) ++x;
  //printf("x   = %04x %d\n", x, x);
  cstart= cnext= (L*)x;

  --cnext; // as we inc before assign!
  //printf("next= %04x\n", cnext);
  assert(x&1);
  cend= cstart+MAXCELL;

  // -- statistics
  nops= natoms= ncons= nalloc= 0;

  // -- special symbols - they evaluate to themselves, include car/cdr!
    // TODO: for assembly, consider relocating nil to address $0001;
    // much easier to detect nUll!
    nil= atom("nil");   ATOMVAL(nil)= nil;

      T= atom("T");     setval(T, T, nil);
   FREE= atom("*FREE*");setval(FREE, FREE, nil);
  ERROR= atom("ERROR"); setval(ERROR, ERROR, nil);
    eof= atom("*EOF*"); setval(eof, eof, nil);
    bye= atom("bye");   setval(bye, bye, nil);
  // -- symbols used for compilation, typically
  //   TODO: hmmm, these are duplicates from constant names
  quote= atom("quote");
 lambda= atom("lambda");
closure= atom("closure");
   SETQ= atom("setq");
     IF= atom("if");
    AND= atom("and");
     OR= atom("or");
     DE= atom("de");
     DA= atom("da");
     DC= atom("dc");

  // -- register function names
  while(*s) {
    setatomval(x= atom(*s+2), MKNUM(**s));
    ((Atom*)x)->nargs= (*s)[1];
    ++s;
  }

  // direct code pointers
  // nearly 10% faster... but little dangerous
  #ifndef AL
    setval(atom("car"), mknum((int)(char*)car), nil);
    setval(atom("cdr"), mknum((int)(char*)cdr), nil);
    // only for ... TODO: remove
    //setval(atom("cons"), mknum((int)(char*)cons), nil);
  #endif // AL

}

//#define PERFTEST
#ifdef PERFTEST
#include "perf-test.c"
#endif // PREFTEST

// TODO: maybe smaller as macro?
void report(char* what, unsigned long now, uint *last, unsigned long *llast) {
  unsigned long l= last? *last: llast? *llast: 0;
  if (l!=now) printf("%% %s: +%lu  ", what, now-l);
  //if (last) *last= (uint)now; if (llast) *llast= now;
  if (last) *last= (uint)now; if (llast) *llast= now;
}

void statistics(int level) {
  int cused= cnext-cell+1, hslots= 0, i;
  static uint latoms=0, lcons=0, lalloc=0, leval=0, lmark=0;
  static unsigned long lops=0;

  for(i=0; i<HASH; ++i) if (syms[i]) ++hslots;

  if (level>1) {
    printf("%% Heap: max=%u mem=%u\n", _heapmaxavail(), _heapmemavail());
    printf("%% Cons: %u/%u  Hash: %u/%u  Arena: %u/%u  Atoms: %u\n",
      ncons, MAXCELL/2,  hslots, HASH,  arptr-arena, ARENA_LEN, natoms);
  }

  if (level) {
    report("Eval", neval, &leval, 0);
    report("Cons", ncons, &lcons, 0);
    report("Atom", natoms, &latoms, 0); // TODO: outoput messed up?
    report("Alloc", nalloc, &lalloc, 0);
    report("Marks", nmark, &lmark, 0);
    report("Ops", nops, 0, &lops);
    NL;
  }
}

// TODO: turn on GC
char echo=0,noeval=0,quiet=0,gc=0,stats=1,test=0;

#define DOPRINT 0

// Read and Eval lines of text

// If LiNe given, set it as input to read.
// Read and execute froms, until EOF or symbol bye.

// Returns modified env
L readeval(char *ln, L env, char noprint) {
  // TODO: not sure what function env has an toplevel:
  //   we're setting/modifying globals, right?
  //   so it would reasonably be nil. LOL
  //   Ah, how about this? Use it for *special* variables!
  //   As long as they aren't defined, TODO: or we need
  //   setval to differentiate because of the name?
  //   Alt is to do "pushdown" (use property value?)
  long i= 0;
  L r, x;
  char* saved= _rs;
  _rs= ln;

  // TODO wanted result, abort/rest?
  if (setjmp(toploop)) printf("\n%% Recovering...\n");

  r= ERROR;
  do {
    //printf("X=%d Y=%d\n", wherex(), wherey());

    // -- read
    if (!ln && !quiet && !echo && !test) printf("65> "); // TODO: maybe make nextc echo???
    r= ERROR;
    switch(docompile) {
    case 0: x= lread(); break;

    #ifdef AL
    case 1:
      // TODO: lread() does "macro expansion" ? lol?
    case 2:
      x= alcompileread();
      NL; // hmmm
      if (verbose) { printf("\n\n=============AL.compiled: "); prin1(x); NL; }
      assert(x==eof || ISAL(x));
      break;
    case 3:
    #endif // AL

    default: printf("Unknown docompile %d\n", docompile); return env;
    }

    // -- info/end
    if (x==eof || x==bye) break;

    if (echo || test) { printf("\n\n> "); prin1(x); NL; }

    //printf("!noprint=%d && (echo=%d || !quiet=%d || bench=%d)\n", !noprint, echo, !quiet, bench);

    // -- eval
    if (!bench) bench= 1;
    if (!noeval && x!=ERROR) {

// TODO: clean this up, this is only special for top-level
#ifdef AL
      // TODO: all this replace by JSR ?
      if (ISBIN(x)) {
        switch(docompile) {
        case 1: // byte-code al
          if (ISAL(x)) {
            // run n tests // slow? interact with MC
            for(; bench>0; bench>0 && --bench) {
              r= al(BINSTR(x));
              if (r==ERROR) break;
            }
          } else error1("dcompile=1 and NOT AL", x);
          break;
#ifdef GENASM
        case 2: // machine code
          #ifdef JIT
            // compiles AL from buff to gen
            machinecompile(buff);
            // run gen
            //r= coderun(gen); // 40% overhead!
            r= genrun();
          #else // ASM
            printf("--------------HERE alcodecompileandrun!\n");
            // one-shot
            {
              // Compiling to and returning static buffer
              char* m= asmpile(BINSTR(x));
              r= alasmrun(m);
            }
            // TODO: free x? lol
          #endif // JIT
#endif // GENASM
          break;
        default: error1("Unknown BIN type", x);
        }
      } else
#endif AL
      {

        // TODO: option to compare results? slow but equal
        for(; bench>0; bench>0 && --bench) { // run n tests // slow? interact with MC
          r= eval(x, env);
          if (r==ERROR) break;
        }
      }
    }

    // -- print
    //{ printf("RES= "); prin1(r); NL; }
    //printf("!noprint=%d && (echo=%d || !quiet=%d || bench=%d)\n", !noprint, echo, !quiet, bench);
    if (!noprint && (echo || !quiet || bench)) { prin1(r); NL; }

    // -- info
    if (gc) GC(env, alvals); // TODO: only if needed?
    if (!quiet & stats) {NL; statistics(stats); }

  } while (1);
  if (!noprint) NL;

  _rs= saved;
  
  NOPS(report("Eval", neval, 0, 0); report("Ops", nops, 0, 0); NL);

  memset(toploop, 0, sizeof(toploop));
  return env;
}

L testing(env) {
  #ifdef BIGMAX
  btest(); return 0;
  #endif // BIGMAX

  // TODO: define way to test, and measure clocks ticks
  #ifdef PERFTEST
  perftest();
  #endif // PERFTEST

  // set some for test
  setval(atom("foo"), mknum(42), nil);
  setval(atom("bar"), mknum(33), nil);
  setval(atom("bar"), mknum(11), nil);
  env= cons( cons(atom("*fie*"), mknum(99)),
       cons( cons(atom("*foo*"), mknum(777)),
             env));

  // TODO: remove, because -b doesn't have onerun?
  setval(atom("one"), mknum(1), nil);
  setval(atom("two"), mknum(2), nil);

  //env= readeval("(de clos (lambda (n) (+ n n)))", env, quiet);

  return env;
}

int main(int argc, char** argv) {
  L env= nil; char interpret= 1;

  if (!quiet) statistics(3);

  initlisp();

  env= nil; // must be done after initlisp();

  // - read args
  while (--argc>0) {
    ++argv;
    if (!*argv) break;

    if (verbose) printf("--ARGC: %d *ARGV: \"%s\" %d\n", argc, *argv, *argv);

    if (0==strcmp("--nogc", *argv)) gc=0;
    else switch((*argv)[1]) {
      // simple flags
      case 'E': echo=1; break;
      case 'N': noeval=1;  break;
      case 'd': debug=1;  break;
      case 'v': ++verbose,++stats;  break;
      case 'q': quiet=1,echo=stats=0;  break;
      case 's': ++stats,statistics(stats);  break;
//      case 't': test=1,quiet=1,echo=0,env=testing(env);  break;
      case 't':
        echo=0;env=testing(env);test=1;  break;
      case 'c': ++docompile; break;
      // actions
      case 'b': bench= atol(argv[1]); if (bench) --argc,++argv; else bench= 5000;
        echo= 1; quiet= 1;  break;
      case 'p': printf("%s\n", *++argv),--argc;  break;
      case 'i': interpret=0,echo=quiet=0,env= readeval(NULL, env, DOPRINT);  break;
      case 'e': case 'x':
        //printf("ARGV= '%s' %d\n", *argv, (*argv)[1]=='x');
        env=readeval(argv[1], env, (*argv)[1]=='x');
        interpret= 0; --argc; ++argv;  break;

      default: printf("%% ERROR.args: %s\n", *argv);
        printf("\n-e '(+ 3 4)'    eval (and maybe print result)\n-x '(+ 3 4)'	eval & echo expression\n-i 		interactive (till EOF) can be several\n\n-q		quiet\n-N		No-eval\n-E		echo (input)\n-d ...		increase debug level\n-v ...		increase verbosity\n-s		print/increase statistics\n\n-t		test setup, echo input/output\n\n-b [N]		set benchmarking, N default 5000\n-p 'text'	print text for debugging purposes\n\n\n--nogc		turn of gc (has bugs)\n-c		increase defautlt compilation level\n");
        exit(1);
      }
    
  } // while more args

  if (!interpret) return 0;
  if (!quiet) {
    if (bench==1 && !test) clrscr(); // || only if interactive?
    PRINTARRAY(syms, HASH, 0, 1); // debug
    printf("\n65LISP>02 (>) 2024 Jonas S Karlsson, jsk@yesco.org\n\n");
  }

  if (stats) statistics(3);

  // TODO: if used -e and -i do we want to do this again? also in batch? stdin?
  // The Meat
  env= readeval(NULL, env, 0);

  NL;

  // Info
  PRINTARRAY(syms, HASH, 0, 1);
  if (stats || test) {
    statistics(255);
    PROGSIZE;
  }

  //{clock_t x= clock(); } // TODO: only on machine?
  return 0;
}
