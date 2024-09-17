// WARNING: this file is in complete flux,
// as it's being EXPERIMENTED ON
//
// ...


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


// singlisp.c: 15.14s for 2000 "caaaddddr" (no more evallist for primtives)
// (65)lisp.c: 19.38s for 2000 ... EVAL
// (65)lisp.c:  7.23s for 2000 ... AL/TOP

//(singlisp.c: 25.52s for 2000 "caaaddddr") - OLD, not optimized
// xxxxx (65)lisp.c:  1.03s for 2000 ... AL/TOP - erh?)) xxxx - BUG?

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
typedef unsigned int D;  D nil, LAMBDA, QUOTE, T;

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
  else { for (putchar('(');;putchar(' ')) {
      princ(car(x)); x= cdr(x); if (!iscons(x)) break;
    }
    if (x==nil) { printf(" . "); princ(x); }
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
  if (c=='.') { D x= lread(); if (!unc) getchar(); unc= 0; return x; } // TODO: .5 lol? check ')'
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
  // assume atom
  { char s[32]={0}, *p= s; // overflow?
    do { *p++= c; c= getchar(); }while(c>0 && !isspace(c) && c!='(' && c!=')');
    unc= c; return atom(strdup(s));
  }
}


// --------------- lisp eval

D evallist(D v, D env) {
  return v==nil? nil: cons( eval(car(v),env), evallist(cdr(v),env) );
}

D bindeval(D b, D v, D env) {
  return b==nil? nil: cons( cons( car(b), eval(car(v),env) ),
                            bindeval(cdr(b), cdr(v), env) );
}

D assoc(D a, D env) {
  return a==car(car(env))? car(env): env==nil? nil: assoc(a, cdr(env));
}

D eval(D x, D env) {
printf("EVAL: "); princ(x); printf(" ENV= "); princ(env); terpri();
  if (x==nil || isnum(x)) return x;
  if (isatom(x)) { env= assoc(x, env); return env==nil? car(x): cdr(env); }// var
  // TODO: set?
  //if (car(x)==LAMBDA) return cons(car(car(x)), cdr(x));
  //if (car(x)==LAMBDA) return cons( cons(car(car(x)), cdr(x)), env );
  return car(x)==QUOTE? car(cdr(x)): apply(car(x), cdr(x), env);
}

D apply(D f, D x, D env) {
  char nf;
  D a, b;

 applyagain:
printf("APPLY: '%c'(%d): ", num(car(f)), num(car(f))); princ(f); printf(" ARGS= "); princ(x); printf(" ENV= "); princ(env); terpri();
  if (!isnum(f) && car(f)==LAMBDA) {
    // TODO: progn
    //return eval( car(cdr(cdr(f))), bindeval(car(cdr(f)), x, env));
    D e= bindeval(car(cdr(f)), x, env);
    //printf("LAMBDA: "); princ(f); printf("\nENV= "); princ(e); terpri();
    return eval( car(cdr(cdr(f))), e);
  }
  nf= num(car(f));
  if (!nf) { f= eval(car(f), env); goto applyagain; }
  
  // lambda, eval all args

  // ONE arg
  a= eval(car(x), env);
  //printf("A= "); princ(a); terpri();

  switch(nf) {
  case 'U': return a==nil? T: nil;
  case 'K': return iscons(a)? T: nil;
  case '#': return isnum(a)? T: nil;
  case '!': return isatom(a)? T: nil;

  case 'A': return car(a);
  case 'D': return cdr(a);
  case 'P': terpri(); // fallthrough
  case '.': return princ(a);
  case 'T': return terpri(), nil; // zero arg
  }

  // TWO args
  b= eval(car(cdr(x)), env); // not safe if do "again"
  //printf("B= "); princ(b); terpri();

  switch(nf) {
  case ':': return car(a)= b; // global set
  case 'C': return cons(a, b);
  case '=': return a==b? T: nil;
  case '+': return a+b;
  case '*': return a/2*b;

  // N args - lambda
  // see above
  //  case'\\': return eval( car(cdr(cdr(f))), bind(car(cdr(f)), x, env));
  }

  // not primitive, what could it be?
  // return apply(eval(f, env), x, env);
  //if (iscons(f)) { f= eval(f, env); goto applyagain; }

  // ERROR
  printf("\n%% No such function: "); princ(f); putchar(' '); princ(x); terpri(); terpri();
  exit(1);
}

// tap 6681 bytes -> 6648 bytes lol intead of array of strings
#define NAMES "\\ lambda\0' quote\0A car\0D cdr\0C cons\0+ +\0- -\0* *\0/ /\0U null\0K consp\0# number\0! atom\0= req\0: set\0P print\0. princ\0W prin1\0\0"

int main(int argc, char** argv) {
  char *np= NAMES;
  long m= 5000, i;
  D x, r;
  //m= 4921;// 4921 x cons = crash!
  m= 1000;
  m= 6000; // plus, no longer create long conses...
  m= 2000; // ((lambda (n) (+ n n)3)) x 2000 => 11.9s, 65EVAL: 26.83s, but it no closures...
  //m= 3000;
  m= 1;
  m= 5000; // standard test

  //assert(sizeof(Atom)==sizeof(Cons));

  C= ((Cons*)callaign(MAXCONS, 3))-1;
  nil= (D)callaign(MAXATOM, 1); car(nil)= nil; cdr(nil)= nil;
  A= 1+(Atom*)nil; T= atom("T"); car(T)= T; QUOTE= atom("quote"); LAMBDA= atom("lambda");

  while(*np) { car(atom(np+2))= mknum(*np); np+= strlen(np)+1; }

  // read-eval loop
  while(!feof(stdin)) { printf("65> "); x= lread(); terpri();
    for(i=m; i; --i) r= eval(x, nil);
    princ(r); terpri();
  }

  return argv? argc-1: 0; // BS
}
