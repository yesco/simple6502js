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

#define DBLE 10

char *lastname= NULL;

void printname(char* s) {
  char c= (40-strlen(s))/2;
  char *p= TEXTSCREEN + 25*40;

  lastname= s;
  memset(p, ' ', 3*40);

  p+= 40+c;
  
  *p= DBLE;
  strcpy(p+1, s);

  p+= 40;

  *p= DBLE;
  strcpy(p+1, s);
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

void bubblesort() {
  char r, i, v, vv;

  printname("BubbleSort");

  i= 1;
  while(i) {
    i= 0;
    for(r= 0; r<HIRESROWS-1; ++r) {
      v = get(r,   1);
      vv= get(r+1, 1);
      if (v > vv) {
        ++i;
        arr[r]  = vv;
        arr[r+1]= v;
        show(r,  7);
        show(r+1, 7);
      } else {
        get(r,   7);
        get(r+1, 7);
      }
    }
  }
}

void qs(char a, char b) {
  // only one - nothing to sort
  if (a>=b) return;

  // swap if 2 in wrong order
  if (a+1==b) {
    char v= get(a, 1);
    char vv= get(b, 1);
    if (vv < v) {
      arr[a]= vv;
      arr[b]= v;

      show(a, 7);
      show(b, 7);
    } else {
      get(a, 7);
      get(b, 7);
    }
    return;

  } else {

    // else divide by middle pivot 
    char pi = (a+b)/2;
    char pv = get(pi, 1);
    char oa= a, ob= b;
    char v, vv;

    while(a<b) {
      // move up lower boundary if < 
      --a;
      do {
        ++a;
        v= get(a, 1);
      } while(a<b && v<pv);
      
      // move down upper boundary if >=
      ++b;
      do {
        --b;
        vv= get(b, 1);
      } while(a<b && vv>=pv);

      if (a<b) {
        // two elt out of place: swap
        arr[b]= v;
        arr[a]= vv;
      
        show(a, 4);
        show(b, 4);
      }
    }
    pi= a;

    // clear colors
    a= oa; b= ob;
    while(a<b) get(a++, 7);

    // sort the parts
    qs(oa, pi);
    qs(pi+1, ob);
  }
}

void quicksort() {
  printname("BubbleSort");

  qs(0, HIRESROWS-1);
}

#define METHODS 4

word csecs[METHODS+1]= {0};
char* name[METHODS+1]= {0};


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
  for(m=1; m<=METHODS; ++m) {

    play(1, 0, 0, 10);
    sfx(SILENCE);

    hires();
    gclear();
  
    // randomize values
    for(r= 0; r<HIRESROWS; ++r) {
      arr[r]= rand() % 220;
      show(r, 7);
    }

    // reset timer to avoid wraparound
    // (/ 65535 100 60) = 10 minutes (665 s)
    *(int*)0x276= 0xffff;
    csecs[m]= time();

    switch(m) {

    case 1: quicksort(); break;
    case 2: selectionsort(); break;
    case 3: insertsort(); break;
    case 4: bubblesort(); break;

    }

    csecs[m]-= time();
    name[m]= lastname;


    // print timing
    sprintf(TEXTSCREEN+ 40*26 + 32, "%c%d", 3, csecs[m]);
    sprintf(TEXTSCREEN+ 40*27 + 32, "%c%d", 3, csecs[m]);


    // TODO: test is sorted - lol!

    // show result
    for(r= 0; r<HIRESROWS; ++r) {
      wait(1);
      show(r, 2);
    }


    sfx(SILENCE);

    wait(150);
  }
 
  // show summary result
  text();
  clrscr();

  putchar('\n');
  for(m=1; m<=METHODS; ++m) {
    sprintf(TEXTSCREEN+ 40*(8+m*2) + 8, "%c%5d  %s\n",
            DBLE, csecs[m], name[m]);
    sprintf(TEXTSCREEN+ 40*(9+m*2) + 8, "%c%5d  %s\n",
            DBLE, csecs[m], name[m]);
  }

  // don't mess up the display
halt:
  goto halt;
}
