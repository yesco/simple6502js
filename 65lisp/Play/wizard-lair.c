// Just simulating

//#include "conio-raw.c"
#define MAIN
#include "../hires-raw.c"

// 1080 chars
char* sherlock= "THE COMPLETE SHERLOCK HOLMES Arthur Conan Doyle Table of contents A Study In Scarlet The Sign of the Four The Adventures of Sherlock Holmes A Scandal in Bohemia The Red-Headed League A Case of Identity The Boscombe Valley Mystery The Five Orange Pips The Man with the Twisted Lip The Adventure of the Blue Carbuncle The Adventure of the Speckled Band The Adventure of the Engineer's Thumb The Adventure of the Noble Bachelor The Adventure of the Beryl Coronet The Adventure of the Copper Beeches The Memoirs of Sherlock Holmes Silver Blaze The Yellow Face The Stock-Broker's Clerk The \"Gloria Scott\" The Musgrave Ritual The Reigate Squires The Crooked Man The Resident Patient The Greek Interpreter The Naval Treaty The Final Problem The Return of Sherlock Holmes The Adventure of the Empty House The Adventure of the Norwood Builder The Adventure of the Dancing Men The Adventure of the Solitary Cyclist The Adventure of the Priory School The Adventure of Black Peter The Adventure of Charles Augustus Milverton The Adventure of the Six Napoleons The Adventure of the Three Stor";

// Dummys for ./r script
int T,nil,doapply1,print;

#include <stdlib.h>

//#define DOHIRES

void main() {
  char * hend= HIRESSCREEN+HIRESSIZE, * p= sherlock;
  int i, j;
  char c=0, w=0;

  init_conioraw();

  #ifdef DOHIRES
    hires();
    gotoxy(0,0);
  #else
    text();
    clrscr();
  #endif

  // simulating loading text-screen at 2400 baud
  while(*p) {
    cputc(*p++);
    if (w=1-w) wait(1);
  }

  #ifndef DOHIRES
    // make all hires screen rows switch to text mode!
    gcurp= HIRESSCREEN;
    for(i=0; i<200; ++i) {
      *gcurp= TEXTMODE;
      gcurp+= 40;
    }

    hires();
  #endif

  // simulate 2400 baud loading
  gcurp= HIRESSCREEN;
  i= 0;
  while(gcurp<=hend) {
    c= 0;
    for(j=0; j<8; ++j) {
      *gcurp++= (c++ & 7) | 16;
      if (w=1-w) wait(1);
    }
    
    for(j=0; j<i; ++j) {
      *gcurp++= 16;
      if (w=1-w) wait(1);
    }
    ++i;
  }
  gclear();
}

