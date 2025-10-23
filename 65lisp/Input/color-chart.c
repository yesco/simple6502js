#include <stdio.H>
word main() {
  r= 0; while(r<8) {
    putcraw(16+r); putu(r);
    putchar(' '); putchar(' ');

    c= 0; while(c<8) {
      putcraw(c); putu(c);
      putcraw(c+128); putcraw(128+'0'+c); //+128);
      ++c;
    }

    putchar('\n');
    ++r;
  }
}
