// isalpha... test <ctype.h>
#include <ctype.h>
word c;
word main() {
//  for(i=0; i<256; ++i) {
  c= 0; while(c<128) {
    putu(c); putchar(' ');
    // indent==no inline
    putu(isspace(c));putchar('\t');
      putu(isxdigit(c));putchar('\t');
    putu(isdigit(c));putchar('\t');
      putu(isalnum(c));putchar('\t');
    putu(isalpha(c));putchar('\t');
      putu(isupper(c));putchar('\t');
      putu(islower(c));putchar('\t');
      putu(ispunct(c));putchar('\t');
    putchar(toupper(c));putchar('\t');
    putchar(tolower(c));putchar('\t');
    ++c; putchar('\n');
  }
}
