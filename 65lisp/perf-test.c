int fib(int n) {
  if (n<2) return n;
  else return fib(n-1)+fib(n-2);
}

L lispfib(L n) {
  n= num(n);
  if (n<2) return mknum(n);
  else return mknum(num(lispfib(mknum(n-1)))+num(lispfib(mknum(n-2))));
}

L flispfib(L n) {
  n= NUM(n);
  if (n<2) return MKNUM(n);
  else return MKNUM(NUM(lispfib(MKNUM(n-1)))+NUM(lispfib(MKNUM(n-2))));
}

int fib(int n) {
  if (n<2) return n;
  else return fib(n-1)+fib(n-2);
}

// This will FAIL with -Cl optimization!!!
int lfib(int n) {
  int r= n;
  if (n>=2) { r= lfib(n-1); r+= lfib(n-2); }
  //if (n>=2) r= lfib(n-1)+lfib(n-2); // works!
  return r;
}

void perftest() {
  printf("FIB(7)= %d\n", fib(7));
  printf("lFIB(7)= %d\n", lfib(7));
  assert(fib(7)==lfib(7));

  //printf("lispFIB(7)= %d\n", fib(7));
  n= 21;
  printf("FIB(%d)= %d\n", n, fib(21)); // 21=>3s
  printf("lispFIB(7)= %d\n", num(lispfib(mknum(7))));
  //same speed? lispfib and flispfib=macro
  printf("lispFIB(%d)= %d\n", n, num(lispfib(mknum(n)))); // 21=>17s
  printf("FlispFIB(%d)= %d\n", n, NUM(flispfib(MKNUM(n)))); // 21=>17s

//  r= 0;
//  for(i=n; n>0; --n) {
//    r+= fib(30);
//  }

  //printf("TESTS=%d\n", n);

#ifdef FISH
  printf("--- 1\n");
  print(mknum(1));
  printf("--- 2\n");
  print(mknum(2));
  printf("--- (nil . nil)\n");
  print(cons(nil, nil));
  printf("--- (1)\n");
  print(cons(mknum(1), nil));
  printf("--- (1 . 2)\n");
  print(cons(mknum(1), mknum(2)));
  exit(0);
#endif

}
