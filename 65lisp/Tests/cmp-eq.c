// cmp test ==

// (all these are ignored by MeteoriC!)
#include <stdio.h>
#include <stdint.h>
typedef uint16_t word;
#define putu(v) printf("%u",v)
#define putz(s) printf("%s",s)
#define puth(x) printf("$%04x",x)

word a, b, pass;

word report(word v, word s) {
  putz(s);
  putz("\t=> "); putu(v);
  putz("\ta="); puth(a);
  putchar(' '); // lol
  putz("b="); puth(b);
  putchar('\n');
}

word TRUE(word v, word s) {
  if (v) { putz("pass: TRUE\t"); ++pass; }
  else   putz("!!FAIL: TRUE\t");
  report(v, s);
}

word FALSE(word v, word s) {
  if (v) putz("!!FAIL: FALSE\t");
  else   { putz("pass: FALSE\t"); ++pass; }
  report(v, s);
}

int main() {
  pass= 0;

  // 8-bit
  FALSE(3==4, "3==4");
  TRUE(4==4, "4==4");
  FALSE(5==4, "5==4");
  putchar('\n');
  
  a=4;
  FALSE(3==a, "3==a");
  TRUE(4==a, "4==a");
  FALSE(5==a, "5==a");
  putchar('\n');
  
  b=3; FALSE(b==4, "b==4");
  b=4; TRUE(b==4, "b==4");
  b=5; FALSE(b==4, "b==4");
  putchar('\n');

  b=3; FALSE(b==a, "b==a");
  b=4; TRUE(b==a, "b==a");
  b=5; FALSE(b==a, "b==a");
  putchar('\n');

  // 16-bit
  FALSE(0xff==0x100, "0xff==0x100");
  TRUE(0x100==0x100, "0x100==0x100");
  FALSE(0x101==0x100, "0x101==0x100");
  putchar('\n');

  a=0x100;
  FALSE(0xff==a, "0x0ff==a");
  TRUE(0x100==a, "0x100==a");
  FALSE(0x101==a, "0x101==a");
  putchar('\n');
  
  b=0x0ff; FALSE(b==0x100, "b==0x100");
  b=0x100; TRUE(b==0x100, "b==0x100");
  b=0x101; FALSE(b==0x100, "b==0x100");
  putchar('\n');

  b=0x0ff; FALSE(b==a, "b==a");
  b=0x100; TRUE(b==a, "b==a");
  b=0x101; FALSE(b==a, "b==a");
  putchar('\n');

  // unsigned values
  FALSE(-1u==4, "-1u==4"); // lol
  FALSE(0==4, "0==4");
  FALSE(0==-1u, "0==-1u"); // lol
  TRUE(0==-0, "0==-0");
  putchar('\n');

  // TODO: cc65 things this should be FALSE?
  FALSE(-2u==0xffffu, "-2u==0xffffu"); // lol
  TRUE(-1u==0xffffu, "-1u==0xffffu"); // lol
  FALSE(0==-1u, "0==-1u");
  FALSE(-2u==-1u, "-2u==-1u"); // lol
  TRUE(-1u==-1u, "-1u==-1u"); // lol
  FALSE(-2u==2, "-2u==2"); // lol
  TRUE(-2u==-2, "-2u==-2"); // lol
  putchar('\n');

  // IF (var==CONST)
  a= 3;
  if (a==4) FALSE(1, "if(a==4) ...");
  else      FALSE(0, "if(a==4) ...");
  a= 4;
  if (a==4) TRUE(1, "if(a==4) ...");
  else      TRUE(0, "if(a==4) ...");
  a= 5;
  if (a==4) FALSE(1, "if(a==4) ...");
  else      FALSE(0, "if(a==4) ...");
  putchar('\n');

  a= 0xff;
  if (a==0x100) FALSE(1, "if(a==0x100) ...");
  else          FALSE(0, "if(a==0x100) ...");
  a= 0x100;
  if (a==0x100) TRUE(1, "if(a==0x100) ...");
  else          TRUE(0, "if(a==0x100) ...");
  a= 0x101;
  if (a==0x100) FALSE(1, "if(a==0x100) ...");
  else          FALSE(0, "if(a==0x100) ...");
  putchar('\n');

  // WHILE
  a= 0; while(a==10) {
    putu(a);
    TRUE(1, "while(a==10)...");
    ++a;
  }
  //TRUE(a==10, "AFTER while(a==10)...");
  // TODO: assert hang?
  // assert(a==10);
  putchar('\n');

  a= 0x0100; while(a==0x0100) {
    putu(a);
    TRUE(1, "while(a==0x100)...");
    ++a;
  }
  putchar('\n');

  a= 0x0101; while(a==0x0101) {
    putu(a);
    TRUE(1, "while(a==0x101)...");
    ++a;
  }
  putchar('\n');

  a= 0x0102; while(a==0x0102) {
    putu(a);
    TRUE(1, "while(a==0x101)...");
    ++a;
  }
  putchar('\n');

  a= 0x1234; while(a==0x1234) {
    putu(a);
    TRUE(1, "while(a==0x1234)...");
    ++a;
  }
  putchar('\n');

  // DO...WHILE
  a= 41;
  do {
    TRUE(1, "do...while(a<42)");
    ++a;
  } while (a==42);
  putchar('\n');

  a= 41; b= 42;
  do {
    TRUE(1, "do...while(a<b)");
    ++a;
  } while (a<b);
  putchar('\n');

  // FOR
  // - no need as there is nothing specific for == ???

  // return number of failures
  return 48-pass;
}
