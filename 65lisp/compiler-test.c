// snippets from lisp.c used to test cc65 generated code and speed

#include "extern-vm.c"

// - https://github.com/cc65/cc65/blob/master/libsrc%2Fruntime%2Fldaxi.s


//L fcdr(L c) { return isnum(c)? nil: CDR(c); }

// 11.70521450042724609375 (fcar & fcdr in ASM!)

//L fc3a4dr(L c) {
//  __AX__= c;  fcdr();fcdr();fcdr();fcdr();fcar();fcar();fcar();  //top= __AX__;
//  return __AX__;
//}

// -b -e 10 => 196.76s

// FIB         149s
// 65vm-asm:   386s
// 

//#define FIB

int fib(int n) {
  if (n==0) return n;
  else if (n==1) return n;
  else return fib(n-1) + fib(n-2);
}

int fibb(int n) {
  return n==0?
    n:
    n==1?
    n:
    fib(n-1)+fib(n-2);
}

int fibbb(int n) {
  return !n?
    0:
    !--n?
    1:
    fib(n)+fib(--n);
}

int fub(int a) {
  int b= a+1,
    c= b+1;
  {
    int d= a+b+c;
    {
      int e=a+b+c+d;
      return e+9;
      return e+10000;
    }
  }
}

int varbar= 4711;
int bar(int a) {  
  return varbar+a;
}


#ifdef TESTCOMPILER
L inc(L i) { return i+2; }

L fastcall inc2(L i) { asm("jsr incax2");
  return __AX__; }
#endif


