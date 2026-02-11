// indeXing: arr[ INDEX ] cost in bytes
char s[]={'f','o','o','b','a','r',0};
word a,b,p,z,zz,zd,zo;

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
  p= s;
  zo= 43; zz= _PC()+24;
  pc("calibrate   : ?=", p[3], _PC());
  pc("p[3]        : b=", p[3], _PC());
  pc("p[(char)a]  : b=", p[(char)a], _PC());
  pc("p[(char)(a)]: b=", p[(char)(a)], _PC());
  pc("p[300]      : ?=", p[300], _PC());
  pc("p[a]        : b=", p[a], _PC());
  pc("p[(a)]      : b=", p[(a)], _PC());
  return 4711;
}
