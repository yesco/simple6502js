// isalpha... test <ctype.h>
#include <ctype.h>

word p(word n) {
  if (n) putu(1); else putu(0);
  putchar(' ');
}

word c;

word main() {
  for(c=32; c<128; ++c) {
    putu(c); putchar(' ');
    // indent==no inline
    p(isspace(c));
      p(isxdigit(c));
    p(isdigit(c));
      p(isalnum(c));
    p(isalpha(c));
      p(isupper(c));
      p(islower(c));
      p(ispunct(c));
    p(toupper(c));
    p(tolower(c));
    ++c; putchar('\n');
  }
}
