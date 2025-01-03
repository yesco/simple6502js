#include <string.h>

#include "../conio-raw.c"

void keydef(char c, char row, char col) {
  char *p= CHARDEF(c);
  char m= (32>>col);
  char x= 63;
  if (1) {
    p[0]= row==0? x: m;
    p[1]= row==1? x: m;
    p[2]= row==2? x: m;
    p[3]= row==3? x: m;
    p[4]= row==4? x: m;
    p[5]= row==5? x: m;
    p[6]= row==6? x: m;
    p[7]= row==7? x: m;
  } else {
    // flickers ?
    memset(p, m, 8);
    p[row]= x;
  }
}

// Dummys for ./r script
int T,nil,doapply1,print;

int main() {
//  #define WAIT 100
  #define WAIT 200
  int w;
  char c, row, col;
  int n= 0;

  clrscr();
  while(1) {
    if (wherey()<27) {
    putchar(128+(n&7));
    putchar(128+((n/8)&7)+16);

    putchar('O'+128);
    putchar('R'+128);
    putchar('I'+128);
    putchar('C'+128);
    putchar(9);
    putchar(9);
    putchar(9);
    putchar(9);
    ++n;
    }

    keydef(' ', row, col);
    c= cgetc();
    w= WAIT; while(--w);
    switch(c) {
    case KEY_UP:   --row; break;
    case KEY_DOWN: ++row; break;
    case KEY_LEFT:  --col; break;
    case KEY_RIGHT: ++col; break;
    case CTRL+'C': return 0;
    }
    if (row==255) row= 7;
    if (row>7) row= 0;
    if (col==255) col= 5;
    if (col>5) col= 0;
  }
}
