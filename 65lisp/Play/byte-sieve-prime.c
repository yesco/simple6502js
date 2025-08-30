// From: onthe6502.pdf - by 
//  jsk: modified for single letter var, putchar
//
// See results cmp in ../parse-asm.asm PRIME

// 5.37s -Or
// 4.17s -Cl -Or
//       other... if all inlined... /2 ?

#include <stdio.h>

typedef unsigned char byte;
typedef unsigned int word;

byte a[256];
byte b[4];

word main(){
  word n,i;
  byte t;
  a[0]=0xff;
  for(t=1; t; t++) a[t]=0xff;
  for(n=2; n<2048; n++) {
    if (a[n>>3] & (1<<(n&7))) {
      i=n;
      t=0;
      // simulates printd?
      do {
        b[t++]= (i%10)+'0';
        i/=10;
      } while(i);
      do {
        putchar(b[--t]);
      } while(t);
      putchar(' ');
      for(i=n+n; i<2048; i+= n) {
        a[i>>3]&= ~(1<<(i&7));
      }
    }
  }
}
