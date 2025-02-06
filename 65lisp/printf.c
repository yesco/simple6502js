// Poor man's printf replacement
//
// (<) 2024 Jonas S Karlsson
//
// We replace the normal CC65 printf which takes 1533 bytes!

#include <stdlib.h>
#include <stdio.h>
#include <conio.h>
#include <string.h>
#include <ctype.h>

// 3707 Bytes w original printf 4030...
#ifndef FOO
int cdecl printf(const char* fm
mt, ...) {
  int n= 0, *p= (int*)&fmt;
  register char* fmt= fmmt;
  static char x[10];

  --fmt;

 next:
  switch(*++fmt) {
  case 0: return n;

  default: cputc(*fmt); ++n; goto next;

  case '%': { // format directive
    char b= 0, sign= 0, *s= NULL, fill= ' ';
    int w= 0, t= 0;

    fnext:
    switch(*++fmt) {
    case '+': sign= 1; goto fnext;
    case '0': fill= *fmt; goto fnext;
    case 'c': cputc((char)*--p); goto next;

    case 's': s= (char*)*--p; break;

    case 'x': b+= 6;
    case 'u': // TODO: unsigned
    case 'd': b+= 2;
    case 'o': b+= 6;
    case 'b': b+= 2; {
        char d;
        unsigned int v= *--p;
        memset(x, 0, sizeof(x));
        s= x+sizeof(x)-1;
        do {
          d= v%b; v= v/b;
          *--s= (d<10? d: d+7)+'0';
          //cputc(*s);
        } while (v);
      } break;

    default:
      if (isdigit(*fmt)) {
        do { w= w*10 + *fmt++-'0'; } while(isdigit(*fmt));
        goto fnext;
      }

      printf("\n%% Unknonwn printf char: '%c'\n", *fmt); exit(1);
    }

    // print spaces before string
    n+= (t= strlen(s));
    w-= t; while(--w>=0) cputc(fill),++n;
    /// TODO: %.5s (print exactly 5!)
    while(*s) putchar(*s),++s;

    } goto next;
  }

  return n;
}
#endif FOO

// dummys
char print, nil, T, doapply1;

void main() {
  printf("Foobar: %d<", 42);
  printf("Foobar: %s<", "fourty-two");
}
