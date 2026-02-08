word a,b,c;
char sa[4];
char sb[4]={0};
char sc[]={'f','o','o','b','a','r',0};
char sd[]="FooBar";
word fun(){}
word main(){
  puth(&a); puth(&b); puth(&c); putchar('\\n');
  // TODO: array should "degrade" to pointer
  puth(&sa); putchar(' '); putu(sizeof(sa)); puts(sa);
  puth(&sb); putchar(' '); putu(sizeof(sb)); puts(sb);
  puth(&sc); putchar(' '); putu(sizeof(sc)); puts(sc);
  puth(&sd); putchar(' '); putu(sizeof(sd)); puts(sd);
  puth(&fun);putchar(' '); puth(sizeof(fun));putchar('\n');
  c= "fish:"; puth(sizeof(c)); putchar('\n');
  putz(c);
  putz("That's all ");
  puts("folk's");
  return 4711;
}
