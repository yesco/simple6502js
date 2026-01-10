// ./r Play/fun1
// 369 Jan 11 00:40 Play/fun1.sim
// 457 Jan 11 00:40 Play/fun1.tap
// 13768 cycles


char T,nil,doapply1,print;
typedef unsigned int word;

word summer(word a) {
//  putu(a); putchar(' ');
  if (a==0) return 0;
  return summer(a-1)+a;
}
word main() { return summer(41); }

