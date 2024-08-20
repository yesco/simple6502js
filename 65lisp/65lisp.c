#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <assert.h>

//#include <conio.h>


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

// can't be bigger than 32K
// should be dynamic, allocate page by page?
#define MAXCELL 31*1024/2
int ncell= 0;
L cell[MAXCELL]= {0};

L prin1(L); // forward TODO: remove

L cons(L a, L d) {
  cell[ncell++]= a;
  cell[ncell++]= d;
  return ncell-1;
}

// TODO: make macro
#define consp(c) ((c)&1)

L car(L c) {
  return consp(c)? cell[c-1]: nil;
}

L cdr(L c) {
  return consp(c)? cell[c]: nil;
}



// --- Atoms

#define MAXSYMLEN 32
L syms= 0;

char isatomchar(char c) {
  return (char)(int)!strchr(" \t\n\r`'\"\\()[]{}", c);
}

L print(L); // forward TODO: remove

L atom(char* s) {
  char* p;
  L r;
  if (0==strcmp(s, "nil")) return nil;
  p= strdup(s);
  r= (int)p;
  //p= malloc(n+2);
  //strcpy(p, s);
  syms= cons(r, syms);
  printf("\nSYMBOL: %04x '%s'\n", p, p);
  //print(syms);
  return r;
}

L atomp(L x) {
  // TODO: lol
  return x&1;
}


// --- Strings

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
  L r;
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

L lreadlist() {
  L r;
  char c= spc();
  if (!c) return nil; // TODO: eof atom?
  if (c==')') return nil;
  unc(c);
  r= lread();
  return cons(r, lreadlist());
}

L lread() {
  char c= spc();
  if (!c) return nil;
  if (c=='(') return lreadlist();
  if (isdigit(c)) { // number
    // TODO: negative numbers... large numbers?
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
    printf("ATOM: %s\n", s);
    return atom(s);
  }
  if (c=='\'') return cons(quote, lread());
  if (c=='"') { // string
    assert(!"NIY: strings");
  }

  printf("%%ERROR: unexpected '%c' (%d)\n", c, c);
  return -2;
}

L eval(L x, L e) {
  return e?x:x;
}

L prin1(L x) {
  //printf("%d=%d=%04x\n", num(x), x, x);
  if (!x) printf("nil");
  else if (consp(x)) {
    L i= x;
    putchar('(');
    do {
      prin1(car(i));
      i= cdr(i);
    } while (i && consp(i));
    if (i) {
      printf(" . ");
      prin1(i);
    }
    putchar(')');
  } else if (numberp(x)) {
    printf("%d", num(x));
  } else if (atomp(x)) {
    printf("%s", x);
  // TODO: strings
  //} else if (stringp(x)) {
  }
  putchar(' ');
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
