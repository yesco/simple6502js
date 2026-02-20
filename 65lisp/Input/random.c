word x,j,i,s;

word xs;

word xorshift() {
  xs ^= xs << 7;
  xs ^= xs >> 9;
  xs ^= xs << 8;
  return xs;    
}

word main() {
//  srand(1);
  xs= 1;
  s= 0;
  j=0; while(j<5) { ++j;
    i= 0; while(++i) {
//      x+= rand();
      x+= xorshift();
//      putu(rand()); putchar('\n');
//      putu(xorshift()); putchar('\n');
    }
  }
}
