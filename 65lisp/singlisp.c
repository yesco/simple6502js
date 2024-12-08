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

//#define EMACS // adds 4552 bytes to PROGSIZE

#ifdef EMACS 
  #include "emacs.c"
#endif // EMACS

// it's implicitly optional, only enabled with -DPROGSIZE
#include "progsize.c" // "first"

//#define ETRACE

#ifndef ETRACE
  #define ETRACE(a) 
#else
  #undef ETRACE
  #define ETRACE(a) do { a; } while(0)
#endif

// ---------------- CONFIG
#define MAXCONS  1024*8
#define MAXATOM  1024

// ---------------- lisp Datatype
typedef unsigned int D;  D nil, LAMBDA, QUOTE, T;

D eval(D, D); D apply(D, D, D); D lread(); D princ(D); // forward

typedef struct { D car, cdr; } Cons;  Cons *C, *CS, *CE;

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
D cons(D a, D d) { ++C; assert(C<CE); C->car= a; C->cdr= d; return (D)C; }
#define car(c) (((Cons*)c)->car)
#define cdr(c) (((Cons*)c)->cdr)

// Atoms stored as: (D globalval, char*)
//   (Note: nil, car(nil)= nil, cdr(nil)= nil
//    car(atom) == global value

// DO NOT ADD ANYTHING TO THIS! *A is an aligned array...
typedef struct { D val; char* str; } Atom;  Atom *A;

// marker used to know when to strdup new atoms
char initialized= 0;

// linear search to find if have existing atom
// 
D atom(char* s) { Atom* x= (Atom*)nil;
  if (0==strcmp(s, "nil")) return nil; // special
  while(s && ++x<=A) if (0==strcmp(x->str, s)) return (D)x;
  // TODO: assert test out of slots for atom
  ++A; A->val= nil; A->str= s?(initialized?strdup(s):s):(char*)nil; return (D)A;
}

void terpri() { putchar('\n'); }

D princ(D x) { if (x==nil) printf("nil");
  else if (isnum(x)) printf("%d", num(x));
  else if (isatom(x)) printf("%s", ((Atom*)x)->str);
  else { for (putchar('(');; putchar(' ')) {
      princ(car(x)); x= cdr(x); if (!iscons(x)) break;
    }
    if (x!=nil) { printf(" . "); princ(x); }
    putchar(')');
  }

  return x;
}

// poor mans ungetchar...
char unc= 0;

//// Very lispy/simple, but too recursive for long lists...
//D readlist2() { 
//  char c= unc? unc: getchar(); unc= 0;
//  if (isspace(c)) return readlist2();
//  if (c==')') return nil;
//  if (c=='.') { D x= lread(); if (!unc) getchar(); unc= 0; return x; }
//  unc= c; return cons(lread(), readlist2()); // order of eval 1...2
//}

// TODO: .5 lol? check ')'
D readlist() { D r= nil, *last= &r; char c;
  do { c= unc? unc: getchar(); unc= 0;
    while (isspace(c)) c= getchar();
    if (c==')') return r;
    if (c=='.') { *last= lread(); lread(); return r; }
    unc= c; *last= cons(lread(), nil); last= &(cdr(*last));
  } while(1);
}

D lread() { int n= 0, c= unc? unc: getchar(); unc= 0;
  if (isspace(c)) return lread();
  if (c<=0 || c==')') return nil;
  while(isdigit(c)) { n= n*10 + c-'0';
    unc= c= getchar(); if (!isdigit(c)) return mknum(n);
  }
  if (c=='\'') return cons(QUOTE, cons(lread(), nil));
  if (c=='(') return readlist();
  // assume atom
  { char s[32]={0}, *p= s; // overflow?
    do { *p++= c; c= getchar(); }while(c>0 && !isspace(c) && c!='(' && c!=')');
    unc= c; return atom(s);
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
  ETRACE(printf("EVAL: "); princ(x); printf(" ENV= "); princ(env); terpri());
  if (x==nil || isnum(x)) return x;
  if (isatom(x)) { env= assoc(x, env); return env==nil? car(x): cdr(env); }// var
  // TODO: set?
  //if (car(x)==LAMBDA) return cons( cons(car(car(x)), cdr(x)), env );
  //return car(x)==QUOTE? car(cdr(x)): apply(eval(car(x), env), cdr(x), env);
  if (car(x)==LAMBDA) return x;
  return car(x)==QUOTE? car(cdr(x)): apply(car(x), cdr(x), env);
}

D apply(D f, D x, D env) {
  char nf= 0;
  D a, b;

 applyagain:
  ETRACE(printf("APPLY: "); princ(f); printf("\t ('%c' %d)\tARGS= ", num(car(f)), num(car(f))); princ(x); printf("   ENV= "); princ(env); terpri());

  if (!isnum(f)) {
    if (f==nil) goto error;
    if (isatom(f)) { f= car(f); goto applyagain; }

    // LAMBDA
    if (car(f)==LAMBDA) {
      // TODO: progn
      //return eval( car(cdr(cdr(f))), bindeval(car(cdr(f)), x, env));
      D e= bindeval(car(cdr(f)), x, env), r= nil;
      ETRACE(printf("LAMBDA: "); princ(f); printf("\nENV= "); princ(e); terpri());
      x= cdr(cdr(f)); // body
      while(iscons(x)) {
        r= eval(car(x), e); // TODO: tail opt?
        x= cdr(x);
      }
      return r;
    }

    // wtf now?
    assert(!"Shouldn't happen?");
  }
  
  nf= num(f);
  ETRACE(printf("NF='%c' %d\n", nf, nf));
  
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

  case 'I': return eval(a==nil? car(cdr(cdr(x))): car(cdr(x)), env); // if
  }

  // TWO args
  b= eval(car(cdr(x)), env); // not safe if do "again"
  //printf("B= "); princ(b); terpri();

  switch(nf) {
  case ':': return car(a)= b; // global set
  case 'C': return cons(a, b);
  case '=': return a==b? T: nil;
  case '<': return a<b? T: nil;
  case '+': return a+b;
  case '-': return a-b;
  case '*': return a/2*b;
  case '/': return a/b*2;
  }

  // not primitive, what could it be?
  // return apply(eval(f, env), x, env);
  //if (iscons(f)) { f= eval(f, env); goto applyagain; }

  // ERROR
 error:
  printf("\n%% No such function: "); princ(f); printf("    ARGS: "); princ(x); terpri(); terpri();
  exit(1);
}

// tap 6681 bytes -> 6648 bytes lol intead of array of strings
// TOOD: leading \0 to be used to indicate type of storage for name/atom/machinecode! see atom.c
//#define NAMES "\0\0\\lambda\0'1quote\0A1car\0D1cdr\0C2cons\0+2+\0-2-\0*2*\0/2/\0U1null\0K1consp\0#1number\0!1atom\0=2eq\0<2<\0:2set\0P1print\0.1princ\0W1prin1\0I-if\0\0"
#define NAMES "\0'1quote\0A1car\0D1cdr\0C2cons\0+2+\0-2-\0*2*\0/2/\0U1null\0K1consp\0#1number\0!1atom\0=2eq\0<2<\0:2set\0P1print\0.1princ\0W1prin1\0I-if\0\0"

int main(int argc, char** argv) {
  char *np= NAMES;
  long m= 5000, i;
  D x, r;

  //m= 4921;// 4921 x cons = crash!
  m= 1000;
  m= 6000; // plus, no longer create long conses...
  m= 2000; // ((lambda (n) (+ n n)3)) x 2000 => 11.9s, 65EVAL: 26.83s, but it no closures...
  //m= 3000;
  m= 100;
  m= 50000; // standard test
  m= 1;

  //assert(sizeof(Atom)==sizeof(Cons));

  // allocate memory, init special atoms
  CS= C= ((Cons*)callaign(MAXCONS, 3))-1; CE= CS+MAXCONS;
  nil= (D)callaign(MAXATOM, 1); car(nil)= nil; cdr(nil)= nil;
  A= 1+(Atom*)nil; T= atom("T"); car(T)= T; QUOTE= atom("quote"); LAMBDA= atom("lambda");

  // register primitives
  ++np; while(*np) { car(atom(np+2))= mknum(*np); np+= strlen(np)+1; }
  initialized= 1;

  // read-eval loop
  while(!feof(stdin)) { printf("65> "); x= lread(); terpri();
    for(i=m; i; --i) r= eval(x, nil);
    princ(r); terpri();
  }

  PROGSIZE;

  return argv? argc-1: 0; // BS
}
