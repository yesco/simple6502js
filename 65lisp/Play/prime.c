typedef unsigned char byte;
typedef unsigned int  word;

word t,n,z,i;

//#include <stdio.h>

// dummy
int putchar(int a) {
  return a;
}

void printd(word n) {
//  printf("%d", n);
  if (n>=10) printd(n/10);
  putchar(n%10);
}


// this is from parse-asm.asm: PRIME w rewrites

byte arr[256];

//byte b[4];
int main(){
//  word n,i;
//  byte t;
//  arr[0]=0xff;
  arr[0]=255;
//;; TODO: for!
//  for(t=1; t; ++t) arr[t]=0xff;
//  for(t=1; t; ++t) arr[t]=255;
  t=1; while(t<256) { arr[t]=255; ++t; }

//  for(n=2; n<2048; ++n) {
  n=2; while(n<2048) {

//;; TODO: no paren
//    if (arr[n>>3] & (1<<(n&7))) {
    z=n&7; z=1<<z;
    if (arr[n>>3] & z) {

      i=n;
      //           // simulates printd?
#ifndef SIMPRINTD
      printd(i);
#else
      t=0;
      do {
        b[t++]= (i%10)+'0';
        i/=10;
      } while(i);
      do {
        putchar(b[--t]);
      } while(t);
#endif
//      putchar(' ');
      putchar(32);

//      for(i=n+n; i<2048; i+= n) {
      i=n*2; while(i<2048) {

//        a[i>>3]&= ~(1<<(i&7));
//        a[i>>3]&= (1<<(i&7))^0xffff;

//        arr[i>>3]&= (1<<(i&7))^65535;
        z=i&7; z=1<<z; z^=65535;
//        arr[i>>3]&= z;
        z&=arr[i>>3];
        arr[i>>3]= z;

        i+=n;

      }
    }
//;; TODO: no for-loop
    ++n;
  }
}
