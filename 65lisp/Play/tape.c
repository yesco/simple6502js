// tape.tap - test tape access
//
// 2025 (>) Jonas S Karlsson, jsk@yeco.org
//
// This program allows experimemnts of saving/loading
// multiple files, in order, or out of order.
// 
// When tape.tap loads (see how it's prepared below)
// you can just type on the screen and it echoes.
//
// Commands start with ESC followed by a letter:
//
//   ESC a   - load a.tap
//   ESC SPC - load "" file (any next file)
//  
//   ESC A   - save screen as a.tap


// For the tests text "screenshots" have been saved.
// a.tap b.tap c.tap containing just a:s, b:s c:s.
//
// The tap-file is a concatenation:
//
//   tape.tap a.tap b.tap c.tap b.tap c.tap b.tap c.tap a.tap
//
// Essentially: T A B C  B C  B C  A


// Every emulator seems to do different things...


// === Oricutron, web
//
// 1) atmos_load("c.tap") oricutron IGNORES the
//    file name; it just loads next file in tap (BUG)
// 2) you can ONLY access files in the order given
//
// However!
// 3) If you save a file.
//    You can then load it BY NAME!
//    However, it immediately EXITS to BASIC after!
//    (it doesn't exit for other preprepared files)
// 4) Even if you save differnt files many times
//    if it's saved you can do RANDOM access it seems
//    and BY NAME! (then it's not ignored, lol)
// 5) Files saved are NOT permanent and NOT added
//    to the memory if you start the emulator again
//    it uses the original tap file. (BUG?)
// 6) Orictron web can download the tap-files,
//    but anything saved using ESC A for example
//    is NOT THERE (BUG)
//
// TODO: read the source cc65 atmos_save, maybe it
//       sets the flags differently and causes the
//       EIXT? (BUG)



// === JORIC, android app
//
// 1) It can load file by name ESC c - loads c.tap
// 2) But only for files in the order as given
//    NO random access.
// 3) You can ESC A save a file - But it's really slow.
// 4) You cannot load the saved file, it seems to be 
//    FORGOTTEN. (BUG)


// === LOCI?
//
// my ORIC ATMOS is "non-responsive" at the momment,
// any takers to test?
//


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
        sprintf(name, "%c.tap", tolower(c));
        printf("\n[saving %s...]", name);
        atmos_save(name, (void*)0xbd80, (void*)(0xbd80+28*40));
        printf("[...saved %s]\n", name);
      } else if (islower(c)) {
        sprintf(name, "%c.tap", tolower(c));
        printf("loading %s...]", name);
        strcpy((char*)0x27b, name); // 0x27f..0x28e filename 16
        atmos_load(name);
//        atmos_load("c.tap"); /// UUUU???a
        printf("loading %s...]", name);
        printf("[loaded %s]", (char*)0x293);
        
        continue;

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
        printf("loading any]");
        name[0]= 0;
        atmos_load(name);
        printf("[found: %s]", (char*)0x293);
      }
    } else putchar(c);
  }
  return 0;
}
