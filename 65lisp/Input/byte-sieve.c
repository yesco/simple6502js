// BYTE SIEVE PRIME benchmark
word m, a, n, c, i, p, k;
word main(){
  m=8192;
  a=malloc(m);
  n=0; do {
    c=0;
    i=0; do {
      poke(a+i, 1); ++i;
    } while(i<m);
    i=0; do {
      if (peek(a+i)) {
        p= i*2+3;
        k=i+p; while(k<m) {
          poke(a+k, 0);
          k+=p;
        }
        ++c;
      }
      ++i;
    } while(i<m);
    putu(c);
    ++n;
  } while(n<10);
  free(a); return c;
}
