#include <stdio.h>

#define MAIN
#include "../conio-raw.c"

char ULQ[]= {
  0b00000000,
  0b00000000,
  0b00000000,
  0b00011111,
  0b00011111,
  0b00011000,
  0b00011000,
  0b00011000
};

char UL[]= {
  0b00000000,
  0b00000000,
  0b00000000,
  0b00111111,
  0b00111111,
  0b00000000,
  0b00000000,
  0b00000000,
};

char URQ[]= {
  0b00000000,
  0b00000000,
  0b00000000,
  0b00111000,
  0b00111100,
  0b00011110,
  0b00011111,
  0b00011111,
};

char BLQ[]= {
  0b00011000,
  0b00011000,
  0b00011000,
  0b00011111,
  0b00000111,
  0b00000011,
  0b00000000,
  0b00000000,
};

char LL[]= {
  0b00011000,
  0b00011000,
  0b00011000,
  0b00011000,
  0b00011000,
  0b00011000,
  0b00011000,
  0b00011000,
};


char BL[]= {
  0b00000000,
  0b00000000,
  0b00111111,
  0b00111111,
  0b00111111,
  0b00111111,
  0b00000000,
  0b00000000,
};

char BRQ[]= {
  0b00011111,
  0b00011111,
  0b00011111,
  0b00111111,
  0b00111111,
  0b00111111,
  0b00000000,
  0b00000000,
};

char RL[]= {
  0b00011111,
  0b00011111,
  0b00011111,
  0b00011111,
  0b00011111,
  0b00011111,
  0b00011111,
  0b00011111,
};

int T,nil,print,doapply1;

void main() {
  memcpy(CHARDEF('['), ULQ, 8);
  memcpy(CHARDEF('\\'), LL, 8);
  memcpy(CHARDEF(']'), URQ, 8);

  memcpy(CHARDEF('-'), UL, 8);

  memcpy(CHARDEF('{'), BLQ, 8);
  memcpy(CHARDEF('|'), RL, 8);
  memcpy(CHARDEF('}'), BRQ, 8);

  memcpy(CHARDEF('_'), BL, 8);

  gotoxy(0,10);
  printf("[------------------]\n");
  printf("\\                  |\n");
  printf("\\                  |\n");
  printf("\\                  |\n");
  printf("\\                  |\n");
  printf("\\                  |\n");
  printf("\\                  |\n");
  printf("\\                  |\n");
  printf("{__________________}\n");

  while(1);
}
