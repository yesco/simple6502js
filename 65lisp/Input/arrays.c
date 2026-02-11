// 5 ways of arrays
char sa[4];
char sb[4]={0};
char sc[]={'f','o','o','b','a','r',0};
char sd[]="FooBar";
word a,b,c,z,zz;

word pc(word expect, word got){
  putz(expect); putchar(got); putchar('\n');
}
word ph(word name, word u){
  putz(name); putz(": "); puth(u); putchar(' '); puts(u);
}
word main(){
  a= 3; b= a+1;
  strcpy(sa, "fie"); strcpy(sb, "fum");

  puts("started...");
  ph("sa", sa); ph("sb", sb); ph("sc", sc); ph("sd", sd);

  pc("foo : x=", 'x');
  pc("3   : b=", sc[3]);
  pc("300 : ?=", sc[300]); // lol, crap
  pc("2+1 : b=", sc[2+1]); // wrong
  pc("a   : b=", sc[a]); // wrong
  pc("b-1 : b=", sc[b-1]); // wrong
  return 4711;
}
