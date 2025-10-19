// test <ctype.h>
word main() {
//  for(i=0; i<256; ++i) {
  c= 0; while(c<128) {
    putu(c); putchar(' ');
    if (c<33) putchar(' '); else putchar(c);
    putchar(' ');
    {
      putu( isspace(c) ); putchar(' ');
        putu( isxdigit(c)); putchar(' ');
      putu( isdigit(c) ); putchar(' ');
        putu( isalnum(c) ); putchar(' ');
      putu( isalpha(c) ); putchar(' ');
        putu( isupper(c) ); putchar(' ');
        putu( islower(c) ); putchar(' ');
        putu( ispunct(c) ); putchar(' ');
    }
    putchar('\n');
    ++c;
  }
}
