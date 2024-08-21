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
#define MAXCELL 29*1024/2

// Arena len to store symbols/constants (and global ptr)
#define ARENA_LEN 1024

// Defined to use hash-table (with Arena
#define HASH 256

// ---------------- Lisp Datatypes

typedef int L;
const int nil= 0; // hmmm
int quote= 1; // hmmm, lol

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

L cons(L a, L d) {
  cell[ncell++]= a;
  cell[ncell++]= d;
  return ((ncell-2)<<2)+3;
}

// TODO: make macro
#define consp(c) (((c)&3)==3)

L car(L c) {
  return consp(c)? cell[c>>2]: nil;
}

L cdr(L c) {
  return consp(c)? cell[(c>>2)+1]: nil;
}



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
#endif

// search arena, this could save next link...
void* searchatom(char* s) {
  char* a= arena;
  a= arena;
  // TODO: more efficient
  while(*s && a<arptr) {
    if (0==strcmp(s, a+4)) return a;
    a+= 4+1+strlen(a+4); // TODO: should be 1???
  }
  return NULL;
}

// search linked list
void* findatom(char* a, char* s) {
  while(a) {
    if (0==strcmp(s, a+4)) return a;
    a= *(char**)(int**)a;
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
  if (0==strcmp(s, "nil")) return nil;

#ifdef HEAP
  p= strdup(s);
  r= (int)p;

  // TODO: keep list of syms?
  //p= malloc(n+2);
  //strcpy(p, s);
  //syms= cons(r, syms);
  //print(syms);
#endif

#ifdef HASH
  h= hash(s);
  // p= searchatom(s);
  p= findatom(syms[h], s);
  if (!p) {
    printf("--NEW: %s HASH=%x\n", s, h);
    p= arptr;
    pi= (void**)p;
    arptr+= 4+1+strlen(s);
    assert(arptr<=arend);
    // TODO: memcpy safer? other arch
    pi[0]= syms[h]; // prev
    pi[1]= 0;
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

L stringp(L x) {
  return x?0:0;
}


// --- Numbers

L numberp(L x) {
  return (!(x&1));
}

int num(L x) {
  if (!numberp(x)) return 0; // "safe"
  return x/2-1;
}

L mknum(int n) {
  // TODO: negatives?
  assert(n >= 0);
  return (n+1)*2;
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
  if (isatomchar(c)) { // symbol
    char n= 0, s[MAXSYMLEN+1]= {0};
    do {
      s[n++]= c;
      c= nextc();
      // TODO: breaking chars: <spc>'"()
    } while(c && isatomchar(c) && n<MAXSYMLEN);
    return atom(s);
  }
  if (c=='\'') return cons(quote, lread());
  if (c=='"') { // string
    assert(!"NIY: strings use atom?");
  }

  printf("%%ERROR: unexpected '%c' (%d)\n", c, c);
  return -2;
}

L eval(L x, L e) {
  return e?x:x;
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
    //printf("%s", atomstr(x));
    printf("%s|%d|#%2x", atomstr(x), (x>>2), hash(atomstr(x)));
  // TODO: strings
  //} else if (stringp(x)) {
  }
  return x;
}

L print(L x) {
  L r= prin1(x);
  putchar('\n');
  return r;
}

int main() {//int argc, char** argv) {
  L r, env= nil;

  //clrscr(); // in conio but linker can't find (in sim?)

  do {
    printf("65> ");
    r= eval(lread(), env);
    print(r);
  } while (r);

  printf("\n\nExiting 65lisp\nBye\n\n");
  return 0;
}

// ENDWCOUNT
