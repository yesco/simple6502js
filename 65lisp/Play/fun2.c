char T,nil,doapply1,print;
typedef unsigned int word;

word plus(word a, word b) {
//  putu(a); putchar(' '); putu(b); putchar('\n');
  return a+b;
}

word r, i;
word main() {
  for(i=1000; i--;) 
    r= plus(plus(1,
                 plus(2, plus(3,4)) ),
            plus(plus(5,plus(6,7)),
                 plus(8,plus(9,10)) ) );
  return r;
}
