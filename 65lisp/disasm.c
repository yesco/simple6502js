// poor man DISASM for 6502, about 1295 bytes! (woz samllest is around 970 B?)

// TODO: a test with 00..FF codes andn params 11 22 33 to verify all.... 
//       and verify length...

#ifndef DISASM

#undef DISASM
#define DISASM(a,b,i) disasm(a,b,i)

#include <stdio.h>

// instructions
#define DA_BRANCH "plmivcvscccsneeq"
#define DA_X8     "phpclcplpsecphacliplaseideytyatayclvinycldinxsed" // verified
#define DA_XA     "asl-1arol-3alsl-5aror-7atxatxstaxtsxdex-danop-fa" // verified duplicate ASL...
#define DA_CCIII  "-??bitjmpjpistyldycpycpxoraandeoradcstaldacmpsbcaslrollsrrorstxldxdecinc" // ASL...
#define DA_JMPS   "brkjsrrtirts"

// crashes when call from asm...
// TODO: define nputz(),putz(),putd(),puth(),put2h()...

#ifdef NEWP
void puth(unsigned int);
void putd(int);

void nputz(char* s, int n) {
  putchar('s');
  while(*s) {
    putchar('#');
    putd(n);
    putchar('$');
    puth((unsigned int)s);
    if (--n<0) { putchar('<'); return; }
    putchar(*s);
    ++s;
  }
}

void putz(char* s) {
  nputz(s, 32767);
}

void put1h(char i) {
  i&= 0xf;
  putchar( (i<10? '0': 'A'-10) + i );
}

void put2h(unsigned int i) {
  put1h(i>>4);
  put1h((char)i);
}

void puth(unsigned int i) {
  put2h(i>>8);
  put2h((char)i);
}

void putd(int i) {
  if (i<0) { putchar('-'); i= -i; }
  if (i>=10) putd(i/10);
  put1h(i);
}

void spcs(int i) {
  while(--i>=0) putchar(' ');
}

void disasm(char* mc, char* end, char indent) {
  char* p= mc;

  //printf("\n%*c---CODE[%d]:\n", indent, ' ', end-mc);
  putchar('\n'); spcs(indent); putz("---CODE["); putd(end-mc); putz("]:\n");
  
  while(p<end) {
    unsigned char i= *p, m= (i>>2)&7;
    spcs(indent); puth((int)p);
    ++p;

    // exception modes
    if      (i==0x20) {putz("jsr $"); puth(*((int*)p)++);}
    else if (i==0x4c) {putz("jmp $"); puth(*((int*)p)++);}
    else if (i==0x6c) {putz("jpi ($"); puth(*((int*)p)++); putchar(')');}
    // branches
    else if ((i&0x1f)==0x10) 
      {putchar('b');nputz(DA_BRANCH-1+(i>>4),2);putchar(' ');putd(*(signed char*)p);putz("\t=> $");puth((int)(p+1+*(signed char*)p++));}
    // single byte instructions
    else if ((i&0xf)==0x8 || (i&0xf)==0xA) {nputz((i&2?DA_XA:DA_X8)+3*(i>>4),3);}
    else if (!(i&0x9f)) {nputz(DA_JMPS+3*(i>>5),3);}
    // regular instructions with various addressing modes
    else {
      unsigned char cciii= (i>>5)+((i&3)<<3); // "ccc_ __ii" encoding change to "cciii"
      if (cciii<0b11000) {nputz(DA_CCIII+3*cciii,3);}
      else {putchar('$');put2h(i);putz(" ??? ");}

      switch(m) { // addressing modes
      case 0b000: if(i%1){putz(" ($");put2h(*p++);putz(",x)");}else{putz(" #$");put2h(*p++);} break;
      case 0b001: {putz(" $");put2h(*p++);putz(" zp");} break;
      case 0b010: if(i&1){putz(" #$");put2h(*p++);}else{putz(" A");*p++;} break;
    //case 0b011: printf(i&1?" $%04x":" A", *((int*)p)++); break; // wrong for STX ?
      case 0b011: if(i%3){putz(" $");puth(*((int*)p)++);}else{putz(" A");} break; // hmmm, seems to work, lol
      case 0b100: {putz(" ($");put2h(*p++);putz("),y");} break;
      case 0b101: {putz(" $");put2h(*p++);putz(",x");} break;
      case 0b110: {putz(" $");puth(*((int*)p)++);putchar(',');putchar(m&1?'y':'x');} break;
      }
    }
    putchar('\n');
  } //putchar('\n');
}

#else

//#ifdef __ATMOS__
#if 1
  #define ADDR "\x83"
  #define MNIC "\x86"
  #define JMP  "\b\x82"
  #define ARG  "\x87"
  #define VAR  "\x82"
#else
  #define ADDR " "
  #define MNIC " "
  #define JMP  " "
  #define ARG  " "
  #define VAR  " "
#endif // __ATMOS__


extern char vars;

void pvar(int a) {
  char c= a;
  if (a & 0xff00) return;
  c-= (int)&vars;
  if (c>128) ; //printf(" %x", c);
  else printf(VAR"  %c", c/2+'A');
  if (c&1) printf("+1");
}


char* disasm(char* mc, char* end, char indent) {
  char * p= (char*)mc, c;
  int maxlines= 25;

  if (!(end-mc)) return p;
//  printf("\n%*c---CODE[%u]:\n", indent, ' ', end-mc);
  while(p<end) {
    unsigned char i= *p, m= (i>>2)&7;

    // TODO: remove
    indent= 2;

    printf(ADDR"%*c%04X"MNIC, indent, ' ', p);

#ifdef __ATMOS__    
    if (!--maxlines) return p;
#endif

    ++p;

    // exception modes
    if      (i==0x20) printf(JMP"jsr"ARG"$%04x",*((int*)p)++);
    else if (i==0x4c) printf(JMP"jmp"ARG"$%04x",*((int*)p)++);
    else if (i==0x6c) printf(JMP"jpi"ARG"($%04x)",*((int*)p)++);
    // branches
    else if ((i&0x1f)==0x10) 
      printf(JMP"b%.2s"ARG"%+d\t=>"ADDR"$%04X", DA_BRANCH-1+(i>>4), *(signed char*)p, p+1+*(signed char*)p++);
    // single byte instructions
    else if ((i&0xf)==0x8 || (i&0xf)==0xA) printf("%.3s"ARG,(i&2?DA_XA:DA_X8)+3*(i>>4));
    else if (!(i&0x9f)) printf(JMP"%.3s", DA_JMPS+3*(i>>5));
    // regular instructions with various addressing modes
    else {
      unsigned char cciii= (i>>5)+((i&3)<<3); // "ccc_ __ii" encoding change to "cciii"
      if (cciii<0b11000) printf("%.3s"ARG, DA_CCIII+3*cciii);
      else printf("$%02x ??? ", i);

      switch(m) { // addressing modes
      case 0b000: c=*p++;printf(i&1?"($%02x,x)":"#$%02x", c); if(i&1) pvar(c); break;
      case 0b001: c=*p++;printf("$%02x", c); pvar(c); break;
      case 0b010: c=*p++; printf(i&1?"#$%02x":"a", c);
       if (i&1 && ((char)((c&0x7f)-' ')<128-' ')) printf("  '%c'", c);   break;
    //case 0b011: printf(i&1?" $%04x":" a", *((int*)p)++); break; // wrong for STX ?
      case 0b011: printf(i&3?"$%04x":"a", *((int*)p)++); break; // hmmm, seems to work, lol
      case 0b100: c=*p++;printf("($%02x),y", c); pvar(c); break;
      case 0b101: c=*p++;printf("$%02x,x", c); pvar(c); break;
      case 0b111:
      case 0b110: ;printf("$%04x,%c", *((int*)p), i&6?'x':'y'); pvar(*((int*)p)++); break;
      }
    }

    putchar('\n');
  } //putchar('\n');

#ifdef __ATMOS__
// press return for one more line
// currow>24
//  if (*(char*)0x268>24) {
//    putchar(' '); putchar(' '); putchar('>'); getchar();
//  }
#endif __ATMOS__

  return p;
}

#endif // NEWP

#endif // DISASM

#ifdef TESTMAIN

#define MC " \xad\xba \xef\xbe\x60" 
char *mc= MC;

int main() {
  disasm(MC, MC+sizeof(MC));
}

#endif // TESTMAIN
