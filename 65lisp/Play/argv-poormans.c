// poor mans argv, LOL
#define ARG(n) (*((uint*)(&len-2*n)))

#ifdef BAR
void __cdecl__ addasm(char* x, uchar len, ...) {
  uchar c, n= 1;
  uint* p= (uint*)&len;
  //va_list ap;
  //va_start(ap, fmt);
  //for(c=1; c<15; ++c) printf("%04X = %04x\t", ARG(c), *--p);   putchar('\n');

  printf("ASM[%d]:  \"%s\"\n", len, x);
  for(bi=0 ;bi<len; ) {
    c= x[bi];

    if (c=='#') { buff[bz]= *--p; ++n; }
    else if (c=='?') { buff[bz]= *--p; ++bz; ++bi; buff[bz]= *p >> 8; ++n; }
    else buff[bz]= c;
 
    ++bz;
    buff[bz]= 0; // BRK, haha

    ++bi;
  }
  printf("ASM[%d]=> \"%s\"\n", len, buff);
}

#endif // BAR
