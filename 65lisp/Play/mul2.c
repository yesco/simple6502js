char T,nil,doapply1,print;
typedef unsigned int word;

word mul(word a, word b) {
//  putu(a); putchar(' '); putu(b); putchar('\n');
  if (!a) return 0;
  if (a&1) return mul(a/2, b*2)+b;
  return mul(a/2, b*2);
}
word i,r;
word main() {
//  return mul(3,4);
//  for(i=0;i--;)
    r= mul(40,40);
  return r;
}

