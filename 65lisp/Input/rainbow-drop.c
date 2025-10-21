// Rainbow-droping
#include <stdio.h>
word main() {
  hires();
  b= 40960; // 0xa000

  m= 8000; c= 8; s= m>>3;
  a= b; j= 0;
  i=0; while(i<m) {
//    if (j==0) { --c; j= s; }
//    poke(b+i, c+16);
//    v= c+16;
//    v= 64+32+8+1;
    //WRONG!
    //v= 105; poke(a+i, v);
    poke(a+i, 105); // - ok
    ++i; //++a;
    //++i; --j; a+= 40;
  }
  putu(i);
}
