#define MAIN
#include "../hires-raw.c"

char T, nil, print, doapply1;

void main() {
  static char r, c, v, *p;
  int dx= 99, dy= 99;

  hires();
  gclear();
  
  c= KEY_UP;
  do {
    gclear();
    gcurx= 40; gcury=  50; draw(180,  15, 2);
    gcurx= 40; gcury= 150; draw(180, -15, 2);

    /// xor down to fill! clevef simple!
    switch(2) {

    case 1: // xor every byte only (no fill)
      for(c=0; c<40; ++c) {
        p= HIRESSCREEN-40+c;
        v= 0;
        for(r=0; r<200; ++r) {
          p+=40;
          *p^= 63;
        }
      } break;

    case 2: { // xor fill all screen
      char mask[]= {1+4+16 +64+128, 2+8+32 +64+128};
      #define MASKMASK 0b01

      for(c=0; c<40; ++c) {
        p= HIRESSCREEN-40+c;
        v= 0;
        for(r=0; r<200; ++r)
          *p= v= (*(p+=40)^v)|64;
      }
    } break;

    case 3: { // xor fill with MASK all screen
      char mask[]= {1+4+16 +64+128, 2+8+32 +64+128};
      #define MASKMASK 0b01

      for(c=0; c<40; ++c) {
        p= HIRESSCREEN-40+c;
        v= 0;
        for(r=0; r<200; ++r)
          *p= (v= (*(p+=40)^v)|64) & mask[r & MASKMASK];
      }
    } break;

    case 4: // xor fill limited area
      for(c=40/6-1; c<=(40+180)/6+1; ++c) {
        p= HIRESSCREEN + 50*40-40 + c;
        v= 0;
        for(r=50; r<150; ++r)
          *p= v= (*(p+=40)^v)|64;
      }
      break;
    }

    if (0)
    switch(c) {
    case KEY_UP:     if (--dy<-99) { dy= -99; }  break;
    case KEY_DOWN:   if (++dy> 99) { dy=  99; } break;
    case KEY_LEFT:   if (--dx<-99) { dx= -99; }  break;
    case KEY_RIGHT:  if (++dx> 99) { dx=  99; }    break;
    }
    //gotoxy(0, 25); printf("dx %d dy %d\n", dx, dy);
  } while (1);
}
