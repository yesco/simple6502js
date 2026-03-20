#include <stdio.h>
#include <string.h>

typedef unsigned int word;
#define BFILL(arr, v) memset(arr, v, sizeof(arr))

word n, c, i, p, k;
char flag[8192];
int main(){
  n=0; do {
    c=0;

    // no set : 206 B
    //i=0; do flag[i++]= 1; while(i<8192); // 258 B 234s
    //memset(flag, 1, sizeof(flag)); // 247 B 176s
//    BZERO(flag); // 232 B 176s (1.8s 1x!) - wrong need 1!
    BFILL(flag, 1); // 234 B 176s (1.8s 1x!)
    i=0; do {
      if (flag[i]) {
        p= i+i+3;
        k=i+p; while(k<8192) {
          flag[k]= 0;
          k+=p;
        }
        ++c;
      }
      ++i;
    } while(i<8192);
    printf("%u", c);
    ++n;
  } while(n<10);
  return c;
}
