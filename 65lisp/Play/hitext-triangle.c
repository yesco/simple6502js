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

// HIRES: 10210 bytes
#define HIRESSCREEN ((char*)0xA000) // $A000-BF3F
#define HIRESSIZE   8000
#define HIRESEND    (HIRESSCREEN+HIRESSIZE)

#define HIRESTEXT   ((char*)0xBF68) // $BF68-BFDF
#define HIRESTEXTSIZE 120
#define HIRESTEXTEND (HIRESTEXT+HIRESTEXTSIZE)

#define HIRESCHARSET ((char*)0x9800) // $9800-9BFF
#define HIRESALTSET  ((char*(0x9C00) // $9C00-9FFF

#define HIRESMODE 30 // and 31
#define TEXTMODE  26 // and 27

int main() {
  #define W 200
  int i; char* p;
  long w;
  clrscr();
  paper(7);
  ink(4);
  *SCREENXY(39,27)= HIRESMODE;

  memcpy(HIRESCHARSET, CHARSET, 128*8);

  p= HIRESSCREEN; i= 0;
  while (p<SCREENEND) *p++ = ((i/40)&63)+64,++i;

  for(p= HIRESSCREEN; p<SCREENEND; p+= 40) {
    *p++ = TEXTMODE;
  }
  for(p= TEXTSCREEN; p<SCREENEND; p+= 40) {
    *p++ = HIRESMODE;
  }


  *SCREENXY(39,27)= HIRESMODE;
  //TEXTSCREEN[-1]= HIRESMODE;

  memcpy(CHARSET, HIRESCHARSET, 128*8);
  *CHARSET= TEXTMODE;


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
