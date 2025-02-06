#define MAIN
#include "../hires-raw.c"

char T, nil, print, doapply1;

void main() {
  int c;
  int dx= 99, dy= 99;

  hires();
  gclear();
  
  c= KEY_UP;
  do {
    // show line, wiat key, erase line
    gcurx= 120; gcury= 100; draw(dx, dy,2);
    //c= cgetc();
    //gcurx= 120; gcury= 100; draw(dx, dy,0);

    switch(c) {
    case KEY_UP:     if (--dy<-99) { dy= -99; c= KEY_LEFT; }  break;
    case KEY_DOWN:   if (++dy> 99) { dy=  99; c= KEY_RIGHT; } break;
    case KEY_LEFT:   if (--dx<-99) { dx= -99; c= KEY_DOWN; }  break;
    case KEY_RIGHT:  if (++dx> 99) { dx=  99; c= KEY_UP; }    break;
    }
    gotoxy(0, 25); printf("dx %d dy %d\n", dx, dy);
  } while (1);
}
