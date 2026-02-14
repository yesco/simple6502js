----------------------------------------
// yet another example of fibonaci
// using arrays, but this time it uses
// word. Doke/Deek didn't work as as
// expected (I guess...) so I resorted
// to this "hackish" byte addressing, lol
word fa;
word i, x, y;
word val, ptr, idx;

word my_doke(word idx, word val) {
  ptr = 2 * idx;
  poke(fa + ptr, val);

  // fill second byte
  ptr = ptr + 1;
  if (val < 256) {
    poke(fa + ptr, 0);
  } else {
    poke(fa + ptr, val >> 8);
  }

  return 0;
}

word fib(word n) {
  fa = xmalloc(n * 2);
  i = 0;
  while (i < n) {
    if (i < 2) {
      val = i;
    } else {
      // retrive the two previous positions in array
      x = 2 * (i - 1);
      y = 2 * (i - 2);
      val = deek(fa + x);
      val += deek(fa + y);
    }

    my_doke(i, val);

    ptr = i * 2;  // needs to align byte for deek
    putu(i);
    putchar(' ');
    putu(deek(fa + ptr));
    putchar('\n');

    ++i;
  }

  return 0;
}

word main() {
  fib(25);
  return 0;
}
