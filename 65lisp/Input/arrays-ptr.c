// 5 ways of arrays
char sa[4];
char sb[4]={0};
char sc[]={'f','o','o','b','a','r',0};
char sd[]="FooBar";
word a,b,c,z,zz,zd,zo;

word ph(word name, word u) {
  putz(name); putz(": "); puth(u); putchar(' '); puts(u);
}

word pc(word expect, word got, word z){
  putz(expect);
  // no || or
  if (got<' ')
    putchar('?');
  else if (126<got)
    putchar('?');
  else
    putchar(got);
  putchar(' ');
  putchar('  ');
  zd= z-zz-zo;
  putu(zd);
  zz= z;
  putchar('\n');
  return zd;
}

word main(){
  a= 3; b= a+1;
  strcpy(sa, "fie"); strcpy(sb, "fum");

  ph("sa", sa); ph("sb", sb); ph("sc", sc); ph("sd", sd);

  // calibration to remove overhead
  puts("\nINDEX       CHECK BYTES");
  puts(  "=====       ===== =====");
  zo= 46; zz= _PC()+8;
  p= &sc;
  pc("calibrate   : ?=", sc[3], _PC());
  pc("p[3]        : b=", p[3], _PC());
  pc("p[(char)a]  : b=", p[(char)a], _PC());
  pc("p[(char)(a)]: b=", p[(char)(a)], _PC());
  pc("p[300]      : ?=", p[300], _PC());
  pc("p[a]        : b=", p[a], _PC());
  pc("p[(a)]      : b=", p[(b)], _PC());
  
  return 4711;
}
