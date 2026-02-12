// assignment: p[index]= value;
char s[]={'f','o','o','b','a','r',0};
word a,p,z,zz,zd,zo;

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
  a= 3;

  ph("s", s);

  // calibration to remove overhead
  puts("\nINDEX         CHECK BYTES");
  puts(  "=====         ===== =====");
  p= s; // TODO: array-assign-ptrval
  zo= 43+5+1; zz= _PC()+9;
  pc(".   calibrate: ?=", s[3], _PC());
p[3]= 'A';
  pc("p[3]=        : A=", s[3], _PC());
p[(char)a]= 'B';
  pc("p[(char)a]=  : B=", s[3], _PC());
//p[(char)(a)]= 'C';
//  pc("p[(char)(X)]=: C=", s[3], _PC());
  zo+= 6;
  pc(".   calibrate: ?=", s[300], _PC()+10);
p[300]= 'D';
  pc("p[300]=      : D=", s[300], _PC()+10);
  zo-= 6;
  pc(".   calibrate: ?=", s[3], _PC());
p[a]= 'E';
  pc("p[a]=        : E=", s[3], _PC());
p[(a)]= 'F';
  pc("p[(EXPR)]=   : F=", s[3], _PC());
  return 4711;
}
