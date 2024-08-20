#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <assert.h>

//#include <conio.h>

// Lisp Datatypes
typedef int L;
const int nil= 0;

// can't be bigger than 32K
// should be dynamic, allocate page by page?
#define MAXCELL 32*1024/2
int ncell= 0;
L cell[MAXCELL]= {0};

L cons(L a, L d) {
  cell[ncell++]= a;
  cell[ncell++]= d;
  return -(ncell-2);
}

L car(L c) {
  return -(cell[c]);
}

L cdr(L c) {
  return -(cell[c+1]);
}

L syms= 0;

L print(L); // forward

void* atom(char* s) {
  char* p;
  // TODO: global variable?
  p= strdup(s);
  //p= malloc(n+2);
  //strcpy(p, s);
  syms= cons(p, syms);
  printf("\nSYMBOL: %04x '%s'\n", p, p);
  print(syms);
  return p;
}

// IO

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
  char r= 0, c;
  c= spc();
  if (!c) return -1;
  if (c==')') return nil;
  unc(c);
  r= lread();
  // TODO: how long list can we read with cc65?
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
    return n;
  }
  if (isalnum(c)) { // symbol
    char n= 0, s[32]= {0}, *p;
    do {
      s[n++]= c;
      c= nextc();
    } while(c && isalnum(c) && n<32-1);
    p= atom(s);
    return (int)p;
  }
  // what is it?
  printf("%%ERROR: unexpected '%c' (%d)\n", c, c);
  return -2;
}

L eval(L x, L e) {
  return e?x:x;
}

L print(L x) {
  printf("%d=%04x='%.32s'\n", x, x, x);
  return x;
}

int main() {//int argc, char** argv) {
  L r, env= nil;
  int n;

  //clrscr(); // in conio but linker can't find (in sim?)

  while (1) {
    printf("65> ");
    r= eval(lread(), env);
    print(r);
  }

  printf("\n\nExiting 65lisp\nBye\n\n");
  return 0;
}
