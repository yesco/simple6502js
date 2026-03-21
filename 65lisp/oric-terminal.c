#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

int bgcol= 0, fgcol= 7;

int fullwidth= 0xFF00; // "space"

// Enable to get fullwidth wide chars
//#define WIDE

#ifdef WIDE
  #define SPACE "  "
#else
  #define SPACE " "
#endif


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
void resetcolors() { printf("\x1b[0m"); bgcol= 0; fgcol= 7; }

void gotorc(int r, int c) {
  // negative values breaks the ESC seq giving garbage on the screen!
  assert(r>=0 && c>=0);
  printf("\x1b[%d;%dH", r+1, c+1);
}

void esc() {
  int c= getchar();

  if (c!=']') {
    // pass-through
    putchar('\e');
    putchar(c);
    return;
  }

  // handle OSC
  char buff[80]= {0}, i= 0, *p;

  while((c=getchar())!=EOF && c!='\e' && c!='\a' && i<sizeof(buff)-1)
    buff[i++]= c;

  // skip trailing \ after ESC
  if (c=='\e') { c= getchar(); c= '\a'; } // lol

  // ESC ] "oric:command;params...\a"
  if (strncmp(buff, "oric:unix:", 10)==0) {
    p= buff+10;
    printf("\n\n> %s[%d]\n\n", p, c);
    system(p);
    return;
  }
  if (strncmp(buff, "oric:", 5)==0) {
    p= buff+5;
    printf("\nOSC.*:%s[%d]\n", buff, c);
    return;
  }

  // pass through everything!
  printf("\e%s%c", buff, c);
}

void fullputc(int c) {
  switch(c) {

  // ^L clear screen
  case 12:
  case 12+128:
    clear(); break;

  case '\e':
    esc(); break;

  case ' ':
    printf(SPACE);
    break;

  // normal characters
  case 33 ... 126:
#ifdef WIDE
    u8put(fullwidth-32+c); break;
#else
    putchar(c); break;
#endif

  // inverse
  case (128+32) ... 255:
    // this is 'inverse video' vt100
#define VT100INVERSE
#ifdef VT100INVERSE
    printf("\e[7m");
#else
    // TODO: real ORIC color inversion
    printf("\e[%dm", 7-fgcol+30); break;
    printf("\e[%dm", 7-bgcol+40); break;
#endif
    fullputc(c&0x7f);

#ifdef VT100INVERSE
    printf("\e[27m");
#else
    // TODO: real ORIC color inversion
    printf("\e[%dm", fgcol+30); break;
    printf("\e[%dm", bgcol+40); break;
#endif

    break;

  case '\n':
  case '\n'+128:
    // each new text line on ORIC resets colros
    // to BLACK background and WHITE foreground
    resetcolors();
    putchar('\n');
    // two attribute columns are not printable
    printf(SPACE SPACE);
    break;
  case '\r':
  case '\r'+128:
    putchar('\r');
    printf("\e[2C"); // forward 2 steps
    break;

  // 28,29,30,31 cursor movements (MeteoriC bios)

  // text colors
  case (128) ... (128+7):
    // ORIC attributes take up one space
    // TODO: why two spaces? one gets eaten up!
    fgcol= c-128;
    printf("\e[%dm" SPACE, fgcol+30); break;

  // background colors
  case (128+16) ... (128+16+7):
    bgcol= c-16-128;
    printf("\e[%dm" SPACE, bgcol+40); break;

  // backspace - double up
  case 8:
    #ifdef WIDE
      putchar(c);
    #endif

  // what chars remains?
  default:
    putchar(c);
    //printf("%02x", c); break;
  }
}

char* fullputs(char* s) {
  while(*s) fullputc(*s++);
  return s;
}

int main(void) {
  //u8put('X'); printf("\n");
  //u8put(0x20AC); // eurosign output: E2 82 AC.

  // Set stdout to be unbuffered
  setvbuf(stdout, NULL, _IONBF, 0);

  clear();
  // status line? lol
  // fullputs("\nORIC 65LISP>02                     CAPS");

  clearend();

  // set scroll region
  // printf("\e[3;29r");

  gotorc(1, 1);

  // Hmmm (?)
  for(int i=1; i<28; i++) {
    printf("\n");
    clearend();
  }
  gotorc(2, 1);
  printf("   ");

  // process characters
  int c;
  while((c=getchar())!=EOF) {
    fullputc(c);
  }
//  clearend();

  printf("\n[m");
  printf("\n");
  printf("\e[r\n"); // no more scroll region

  // TODO: got end of screen, need to get size...
  gotorc(1000, 1);

  return 0;
}

