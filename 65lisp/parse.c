// Dummys for ./r script LOL
//int T,nil,doapply1,print;

// 2434 bytes with printf, 
// #include <stdio.h>

extern void showsize();
extern void start();
extern void* endfirstpage;

#include "disasm.c"

unsigned char* last= 0;

extern char** rules;

extern char *out, output;
#pragma zpsym ("out")

// disasm from last position/call
extern void dasm() {
  if (!last || last==out) last= &output;
  // TODO: this hangs as printf data in ZP corrupted?
  // TODO: use my own printf? lol
  // TODO: define putd(),puth(),put2h()...
  //printf("\nDASM $%u-$%u!\n", last, out);
  disasm(last, out, 2);
  last= out;
}

extern void dasmcc() {
  disasm((void*)start, (void*)&endfirstpage, 0);
}

// from conio-raw.c
#define TEXTSCREEN ((char*)0xBB80) // $BB80-BF3F
#define SCREENROWS 28
#define SCREENCOLS 40
#define SCREENSIZE (SCREENROWS*SCREENCOLS)
#define SCREENLAST (TEXTSCREEN+SCREENSIZE-1)


// C implementation of minimal parse-asm.asm in
// TODO: compare compiled sizes and speed

// (- #x77e #x493) = 747 bytes (asm: 554 bytes, no library)

unsigned int vars[64];

unsigned int num, addr;


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

    // digits
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
    // var something
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
    case ']': goto next;
    case ':': num= addr; goto nextgen;
      // out gen
    case '<': c= num; break;
    case '>': c= num>>8; break;
    case '+': {
      unsigned int t= num+1;
      *out= t; ++out;
      // assume next char is '>'
      c= t>>8;
      nextgen:
      ++rule; } break;
    }
    // output
    *out= c; ++out;
    goto gen;

    // quoted
  case '\\': ++rule; c= *rule;
    // literal
  default:
    // rules(?) - ok can't match unicode... lol
    if (c&128) {
      in= parse(c, in);
      if (in) goto next; else return NULL;
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



// empty main: 284 Bytes (C overhead)

// 423 bytes w printz (- 423 284 30)= 109

// (- 495 423) = 72 bytes for test 28*3 etc...

// 618 bytes w _nil,_t,_eval (- 618 423 72 109) = 14 bytes(?)

// 741 bytes printh (- 741 690) = 51 bytes for printhex

void main() {
  //printf("Hello World!\n");
  
  *TEXTSCREEN= 'A';

  showsize();

  start();

  TEXTSCREEN[2]= 'C';
}
