word j,i,s;

word xs;

word xorshift() {
  xs ^= xs << 7;
  xs ^= xs >> 9;
  xs ^= xs << 8;
  return xs;
}

word main() {
  xs= 1;
  s= 0;
  j=5; do {
    i= 0; do {
      s+= xorshift();
//      putu(xorshift()); putchar('\n');
;
    } while(--i);
  } while(--j);
  return s;
}
