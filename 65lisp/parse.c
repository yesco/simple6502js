// Dummys for ./r script LOL
//int T,nil,doapply1,print;

// 2434 bytes with printf, 
//#include <stdio.h>

// this makes compiling cgetc() ok but linker fails!
// (I think not defined for sim6502!)
//#include <conio.h>

#include <ctype.h>

extern void clrscr();
extern void init();

// linmker can't find
//extern char mygetc() { return cgetc(); }

#include <stdlib.h>

extern void compileInput();
extern void compileAX(char*);
extern void run();
extern void runN(unsigned int);
extern unsigned int runs; // exitcode, lol
#pragma zpsym ("runs")
extern char mode;
#pragma zpsym ("mode")
extern void tab();
extern void printchar(char c);
extern void printnames();
extern void printvars();
extern void printenv();
extern char* ruleVARS;
#pragma zpsym ("ruleVARS")

void Cstart(){}
void disasmStart(){}


//////////////////////////////////////////
// EXTRA = (- 18608 11427) = 7181 Bytes
//

// TODO: things become unstable if removed! LOL
//   WHY, it's all replaced by RTS (?)

//
#define EXTRAS

// -- enable pretty print of C code 
// 1900 bytes or so!
//#define PRETTYPRINT


#ifdef EXTRAS
  #include "disasm.c"
#else
  
#endif

//extern void showsize();
extern void start();
extern void* endfirstpage;
extern char** rules;
extern unsigned int out;
#pragma zpsym ("out")
extern char output, OK;

//unsigned char* last= 0;
extern unsigned int last= 0;

#ifdef EXTRAS

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
  if (!last || last>=out) iasmstart();
  // TODO: this hangs as printf data in ZP corrupted?
  // TODO: use my own printf? lol
  // TODO: define putd(),puth(),put2h()...
  //printf("\nDASM $%u-$%u!\n", last, out);
  iasm();
  if (last<out) printf("  q - to see more");
}

extern void dasmcc() {
//  disasm((void*)start, (void*)&endfirstpage, 0);
  disasm((char*)(int)&OK, (char*)((int)&OK)+20, 0);
}

// TODO: remove?
extern int myfun(int a, int b) {
  printf("\nmyfun(%d, %d)\n", a, b);
  return a+b;
}

// TODO: remove?

// cc65 library functions are weak and can be overwritten
void gotoxy(char x, char y) { // mabye used int, int
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

#else

// dummies
extern void iasmstart() {}
extern void iasm() {}
extern void dasm() {}
extern int myfun(int a, int b) {}
void gotoxy(char x, char y) {}

#endif

void disasmEnd(){}



// from conio-raw.c
#define TEXTSCREEN ((char*)0xBB80) // $BB80-BF3F
#define SCREENROWS 28
#define SCREENCOLS 40
#define SCREENSIZE (SCREENROWS*SCREENCOLS)
#define SCREENLAST (TEXTSCREEN+SCREENSIZE-1)


// OLD: fix it...
//
// C implementation of minimal parse-asm.asm in
// TODO: compare compiled sizes and speed
//
// (- #x77e #x493) = 747 bytes (asm: 554 bytes, no library)

#ifdef CPARSE
void CparseStart(){}

// TODO: somehow still get varning?
//#pragma zpsym ("vars")
//extern unsigned int vars[64];

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
//      case 'A': addr= (int)(vars+v); break;
//      case 'V': num= (int)(vars+v); break;
//      case 'N': vars[v]= (int)out; break;
//      case 'U': num= vars[v]; break;
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
#endif // CPARSE



// empty main: 284 Bytes (C overhead)
// 423 bytes w printz (- 423 284 30)= 109
// (- 495 423) = 72 bytes for test 28*3 etc...
// 618 bytes w _nil,_t,_eval (- 618 423 72 109) = 14 bytes(?)
// 741 bytes printh (- 741 690) = 51 bytes for printhex

#include <string.h>

void prettyprintStart(){}

#ifdef EXTRAS

#ifdef PRETTYPRINT

  #include "cprettyprint.c"

#else

  // dummy
  extern void prettyprint(char* s) {}
  
#endif

#else

  // dummy
  extern void prettyprint(char* s) {}

#endif

void prettyprintEnd(){}




extern void info();


void error(char* msg, char* data) {
  if (msg && *msg)
    fprintf(stderr, "\n%%%s %s\n", msg, data);
  fprintf(stderr, "\nUsage: mc\n"
"  filename\t\t# compile and run\n"
"  -f filename\t# load file\n"
"  -c\t\t\t# compile\n"
"  -q\t\t\t# disasm\n"
"  -sbug -c -s_compile -r -s_run\t# take 3 snapshots\n"
"  -r[N]\t\t\t# run N times (defaualt 1)\n"
"  -pV\t\t\t# print Variables\n"
"  -pe\t\t\t# print ENV\n"
);
  exit(1);
}




#ifdef __ATMOS___
  // #define EDITSTART HICHARSET;
  #define EDITSTART 0x9800
#else  
  // TODO: lol, we haven't even allocated it!
  //   will (!) get corrupted
  #define EDITSTART 0x9800
#endif // __ATMOS__


//#define PRINTVARIABLES

// C; 736 B   _printvar ASM: 217 B _printenv: 167 B
// double in C? hmmmm
void printvariables() {
#ifdef PRINTVARIABLES
  char * p= ruleVARS, c, t, * name;
  unsigned int v, * a, z;

  printf("=== VARIABLES ===\n");

  while((c= *++p)) {
    // address in ENV
    //putchar('\n');
    //printf("$%04X: ", p);

    // print name, and skip till end of it: '%'
    name= p;
    v= 0;
    while(*p!='%') { putchar(*p++); ++v; }
    // gotox(10+1+4+15); //29 (- 38 29)
    while(v && v++<9) putchar(' ');
    
next:
    ++p; // skip %
    //printf(" {%%%c} ", *p);
    switch((c= *p)) {
// crazy, print one char and you get memory messed up
//    case 'R': p+= 2; putchar('.'); continue; // jumper
    case 'R': p+= 2; printf("\n"); continue; // jumper
    case 'b': ++p; goto next; // wordbreak: ignore
    default:
      if (c & 0x80) {
        // skipper - print variable data
        ++p;
        t= p[2]; a= *(unsigned int**)p; v= *a;
        z= *(unsigned int**)(p+3);

        printf("@ $%04x:", a); printchar(t); //10
        if (t<128) putchar(' '); //1
        printf("%3dz ", z); //4
        // for debugging: any var "sfoo" is assumed string
        if (*name=='s' || t==('C' && 127)) {
          // print string: array=p pointer=v
          char * s= t&0x80? *(char**)p: (char*)v;
          printf("#%2d=\"", strlen(s));
          while(*s) printchar(*s++);
          puts("\"");
        } else {
          // number
          if (v<256) {
            // char
            printf("=%3u '%c' ($%02x)\n",
                   v,
                   (v&127)<' '?0 : v<127?v: 0,
                   v); //14
          } else {
            // word
            printf("= %5u ($%04x)\n", v, v); //15
          }
        }

        // delimit function+params
        if (t=='F') putchar('\n');

        p+= 6; // 5+1 // used to be 3 // TODO:???
        break;
      } else printf("Unknown %%c operator\n", c);
    }
  }
  //putchar('\n');
#endif // PRINTVARIABLES
}

// 315 B!
// just names
void prvars() {
#ifndef PRINTVARIABLES
  char * p= ruleVARS, c, t;
  unsigned int v, z;

  while(*++p) {
    // print name, and skip till end of it: '%'
    v= 0;
    while(*p!='%') { putchar(*p++); ++v; }
next:
    switch((c= *++p)) {
    case 'R': p+= 2; putchar('('); continue; // jumper
    case 'b': ++p; goto next; // wordbreak: ignore
    default:
      if (c & 0x80) {
        // skipper - print variable data
        t= p[3];// a= *(unsigned int**)(p+1) v= *a;
        z= *(unsigned int**)(p+4);

        // TODO: BUG: 0 parameter no '(' printed...
        if (t=='F') printf(") ");
        else if (z!=2) printf("[%d] ", z);
//        else if (t!='w') { putchar(':'); printchar(t); }
        else putchar(' ');

        p+= 7; // 5+1 // used to be 3 // TODO:???
      } else error("op:?", 0);
    }
  }
  putchar('\n');
#endif // !PRINTVARIABLES
}



int argc;
char** argv;


#ifdef __ATMOS__

//void inputfile(char* filename) {
//}

extern int processnextarg() { return 0; }

#else

void inputfile(char* filename) {
  // filename
  char* p= (char*)EDITSTART;
  int c;
  FILE* f= fopen(filename, "r");
  if (!f) error("Not such file:", filename);

  while((c= fgetc(f))!=EOF) {
    *p= c; ++p;



    // TODO: catch TOO BIG file!
    //   EDITEND (sim: _inputend)



  }
  // zero terminate
  *p++= 0;

  fclose(f);
  fprintf(stderr, "\nLoaded file: %s\n", filename);
}

// write whole RAM to a binary snapshot file
int nsnap= 0;
char* snapname= "mc";
char fn[32];

void snapshot(char* arg) {
  char * key= "", * p;
  FILE * f;
  unsigned int a= 0;

  if (*arg) {
    if (*arg=='_') key= arg;
    else           snapname= arg;
  }

  memset(fn, 0, sizeof(fn));
// remove these two adn fail compile on 6502?
  puts("");

// works
//  printf("snap-%s-%02d%s.ram\n",
//         snapname, nsnap, key);

// doesn't work?!?!?!
//  snprintf(fn, sizeof(fn), "snap-%s-%02d%s.ram",
//           snapname, nsnap, key);

  // TODO: doesn't work!? cc65
  //sprintf(&fn[0]+strlen(fn)-1, "%02u", nsnap);

  strcat(fn, "snap-");
  strcat(fn, snapname);
  p= fn+strlen(fn);
  p[0]= '-';
  p[1]= nsnap/10+'0';
  p[2]= nsnap%10+'0';
  strcat(fn, key);
  strcat(fn, ".ram");

  printf("Snapshot: %s\n", fn+0);

  f= fopen(fn, "w");
  // write out 64K
  if (1) {
    p= a= 0; do {
      fputc(*p++, f);
    } while(++a);
    printf("Snapshot generated: %s\n", fn);
  } else {
    // TODO: cc65 - doesn't do anything!
    if (256==fwrite((char*)0, 256, 256, f)) 
      printf("Snapshot generated: %s\n", fn);
    else
      error("Problem writing snapshot:", fn);
  }
  fclose(f);

  ++nsnap;
}

// process args
// (ignores first==program name)

extern void processnextarg() {
  char* a= *++argv;

  putchar('\n');

  // not processing arguments
  if (argc < 0) return;

  // finished arguments: exit
  if (argc <= 1) {
    putchar('\n');
    exit(runs); // only returns byte?
  }

  putchar('\n');

  printf("\n--- arg %d: %s\n", argc, a);

  --argc;

  if (isalpha(*a)) {

    inputfile(a);

    // compileAX doesn't return, so let's hack:
    strcpy(a, "-r"); // replacde filename w "-r"
    ++argc; // run one extra time
    --argv; // step back to "-r"
      
    printf("--------------------\n");
    compileAX((char*)EDITSTART);

  } else if (*a== '-') {

    // process other args -?
    switch (a[1]) {
    case 0: break;
      // these DO NOT return!
    case 'c': compileAX((char*)EDITSTART); break;
    case 'r': runN(atoi(a+2)); break;
      // these do return
    case 's': snapshot(a+2); break;
    case 'f':
    case 'l': --argc; ++argv; inputfile(*argv); break;
    case 'q': dasm(); break;
    case 'p': // print 
      switch(a[2]) {
      case 'V': printvariables(); break;
      case 'v': printvars(); break; // bad?
      case 'N': printnames(); break;
      case 'n': prvars(); break;
      case 'e': printenv(); break;
      case 's': // print source
      default: error("Unknown 'p'rint option(-pv -pe): ",a);
      }
      break;
      // TODO:
    case 'h': error("", ""); // help
    case 'b': // benchmark
    case 'e': // expression
    default: error("Unkown option: ", a);
    }

  } else error("Unknown option: ", a);

  // we "recurse"
  processnextarg();
}

#endif


void main(int iargc, char** iargv) {
  // save for processnextarg()
  argc= iargc; argv= iargv;

  init();
  
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
  // first we compile showing white
  *(char*)0x26c= 7; // white

#endif // __ATMOS__


  // from tty-helpers.asm (?)
  clrscr();
  // cputc('X'); // not on sim!

#ifdef __ATMOS__
  TEXTSCREEN[0]= 'A';
#endif // __ATMOS__

  // if args, don't go interactive
  if (argc > 1) {
    // don't do intro in batchmode
    // no buffer to init
    mode = 0;

    processnextarg();
    // doesn't return 

  } else {
    // mark that we're NOT processing args
    argc= -1;
  }

  start();
  // never returns, but if it did

#ifdef __ATMOS__
  TEXTSCREEN[2]= 'C';
#endif // __ATMOS__

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
extern char     stmtbyterulestart,stmtbyteruleend;
extern char     oricstart,oricend;
extern char   byterulesstart,byterulesend;
extern char idestart,ideend;
extern char   editorstart,editorend;
extern char   helptext,helptextend,help,helpend;
extern char   inputstart,inputend;
extern char debugstart,debugend;
extern char biosstart,biosend;
extern char librarystart,libraryend;
extern char   runtimestart,runtimeend;
extern char   ctypestart,ctypeend;
extern char   stdiostart,stdioend;
extern char   stringstart,stringend;
extern char   stdlibstart,stdlibend;
extern char   mathstart,mathend;
extern char   graphicsstart,graphicsend;
extern char   minimallibrarystart,minimallibraryend;
extern char   outputstart,outputend;

extern void Cend();
extern void infoEnd();

#ifdef EXTRAS

void info() {
  static unsigned int outsize;
  outsize= out-(int)&output;
  if (outsize>16384) outsize= 0;

   //--------------------------------------



// TAP-file: (- 16792 2944 1350 922 7394)= 4182
//
// TODO: RODATA: +13xx bytes from disasm + prettyprint
// TODO: 4KB cc65 libraries (?) - is this correct?
//    can create file without any asm and see size?


  printf
    ("\x0c\x94\x87- CC02  MeteoriC-6502-compiler -  \x90\n"
// TAP-file
     "C %u main %u (loader) TEXT: ?%u\n"
     "  (disasm)   %6u - ^Q disasm code\n"
//     "  parse      %6u - alt impl\n"
     "  (prettypr) %6u - ^G colorize\n"
     "  (info)     %6u - *this* page!\n"
   //--------------------------------------
     "FILES        %6u - input/files\n"
     "ASM          %6u   Debug   %4u\n"
     "\x86""IDE         %6u\n"
     "  editor     %6u   commands%4u\n"
     "  help       %6u - help text+code\n"
     "\x86""C-compiler  %6u\n"
     "  BNF-intrp  %6u - BNF interpreter\n"
     "  C-rules    %6u - C lang rules\n"
     "    I/O      %6u - put,get-char\n"
     "    mem      %6u - peek/malloc\n"
     "    ops      %6u - + / * ... == <\n"
     "    params   %6u - f(3,4,a,b)\n"
     "    stms     %6u - if while a+=3;\n"
     "      oric   %6u - ORIC ATMOS API!\n"
     "      byterules%4u - ++$c; etc\n"
     "    misc     %6u - misc rules;\n"
     "    (incl optimize ?%u/byte ?%u)\n"
// TODO:
//    "      OPT    %6u - OPT: normal ops\n"
// TODO:
//   "  symbols           \n"
   //--------------------------------------
     // "  minilib    %6u\n"
     "\xff  bios\x83+%u\x82 LIB\x82runtime\x87%u\x82misc\x87%u\n"
     "\xff  LIB ctype\x87%u\x82stdio\x87%u\x82str\x87%u\n"
     "\x83\xff tap-file \x80\x93=%4u\x82\x90"" bios\x87LIBS\x83+%u\n"
     "\xff  LIB stdlib\x87%u\x82math\x87%u\x82graphics\x87%u\n"
     "\xff  code      \x83+%4u\x82- compiled code" // no \n1
     
//     "  /reserv    %6u - area reserved"
     , (char*)Cend-(char*)Cstart
       , (char*)Cend-(char*)Cstart-(0
          + (char*)disasmEnd-(char*)disasmStart
//          + (char*)CparseEnd-(char*)CparseStart
          + (char*)prettyprintEnd-(char*)prettyprintStart
          + (char*)infoEnd-(char*)info
          )
       , 1300
       , (char*)disasmEnd-(char*)disasmStart
//       , (char*)CparseEnd-(char*)CparseStart
       , (char*)prettyprintEnd-(char*)prettyprintStart
       , (char*)infoEnd-(char*)info
     , &inputend-&inputstart
     , &asmend-&asmstart, &debugend-&debugstart
       , &ideend-&idestart
         , &editorend-&editorstart
              , ( (&ideend-&idestart)
                  - (&editorend-&editorstart)
                  - (&helptextend-&helptext)
                  - (&helpend-&help)
                )
         , (0
          + &helptextend-&helptext
          + &helpend-&help
          )
       , (0
          + &bnfinterpend-&bnfinterpstart
          + &rulesend-&rulesstart
          )
         , &bnfinterpend-&bnfinterpstart
         , &rulesend-&rulesstart
           , &iorulesend-&iorulesstart
           , &memoryrulesend-&memoryrulesstart
           , &oprulesend-&oprulesstart
           , &parametersend-&parametersstart
           , &stmtrulesend-&stmtrulesstart
             , &oricend-&oricstart
             , &stmtbyteruleend-&stmtbyterulestart
           , (&rulesend-&rulesstart
              - (&iorulesend-&iorulesstart)
              - (&memoryrulesend-&memoryrulesstart)
              - (&oprulesend-&oprulesstart)
              - (&parametersend-&parametersstart)
              - (&stmtrulesend-&stmtrulesstart)
              - (&byterulesend-&byterulesstart)
              )
         // optimizations
           , 1300
           , &byterulesend-&byterulesstart
       // TODO: , symbols...
       // one line "bios..."
         , &biosend-&biosstart
         , &runtimeend-&runtimestart
         , (&libraryend-&librarystart
            -(&runtimeend-&runtimestart)
            -(&ctypeend-&ctypestart)
            -(&stdioend-&stdiostart)
            -(&stringend-&stringstart)
            -(&stdlibend-&stdlibstart)
            -(&mathend-&mathstart)
            -(&graphicsend-&graphicsstart)
            )
       // second line "ctype..."
         , &ctypeend-&ctypestart
         , &stdioend-&stdiostart
         , &stringend-&stringstart
         // , &minimallibraryend-&minimallibrarystart
       // TAP-file estimate
       , (0
          + (&biosend-&biosstart)
          + (&libraryend-&librarystart)
          // + (&minimallibraryend-&minimallibrarystart)
          + outsize
          )
       // library summary
       , &libraryend-&librarystart
       // second last line "stdlib..."
         , &stdlibend-&stdlibstart
         , &mathend-&mathstart
         , &graphicsend-&graphicsstart
       , outsize
     );
}

#else

// dummy
//void info() { cputs("Nothing here!\n"); }

// empty one crashes? why?

void info() { }

#endif // EXTRAS

void infoEnd(){}

// difficult to refer to!
void Cend() {}

