// fibonacci recursion

// - for unix
//typedef unsigned int word;

word add(word a, word b) {
  return a+b;
}

word fib(word n) {
  if (n<2) return n;
  // no complex expressions (yet)
  // return fib(n-1) + fib(n-2);
  return add(fib(n-1), fib(n-2));
}

word main() {
  return fib(24);
}
