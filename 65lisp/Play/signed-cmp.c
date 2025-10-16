#define UBIG

#include <stdio.h>
#include <stdint.h>

//typedef uint16_t XYZ;
typedef int16_t XYZ;

extern int getcalled;

int main(void) {
  XYZ i=4711;
  printf("int=%d\n", sizeof(int));
  printf("short=%d\n", sizeof(short));
  printf("TYPE=%d\n", sizeof(XYZ));
  printf("%d=> %d %d %d\n", i, (i<-13), (i<-17), (i<033000));
  i= -3;
  printf("%d=> %d %d %d\n", i, (i<-13), (i<-17), (i<033000));
  i= -66666;
  printf("%d=> %d %d %d\n", i, (i<-13), (i<-17), (i<033000));
  return 42;
}
