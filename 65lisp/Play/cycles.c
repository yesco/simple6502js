// NOTICE:
// 
// The cl65 sim65 of termux doesn't have cycles stuff
// enabled, you need to compile your own version

// It's assuemd to be on a sisterlevel: ../../cc65/

// ../../cc65/bin/cl65 -t sim6502 Play/cycles.c -o cycles.sim && ../../cc65/bin/sim65 cycles.sim


// sim6502 works!
//
// cl65 -t sim6502 Play/fopen.c && sim65 fopen.sim ; echo "Exitcode $?"
#include <stdio.h>

#define LATCH_CYCLES() __asm__("sta $FFC0")

unsigned int cycles() {
//  *(volatile char*)0xFFC0 = 0;
  LATCH_CYCLES();
  *(volatile char*)0xFFC1 = 0;
  return *(volatile unsigned int*)0xFFC2;
}

#define CYCLES() ( *(volatile char*)0xffc0= 0, \
                   *(volatile char*)0xffc1= 0, \
                   *(volatile unsigned long*)0xffc2 )

unsigned long lcycles() {
  LATCH_CYCLES();
  *(volatile char*)0xFFC1 = 0;
//  *(volatile char*)0xFFC0 = 0;
  return *(volatile unsigned long*)0xFFC2;
}

unsigned long lnanos() {
  *(volatile char*)0xFFC0 = 0;
  *(volatile char*)0xFFC1 = 0x80;
  return *(volatile unsigned long*)0xFFC2;
}


#ifdef FISH
int main(void) {
  long start, end, diff;
//  start= lcycles();
//  end= lcycles();
  start = CYCLES();
  end= CYCLES();
  diff= end-start;
  printf("DIFF=%lu\n", diff);
} 

#else

// put inside main and get garbage?
volatile unsigned long calib,start,end;

int main(void) {
  volatile int i;

   calib= lcycles();
   calib= lcycles()-calib;

    while(1) {
      start= lcycles();
      asm("nop");
      end= lcycles()-calib;

      printf("Raw Value, diff: %lu %lu\n", lcycles(), end-start);
    }
} 
#endif

#ifdef foo
int main(int argc, char** argv) {
  FILE* f= fopen("fil", "r");
  int c;
  volatile unsigned long start, end;

  printf("f= $%04x\n", f);
  while((c= fgetc(f))!=EOF) {
    putchar(c); putchar('.');
  }
  fclose(f);

  printf("\n\nKeybaord input:\n");

  while((c= fgetc(stdin))!=EOF) {
    putchar(c); putchar(c); putchar(c);
    printf("\n");
    if (c=='C'-'@') break;
  }

  printf("a\nb\nc\n   bar\rfoo\n");

  printf("Cycles: %lu, %lu ns\n", lcycles(), lnanos());
  asm("nop");
  asm("nop");
  printf("Cycles: %lu, %lu ns\n", lcycles(), lnanos());
  asm("nop");
  asm("nop");
  asm("nop");
  printf("Cycles: %lu, %lu ns\n", lcycles(), lnanos());
  printf("\nc= %d\n", c);
  printf("\nc= %d\n", c);
  printf("Cycles: %lu, %lu ns\n", lcycles(), lnanos());
  printf("Cycles: %lu, %lu ns\n", lcycles(), lnanos());
  printf("Cycles: %lu, %lu ns\n", lcycles(), lnanos());

#define LATCH_CYCLES() ((*(volatile char*)0xFFC0 = 0,\
  *(volatile char*)0xFFC1 = 0))

  // Inside main...
  LATCH_CYCLES();
  printf("Cycles: %lu\n", *(unsigned long*)0xFFC2);
  LATCH_CYCLES();
  start= *(unsigned long*)0xFFC2;
  printf("\noutput %d", c);
  LATCH_CYCLES();
  end= *(unsigned long*)0xFFC2;

  printf("\n\nDIFF= %lu\n\n\n", end-start);

  LATCH_CYCLES();
  printf("Cycles: %lu\n", *(unsigned long*)0xFFC2);

  {
    unsigned long c1, c2;
    LATCH_CYCLES(); c1 = *(unsigned long*)0xFFC2;
    LATCH_CYCLES(); c2 = *(unsigned long*)0xFFC2;
    printf("Do we get diff cycles: %lu\n", c2 - c1);
  }


  return 42;
}
#endif
