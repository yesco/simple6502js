// AL - Alphabetical Lisp (a byte VM)
//
// simple primitive function dispatcher

// Based on
// - https://github.com/yesco/parsie/blob/main/al.c

L de(L args) {
  assert(!"NIY: de");
  return error;
}

L df(L args) {
  assert(!"NIY: df");
  return error;
}

// TODO: progn?

// tailrecursion?
L iff(L args, L env) {
  assert(!"NIY: iff");
  return error;
}

L lambda(L args, L env) {
  return cons(args, env);
}

L evallist(L args, L env) {
  assert(!"NIY: evallist");
  return error;
}

L evalappend(L args) {
  assert(!"NIY: append");
  return nil;
}

L length(L a) {
  int n= 0;
  while(consp(a)) {
    n++;
    a= CDR(a);
  }
  return mknum(n);
}

L member(L x, L l) {
  while(consp(l))
    if (CAR(x)==x) return l;
  return l;
}

L mapcar(L f, L l) {
  return (!l || !consp(l))? nil:
    cons(apply(f, CAR(l), nil), mapcar(f, CDR(l)));
}
  
// TODO: nthcdr
L nth(L n, L l) {
  n= num(n);
  while(n-- > 0) if (!consp(l)) return nil; else l= CDR(l);
  return CAR(l);
}

////////////////

L primop(char f, L args, L env) {
  L a=1, b; // used by '*' and '-'

  //printf("--> primop %c (%d) ", f, f); prin1(args); terpri();

  // --- nargs
  switch(f) {
    // - nlambda - no eval
  case ':': return de(args);
  case ';': return df(args);
  case 'I': return iff(args, env);
  case 'R': return lread();
  case '\'':return car(args);
  case '\\':return lambda(args, env);

    // - nargs - eval many args
  case '+': a--;
  case '*':
    while(consp(args)) {
      b= NUM(eval(CAR(args), env));
      args= CDR(args);
      if (f=='*') a*= b; else a+= b;
    } return mknum(a);
  case 'L': return evallist(args, env);
  case 'H': return evalappend(args);
  }


  // --- one arg
  if (!consp(args)) return error;
  a= eval(CAR(args), env);
  args= CDR(args);

  switch(f) {
  case 'A': return car(a);
  case 'D': return cdr(a);
  case 'K': return consp(a);
  case 'O': return length(a);
  case 'P': return print(a);
  case 'T': terpri(); return nil;
  case 'U': return a? mknum(1): nil;
  case 'W': return prin1(a);
  }


  // --- two args
  if (!consp(args)) return error;
  b= eval(CAR(args), env);
  args= CDR(args);

  switch(f) {
  case '%': return mknum(num(a) % num(b));
  case '&': return mknum(num(a) & num(b));
  case '-': return mknum(num(a) - num(b));
  case '/': return mknum(num(a) / num(b));
  case '|': return mknum(num(a) | num(b));

  case 'C': return cons(a, b);
  case 'B': return member(a, b);
  case 'G': return assoc(a, b);
  case 'M': return mapcar(a, b);
  case 'N': return nth(a, b);

  default: return error;
  }
}
