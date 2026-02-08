word a,b,c;
char sa[4];
char sb[4]={0};
char sc[]={'f','o','o','b','a','r',0};
char sd[]="FooBar";
word fun(){}
word main(){
  puth(&a); puth(&b); puth(&c); putchar('\\n');
  // TODO: array should "degrade" to pointer
  puth(&sa); puts(sa);
  puth(&sb); puts(sb);
  puth(&sc); puts(sc);
  puth(&sd); puts(sd);
  puth(&fun); putchar('\n');
  c= "fish:";
  putz(c);
  putz("That's all ");
  puts("folk's");
  return 4711;
}
