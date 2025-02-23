#define MAIN
#include "../hires-raw.c"

char glastchar= 0, * glastch= 0;

#define GFONTHEIGHT 8
#define GFONTWIDTH 6 // TODO: varying later
//#define GSPACEWIDTH 3
#define GSPACEWIDTH 2

// plot char on hires screen
void gputc(char c) {

  switch(c) {

  case 10: // \n
    gcurx= 0; gcury+= GFONTHEIGHT;
    if (gcury>200-GFONTHEIGHT) { gcurx= gcury= 0; } // wrap lol
    break; 

  case 13: gcurx= 0; break; // \r

  default: // plot visible char
    if (c<32) return;
    if (c>=128) c&= 127; // TODO: inverse? or extra!

    if (c==32 || glastchar==32) { // space
      if (c==32 && gcurx==0) return;
      //if ((gcurx>240-2*GFONTWIDTH)) gputc('\n');
      if ((gcurx>240-2*6)) gputc('\n');
      else if (c==32) {
        // TODO: actually clear some pixels?
        gcurx+= GSPACEWIDTH;
      }
    }
    if (c==32) break;
    else { // printable char
      char * ch= c*8 + (HIRESCHARSET-1), * tch, * gch;
      char i= 8;
      char m, * d;
      char n,lc,w= 0;

      // pixel kern
      i= 8; tch= ch; gch= glastch;
      do {
        c= *++tch;
        lc= *++gch;
        n= 2; // 2 waster pixels
        do {
          /// shift till overlap
          if ((c<<8) & (lc<<n)) break;
          ++n;
        } while(n<8);
        w= n>w? n: w;
      } while(--i);
      w-= 2;
      //c= '0'+w; //putchar('0'+w);
      w= 5;
      //w= 6;

      glastch= ch;

      // is there room enough?
      if ((gcurx+=w)>240) {
        // break word, add '-' (must have space!)
        //gputc('-'); // TODO: have space for this?
        gputc('\n'); // TODO: remove recrusion?
      }

      d= (gcury*5)*8 + div6[gcurx+1] + (HIRESSCREEN - 40);
      m= 5-mod6[gcurx+1];
      
      // plot actual char
      i= 8;
      do {
        if (1 || gcurx) {
          char s= m + 5-w;
          unsigned int x= (*++ch)<<s;

          *(d+= 40) |= (x&63) | 64;
          if (x>63) d[-1] |= ((x>>6)&63) | 64;
          // This may wrap backwards... (prev line/i.e. right side
          if (x>63*64) d[-2] |= ((x>>12)&63) | 64;
        } else {
          *(d+= 40)= *++ch | 64 | (i==1?63:0);
        }
        //if (curdouble) *(d+= 40)= *ch | 64;
      } while(--i);
      
      // TODO: basically same "is there room enough"
      // but this one acutally moves forward
      //if ((gcurx+=w)>=240) gputc('\n');

    } break;
  }

  glastchar= c;
}

#define SHERLOCK "THE COMPLETE SHERLOCK HOLMES Arthur Conan Doyle Table of contents A Study In Scarlet The Sign of the Four The Adventures of Sherlock Holmes A Scandal in Bohemia The Red-Headed League A Case of Identity The Boscombe Valley Mystery The Five Orange Pips The Man with the Twisted Lip The Adventure of the Blue Carbuncle The Adventure of the Speckled Band The Adventure of the Engineer's Thumb The Adventure of the Noble Bachelor The Adventure of the Beryl Coronet The Adventure of the Copper Beeches The Memoirs of Sherlock Holmes Silver Blaze The Yellow Face The Stock-Broker's Clerk The \"Gloria Scott\" The Musgrave Ritual The Reigate Squires The Crooked Man The Resident Patient The Greek Interpreter The Naval Treaty The Final Problem The Return of Sherlock Holmes The Adventure of the Empty House The Adventure of the Norwood Builder The Adventure of the Dancing Men The Adventure of the Solitary Cyclist The Adventure of the Priory School The Adventure of Black Peter The Adventure of Charles Augustus Milverton The Adventure of the Six Napoleons The Adventure of the Three Students The Adventure of the Golden Pince-Nez The Adventure of the Missing Three-Quarter The Adventure of the Abbey Grange The Adventure of the Second Stain The Hound of the Baskervilles The Valley Of Fear His Last Bow Preface The Adventure of Wisteria Lodge The Adventure of the Cardboard Box The Adventure of the Red Circle The Adventure of the Bruce-Partington Plans The Adventure of the Dying Detective The Disappearance of Lady Frances Carfax The Adventure of the Devil's Foot His Last Bow The Case-Book of Sherlock Holmes Preface The Illustrious Client The Blanched Soldier The Adventure Of The Mazarin Stone The Adventure of the Three Gables The Adventure of the Sussex Vampire The Adventure of the Three Garridebs The Problem of Thor Bridge The Adventure of the Creeping Man The Adventure of the Lion's Mane The Adventure of the Veiled Lodger The Adventure of Shoscombe Old Place The Adventure of the Retired Colourman A STUDY IN SCARLET Table of contents Part I Mr. Sherlock Holmes The Science Of Deduction The Lauriston Garden Mystery What John Rance Had To Tell Our Advertisement Brings A Visitor Tobias Gregson Shows What He Can Do Light In The Darkness Part II On The Great Alkali Plain The Flower Of Utah John Ferrier Talks With The Prophet A Flight For Life The Avenging Angels A Continuation Of The Reminiscences Of John Watson, M.D. The Conclusion PART I (Being a reprint from the reminiscences of John H. Watson, M.D., late of the Army Medical Department.) CHAPTER I Mr. Sherlock Holmes In the year 1878 I took my degree of Doctor of Medicine of the University of London, and proceeded to Netley to go through the course prescribed for surgeons in the army. Having completed my studies there, I was duly attached to the Fifth Northumberland Fusiliers as Assistant Surgeon. The regiment was stationed in India at the time, and before I could join it, the second Afghan war had broken out. On landing at Bombay,"

// dummy
char T,nil,doapply1,print;

void main() {
  char lasty, * p= SHERLOCK;

  hires();
  gclear();
  gcurx= gcury= 0;
  do {
    lasty= gcury;
    gputc(*p); ++p;
    //wait(10);
  } while(*p && gcury>=lasty); // end at wrap-around

  gotoxy(0,25);
  printf("\nWrote %d characters %d chars per line.  ", p-SHERLOCK, (p-SHERLOCK)/25);
  while(1);
}
