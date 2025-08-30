// CC02: 68 bytes
// cc65: 50 bytes

#include <stdio.h>
//int a;
unsigned char a;

void main(){ a=65; A: putchar(a); ++a; if (a<91) goto A; putchar(46); }
