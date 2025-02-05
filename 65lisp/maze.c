#define TEXT ((char*)0xBB80)
#define TSIZE (28*40)

#define HIRES ((char*)0xA000)
#define HSIZE (200*40)

#define TEXTMODE  26 // and 24-39 (2x 60 Hz, 2x 50 Hz)
#define HIRESMODE 30 // and 28-31 (2x 60 Hz, 2x 50 Hz)

#include <string.h>

 // dummys
 int T, nil, print, doapply1;

 // TODO: asm
 void fill(char* p, char v, char n) {
   ++n; p-= 40;
   while(--n!=0) *(p+=40)= v;
 }

void waitms(long w) {
  w <<= 3;
  while(--w>=0);
}

void main() {
  *(TEXT+TSIZE-1)= HIRESMODE;
  memset(HIRES, 64, HSIZE);
  {
    static char c,i,j,n, *u, *l, s;
    // TODO: draw fine line 

    s= 0;
    while(1) {
      c= ++s;
      u= HIRES+100*40;
      // TODO: draw other way around, then only need update colors!
      i= 100-1-1;
      n= 1;
      while(--i!=0) {
        // draw one color
        j= ++n;
        while(--j!=0 && u<HIRES+HSIZE-40) *(u+= 40)= 16+(c&7);
        ++c;
      }
      waitms(15);
    }
  }
}

/*
    while(1) {
      if (--ns==0) { ++cc; ns= nc; }
      ni= ns;
      left = HIRES- 1-5*40;
      right= HIRES+39-5*40;
      n= 200+12;
      // TODO: draw other way around, then only need update colors!
      for(i= 1; i<21; ++i) {
        fill(left += 5*40+1, 16+(c&7), n-= 10);
        fill(right+= 5*40-1, 16+(c&7), n);
        if (--ni==0) { ni= --nc; ++c; }
      }
    }

*/
