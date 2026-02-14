// fatorial example - by Ribeiro :)
word n;

word factorial(word n) {
  if (n == 1) {
    return 1;
  }
  return n * factorial(n - 1);
}

word main() {
  putu(factorial(6));
  return 0;
}
