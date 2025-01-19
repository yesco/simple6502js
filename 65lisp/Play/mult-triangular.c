#include <stdio.h>

#ifdef FOO
int get_input(const char* prompt) {
    printf("%s", prompt);
    int n;
    scanf("%d", &n);
    int is_non_negative = n >= 0;
    printf(is_non_negative ? "" : "Invalid input. Please enter a non-negative integer.\n");
    return is_non_negative ? n : get_input(prompt);
}
#endif

char log2(unsigned int n) {
  char r= 0;
  if (n>=256) { r=8; n/=256; }
  if (n>=16) { r+=4; n/=16; }
  while(n) n/=2,++r;
  return r-1;
}

int T(int n) {
  static int l;
  return (n == 0) ? 0 :
    (l = log2(n),
     (((((n<<1) ^ (2<<l)) + (1<<l) + 1) << l) >> 1)
     + T(n^(1<<l)));
}

unsigned recmul(unsigned int a, unsigned int b) {
  return b==0? 0: (recmul(a, b/2)<<1)+(b&1? a: 0);
}

static unsigned int r, aa, bb;

unsigned loopmul() {
  // unsigned int a, unsigned int b) {
  //register unsigned int r, aa, bb; // slower!
  r= 0; //aa= a; bb= b;
  while(bb) {
    if (bb&1) r+= aa;
    bb/= 2; aa*= 2;;
  }
  return r;
}

void main() {
  char i= 0;
  unsigned int a= 167;
  unsigned int b= 217;

  for(; i<10; ++i) {

    // 278098c - built-in multiplication (library) on cc65
    //printf("The product of %u and %u is %u\n", a, b, a*b);

    // 456055c - Triangular "multiplication" (double cost)
    //           using improved log2
    //printf("The product of %d and %d is %d\n", a, b, T(a + b) - T(a) - T(b));

    // 300871c - recmul - rec mul (8.2% worse than builtin)
    //printf("The product of %u and %u is %u\n", a, b, recmul(a,b));

    // 298222c - loop mul (7.2% worse than builtin)
    // 296012c - static r (6.4% worse than builtin)
    // 287120c - static r,a,b (3.2% overhead cmp builtin)
    // 285770c - passing by global var (2.8% overhead)
    printf("The product of %u and %u is %u\n", a, b, (aa=a,bb=b,loopmul()));

    ++b;
  }
}
