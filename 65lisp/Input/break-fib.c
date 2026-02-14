// fibonacci recursion

// - for unix
//typedef unsigned int word;

word add(word a, word b) {
  _ return a+b;
}

word fib(word n) {
  _ if (n<2) _ return n;
  // no complex expressions (yet)
  // return fib(n-1) + fib(n-2);
  _ return _ add(_ fib(n-1), _ fib(n-2));
}

word main() {
  _ _ _ _ return fib(24);
}
