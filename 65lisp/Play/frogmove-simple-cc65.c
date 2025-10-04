// compiling on cc65 requires "compat" library

// ./tap Play/frogmove-simple-cc65

typedef unsigned char byte;
typedef unsigned int word;

word a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z;

void poke(int a, unsigned char v) {
  *(char*)a= v;
}

unsigned char peek(int a) {
  return *(char*)a;
}

// dummy for ./tap script
char nil,doapply1,print;

#include "frogmove-simple.c"
