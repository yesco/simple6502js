// A 6502 lisp from Hackware presentation in Singapore
// (>) 2024 Jonas S Karlsson

// Based on the "Maxwell Equations of Software",
// almost directly translated to C from McCarthy.

// Compared to (65)lisp.c, this lisp is quite slow
// but adheres to history: eval calling apply calling eval.

// It is only, so far, optimized in the simplicity of
// its datatypes. It currently only provides:

//  datatype           bit pattern
//
//    int15       nnnn nnnn  nnnn nnn 0
//    atom        pppp pppp  pppp pp 01
//    cons        pppp pppp  pppp pp 11

// We use MIS-aligned memory aligned arrays!
// (This is ok (only) on 8-bit systems)
//
// This gives us type-tagging for free without
// any bit-manipulation, and with minimal overhead.
//
// We pass around "D" which is an unsigned int16.
// Basically, it's an actual memory pointer!
// We can identify the datatype by:
//
//    x==nil, isnum(x), isatom(x), iscons(x)
//
// car(x) is always legal on non-numbers:
//   of a cons, returns first element in a pair
//   of nil, returns nil (special case)
//   of an atom, returns the global value of the name
//   (warning: of a number, returns uint16 value at MEMW[x]
//    most likely not a legal lisp value)
//
// cdr(x) is only to be used by cons:
//   of a cons, the second element in a pair
//   of nil, returns nil (special case)
//   (warning: cdr of any other atom gives a char*
//    to the name, but this isn't a legal lisp value)
//   (warning: of a number, returns uint16 value at MEMW[x+2]
//    most likely not a legal lisp value)


// singlisp.c: 25.52s for 2000 "caaaddddr"
// (65)lisp.c:  1.03s for 2000 ...
//
// The main reason being: evaluation of expressions
// do evallist that creates "garbage"
//
// Second reason: eval/apply is two functions, and
// function calls are expensive on 6502.

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

// ---------------- CONFIG
#define MAXCONS  1024*8
#define MAXATOM  1024

// ---------------- lisp Datatype
typedef unsigned int D;  D nil, LAMBDA, QUOTE, T,PLUS,TIMES,CAR,CDR,CONS,EQ;

D eval(D, D); D apply(D, D, D); D lread(); D princ(D); // forward

typedef struct { D car, cdr; } Cons;  Cons *C;

// return N multiple of 4 bytes, aligned bits (bPPP..PPP01) if bits==01
void* callaign(size_t n, char bits) { char* p= calloc(n+1, sizeof(Cons)); 
  while((((D)p) & 0x03) != bits) p++; return p;
}

// ---------------- Type Testers, and num stuff
#define mknum(n) ((n)<<1)      // nnnn0
#define num(n)   ((n)>>1)      // nnnn0
#define isnum(n) (((n)&1)==0)  // nnnn0
#define isatom(n) (((n)&3)==1) // ppp01
#define iscons(n) (((n)&3)==3) // ppp11

// TODO: assert test out of cons
D cons(D a, D d) { ++C; C->car= a; C->cdr= d; return (D)C; }
#define car(c) (((Cons*)c)->car)
#define cdr(c) (((Cons*)c)->cdr)

// Atoms stored as: (D global  value, char*)
//   (Note: nil, car(nil)= nil, cdr(nil)= nil
//   car(atom) == global value
typedef struct { D val; char* str; } Atom;  Atom *A;

// TODO: assert test out of slots for atom
D atom(char* s) { Atom* x= (Atom*)nil;
  if (0==strcmp(s, "nil")) return nil; // special
  while(s && ++x<=A) if (0==strcmp(x->str, s)) return (D)x;
  ++A; A->val= nil; A->str= s? s: (char*)nil;  return (D)A;
}

void terpri() { putchar('\n'); }

D princ(D x) { if (x==nil) printf("nil");
  else if (isnum(x)) printf("%d", num(x));
  else if (isatom(x)) printf("%s", ((Atom*)x)->str);
  else { putchar('('); while(iscons(x)) {
      princ(car(x)); x= cdr(x); if (iscons(x)) putchar(' ');
    }
    if (!iscons(x) && x!=nil) { printf(" . "); princ(x); }
    putchar(')');
  }  
  return x;
}

// poor mans ungetchar...
char unc= 0;

D readlist() { 
  char c= unc? unc: getchar(); unc= 0;
  if (isspace(c)) return readlist();
  if (c==')') return nil;
  if (c=='.') { D x= lread(); if (!unc) getchar(); unc= 0; return x; }
  unc= c; return cons(lread(), readlist()); // order of eval 1...2
}

D lread() { int n= 0, c= unc? unc: getchar(); unc= 0;
  if (isspace(c)) return lread();
  if (c<=0 || c==')') return nil;
  while(isdigit(c)) { n= n*10 + c-'0';
    unc= c= getchar(); if (!isdigit(c)) return mknum(n);
  }
  if (c=='\'') return cons(QUOTE, cons(lread(), nil));
  if (c=='(') return cons(lread(), readlist());
  { char s[32]={0}, *p= s; // overflow?
    do { *p++= c; c= getchar(); }while(c>0 && !isspace(c) && c!='(' && c!=')');
    unc= c; return atom(strdup(s));
  }
}


// --------------- lisp eval

D evallist(D v, D env) {
  return v==nil? nil: cons( eval(car(v),env), evallist(cdr(v),env) );
}

D bind(D b, D v, D env) {
  return b==nil? nil: cons( cons( car(b), eval(car(v),env) ),
                            bind(cdr(b), cdr(v), env) );
}

D assoc(D a, D env) {
  return a==car(car(env))? car(env): env==nil? nil: assoc(a, cdr(env));
}

D eval(D x, D env) {
  if (x==nil || isnum(x)) return x;
  if (isatom(x)) { env= assoc(x, env); return env==nil? car(x): cdr(x); }
  return car(x)==QUOTE? car(cdr(x)): apply(car(x), evallist(cdr(x),env), env);
}

D apply(D f, D x, D env) {
//printf("APPLY: '%c'(%d)", num(car(f)), num(car(f))); princ(f); printf(" ARGS= "); princ(x); terpri();
#ifndef FISH
// cons 12.40s plus 600: 9.96s slightly faster, with more ops later...
  switch(num(car(f))) {
  case 'A': return car(car(x));
  case 'D': return cdr(car(x));
  case 'C': return cons(car(x), car(cdr(x)));
  case '=': return car(x)==car(cdr(x))? T: nil;
  case '+': return car(x)+car(cdr(x));
  case '*': return car(x)/2*car(cdr(x));
  case'\\': return eval( car(cdr(cdr(f))), bind(car(cdr(f)), x, env));
  default:  return apply(eval(f, env), x, env);
  }
#else
  // FASTER!!! cons 12.05s plus 600: 10.36s
  if (f==CAR) return car(car(x));
  if (f==CDR) return cdr(car(x));
  if (f==CONS) return cons(car(x), car(cdr(x)));
  if (f==EQ) return car(x)==car(cdr(x))? T: nil;
  if (f==PLUS) return car(x)+car(cdr(x));
  if (f==TIMES) return car(x)*car(cdr(x))/2;
  if (f==LAMBDA) return eval( car(cdr(cdr(f))), bind(car(cdr(f)), x, env));

  return apply(eval(f, env), x, env);
#endif
}

int main(int argc, char** argv) {
  long m= 5000, i;
  D x, r;
  //m= 4921;// 4921 x cons = crash!
  m= 1000;
  m= 600; // plus

  //assert(sizeof(Atom)==sizeof(Cons));

  C= ((Cons*)callaign(MAXCONS, 3))-1;
  nil= (D)callaign(MAXATOM, 1); car(nil)= nil; cdr(nil)= nil;
  A= 1+(Atom*)nil; T= atom("T"); car(T)= T;

  LAMBDA= atom("lambda"); car(LAMBDA)= mknum('\\');
  QUOTE= atom("quote"); car(QUOTE)= mknum('\'');

  // TODO: remove, by using dispatch system?
  CAR= atom("car");   car(CAR)= mknum('A');
  CDR= atom("cdr");   car(CDR)= mknum('D');
  CONS= atom("cons"); car(CONS)= mknum('C');
  EQ= atom("eq");     car(EQ)= mknum('=');
  PLUS= atom("+");    car(PLUS)= mknum('+');
  TIMES= atom("*");   car(TIMES)= mknum('*');

  while(!feof(stdin)) { printf("65> "); x= lread();
    for(i=m; i; --i) r= eval(x, nil);
    princ(r); terpri();
  }

  return argv? argc-1: 0; // BS
}
