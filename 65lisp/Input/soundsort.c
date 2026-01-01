typedef unsigned int word;

// dummy
char T,nil,print,doapply1;

#define MAIN
#include "../hires-raw.c"

#include "../sound.c"

char* row[HIRESROWS];

char arr[HIRESROWS];


char pr;
char pcolor;

#define GET(prr, pcc) (pr= prr, pcolor= pcc, get())

//char get(char r, char color) {
char get() {
  static char v;
  static word period;
  static char *p;
  v= arr[pr];
  period= v;
  p= row[pr];
  
  *p= pcolor;

  if (pcolor!=7) {
    play(1, 0, 0, 10);
    sound(1, period, 5);
  }

  return v;
}

char partline[]= {0b1100000, 0b1110000, 0b1111000, 0b1111100,
 0b1111110, 0b1111111};

void show(char r, char color) {
  char c=1, v= GET(r, color);
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

  v= GET(0, 1);
  show(0, 7);
  for(r= 1; r<HIRESROWS-1; ++r) {
    // next to insert
    v= GET(r, 1);
    for(i= 0; i<r; ++i) {
      vv= GET(i, 1);
      if (vv >= v) break;
      GET(i, 7);
    }
    GET(r, 7);

    at= i;

    // move up rest
    while(i < r) {
      t= GET(i, i==at? 4: 1);
      arr[i]= v;
      v= t;
      show(i, i==at? 4: 6);
      ++i;
    }
    arr[i]= v;
    show(i, 7);

    GET(at, 4);
  }
}

void selectionsort() {
  char r, i, v, vv, at, t;

  printname("SelectionSort");

  for(r= 0; r<HIRESROWS-1; ++r) {
    // find smallest
    at= r; v= GET(r, 1);
    for(i= r+1; i<HIRESROWS; ++i) {
      vv= GET(i, 1);
      if (vv < v) {
        at= i; v= vv;
      }
      GET(i, 7);
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
  char r, n, v, vv;

  printname("BubbleSort");

  n= 1;
  while(n) {
    n= 0;
    for(r= 0; r<HIRESROWS-1; ++r) {
      v = GET(r,   1);
      vv= GET(r+1, 1);
      if (v > vv) {
        ++n;
        arr[r]  = vv;
        arr[r+1]= v;
        show(r,  4);
        show(r+1, 4);
      } else {
        GET(r,   7);
        GET(r+1, 7);
      }
    }
  }
}

void doublebubblesort() {
  char n, v, vv;
  int s, r, e, d;

  printname("DoubleBubbleSort");

  s= 0;
  d= +1;
  e= HIRESROWS-1;
  r= s;

  n= 1;
  while(n) {
    n= 0;
    do {
      v = GET(r,   1);
      vv= GET(r+1, 1);
      if (v > vv) {
        // swap
        ++n;
        arr[r]  = vv;
        arr[r+1]= v;

        show(r,  4);
        show(r+1, 4);
      } else {
// going up doesn't show???
        GET(r,   7);
        GET(r+1, 7);
      }

      r+= d;
    } while (r>=s && r<e);
    // turn around
    d= -d;
    r+= d;
    if (r==s) r= ++s; else r= --e;
  }
}

void qs(char a, char b);

// TODO: at some point call bubblesort!
void randsort() {
  char a,b, v, vv, t, g;
  word n=0, nn=0, d= HIRESROWS;
  long c=0, lastc=0, sumg=0;

  printname("RandSortQS");

  while(1) {
      ++c;

      a= rand() % HIRESROWS;
      b= rand() % HIRESROWS;
      if (a>b) { t= a; a= b; b= t; }

      v = GET(a, 1);
      vv= GET(b, 1);
      if (v > vv) {
        ++n;
        arr[a]= vv;
        arr[b]= v;
        show(a, 4);
        show(b, 4);
      } else {
        GET(a, 7);
        GET(b, 7);
      }
      // bailout! lol
      if (c>3000) { qs(0, HIRESROWS-1); return; }
  }
}


void qs(char a, char b) {
  // only one - nothing to sort
  if (a>=b) return;

  // swap if 2 in wrong order
  if (a+1==b) {
    char v= GET(a, 1);
    char vv= GET(b, 1);
    if (vv < v) {
      arr[a]= vv;
      arr[b]= v;

      show(a, 4);
      show(b, 4);
    } else {
      GET(a, 7);
      GET(b, 7);
    }
    return;

  } else {

    // else divide by middle pivot 
    char pi = (a+b)/2;
    char pv = GET(pi, 1);
    char oa= a, ob= b;
    char v, vv;

    while(a<b) {
      // move up lower boundary if < 
      --a;
      do {
        if (a>=0) GET(a, 7);
        ++a;
        v= GET(a, 1);
      } while(a<b && v<pv);
      
      // move down upper boundary if >=
      ++b;
      do {
        if (b<HIRESROWS) GET(b, 7);
        --b;
        vv= GET(b, 1);
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
    while(a<=b) GET(a++, 7);

    // sort the parts
    qs(oa, pi);
    qs(pi+1, ob);
  }
}

void quicksort() {
  printname("QuickSort");

  qs(0, HIRESROWS-1);
}

#define METHODS 6

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

// TODO: menu run choosen number, or 0 all!

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

    case 1: selectionsort(); break;
    case 2: insertsort(); break;
    case 3: bubblesort(); break;
    case 4: doublebubblesort(); break;
    case 5: quicksort(); break;
    case 6: randsort(); break;

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
