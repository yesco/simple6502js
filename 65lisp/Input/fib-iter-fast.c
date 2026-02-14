// iterative fibonacci using two vars
// it is efficient as expected
// consumes 2,825,391 cycles while
// recursive fibonacci (fib-list.c)
// consumes 96,401,559 cycles
// by Ribeiro
word a, b, i, tmp;

word fib(word n) {
  if (n < 2) return n;
  a = 0;
  b = 1;
  i = 0;
  do {
    putu(i);
    putchar('\t');
    putu(a);
    putchar('\n');
    tmp = b;
    b = a + b;
    a = tmp;
    ++i;
  } while (i < n);
  return b;
}

word main() {
  fib(24);
  return 0;
}
