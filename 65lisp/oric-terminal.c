#include <stdio.h>
#include <assert.h>

int fullwidth= 0xFF00; // "space"

// UTF-8 in this range 1110xxxx10xxxxxx10xxxxxx
void u8put_r(int uc, int m) {
  if (m==128 && uc<128) { putchar(uc); return; }
  //putchar((uc & 63) | 128);
  int o;
  if (uc > m/2) {
    u8put_r(uc>>6, (m/2) | 128);
    o = (uc&63) | 128;
  } else {
    o = m | uc;
  }
  // printf("%02x ", o);
  putchar(o);
}

void u8put(int uc) {
  u8put_r(uc, 128);
}

void clear() { printf("\x1b[2J\x1b[H"); }
void clearend() { printf("\x1b[K"); }
void cleareos() { printf("\x1b[J"); }
void gotorc(int r, int c) {
  // negative values breaks the ESC seq giving garbage on the screen!
  assert(r>=0 && c>=0);
  printf("\x1b[%d;%dH", r+1, c+1);
}

void fullputc(int c) {
  switch(c) {
  case 12:
    clear(); break;
  case ' ':
    printf("  "); break;
  case 33 ... 126:
    u8put(fullwidth-32+c); break;
  case '\n':
    clearend();
    printf("\n    "); break;
  case '\r':
    printf("\r    "); break;

  // TODO:
  // not correct as when new line on oric colors white on black

  // text colors
  case (128)...(128+7):
    printf("\e[%dm  ", c-128+30);
    break;
  // background colors
  case (128+16)...(128+16+7):
    printf("\e[%dm  ", c-128-16+40);
    break;

  // double up
  case 8:
    putchar(c);
  default:
    putchar(c);
    //printf("%02x", c); break;
  }
}

char* fullputs(char* s) {
  while(*s) fullputc(*s++);
}

int main(void) {
  //u8put('X'); printf("\n");
  //u8put(0x20AC); // eurosign output: E2 82 AC.

  clear();
  fullputs("\nORIC 65LISP>02                     CAPS");

//  printf("\e[30;47;1m\n    "); // background white, black text bold

  clearend();
//  printf("\e[3;29r"); // set scroll region
  gotorc(1, 1);

  for(int i=1; i<28; i++) {
    printf("\n");
    clearend();
  }
  gotorc(2, 1);
  printf("   ");

  int c;
  while((c=getchar())!=EOF) {
    fullputc(c);
  }
  clearend();

  printf("\n[m");
  printf("\n");
  printf("\e[r\n"); // no more scroll region

  gotorc(34, 1);
  return 0;
}

