// BYTE SIEVE PRIME benchmark
word main(){
  m=8192;
  a=malloc(m);
  n=0; while(n<10) {
    c=0;
    i=0; while(i<m) {
      poke(a+i, 1); ++i;
    }
    i=0; while(i<m) {
      if (peek(a+i)) {
        p= i*2+3;
        k=i+p; while(k<m) {
          poke(a+k, 0);
          k+=p;
        }
        ++c;
      }
      ++i;
    }
    putu(c);
    ++n;
  }
  free(a);
  return c;
}
