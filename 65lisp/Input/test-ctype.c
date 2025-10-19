// test <ctype.h>
void T() {
  putu(a); putchar(' ');
}

word main() {
//  for(i=0; i<256; ++i) {
  c= 0; while(c<128) {
    putu(c); putchar(' ');
    if (c<33) putchar(' '); else putchar(c);
    putchar(' ');
    {
      // extra indented rows cannot be inlined CTYPE

      putu( isspace(c) ); putchar(' ');
        putu( isxdigit(c)); putchar(' ');
      putu( isdigit(c) ); putchar(' ');
        putu( isalnum(c) ); putchar(' ');
      putu( isalpha(c) ); putchar(' ');
        putu( isupper(c) ); putchar(' ');
        putu( islower(c) ); putchar(' ');
        putu( ispunct(c) ); putchar(' ');
        
// TODO: fix function call: T uses wrong address?
//      a= isspace(c); T();
//        a= isxdigit(c); T();
//      a= isdigit(c); T();
//        a= isalnum(c); T();
//      a= isalpha(c); T();
//        a= isupper(c); T();
//        a= islower(c); T();
//        a= ispunct(c) ); T();

      putchar( toupper(c) ); putchar(' ');
      putchar( tolower(c) ); putchar(' ');
    }
    putchar('\n');
    ++c;
  }
}
