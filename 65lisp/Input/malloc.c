// malloc exuahustion test
word size, total, p;
word main() {
  size= 32768;
  total= 0;

  do {
    p= malloc(size);
    if (p) {
      total+= size;
      putu(total); putchar('\t'); puth(p); putchar('\t'); putu(size); putchar(10);
      // try same size again till fail!
    } else {
      size>>= 1;
      putz("\t -\t"); putu(size); putchar('\n');
    }
    if (!size) return total;
  } while(size);
  return total;
}
