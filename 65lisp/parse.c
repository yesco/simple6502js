// Dummys for ./r script LOL
//int T,nil,doapply1,print;

// 2434 bytes with printf, 
// #include <stdio.h>

void Cstart(){}

void disasmStart(){}

#include "disasm.c"

extern void showsize();
extern void start();
extern void* endfirstpage;
extern char** rules;
extern unsigned int out;
#pragma zpsym ("out")
extern char output, OK;

//unsigned char* last= 0;
unsigned int last= 0;

// incremental disasm from last position/call
extern void iasmstart() {
  last= (int)&output;
  if (out-last) printf("---CODE[%u]:\n", out-last);
}

extern void iasm() {
  if (out<=last) return;
  putchar('\n');
  last = (int)disasm((char*)last, (char*)out, 2);
  putchar(128+2); // green code text
}

// disasm from last position/call
extern void dasm() {
  if (!last || last==out) iasmstart();
  // TODO: this hangs as printf data in ZP corrupted?
  // TODO: use my own printf? lol
  // TODO: define putd(),puth(),put2h()...
  //printf("\nDASM $%u-$%u!\n", last, out);
  iasm();
}

extern void dasmcc() {
//  disasm((void*)start, (void*)&endfirstpage, 0);
  disasm((int)&OK, ((int)&OK)+20, 0);
}

void disasmEnd(){}



extern int myfun(int a, int b) {
  printf("\nmyfun(%d, %d)\n", a, b);
  return a+b;
}

// from conio-raw.c
#define TEXTSCREEN ((char*)0xBB80) // $BB80-BF3F
#define SCREENROWS 28
#define SCREENCOLS 40
#define SCREENSIZE (SCREENROWS*SCREENCOLS)
#define SCREENLAST (TEXTSCREEN+SCREENSIZE-1)


void CparseStart(){}

// OLD: fix it...
//
// C implementation of minimal parse-asm.asm in
// TODO: compare compiled sizes and speed

// (- #x77e #x493) = 747 bytes (asm: 554 bytes, no library)

unsigned int vars[64];

unsigned int num, addr, tmp;

char* parse(char r, char* in) {
  char* rule= rules[r&63];
  char c, t;

  --rule; // lol
 next:
  ++rule;
  switch(*rule) {

    // success!
  case 0: case '|': return in;

    // matchers
  case '%': 
    ++rule;

    // %D - digits
    if ((c= *in)=='D') {
      t= num= 0;
      while(1) {
        c= *in-'0';
        if (c>'9') {
          if (t) goto next;
          else goto fail;
        }
        ++in;
        num= num*10+c;
        ++t;
      }
    }
    // %A %V %N %U - var something
    // TODO: long names
    {
      unsigned v= *in-'@';
      if (v>'z'-'@') goto fail;
      switch(c) {
      case 'A': addr= (int)(vars+v); break;
      case 'V': num= (int)(vars+v); break;
      case 'N': vars[v]= (int)out; break;
      case 'U': num= vars[v]; break;
      default: goto fail;
      }
    }
    // generate
  case '[':
  gen:
    switch((c= *rule)) {
// TODO: ; # D d ...
    case ']': goto next;
    case ':': num= addr; goto nextgen;
      // out gen
    case '<': c= num; break;
    case '>': c= num>>8; break;
    case '+':
      tmp= num+1;
//TODO: fix
//      *out= t; ++out;
      // assume next char is '>'
      c= t>>8;
      nextgen:
      ++rule;
      break;
    }
    // output
//TODO: fix
//    *out= c; ++out;
    goto gen;

    // quoted
  case '\\': ++rule; c= *rule;
    // literal
  default:
    // rules(?) - ok can't match unicode... lol
    if (c&128) {
      char* r= parse(c, in);
      if (r) {
        in= r;
        goto next;
      } else goto fail;
    }    
    // letter
    if (c != *in) goto fail;
    ++in;
    goto next;
  }

 fail:
  // TODO: can we by mistake go past 0 above?
  do {
    c= *++rule;
    if (!c) return NULL;
  } while (c!='|');
  goto next;
}

void CparseEnd(){}


// empty main: 284 Bytes (C overhead)

// 423 bytes w printz (- 423 284 30)= 109

// (- 495 423) = 72 bytes for test 28*3 etc...

// 618 bytes w _nil,_t,_eval (- 618 423 72 109) = 14 bytes(?)

// 741 bytes printh (- 741 690) = 51 bytes for printhex

#include <conio.h>

// cc65 library functions are week and can be overwritten
void gotoxy(char x, char y) {
#define CURROW *(char*)0x268
#define CURCOL *(char*)0x269
#define ROWADDR *(int*)0x12
#define SCREEN 0xbb80
//TODO: cursor off
  putchar('Q'-'@');
  CURCOL= x;
  CURROW= y;
  ROWADDR= 40*y+SCREEN;
  putchar('Q'-'@');
//TODO: cursor on
}


void prettyprintStart(){}

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
#define COMMENT   GREEN

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
  char c, i, *x, found;

  lastc= nextcol= 0;
  color= DEFAULT;

//  printf("%s", s); return;

next:
  while(c= *s) {
    found= 0;
    switch(c){
    case '\r': case '\n': color= DEFAULT; lastc=0;
    case '(': case ')': case '[': case ']':
    case ';': pc(c); break; // no car color!
    case '"': pc(STRING); while((c=*s)!='"')pc(c),++s; pc(c); break;
    case '\'': pc(STRING); pc(*s);pc(*++s);pc(*++s); break;
    case '/': if (s[1]=='/') { pc(COMMENT); while((c=*s) && c!='\n' && c!='\r') pc(c),++s; goto next; }
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
void prettyprintEnd(){}


extern void info();


void main() {
#ifdef FIHS
  int i;
  printf("%d\n", myfun(17, 42));
  for(i=0; i<26; ++i) { gotoxy(i,i); putchar('A'+i); }
  getchar();
#endif

#ifdef __ATMOS__
  // bgcolor(0);
  // $26B Paper colour (+16).
  *(char*)0x26b= 16+0;

  //textcolor(2);
  // $26C Ink colour.
  *(char*)0x26c= 2; // green
#endif // __ATMOS__

  clrscr();

  printf("Hello World!\n");

  //exit(42);
  
  *TEXTSCREEN= 'A';

  showsize();
  info();

  start();

  TEXTSCREEN[2]= 'C';
}

// show sizes info

extern char asmstart,asmend;
extern char bnfinterpstart,bnfinterpend;
extern char rulesstart,rulesend;
extern char   iorulesstart,iorulesend;
extern char   memoryrulesstart,memoryrulesend;
extern char   postprerulesstart,postprerulesend;
extern char   oprulesstart,oprulesend;
extern char   parametersstart,parametersend;
extern char   stmtrulesstart,stmtrulesend;
extern char   byterulesstart,byterulesend;
extern char   oricstart,oricend;
extern char idestart,ideend;
extern char   editorstart,editorend;
extern char   helptext,helptextend,help,helpend;
extern char   inputstart,inputend;
extern char   biosstart,biosend;
extern char   librarystart,libraryend;
extern char   minimallibrarystart,minimallibraryend;
extern char   outputstart,outputend;

extern void Cend();
extern void infoEnd();

void info() {
    //----------------------------------------
  printf
    ("--- CC02 (65-MUCC-02 w C-rules) ---\n"
     "C               %6u - used as 'loader'\n"
     "  disasm        %6u - ^Q disasm code\n"
     "  parse         %6u - alt impl.\n"
     "  prettyprint   %6u - ^G colorize\n"
     "  info          %6u - *this* page!\n"
     "  main          %6u - main/loader\n"
     "asm             %6u (bytes)\n"
     "  C-compiler    %6u\n"
     "    BNF-intrp   %6u - BNF interpreter\n"
     "    C-rules     %6u - C lang rules\n"
     "      iorules   %6u - printf/put,get-char\n"
     "      memrules  %6u - peek/poke/malloc\n"
     "      ++--rules %6u - ++a; --b; ...\n"
     "      op-rules  %6u - + / * ... == <\n"
     "      paramsrul %6u (3,4,a,b)\n"
     "      stmsrules %6u - if do while a+=3;\n"
     "        oric    %6u - ORIC ATMOS API!\n"
     "   (byterules   %6u)- optional: byte ops\n"
//   "  symbols           \n"
     "  IDE           %6u\n"
     "    editor      %6u\n"
     "    help        %6u - help text+code\n"
     "    input       %6u - input/test files\n"
     "  tap-file      %6u - estimated .tap-file\n"
     "    bios        %6u - getchar/putchar\n"
     "    library     %6u - try to keep minimal\n"
     "    minilib     %6u\n"
     "    output      %6u - (%4x-%4x) gen code\n"
     "    /reserv     %6u - total area reserved\n"
     "\n\n\n"
     , (char*)Cend-(char*)Cstart
       , (char*)disasmEnd-(char*)disasmStart
       , (char*)CparseEnd-(char*)CparseStart
       , (char*)prettyprintEnd-(char*)prettyprintStart
       , (char*)infoEnd-(char*)info
       , (char*)Cend-(char*)Cstart-(0
          + (char*)disasmEnd-(char*)disasmStart
          + (char*)CparseEnd-(char*)CparseStart
          + (char*)prettyprintEnd-(char*)prettyprintStart
          + (char*)infoEnd-(char*)info
          )
     , &asmend-&asmstart
       , (0
          + &bnfinterpend-&bnfinterpstart
          + &rulesend-&rulesstart
          )
         , &bnfinterpend-&bnfinterpstart
         , &rulesend-&rulesstart
           , &iorulesend-&iorulesstart
           , &memoryrulesend-&memoryrulesstart
           , &postprerulesend-&postprerulesstart
           , &oprulesend-&oprulesstart
           , &parametersend-&parametersstart
           , &stmtrulesend-&stmtrulesstart
             , &oricend-&oricstart
           , &byterulesend-&byterulesstart
       // TODO: , symbols...
       , &ideend-&idestart
       , &editorend-&editorstart
       , (0
          + &helptextend-&helptext
          + &helpend-&help
          )
       , &inputend-&inputstart
       , (0
          + (&biosend-&biosstart)
          + (&libraryend-&librarystart)
          + (&minimallibraryend-&minimallibrarystart)
          + (out-(int)&output)
          )
         , &biosend-&biosstart
         , &libraryend-&librarystart
         , &minimallibraryend-&minimallibrarystart
         , out-(int)&output, out, (int)&output
         , &outputend-&outputstart
     );
}
void infoEnd(){}

// difficult to refer to!
void Cend() {}

