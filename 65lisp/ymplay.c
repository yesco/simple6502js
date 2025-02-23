#include <stdio.h>

#define MAIN
#include "sound.c"

// This is a long "con""cat""en""ated" string
// ( sizeof(song) gives length in bytes + 1 for terminating \0)
char song[]= {
//  #include "../../OSME/tools/ym.c"
  #include "../../badgerbadger/w.c"
//  #include "../../badgerbadger/w1k.c"
};

void waitms(unsigned int ms) { long w= ms*7L; while(--w); }

void playYM(char* ym, int bytes) {
  while((bytes-=14) >= 0) {
    sfx(ym); ym+= 14;
    //x gotoxy(39-4-8, 0); printf("YM%04d ", bytes);
    waitms(24);
  }
  play(0,0,0,0);
}

void main() {
  asm("SEI");
  clrscr(); gotoxy(17, 12);
  printf("Hello ym!\n");
  playYM(song, sizeof(song));
}
