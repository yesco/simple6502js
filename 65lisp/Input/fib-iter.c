// a iterative fibonacci example,
// I restricted to a byte of storage
word fa, i, val, x, y, res;

word fib(word n) {
  fa = xmalloc(n);
  i = 0;
  while (i < n) {
    if (i < 2) {
      val = i;
    } else {
      x = i - 1;
      y = i - 2;
      // val = peek(fa + x) + peek(fa + y); // doesn't support
      // val = peek(fa + (i - 1)); // doesn't support
      val = peek(fa + x);
      val += peek(fa + y);
    }

    poke(fa + i, val);

    // print
    putu(i);
    putchar(' ');
    putu(peek(fa + i));
    putchar('\n');

    ++i;
  }
  return 0;
}

word main() {
  fib(14);  // 14 > 256
  return 0;
}
