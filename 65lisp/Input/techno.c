#define MAIN

// dummy
char T,nil,doapply1,print;

typedef unsigned int word;

#include "../conio-raw.c"
#include "../sound.c"
#include <string.h>
#include <assert.h>


#define TLEN 8
//char NOTE[]= "h#a#g#fe#d#c";
char NOTE[]= "c#d#ef#g#a#h";

// Jingle Bell
char tune[]= "eee eee fgcde fff ffee edde dg";

word main() {
  char i, c, t, *p;

  clrscr();

  while(1) {

    // play it sam
    for(i=0; i<sizeof(tune)-1; ++i) {
      c= tune[i];
      putchar(c);
      if (c==' ') play(0,0,0,0);
// TODO:
// if (c=='#') ... +1
      else {
        p= strchr(NOTE, c);
        assert(p);
        t= p-NOTE+1;

        music(1, 4, t, 8);
// vol 0 means use envelope (or 16?)
//        music(1, 4, t, 0);
//        play(1, 0, 7, 2000);
        // length of note
        play(1,0,0,10);
      }
      wait(30);

      // pause between notes?
      play(0,0,0,0);
      wait(10);
    }

    wait(60);

    // mutate?


    putchar('\n');
  }

  // sliencio
  play(0,0,0,0);

  return 0;
}
