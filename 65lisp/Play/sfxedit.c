#include "../conio-raw.c"

#include "../sound.c"

typedef struct SFX {
  unsigned int pA, pB, pC; // 12 bit pitch: 0-4095
  unsigned char noise;     // 0-31 (?)
  unsigned char noiseABCenableABC; // 0b00111111 = off, 0b00 011 100, enable d
  char volA; // vol: 0-15, 16-- Envelope
  char volB;
  char volC;
  unsigned int penv;
  char env;
} SFX;

SFX s; 

  //                          0-31 NNNcba     (Mod)vvvv   T      0-15
  //           0   1   2   3   4   5   6   7   8   9  10  11  12  13
  //          Al  Ah  Bl  Bh  Cl  Ch  N4  Ch  Va  Vb  Vc Env-freq ENV
//char* x= "\x00\x00\x00\x00\x00\x00\x1f\x07\x10\x10\x10\x00\x18\x00"; // EXPLODE
//char* x= "\x00\x04\x05\x06\x00\x00\x00\x30\x10\x10\x10\x01\x03\x00"; 
//char* x= "\x18\x00\x00\x00\x00\x00\x00\x3e\x10\x00\x00\x00\x0f\x00"; // PING

char* y= "\x18\x05\x00\x00\x00\x00\x00\x3e\x10\x00\x00\x00\x02\x00"; // dut
char* z= "\x18\x07\x00\x00\x00\x00\x00\x3e\x10\x00\x00\x00\x02\x00"; // boh
//  char* x= "\x00\x00\x00\x00\x00\x00\x0f\x07\x10\x10\x10\x00\x02\x00"; // very short symbal
 // char* x= "\x00\x00\x00\x00\x00\x00\xff\x07\x10\x10\x10\x00\x01\x00"; // short symbal
  char* x= "\x18\x00\x00\x00\x00\x00\x00\x30\x10\x10\x10\x00\x01\x00"; // short symbal // ligher
//  char* x= "\x07\x03\x00\x00\x00\x00\x00\x30\x10\x10\x10\x00\x01\xb3"; // short symbal // ligher
// char x[]= {32,2, 140,0, 5,132, 14, 136, 132, 12,140,0, 69,173}; // TURBOPROP
//   char x[]= {32,2, 140,0, 145,0, 14, 0, 0, 12,140,0, 0,173}; // TURBOPROP

//char* x= "\x18\x00\x00\x00\x00\x00\x00\x3e\x10\x00\x00\x00\x0f\x00"; // PING
//char* x= "\xff\x00\x00\x00\x00\x00\x00\x26\x10\x00\x00\x00\x05\x00"; // 
//char* x= "\x00\x07\x00\x00\x00\x00\xff\x3e\x10\x00\x00\x00\x03\x00"; // 

void waitms(long w) {
  w*= 7;
  while(w-->0);
}

void main() {
  char c=10, i= 0;

  init_conioraw();
  clrscr();

  memcpy(&s, x, sizeof(s));
  //s.pA-=24;
  
  //memcpy(&s, PONG, sizeof(s));
  do {
    cputc(c);
    printf("SFX> ");
    for(i=0; i<sizeof(SFX); ++i) printf("%02x", ((char*)&s)[i]);
    sfx((char*)&s);
    waitms(10);
    sfx((char*)&y);
    waitms(10);
    sfx((char*)&z);
    waitms(25);
  } while(1);
}
