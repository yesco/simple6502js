#include <6502.h>
#include "../conio-raw.c"

char interStack[1024];

void inter() {
  putchar('!');
}

extern int T=0;
extern int nil=0;
extern int doapply1=0;
extern int print=0;

void main() {
  set_irq((irq_handler)inter, interStack, sizeof(interStack));

  printf("Hello Interrupt!\n");
  while(1) {
    putchar('.');
    wait(100);
  }
}
