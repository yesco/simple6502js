// A 6502 lisp from Hackware presentation in Singapore
// (>) 2024 Jonas S Karlsson

// Based on the "Maxwell Equations of Software",
// almost directly translated to C from McCarthy.

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

#define MAXCONS  1024*8
#define MAXATOM  1024

typedef unsigned int D;
D nil, LAMBDA, QUOTE, T,  PLUS, CAR, CDR, CONS, EQ;

D eval(D, D); D apply(D, D, D); D lread(); D princ(D); // forward

typedef struct { D car, cdr; } Cons;  Cons *C;

void* callaign(size_t n, char bits) {
  char* p= calloc(n+1, sizeof(Cons)); // same size Atom!
  while((((D)p) & 0x03) != bits) p++;
  return p;
}

#define mknum(n) ((n)<<1)      // nnnn0
#define num(n)   ((n)>>1)      // nnnn0
#define isnum(n) (((n)&1)==0)  // nnnn0
#define isatom(n) (((n)&3)==1) // ppp01
#define iscons(n) (((n)&3)==3) // ppp11

D cons(D a, D d) { ++C; C->car= a; C->cdr= d; return (D)C; }
#define car(c) (((Cons*)c)->car)
#define cdr(c) (((Cons*)c)->cdr)

// Atoms stored as: (D global  value, char*)
typedef struct { D val; char* str; } Atom;  Atom *A;

D atom(char* s) {
  Atom* x= (Atom*)nil;
  if (0==strcmp(s, "nil")) return nil; // special
  while(s && ++x<=A) if (0==strcmp(x->str, s)) return (D)x;
  ++A; A->val= nil; A->str= s? s: (char*)nil;
  return (D)A;
}

D princ(D x) {
  if (x==nil) printf("nil");
  else if (isnum(x)) printf("%d", num(x));
  else if (isatom(x)) printf("%s", ((Atom*)x)->str);
  else { putchar('('); while(iscons(x)) {
      princ(car(x));
      x= cdr(x);
      if (iscons(x)) putchar(' ');
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

D lread() {
  int n= 0, c= unc? unc: getchar(); unc= 0;
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
  if (a==car(car(env))) return car(env);
  return env==nil? nil: assoc(a, cdr(env));
}

D eval(D x, D env) {
  if (x==nil || isnum(x)) return x;
  if (isatom(x)) { env= assoc(x, env); return env==nil? car(x): cdr(x); }
  return car(x)==QUOTE? car(cdr(x)): apply(car(x), evallist(cdr(x),env), env);
}

D apply(D f, D x, D env) {
  //printf("APPLY: "); princ(f); printf(" ARGS= "); princ(x); putchar('\n');
  if (f==CAR) return car(car(x));
  if (f==CDR) return cdr(car(x));
  if (f==CONS) return cons(car(x), car(cdr(x)));
  if (f==EQ) return car(x)==car(cdr(x))? T: nil;
  if (f==PLUS) return car(x)+car(cdr(x));
  if (f==LAMBDA) return eval( car(cdr(cdr(f))), bind(car(cdr(f)), x, env));
  return apply(eval(f, env), x, env);
}

int main(int argc, char** argv) {
  //assert(sizeof(Atom)==sizeof(Cons));

  C= ((Cons*)callaign(MAXCONS, 3))-1;
  nil= (D)callaign(MAXATOM, 1); car(nil)= nil; cdr(nil)= nil;
  A= 1+(Atom*)nil; LAMBDA= atom("lambda"); QUOTE= atom("quote"); T= atom("T"); car(T)= T;

  // TODO: remove, by using dispatch system?
  CAR= atom("car"); car(CAR)= CAR; CDR= atom("cdr"); car(CDR)= CDR;
  CONS= atom("cons"); car(CONS)= CONS; EQ= atom("eq"); car(EQ)= EQ;
  PLUS= atom("+"); car(PLUS)= PLUS;

  while(!feof(stdin)) { printf("65> "); princ(lread()); putchar('\n'); }

  return argv? argc-1: 0; // BS
}
