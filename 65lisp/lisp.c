#include <stdint.h> // cc65 uses 29K extra memory???
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <assert.h>

//#include <conio.h>

// ---------------- CONFIG

// Number of cells (2 makes a cons)
//   can't be bigger than 32K
//   should be dynamic, allocate page by page?
//   DECREASE if run out of memory. LOL
#define MAXCELL 26*1024/2

// Arena len to store symbols/constants (and global ptr)
#define ARENA_LEN 1024

// Defined to use hash-table (with Arena
#define HASH 256

// ---------------- Lisp Datatypes
typedef int16_t L; // requires #include <stdint.h> uses 26K more!

// special atoms
//const L nil= 0;
#define nil 0 // slightly faster 0.1% !
L error, quote=0;

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
L cell[MAXCELL]= {0};

L prin1(L); // forward TODO: remove

// smaller!
#define terpri() putchar('\n')

L cons(L a, L d) {
  cell[ncell++]= a;
  cell[ncell++]= d;
  return ((ncell-2)<<2)+3;
}

// macro takes less code than funcall, and is faster
#define consp(c) (((c)&3)==3)

// unsafe macro 10% faster,but uses 80 bytes more
// make sure it's consp first (in loop)!
#define CAR(c) (cell[ (c)>>2   ])
#define CDR(c) (cell[((c)>>2)+1])

// returning nil is faster than 0! (1%)
L car(L c)         { return consp(c)? CAR(c): nil; }
L setcar(L c, L a) { return consp(c)? CAR(c)= a: nil; }
L cdr(L c)         { return consp(c)? CDR(c): nil; }
L setcdr(L c, L d) { return consp(c)? CDR(c)= d: nil; } 

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

L atomp(L x) {
  // TODO: lol
  return (x&3)==1; // ENC
}

char* atomstr(L x) {
  if (!x) return "nil";
  if (!atomp(x)) return NULL;
  return arena + 4 + (x>>2); //ENC
}

// 3% cost of atomp()
#define ATOMVAL(x) (arena[2+((x)>>2)]) // ENC
//#define atomval(x) (atomp(x)?arena[2+((x)>>2)]:nil)

L atomval(L x) {
  if (!atomp(x)) return nil;
  return ATOMVAL(x);
}

L setatomval(L x, L v) {
  if (!x || !atomp(x)) return nil;
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

  assert(sizeof(void*)==2); // cc65, see below ptr

  if (0==strcmp(s, "nil")) return nil;

#ifdef HEAP
  p= strdup(s);
  r= (L)p; // not portable

  // TODO: keep list of syms?
  //p= malloc(n+2);
  //strcpy(p, s);
  //syms= cons(r, syms);
  //print(syms);
#endif

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
    pi[1]= nil; // global val
    strcpy(p+4, s);
    syms[h]= p;
  }
  r= ((p-arena)<<2)+1; // ENC
  //assert(0==strcmp(s, atomstr(r)));
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
#define stringp(x) (0)

// --- Numbers

// macor smaller code and 10% faster
#define numberp(x) (!((x)&1))

#define NUM(x) ((x)/2-1)

int num(L x) {
  if (!numberp(x)) return 0; // "safe"
  return NUM(x);
}

#define MKNUM(n) (((n)+1)*2)

// no need inline/macro
L mknum(int n) {
  // TODO: negatives?
  assert(n >= 0);
  return MKNUM(n);
}

// ---------------- IO

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
  if (!c || c=='(' || c=='{' || c=='[') return lreadlist(c);
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
  //if (c=='"') { // string
    //assert(!"NIY: strings use atom?");
//}

  printf("%%ERROR: unexpected '%c' (%d)\n", c, c);
  return error;
}

L assoc(L x, L l) {
  L p;
  while(l) {
    p= car(l);
    if (car(p)==x) return cdr(p);
    l= cdr(l);
  }
  return nil;
}

L setval(L x, L v, L e) {
  L p= assoc(x, e);
  if (p) return setcdr(p, v);
  return setatomval(x, v); // GLOBAL
}

L getval(L x, L e) {
  L p= assoc(x, e);
  if (p) return cdr(p);
  return atomval(x); // GLOBAL
}

L eval(L x, L e); // forward
L apply(L f, L a, L e); // forward

// primops()
#include "al.c"

L apply(L f, L a, L e) {
  // TODO: trace
  //terpri();
  //printf("F= "); print(f);
  //printf("A= "); print(a);
  //printf("E= "); print(e);
  if (atomp(f)) return primop(NUM(ATOMVAL(f)), a, e);

  assert(!"UDF?"); // TODO:
  return nil;
}

L eval(L x, L e) {
  if (!x || numberp(x) || stringp(x)) return x;
  if (atomp(x)) return getval(x, e);
  if (consp(x)) return apply(car(x), cdr(x), e);
  printf("%%LISP: unknown data type %04x\n", x);
  abort();
}

// print unquoted value without space before/after
L prin1(L x) {
  //printf("%d=%d=%04x\n", num(x), x, x);
  if (!x) printf("nil");
  else if (consp(x)) {
    L i= x;
    putchar('(');
    do {
      prin1(car(i));
      i= cdr(i);
      if (i) putchar(' ');
    } while (i && consp(i));
    if (i) {
      printf(". ");
      prin1(i);
    }
    putchar(')');
  } else if (numberp(x)) {
    printf("%d", num(x));
  } else if (atomp(x)) {
    // TODO: if |foo  bar| input => prin1 should print s
    printf("%s", atomstr(x));
    //printf("%s|%d|#%2x", atomstr(x), (x>>2), hash(atomstr(x)));
  // TODO: strings - or for now use atoms?
  //} else if (stringp(x)) {
  }
  return x;
}

L print(L x) {
  L r= prin1(x);
  terpri();
  return r;
}

void regc(char* name, char n) {
  L a= atom(name);
  setatomval(a, mknum(n)); // TODO: overhead
}

void reg(char* charspacename) {
  char c= *charspacename;
  regc(charspacename+2, c);
}

// TODO: point to these in arena?

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

  // important assumption for cc65
  // (supress warning: error is set later, now 0)
  assert(sizeof(L)+error==2); 

  // special symbols
  error= atom("ERROR");
  quote= atom("quote");

  // register function names
  while(*s) {
    reg(*s);
    ++s;
  }
}

#define PERFTEST
int fib(int n) {
  if (n<2) return n;
  else return fib(n-1)+fib(n-2);
}

L lispfib(L n) {
  n= num(n);
  if (n<2) return mknum(n);
  else return mknum(num(lispfib(mknum(n-1)))+num(lispfib(mknum(n-2))));
}

L flispfib(L n) {
  n= NUM(n);
  if (n<2) return MKNUM(n);
  else return MKNUM(NUM(lispfib(MKNUM(n-1)))+NUM(lispfib(MKNUM(n-2))));
}

//#define CL
#ifdef CL
int fib(int n) {
  if (n<2) return n;
  else return fib(n-1)+fib(n-2);
}

// This will FAIL with -Cl optimization!!!
int lfib(int n) {
  int r= n;
  if (n>=2) { r= lfib(n-1); r+= lfib(n-2); }
  //if (n>=2) r= lfib(n-1)+lfib(n-2); // works!
  return r;
}
#endif

int main(int argc, char** argv) {
  int i;
  L r, x, env= nil;

  // TODO: define way to test, and measure clocks ticks
  int n= 1;

  #ifdef CL  
  printf("FIB(7)= %d\n", fib(7));
  printf("lFIB(7)= %d\n", lfib(7));
  assert(fib(7)==lfib(7));
  #endif

  //printf("lispFIB(7)= %d\n", fib(7));
  #ifdef PERFTEST
  n= 21;
  //printf("FIB(%d)= %d\n", n, fib(21)); // 21=>3s
  //printf("lispFIB(7)= %d\n", num(lispfib(mknum(7))));
  // same speed? lispfib and flispfib=macro
  //printf("lispFIB(%d)= %d\n", n, num(lispfib(mknum(n)))); // 21=>17s
  //printf("FlispFIB(%d)= %d\n", n, NUM(flispfib(MKNUM(n)))); // 21=>17s
  #endif

  initlisp();

  // read args
  while (--argc) {
    ++argv;
    //printf("ARG: %s\n", *argv);
    if (0==strcmp("-t", *argv)) {
      n= atoi(argv[1]);
      if (n) --argc,++argc; else n= 10000;
    }
// TODO: read from memory...
//    if (0==strcmp("-e", *argv)) {
//      --argc,++argc;
//      x= lread();
//    }
  }

//  r= 0;
//  for(i=n; n>0; --n) {
//    r+= fib(30);
//  }

  //printf("TESTS=%d\n", n);

  //clrscr(); // in conio but linker can't find (in sim?)

  setval(atom("bar"), mknum(33), nil);

  env= cons(cons(atom("foo"), mknum(42)), env);
  do {
    printf("65> ");
    x= lread();
    for(i=n; i>0; --i)
      r= eval(x, env);
    print(r);
  } while (!feof(stdin));

  // TODO: remove?
  printf("\n\nExiting 65lisp\nBye\n\n");
  return 0;
}

// ENDWCOUNT
