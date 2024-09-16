void clrscr() {
  printf("[H[2J[3J");
}

char reverson= 0;
char revers(char on) {
  char ret= reverson;
  reverson= on;
  printf(on? "[7m": "[0m");
  return reverson;
}

void gotoxy(unsigned char x, unsigned char y) {
  printf("\x1b[%d;%dH", x, y);
}

void cputcxy (unsigned char x, unsigned char y, char c) {
  gotoxy(x, y); putchar(c);
}

unsigned char textcol= 7;
unsigned char textcolor(unsigned char color) {
  unsigned char ret= textcol;
  printf("\x1b[[3%dm", color);
  textcol= color;
  return ret;
}

unsigned char bgcol= 0;
unsigned char bgcolor(unsigned char color) {
  unsigned char ret= bgcol;
  printf("\x1b[[4%dm", color);
  bgcol= color;
  return ret;
}

//getcursor DSR         Get cursor position                    ^[6n
//cursorpos CPR            Response: cursor is at v,h          ^[<v>;<h>R

// TODO: not working? - seems to scroll sideways! lol!
unsigned char wherex() {
  int curx, cury;
  printf("6n");
  scanf("%d;%dR", &curx, &cury);
  return curx;
}

// TODO: not working?
unsigned char wherey() {
  int curx, cury;
  printf("6n");
  scanf("%d;%dR", &curx, &cury);
  return cury;
}


