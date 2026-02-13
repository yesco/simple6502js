// assignment: arr[index]= value;
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
  puts("\nINDEX       CHECK BYTES");
  puts(  "=====       ===== =====");
  //p= s; // TODO: array-assign-ptrval
  zo= 43+5+1; zz= _PC()+9;
  pc(".   calibrate: ?=", s[3], _PC());
s[3]= 'A';
  pc("s[3]=        : A=", s[3], _PC());
s[(char)a]= 'B';
  pc("s[(char)a]=  : B=", s[3], _PC());
s[(char)(a)]= 'C';
  pc("s[(char)(X)]=: C=", s[3], _PC());
  zo+= 6;
  pc(".   calibrate: ?=", s[300], _PC()+10);
s[300]= 'D';
  pc("s[300]=      : D=", s[300], _PC()+10);
  zo-= 6;
  pc(".   calibrate: ?=", s[3], _PC());
s[a]= 'E';
  pc("s[a]=const   : E=", s[3], _PC());
zo+= 4;
  pc(".   calibrate: ?=", s[300], _PC()+10);
s[a]= 'P'+1;
  pc("s[a]=EXPR    : Q=", s[3], _PC());
zo-= 4;
  pc(".   calibrate: ?=", s[300], _PC()+10);
s[(a)]= 'F';
  pc("s[(EXPR)]=   : F=", s[3], _PC());
  return 4711;
}
