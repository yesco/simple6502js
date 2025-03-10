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

    char cs= 1;
    s= 0;
    while(1) {
      c= cs;
      ++s;
      u= HIRES+HSIZE;
      i= 100-1-1;
      n= 14;

      // first bar, varying start - "moving one pixel forward"
      j= --n-s;
      if (j<=1) { s= 1; ++cs; }
      while(--j!=0) *(u-= 40)= 16+(c&7);

      // rest
      while(1) {
        // draw one color
        if (i==0 || (j= --n)<=1) break;
        ++c;
        while(--j!=0 && --i!=0) *(u-= 40)= 16+(c&7);
      }
      waitms(10);
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
