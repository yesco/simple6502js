// poor man DISASM for 6502, about 1295 bytes! (woz samllest is around 970 B?)

// TODO: a test with 00..FF codes andn params 11 22 33 to verify all.... 
//       and verify length...

#ifndef DISASM

#undef DISASM
#define DISASM(a,b) disasm(a,b)

#include <stdio.h>

// instructions
#define DA_BRANCH "PLMIVCVSCCCSNEEQ"
#define DA_X8     "PHPCLCPLPSECPHACLIPLASEIDEYTYATAYCLVINYCLDINXSED" // verified
#define DA_XA     "ASL-1aROL-3aLSL-5aROR-7aTXATXSTAXTSXDEX-daNOP-fa" // verified duplicate ASL...
#define DA_CCIII  "-??BITJMPJPISTYLDYCPYCPXORAANDEORADCSTALDACMPSBCASLROLLSRRORSTXLDXDECINC" // ASL...
#define DA_JMPS   "BRKJSRRTIRTS"

void disasm(char* mc, char* end) {
  char* p= (char*)mc;
  printf("\n---CODE[%d]:\n", end-mc); p= mc;
  while(p<end) {
    unsigned char i= *p++, m= (i>>2)&7;
    printf("%04X:\t", p);

    // exception modes
    if      (i==0x20) printf("JSR %04x",*((int*)p)++);
    else if (i==0x4c) printf("JMP %04x",*((int*)p)++);
    else if (i==0x6c) printf("JPI (%04x)",*((int*)p)++);
    // branches
    else if ((i&0x1f)==0x10) 
      printf("B%.2s %+d\t=> %04X", DA_BRANCH-1+(i>>4), *p, p+2+(signed char)*p++);
    // single byte instructions
    else if ((i&0xf)==0x8 || (i&0xf)==0xA) printf("%.3s",(i&2?DA_XA:DA_X8)+3*(i>>4));
    else if (!(i&0x9f)) printf("%.3s", DA_JMPS+3*(i>>5));
    // regular instructions with various addressing modes
    else {
      unsigned char cciii= (i>>5)+((i&3)<<3);
      if (cciii<0b11000) printf("%.3s", DA_CCIII+3*cciii);
      else printf("%02x ??? ", i);

      switch(m) { // addressing modes
      case 0b000: printf(i&1?" (%02x,X)":" #%02x", *p++); break;
      case 0b001: printf(" %02x ZP", *p++); break;
      case 0b010: printf(i&1?" #%02x":" A", *p++); break;
      case 0b011: printf(i&1?" %04x":" A", *((int*)p)++); break;
      case 0b100: printf(" (%02x),Y", *p++); break;
      case 0b101: printf(" %02x,X", *p++); break;
      case 0b110: printf(" %04x,%c", m&1?'Y':'X', *((int*)p)++); break;
      }
    }
    putchar('\n');
  } putchar('\n');
}

#endif // DISASM

#ifdef TESTMAIN

#define MC " \xad\xba \xef\xbe\x60" 
char *mc= MC;

int main() {
  disasm(MC, MC+sizeof(MC));
}

#endif // TESTMAIN
