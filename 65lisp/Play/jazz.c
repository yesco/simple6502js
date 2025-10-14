#include "../conio-raw.c"
#include "../sound.c"

// 12 chars
// C = c# = cb
//  |C|D| |F|G|A|
// |c|d|e|f|g|a|h|
//
// TODO: ABC notation?
//  - https://abcnotation.com/examples#notes-pitches

// search reverse 'a' '#a' lol
char KLAVIATUR[]= "h#a#g#fe#d#cH#A#G#FE#D#C";
 
// - https://abcnotation.com/tunePage?a=back.numachi.com:8000/dtrad/abc_dtrad.tar.gz/abc_dtrad/ROWROWBT/0000
// X:1
// T:Row, Row, Row your Boat
// M:6/8
// L:1/8
// K:C
char rowrow[]= "C3 C3| C2 D E3| E2 D E2 F| G6| ccc GGG| EEE CCC| G2 F E2 D| C6|";

#define SINGUNIT 16
void sing(char ch, char oct, char* song) {
  char n, c, *p;
  // unit/s "ticks"
  char lastlen= SINGUNIT, len= SINGUNIT, * s= song;

  while(c= *s++) {
    putchar('\n'); putchar('>');
    putchar(c);

    // TODO: change so that it parse a note/unit
    // - ABC A/8 A3 3ABC -> all these is just A!
    // - [ABC] == chord simulatnious
    // - A# is writtne A= (?)

    // half-note up
    if (c=='#') { --n; continue; }
    // length
    if (c=='/') { // shorter
      if (isdigit(s[1]))
        len/= *++s-'0'; 
      else // shorthand "same"
        len= lastlen;
    } else if (isdigit(c)) { // longer
      len*= c-'0';
    }
    // note
    p= strchr(KLAVIATUR, c);
    if (p || !*s) { // got note or at end
      // TODO: or space too?

      // play last note when have new one!
      // (only then we know we're finished)
      music(ch, oct+n/12, 1+n%12, 7);
      play(1,0,0,2000);
      //play(7,0,1,20000);
      putchar(' '); putchar('W');

      curp^= 128;
      waitms(len*(100L/SINGUNIT));
      curp^= 128;

      if (!*s) break; // loll, strange flow

      lastlen= len;

      // new note
      n= p-KLAVIATUR;
      len= SINGUNIT;
    } else putchar('?');
  }

  // TODO: play last note!!! lol
}

char* it= "";

void main() {
  clrscr();
  printf("HELLO\nSOUND!\n");
  sfx(PING);
  sfx(PING);
  wait(100);
  //sfx(SILENCE);

  //play(1,0,0,10);
  //music(1,0,10,7);
  //wait(300);

  // 3 key
  play(1,0,0,20000);
  sing(1,3,rowrow);

  sfx(PING);
  wait(100);
  sfx(SILENCE);
  gotoxy(0,27); printf("Bye..21........\n\n\n\n\n");
}
