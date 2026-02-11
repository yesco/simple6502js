// indeXing: arr[ INDEX ] cost in bytes
char s[]={'f','o','o','b','a','r',0};
word a,b,c,z,zz,zd,zo;

word ph(word name, word u) {
  putz(name); putz(": "); puth(u);
  putchar(' '); puts(u);
}

word pc(word expect, word got, word z){
  putz(expect);
  // no || or
  if (got<' ')       putchar('?');
  else if (126<got)  putchar('?');
  else               putchar(got);
  putchar(' '); putchar(' ');
  zd= z-zz-zo; putu(zd);
  zz= z;
  putchar('\n');
  return zd;
}

word main(){
  a= 3; b= a+1;

  ph("s", s);

  // calibration to remove overhead
  puts("\nINDEX       CHECK BYTES");
  puts(  "=====       ===== =====");
  zo= 43; zz= _PC()+9;
  pc("calibrate   : ?=", s[3], _PC());
  pc("s[3]        : b=", s[3], _PC());
  pc("s[(char)a]  : b=", s[(char)a], _PC());
  pc("s[(char)(a)]: b=", s[(char)(a)], _PC());
  pc("s[300]      : ?=", s[300], _PC());
  pc("s[a]        : b=", s[a], _PC());
  pc("s[(a)]      : b=", s[(b)], _PC());
  return 4711;
}
