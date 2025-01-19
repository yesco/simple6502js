#include <string.h>

#define MAIN

//#include "../conio-raw.c"
#include "../hires-raw.c" // includes conio-raw, lol

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

void upd(long W) {
  gotoxy(10,10); putchar(128+7+16); putchar(128+0);
  printf(" %ld ", W);
}


#include <6502.h>

char interStack[1024];

static xx=0;
void inter() {
  xx= 1-xx;
  if (xx)
    memset(TEXTSCREEN+40, 16+1, SCREENSIZE-40);
  else
    memset(TEXTSCREEN+40, 16+2, SCREENSIZE-40);
  return;

  if (HIRESSCREEN[0]==TEXTMODE) {
    HIRESSCREEN[0]= 0;
  } else {
    HIRESSCREEN[0]= TEXTMODE;
  }
}

int main() {
  long W= 1;
  int i; char* p;
  long w;

  TIMER= 60000;
  set_irq((irq_handler)inter, interStack, sizeof(interStack));

  clrscr();
  paper(7);
  ink(4);
  *SCREENXY(39,27)= HIRESMODE;

  memcpy(HIRESCHARSET, CHARSET, 128*8);

  p= HIRESSCREEN; i= 0;
  //while (p<SCREENEND) *p++ = ((i/40)&63)+64,++i;
  memset(HIRESSCREEN, 0, CHARSET-HIRESSCREEN); 

  for(p= HIRESSCREEN; p<SCREENEND; p+= 40) {
    *p = TEXTMODE;
    p[1] = 1;
    p[2] = 2;
  }
  for(p= TEXTSCREEN; p<SCREENEND; p+= 40) {
    *p = HIRESMODE;
  }


  *SCREENXY(39,27)= HIRESMODE;
  HIRESSCREEN[0]= TEXTMODE;
  //TEXTSCREEN[-1]= HIRESMODE;

  memcpy(CHARSET, HIRESCHARSET, 128*8);
  //*CHARSET= TEXTMODE;

  gotoxy(15, 8); printf("FoOBAR FIE FUM");
  
  { 
    char up= keypos(KEY_UP);
    char dn= keypos(KEY_DOWN);
    char fw= keypos(KEY_RIGHT);
    char bk= keypos(KEY_LEFT);
    char lt= keypos('<');
    char gt= keypos('>');
    char two= keypos('2');

    while(1) {
      //HIRESSCREEN[0]= 0;
      w= W; while(--w);
      if (keypressed(dn)) { --W; upd(W); }
      if (keypressed(bk)) { W-=50; upd(W); }
      if (W<1) W= 1;
      //HIRESSCREEN[0]= TEXTMODE;
      w= W; while(--w);
      if (keypressed(up)) { ++W; upd(W); }
      if (keypressed(up)) { W+=50; upd(W); }

      // timer changes sync
      if (keypressed(lt)) cgetc(),--TIMER;
      if (keypressed(gt)) cgetc(),++TIMER;
      if (keypressed(two)) TIMER=20000;

      gotoxy(39-6,0); printf("x%uy", TIMER);
    }
  }

  return 0;

  while(1) {
    w= W; while(--w);
    *SCREENXY(39,27)= HIRESMODE;
    w= W; while(--w);
    *SCREENXY(39,27)= TEXTMODE;
  }
  //HIRESEND[-1]= TEXTMODE;
  //HIRESTEXTEND[-1]= TEXTMODE;
  //for(i= 40*3; i; --i) putchar('A');
  //for(i= 40*3; i; --i) putchar('B');
}
