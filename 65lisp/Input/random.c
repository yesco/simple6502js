// random numbers

// give a random nubmer [0..below[
word _r, _m; // locals, LOL
word random(word below) {
  // make a bigger than below bitmask
  _m= 1;
  while(_m < below) _m*= 2;
  --_m;

  do {
    _r= rand() & _m;
  } while (_r >= below);
  return _r;
}

word j, i;

word main() {
  srand(1);
  s= 0;
  j=5; do {
    i= 0; do {
      // 0-42
      putu(random(43)); putchar('\n');
    } while(--i);
  } while(--j);
}
