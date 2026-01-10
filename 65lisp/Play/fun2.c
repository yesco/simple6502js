char T,nil,doapply1,print;
typedef unsigned int word;

word plus(word a, word b) {
//  putu(a); putchar(' '); putu(b); putchar('\n');
  return a+b;
}

word main() {
  return plus(plus(1,
                   plus(2, plus(3,4)) ),
              plus(plus(5,plus(6,7)),
                   plus(8,plus(9,10)) ) );
}
