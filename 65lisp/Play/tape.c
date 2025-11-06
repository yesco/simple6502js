// Test tape access, random and overwrites

#include <atmos.h>
#include <conio.h>
#include <stdio.h>
#include <string.h>

//dummies
char T, nil, print, doapply1;

//void atmos_load(name, start, end);
//void atmos_save(name, start, end);

#include <ctype.h>

int main() {
  char name[17]={0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0};
  char c;

  while((c= cgetc())!='Q') {
    if (c==27) {
      // ESC + A = save "a"
      // ESC + a = load "a"
      // ESC + other = load any ""
      c= cgetc();
      if (isupper(c)) {
        name[0]= tolower(c);
        printf("\n[saving %s...]", name);
        atmos_save(name, (void*)0xbd80, (void*)(0xbd80+28*40));
        printf("[...saved %s]\n", name);
      } else if (islower(c)) {
// The filename on tape is stored at
// #293 to #2A2 (version 1.1).
//
// On version 1.1, the routine that prints a message
// on the top line is patched via a jump at
// #241. This may be (carefully!) altered in order
// to add your own processing at either the 
// ‘search’ or the ‘load’ phase.

// Version 1.1:
// #24D – tape speed (zero when fast, one when slow).
// #27F – #28E – the filename, terminated by #00.
// #25B – the verify flag – set to zero for load, one for verify.
// #25A – the join flag – set to zero for a normal load.



// typical sequence:
//
// JSR E76A (disable interrupts, etc.)
// JSR E57D (print ‘searching’ message)
// JSR E4AC (find file)
// JSR E59B (print ‘loading’)
// JSR E4E0 (load file, or verify)
// JSR E93D (enable interrupts)


        name[0]= c;
        printf("\n[loading %s...]", name);

//        atmos_load(name);

        // set parameters
        *(char*)0x24b= 0; // speed:  0=fast
        *(char*)0x25a= 0; // join:   0=no
        *(char*)0x25b= 0; // verify: 0=load 1=verfy
        strcpy((char*)0x27b, name); // 0x27f..0x28e filename 16
        
        asm("jsr $e76a"); // disable interrupts
next:
        asm("jsr $e4ec"); // find file
        // print filename found
        // (The filename on tape is stored at
        //  #293 to #2A2 (version 1.1).)
        printf("[found: %s]", (char*)0x293);
        printf("[....]");
goto next;
        asm("jsr $e4e0"); // load file
        asm("jsr $e95d"); // enable interrupts

        printf("[...loaded %s]", name);
      } else {
        name[0]= 0;
        atmos_load(name);
      }
    } else putchar(c);
  }
  return 0;
}
