// test <ctype.h>
#include <ctype.h>
word main() {
//  for(i=0; i<256; ++i) {
  c= 0; while(c<128) {
    putu(c); putchar(' ');
    // indent==no inline
    putu(isspace(c));putchar(' ');
      putu(isxdigit(c));putchar(' ');
    putu(isdigit(c));putchar(' ');
      putu(isalnum(c));putchar(' ');
    putu(isalpha(c));putchar(' ');
      putu(isupper(c));putchar(' ');
      putu(islower(c));putchar(' ');
      putu(ispunct(c));putchar(' ');
    putchar(toupper(c));putchar(' ');
    putchar(tolower(c));putchar(' ');
    ++c; putchar('\n');
  }
}
