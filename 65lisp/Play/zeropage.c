// Dummys for ./r script LOL
int T,nil,doapply1,print;

// 2434 bytes with printf
#include <stdio.h>
#include <conio.h>
#include <string.h>

// empty main: 284 Bytes
void main() {
  static int i, v, x, y;
  static int n= 0;
  static char buff[256];

  // Turn off interrupt... still goes wrong!
  asm("sei");

  memcpy(buff, 0, sizeof(buff));

  clrscr();

  while(1) {
    static char s[16]= {0};
    sprintf(s, "%d      \n", n);
    cputsxy(2, 3, s);

    // check
    #define DIV 12
    for(i=0; i<256; ++i) {
// CRASH! include this line and it'll crash at 19-20!
// even if interrupts off
//      if (i%DIV==0) putchar('\n');
      v= *(char*)i;
      x= 2+(i%DIV)*3;
      y= 5+(i/DIV);
      cputcxy(x, y, v==buff[i]? 4: 1);
      sprintf(s, "%02x\n", v);
      cputsxy(x+1, y, s);
    }

    ++n;
  }
}


