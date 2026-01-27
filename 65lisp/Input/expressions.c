// Expressions - limitations
word a, b, c, line;

word main() {
  a= 47; b= a;
  // Restrictions on precedence
  // CANT!
  //   c= a>>2   +   b*100;
  
  // Instead write simple expressions:
  a>>= 2; c= b*100+a;
  putu(c); putchar('\n');

  // So the rule is:
  //
  //         COMPLEX   FIRST!
  //
  // var = COMPLEX + simple - simple;

  // Inline multiply by 40:
  line= 25;
  // (line*4 +line) *4;
  return line <<2 +line <<3;
}
