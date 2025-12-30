typedef unsigned int word;

// dummy
char T,nil,print,doapply1;

#define MAIN
#include "../hires-raw.c"

#include "../sound.c"

char* row[HIRESROWS];

char arr[HIRESROWS];

char get(char r, char color) {
  char v= arr[r];
//  word period= v*2;
  word period= v;
  char *p= row[r];
  
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
  char *p= row[r];

  *p= color;

  // draw line; optimized
  while(v>=6) { p[c]= 0b1111111; ++c; v-= 6; }
  p[c]= partline[v];
  while(c<40) p[++c]= 0;
}

#define DBLE 10;

void printname(char* s) {
  char c= (40-strlen(s))/2;
  char *p= TEXTSCREEN + 25*40;

  memset(p, ' ', 3*40);

  p+= 40+c;
  
  *p= DBLE;
  strcpy(p+1, s);

  p+= 40;

  *p= DBLE;
  strcpy(p+1, s);
}

void selectionsort() {
  char r, i, v, vv, at, t;

  printname("SelectionSort");

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
    show(r, 7);  // reset color
  }
}

void insertsort() {
  char r, i, v, vv, at, t;

  printname("InsertSort");

  v= get(0, 1);
  show(0, 7);
  for(r= 1; r<HIRESROWS-1; ++r) {
    // next to insert
    v= get(r, 1);
    for(i= 0; i<r; ++i) {
      vv= get(i, 1);
      if (vv >= v) break;
      get(i, 7);
    }
    get(r, 7);

    at= i;

    // move up rest
    while(i < r) {
      t= get(i, i==at? 4: 1);
      arr[i]= v;
      v= t;
      show(i, 7);
      ++i;
    }
    arr[i]= v;
    show(i, 7);

    get(at, 4);
  }
}

void main() {
  char r, m;
  char *p= HIRESSCREEN;

#undef putchar
  putchar('Q'-'@'); // cursor off

  // init row array
  for(r=0; r<HIRESROWS; ++r) {
    row[r]= p;
    p+= 40;
  }

  // run through different sorts
  for(m=1; m<=2; ++m) {

    play(1, 0, 0, 10);
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
    case 2: selectionsort(); break;
//    case 3: quicksort(); break;

// TODO: doesn't work?
    }

    // show result
    for(r= 0; r<HIRESROWS; ++r) {
      wait(1);
      show(r, 2);
    }

    sfx(SILENCE);
    
    wait(150);
  }
 

halt:
  goto halt;
}
