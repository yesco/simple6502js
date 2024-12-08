// How to call x from y where x and y are { lisp, al, asm }
//
// TODO: tail-calls across? CAN'T!
// TOOD: better to have APPLY than eval (eval may have to cons)

// lisp:
//  -> lisp - apply... 
//  -> al   - put all args on s, call al() 
//  -> asm  - take all args, F1(), F2(), F3()... 

// al:
//  -> al   - recurse call top= al()
//  -> lisp - popn args from s, top= apply(f, a,b,c)
//  -> asm  - top= F1(a) F2(a,b) F3(a,b,c) F4(...

// asm:
//  -> asm  - JSR addr
//  -> lisp - JSR addr
//  -> al   - JSR addr

// Unified interface? lol

// lisp: plus2
//   jsr apply2 -- from call stack, get lisp addr! then RTS the caller of here

// al: plus2
//   jsr al2 - from call stack figure out alcode addr! then RTS the caller of here

// 

#include <stdio.h>

typedef unsigned int L;
typedef unsigned int D;

extern L nil = 1;
extern L T = 5;

typedef L (*F0)();
typedef L (*F1)(L a);
typedef L (*F2)(L a, L b);
typedef L (*F3)(L a, L b, L c);
typedef L (*FN)(void* fp, L f, L args, L env);

char funparams(L f);
void* funptr(L f);


L eval(L x, L env);
L apply(L x, L args, L env);
L assoc(L x, L lst);

L car(L x);
L cdr(L x);
L cons(L a, L b);

int num(L x);

#define CAR(x) car(x)
#define CDR(x) cdr(x)
#define NUM(x) num(x)

L isnum(L x);
L isatom(L x);
L iscons(L x);

L terpri();
void error1(char*, L);



L eval(L x, L env) {
  if (isnum(x)) return x;
  if (isatom(x)) { env= assoc(x, env); return env? CDR(env): CAR(x); }
  // TODO: other datatypes...
  if (iscons(x)) return apply(car(x), cdr(x), env);
}

L apply0(char fn) {
  switch(fn) {
  case 'T': terpri(); return nil;
  default: error1("apply0: no ", fn);
  }
}
L apply1(char fn, L a) {
  switch(fn) {
  case 'A': return car(a);
  case 'D': return cdr(a);

  case '\'': return isatom(a)?T:nil;
  case '#': return isnum(a)?T:nil;
  case 'U': return a==nil?T:nil;
  case 'K': return iscons(a);
  default: error1("apply1: no ", fn);
  }
}
L apply2(char fn, L a, L b) {
  switch(fn) {
  case '=': return a==b?T:nil;
  case '<': return a<b?T:nil;
  case '>': return a>b?T:nil;
  case 'C': return cons(a, b);
  default: error1("apply2: no ", fn);
  }
}
L apply3(char fn, L a, L b, L c) {
  switch(fn) {
  default: error1("apply3: no ", fn);
  }
}
L applyN(char fn, L f, L args, L env) {
  return nil;
}

L apply(L f, L args, L env) {
  char fn= NUM(f);
  switch(funparams(f)) {
  case 0: return apply0(fn);
  case 1: return apply1(fn, eval(car(args), env));
  case 2: return apply2(fn, eval(car(args), env), eval(car(cdr(args)),env));
  case 3: return apply3(fn, eval(car(args), env), eval(car(cdr(args)),env), eval(car(cdr(cdr(args))),env));
  default: return applyN(fn, f, args, env); // no-eval
  }
}

L applyF(L f, L args, L env) {
  void* fp= funptr(f);
  switch(funparams(f)) {
  case 0: return (*(F0)fp)();
  case 1: return (*(F1)fp)(eval(car(args), env) );
  case 2: return (*(F2)fp)(eval(car(args), env), eval(car(cdr(args)),env) );
  case 3: return (*(F3)fp)(eval(car(args), env), eval(car(cdr(args)),env), eval(car(cdr(cdr(args))), env) );
  default: return (*(FN)fp)(fp, f, args, env); // no-eval
  }
}



int main(void) {
  printf("x-call!\n");
  return 0;
}
