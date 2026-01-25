// strXXX functions tests
word s,foo,bar;

word p(word s) {
  putchar('>'); putz(s); putchar('<');
  putz("   #"); putu(strlen(s));
  putchar('\n');
}

word main() {
  foo= "foo";
  bar= "bar";
  // no way to allocate arrays yet ;-)
  s= "      ";
  p(s);
  strcpy(s, foo);
  //memcpy(s, foo, 4); - wrong?
  p(s);
  strcat(s, bar);
  p(s);
}
