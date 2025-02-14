// TIMER
//
// ORIC ATMOS clock-cycle time meassurements!

#include <6502.h>

// TODO: shrink
char timerStack[1024];

#include "conio-raw.c"

// (/ 65536 16) = 4096 s

long countTime= 0;

#define INC (unsigned int)(0xffff-3)

void interTimer() {
  //putchar('!');
  // unstable
  //countTime+= (65336L-1);

//(- 65536 32 970 11)

  // fc0b count up seems most accurate!
  // gives an error per second out of thousands...
  // (- 65270 65536)

  // (- 5535 65270)
  // (- 65270 528 224)

  // (- 65536 59595)

  asm("clc");
  asm("lda %v+0", countTime);
//  asm("adc #$0b");
//  asm("adc #$ff"); // 25/5082
  asm("adc #$06"); // 25/7127
  asm("sta %v+0", countTime);

  asm("lda %v+1", countTime);
//  asm("adc #$fc");
//  asm("adc #$ff");// 25/5082
  asm("adc #$fc"); // 25/7127
  asm("sta %v+1", countTime);

  asm("lda %v+2", countTime);
  asm("adc #0");
  asm("sta %v+2", countTime);

  asm("lda %v+3", countTime);
  asm("adc #0");
  asm("sta %v+3", countTime);
  //asm("rti");
}

void rti() {
  asm("rti");
}

//(/ 1000000 16.0) ((unsigned int)1000000L/16)
//#define TIMER_START (unsigned int)62500L
#define TIMER_START 0xffff

#define TIMER (*(unsigned int*)0x306)
#define READTIMER (*(unsigned int*)0x304)

void init_timer() {
  // ORIC BASIC ROMs remap interrupt vector to page 2...
  if (*((char*)0xFFFF)==0x02) {
    // We're running under an ORIC BASIC ROM!
  }

  *(int*)0x228= (int)rti;

  TIMER= TIMER_START;
  // TODO: Research - what does it do on ROM-only?
  set_irq((irq_handler)interTimer, timerStack, sizeof(timerStack));
}

#define TIMEROVERHEAD 487


#define UCLOCK_T (3*14 + 12)

unsigned int t1a, t1b, t1c, t1d;
long t1A, t1B, t1C, t1D;

void uclock1() {
  //return (countTime-= TIMEROVERHEAD) + ~READTIMER;
  t1A= countTime;
  asm("lda $304");
  asm("ldx $305");
  asm("sta %v",   t1a);
  asm("stx %v+1", t1a);

  t1B= countTime;
  asm("lda $304");
  asm("ldx $305");
  asm("sta %v",   t1b);
  asm("stx %v+1", t1b);
  
  t1C= countTime;
  asm("lda $304");
  asm("ldx $305");
  asm("sta %v",   t1c);
  asm("stx %v+1", t1c);

  t1D= countTime;
  asm("lda $304");
  asm("ldx $305");
  asm("sta %v",   t1d);
  asm("stx %v+1", t1d);
}

unsigned int t2a, t2b, t2c, t2d;
long t2A, t2B, t2C, t2D;
void uclock2() {
  //return (countTime-= TIMEROVERHEAD) + ~READTIMER;
  t2A= countTime;
  asm("lda $304");
  asm("ldx $305");
  asm("sta %v",   t2a);
  asm("stx %v+1", t2a);

  t2B= countTime;
  asm("lda $304");
  asm("ldx $305");
  asm("sta %v",   t2b);
  asm("stx %v+1", t2b);
  
  t2C= countTime;
  asm("lda $304");
  asm("ldx $305");
  asm("sta %v",   t2c);
  asm("stx %v+1", t2c);

  t2D= countTime;
  asm("lda $304");
  asm("ldx $305");
  asm("sta %v",   t2d);
  asm("stx %v+1", t2d);
}

// t2 - t1
long udiff() {
  long a,b;
  if (0) {
    printf("t1a=%8d t2a=%8d d=+%8d\n", t1a, t2a, t2a-t1a);
    printf("t1b=%8d t2b=%8d d=+%8d\n", t1b, t2b, t2b-t1b);
    printf("t1c=%8d t2c=%8d d=+%8d\n", t1c, t2c, t2c-t1c);
  }

#define CDF 60
#define CYC 60
  if      (t1a-t1b == CYC && t1A==t1B) a= t1A+ ~t1a;
  else if (t1b-t1c == CYC && t1B==t1C) a= t1B+ ~t1b -CDF*1;
  else if (t1c-t1d == CYC && t1C==t1D) a= t1C+ ~t1c -CDF*2;
  else { putchar('A'); return -1; }

  if      (t2a-t2b == CYC && t2A==t2B) b= t2A+ ~t2a;
  else if (t2b-t2c == CYC && t2B==t2C) b= t2B+ ~t2b -CDF*1;
  else if (t2c-t2d == CYC && t2C==t2D) b= t2C+ ~t2c -CDF*2;
  else { putchar('B'); return -2; }

  //a= t1A+ ~t1a;
  //b= t2A+ ~t2a;
  return b-a -252;
//  return a-b -CYC*3;
  //return t1a-t1b - CYC; // for calibration
}


#ifndef MAIN

//#include "conio-raw.c"

// dummy remove
char T,nil,doapply1,print;

long a,b,c,d;

void f() {}

void main() {
  int n=0, err=0;
  init_conioraw();

  // TODO: disable all basic interrupts!

  printf("Hello Interrupt! %u => %u\n", TIMER, TIMER_START);
  init_timer();

  printf("Hello Interrupt!\n");
  while(1) {
    //putchar('.');
    uclock1();
    uclock2();
    a= udiff();
    ++n;
    if (a) {
      ++err;
      printf("%+4ld diff, e=%d/%d\n", a, err, n);
    }

    //f();

    //if (b-a!=0) printf("%+2ld diff between measure!\n", b-a);
    //if (d-c!=0) printf("%+2ld diff between measure!\n", d-c);
    //if (c-b!=12) printf("%+2ld diff for JSR!\n", c-b);
  }
}

#endif // TEST

