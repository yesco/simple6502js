// poor man DISASM for 6502, about 1295 bytes! (woz samllest is around 970 B?)

// TODO: a test with 00..FF codes andn params 11 22 33 to verify all.... 
//       and verify length...

#ifndef DISASM

#undef DISASM
#define DISASM(a,b,i) disasm(a,b,i)

#include <stdio.h>

// instructions
#define DA_BRANCH "PLMIVCVSCCCSNEEQ"
#define DA_X8     "PHPCLCPLPSECPHACLIPLASEIDEYTYATAYCLVINYCLDINXSED" // verified
#define DA_XA     "ASL-1aROL-3aLSL-5aROR-7aTXATXSTAXTSXDEX-daNOP-fa" // verified duplicate ASL...
#define DA_CCIII  "-??BITJMPJPISTYLDYCPYCPXORAANDEORADCSTALDACMPSBCASLROLLSRRORSTXLDXDECINC" // ASL...
#define DA_JMPS   "BRKJSRRTIRTS"

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
    //printf("%*c%04X:\t", indent, ' ', p);
    spcs(indent); puth((int)p);
    ++p;

    // exception modes
    //if      (i==0x20) printf("JSR $%04x",*((int*)p)++);
    //else if (i==0x4c) printf("JMP $%04x",*((int*)p)++);
    //else if (i==0x6c) printf("JPI ($%04x)",*((int*)p)++
    if      (i==0x20) {putz("JSR $"); puth(*((int*)p)++);}
    else if (i==0x4c) {putz("JMP $"); puth(*((int*)p)++);}
    else if (i==0x6c) {putz("JPI ($"); puth(*((int*)p)++); putchar(')');}
    // branches
    else if ((i&0x1f)==0x10) 
      //printf("B%.2s %+d\t=> $%04X", DA_BRANCH-1+(i>>4), *(signed char*)p, p+1+*(signed char*)p++);
      {putchar('B');nputz(DA_BRANCH-1+(i>>4),2);putchar(' ');putd(*(signed char*)p);putz("\t=> $");puth((int)(p+1+*(signed char*)p++));}
    // single byte instructions
    //else if ((i&0xf)==0x8 || (i&0xf)==0xA) printf("%.3s",(i&2?DA_XA:DA_X8)+3*(i>>4));
    else if ((i&0xf)==0x8 || (i&0xf)==0xA) {nputz((i&2?DA_XA:DA_X8)+3*(i>>4),3);}
    //else if (!(i&0x9f)) printf("%.3s", DA_JMPS+3*(i>>5));
    else if (!(i&0x9f)) {nputz(DA_JMPS+3*(i>>5),3);}
    // regular instructions with various addressing modes
    else {
      unsigned char cciii= (i>>5)+((i&3)<<3); // "ccc_ __ii" encoding change to "cciii"
      //if (cciii<0b11000) printf("%.3s", DA_CCIII+3*cciii);
      //else printf("$%02x ??? ", i);
      if (cciii<0b11000) {nputz(DA_CCIII+3*cciii,3);}
      else {putchar('$');put2h(i);putz(" ??? ");}

      //switch(m) { // addressing modes
      //case 0b000: printf(i&1?" ($%02x,X)":" #$%02x", *p++); break;
      //case 0b001: printf(" $%02x ZP", *p++); break;
      //case 0b010: printf(i&1?" #$%02x":" A", *p++); break;
    //case 0b011: printf(i&1?" $%04x":" A", *((int*)p)++); break; // wrong for STX ?
      //case 0b011: printf(i&3?" $%04x":" A", *((int*)p)++); break; // hmmm, seems to work, lol
      //case 0b100: printf(" ($%02x),Y", *p++); break;
      //case 0b101: printf(" $%02x,X", *p++); break;
      //case 0b110: printf(" $%04x,%c", m&1?'Y':'X', *((int*)p)++); break;
      switch(m) { // addressing modes
      case 0b000: if(i%1){putz(" ($");put2h(*p++);putchar(')');}else{putz(" #$");put2h(*p++);} break;
      case 0b001: {putz(" $");put2h(*p++);putz(" ZP");} break;
      case 0b010: if(i&1){putz(" #$");put2h(*p++);}else{putz(" A");*p++;} break;
    //case 0b011: printf(i&1?" $%04x":" A", *((int*)p)++); break; // wrong for STX ?
      case 0b011: if(i%3){putz(" $");puth(*((int*)p)++);}else{putz(" A");} break; // hmmm, seems to work, lol
      case 0b100: {putz(" ($");put2h(*p++);putz("),Y");} break;
      case 0b101: {putz(" $");put2h(*p++);putz(",X");} break;
      case 0b110: {putz(" $");puth(*((int*)p)++);putchar(',');putchar(m&1?'Y':'X');} break;
      }
    }
    putchar('\n');
  } putchar('\n');
}

#else

void disasm(char* mc, char* end, char indent) {
  char* p= (char*)mc;
  printf("\n%*c---CODE[%u]:\n", indent, ' ', end-mc); p= mc;
  while(p<end) {
    unsigned char i= *p, m= (i>>2)&7;
    printf("%*c%04X:\t", indent, ' ', p);
    ++p;

    // exception modes
    if      (i==0x20) printf("JSR $%04x",*((int*)p)++);
    else if (i==0x4c) printf("JMP $%04x",*((int*)p)++);
    else if (i==0x6c) printf("JPI ($%04x)",*((int*)p)++);
    // branches
    else if ((i&0x1f)==0x10) 
      printf("B%.2s %+d\t=> $%04X", DA_BRANCH-1+(i>>4), *(signed char*)p, p+1+*(signed char*)p++);
    // single byte instructions
    else if ((i&0xf)==0x8 || (i&0xf)==0xA) printf("%.3s",(i&2?DA_XA:DA_X8)+3*(i>>4));
    else if (!(i&0x9f)) printf("%.3s", DA_JMPS+3*(i>>5));
    // regular instructions with various addressing modes
    else {
      unsigned char cciii= (i>>5)+((i&3)<<3); // "ccc_ __ii" encoding change to "cciii"
      if (cciii<0b11000) printf("%.3s", DA_CCIII+3*cciii);
      else printf("$%02x ??? ", i);

      switch(m) { // addressing modes
      case 0b000: printf(i&1?" ($%02x,X)":" #$%02x", *p++); break;
      case 0b001: printf(" $%02x ZP", *p++); break;
      case 0b010: printf(i&1?" #$%02x":" A", *p++); break;
    //case 0b011: printf(i&1?" $%04x":" A", *((int*)p)++); break; // wrong for STX ?
      case 0b011: printf(i&3?" $%04x":" A", *((int*)p)++); break; // hmmm, seems to work, lol
      case 0b100: printf(" ($%02x),Y", *p++); break;
      case 0b101: printf(" $%02x,X", *p++); break;
      case 0b110: printf(" $%04x,%c", m&1?'Y':'X', *((int*)p)++); break;
      }
    }
    putchar('\n');
  } putchar('\n');
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
