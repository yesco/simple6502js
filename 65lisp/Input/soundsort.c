typedef unsigned int word;

// dummy
char T,nil,print,doapply1;

#define MAIN
#include "../hires-raw.c"

#include "../sound.c"

char arr[HIRESROWS];

char get(char r, char color) {
  char v= arr[r];
  word period= v*2;
  char *p= HIRESSCREEN + 40*r;
  
  *p= color;

  if (color!=7) {
    play(1, 0, 0, 10);
    sound(1, period, 5);
  }

  return v;
}

char partline[]= {0b1100000, 0b1110000, 0b1111000, 0b1111100,
 0b1111110, 0b1111111};

void show(char r, char color) {
  char c=1, v= get(r, color);
  char *p= HIRESSCREEN + 40*r;

  *p= color;

  // draw line; optimized
  while(v>=6) { p[c]= 0b1111111; ++c; v-= 6; }
  p[c]= partline[v];
  while(c<40) p[++c]= 0;
}

void insertsort() {
  char r, i, v, vv, at, t;

  for(r= 0; r<HIRESROWS-1; ++r) {
    // find smallest
    at= r; v= get(r, 1);
    for(i= r+1; i<HIRESROWS; ++i) {
      vv= get(i, 1);
      if (vv < v) {
        at= i; v= vv;
      }
      get(i, 7);
    }

    // swap w smallest
    t= arr[r];
    arr[r]= v;
    arr[at]= t;

    show(at, 4); // indicate swapped
    show(r, 2); // indicate sorted
  }
}

void main() {
  char r, m;

  putchar('Q'-'@'); // cursor off

  m=0; while(1) {
    ++m;

    sfx(SILENCE);

    hires();
    gclear();
  
    // randomize values
    for(r= 0; r<HIRESROWS; ++r) {
      arr[r]= rand() % 220;
      show(r, 7);
    }

    switch(m) {

    case 1: insertsort(); break;
//    case 1: quicksort(); break;

    otherwise: goto halt;
    }

    sfx(SILENCE);
  }
 

halt:
  goto halt;
}
