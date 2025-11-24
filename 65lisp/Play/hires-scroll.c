#include <string.h>

#define MAIN

#include "../hires-raw.c"

// Dummys for ./r script
int T,nil,doapply1,print;

void scrollright1() {
  char *p= HIRESEND, v=0, n=0;
  while (--p>=HIRESSCREEN) {
    *p= (((n=*p) & 31) << 1) | (v&32?1:0) | 64;
    v= n;
  }
}

void scrollright2() {
  char *p= HIRESEND, v=0, n=0;
  unsigned int i= HIRESSIZE;
  while (--i) {
    *p= (((n=*p) & 31) << 1) | (v&32?1:0) | 64;
    --p;
    v= n;
  }
}

void scrollright() {
  

#ifdef FOO
  asm("lda #<%w", ((unsigned int)HIRESEND)-40);
  asm("ldx #>%w", ((unsigned int)HIRESEND)-40);
  asm("sta 0");
  asm("stx 1");

  asm("ldx #200");
#else
  // only scroll middle
  asm("lda #<%w", ((unsigned int)HIRESSCREEN)+(100+8)*40);
  asm("ldx #>%w", ((unsigned int)HIRESSCREEN)+(100+8)*40);
  asm("sta 0");
  asm("stx 1");

  asm("ldx #16");
#endif

  asm("ldy #39");
  asm("clc");

loop:
  asm("lda (0),y");
  // shift in Carry
  asm("rol");
  // set Carry
  asm("cmp #128+64");

  // set bit 6
  asm("and #63");
  asm("ora #64");
  asm("sta (0),y");

  asm("dey");
  asm("bpl %g", loop);

  // up one row
  asm("ldy #39");

  // - (0)-= 40;
  asm("php");
  asm("sec");
  asm("lda 0");
  asm("sbc #40");
  asm("sta 0");
  asm("bcs %g", skiphidec);
  asm("dec 1");
 skiphidec:
  asm("plp");

  asm("dex");
  asm("bne %g", loop);
}


int main() {
  char ku= keypos(KEY_UP),   kd= keypos(KEY_DOWN);
  char kl= keypos(KEY_LEFT), kr= keypos(KEY_RIGHT);
  #define WAIT 200
  int w;
  char c, row, col;
  int n= 0;

  hires();
  gclear();

  //draw really wrong! lol
  CURSET(0,0,3); draw(200,200,2);
  CURSET(0,200,3); draw(200,-200,2);

  while(1) {

#ifdef KEYS
    if (keypressed(ku)) --row;
    if (keypressed(kd)) ++row;
    if (keypressed(kr)) ++col,scrollright();
    if (keypressed(kl)) --col;

    // boundaries
    if (row==255) row= 0;
    if (row>239) row= 239;
    if (col==255) col= 0;
    if (col>199) col= 199;
#else
    scrollright();
#endif
  }

  return 0;
}
