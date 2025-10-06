char T,nil,doapply1,print;

typedef unsigned char byte;
typedef unsigned int  word;

// magic byte "operator"
#define $ *(char*)&

// not working
//#define @ *(char*)&
//#define $+ foobar

#include <stdio.h>

int main(void) {
  byte foo[5]= "ABCD";
  int i= 0x1234;
  $ i= 0x42;
  int j= 0x4266;
  $ j= 0x6600 | $ i;
  $ foo= 'a';
  $ foo[2]= 'c';

  printf("i=> %d $%04x\n", i, i);
  printf("j=> %d $%04x\n", j, j);
  printf("foo=> \"%s\"\n", foo);
}
