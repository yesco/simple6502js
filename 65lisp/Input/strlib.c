// strXXX functions tests
word s, foo, bar, fie, fum, r, c;
word px(word name, word v) {
  putz(name); putchar('"'); putz(v);
  putz("\" #"); putu(strlen(v));
  putchar('\n');
}
word p(word name, word x){
  px(name, x); px("s=       ", s); }
word main() {
foo="foo";bar="bar";fie="fie";fum="fum";
  s= "123abc456def789"; p("alloc  ->", s);
// hangs - can't use const as param
//putchar('O'); p(strcpy(s, "foo"));
  p("strcpy ->", strcpy(s, foo));
//putchar('A'); p(strcat(s, "bar"));
  p("strcat ->", strcat(s, bar));
  r=stpcpy(strlen(s)+s, fie);
  p("stpcpy ->", r);
  p("strcat ->", strcat(r, fum));
  r= strchr(s, 'u'); p("strchr ->", r);
  *r= toupper(*r); p("toupper->", s);
  *s= 'F';         p("*s='F'   ", s);
}
