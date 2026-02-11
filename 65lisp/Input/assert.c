// debug assert(13) test!
#include <assert.h>

word i;

word main() {
  puts("-- before assert");
  i=0;
  while(++i) {
    putu(i); putchar(' ');
    // don't become 13!
    assert(i-13); 

  }
  puts("--- after assert: Won't get here");
}
