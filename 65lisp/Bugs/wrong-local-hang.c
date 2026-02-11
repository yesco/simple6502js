// 5 ways of arrays
char sa[4];
char sb[4]={0};
char sc[]={'f','o','o','b','a','r',0};
char sd[]="FooBar";
word a,b,c,z,zz;

word fun(){}
word pc(word expect, word got){
  putz(expect); putchar(got); putchar('\n');
}
word ph(word u){
  puth(u); putchar(' '); puts(u);
}
word main(){
  a= 3; b= a+1;
  strcpy(sa, "fie"); strcpy(sb, "fum");
  ph(sa); ph(sb); ph(sc); ph(sd);

  pc("b: ", sc[3]);
  pc("b: ", sc[2+1]);
  pc("b: ", sc[a]);
  pc("b: ", sc[b-1]);
  return 4711;
}
