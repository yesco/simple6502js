// C-code pretty print using 8 colors
//
#define NTYPES 8

char* keywords[]={
  // types (update NTYPES) 
  "void","int","char","long",
  "float","double","byte","word",
  // others
  "if","else","while","do","break","goto","switch","case","default",
  "unsigned","signed","const","volatile","extern","sizeof"};

#define BLACK     128+0
#define RED       128+1
#define GREEN     128+2
#define YELLOW    128+3
#define BLUE      128+4
#define MAGNENTA  128+5
#define CYAN      128+6
#define WHITE     128+7

#define BG        16

#define DEFAULT   GREEN

#define STRING    WHITE
#define KEYWORD   MAGNENTA
#define NUMBER    WHITE
#define FUN       YELLOW
#define TYPE      WHITE
#define DEF       CYAN
#define OPS       GREEN
//#define COMMENT   GREEN
#define COMMENT   CYAN   // best?
//#define COMMENT   BLACK+BG
#define INCLUDE   WHITE

#include <ctype.h>
#include <string.h>

char color, lastc, nextcol;

void pc(char c) {
  if (c>=128) {
    if (color!=c) {
// TODO: if col==2 use col=1 to set color!
      // reuse space/color if was last char
      if (lastc==' ') putchar(8);
      putchar(color=c);
    }
  } else putchar(lastc=c);
}

// BUG: compile again (1 or many times)
//      then ^Garnish it - CRASH!
extern void prettyprint(char* s) {
  char c, *x, found;

  lastc= nextcol= 0;
  color= -1;

//  printf("%s", s); return;

next:
  while(c= *s) {
    found= 0;
    switch(c){
    case '\r': case '\n': color= DEFAULT; lastc=0;
    case '(': case ')': case '[': case ']':
    case ',':
    case ';': pc(c); break; // no car color!
    case '"': pc(STRING); pc(c); while((c=*++s)!='"')pc(c); pc(c); break;
    case '\'': pc(STRING); pc(*s);pc(*++s);pc(*++s); break;
    case '#': pc(INCLUDE); goto printline;
    case '/': if (s[1]=='/') { pc(COMMENT);
      printline: while((c=*s) && c!='\n' && c!='\r')
          pc(c),++s;   goto next; }
      // else fallthrough (if / but not //)
    default:
      if (c<=' ') { pc(c); break; }
      if (isdigit(c)) { pc(NUMBER); found= 1; }
      // -- names
      if (isalpha(c)) {
        // - keyword?
        for(c=0; c<sizeof(keywords)/sizeof(char*); ++c) {
          x= keywords[c];
          if (0==strncmp(x, s, strlen(x))) {
            if (c<NTYPES) pc(TYPE),nextcol=DEF;
            else pc(KEYWORD);
            found= 1;
            break;
          }
        }
        // if not keyword assume FUN/VAR
        if (!found) pc(FUN),found=1;
        // print word
      }
      if (found) {
      printword:
        while(isalnum(c=*s)) pc(c),++s;
        --s;
        if (!nextcol) break;
        // basically word defined
        ++s; // hmmm
        while(isspace(*s)) pc(*s),++s;
        pc(nextcol);
        nextcol= 0;
        goto printword;
      }
      // ELSE: operators?
      // TODO: maybe too many OPS between als chars?
      pc(OPS);
      pc(c);
    }
    // next
    ++s;
  }
}
