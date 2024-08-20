#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <assert.h>

//#include <conio.h>


// ---------------- Lisp Datatypes

// -- Cons

typedef int L;
const int nil= 0; // hmmm
int quote= 1; // hmmm, lol

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
