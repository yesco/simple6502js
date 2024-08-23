#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>.

#include <conio.h>

int main() {//int argc, char** argv) {
  char foo[16]= {0};
  int a, x= 0;

  //clrscr(); // in conio but linker can't find (in sim?)
  //kbhit();

  {
    char *x= 0, *last= 0;
    int i, d;
    int z= 1024, n= 0;
    int ta= 0, tm= 0;
    printf("HEAP...\n");
    do {
      if (x && last) {
        i= (int)x;
        d= x-last-z;
        printf("%2d\t%d%d%d\n", d, i&4, i&2, i&1);
        ta+= z;
        tm+= d+z;
      }
      last= x;
      x = malloc(z);
      n++;
    } while(x);
    printf("\nTOTAL: %u allocs of %d, %u bytes, used %u bytes\n",
           n, z, ta, tm);
    exit(0);
  }
  

#ifdef FOO
  // output test
  printf("printf Hello World\n");
  printf("\n"); // each printf is 100 bytes more???
  putchar('\n'); // 38 bytes!
  puts("foo\n");
  fputc('x', stdout); // not buffered
  putc('y', stdout); // not buffered
  putchar('\n');

  // no have
  //a= setvbuf(stream, NULL, _IONBF, 0);

  // reading test
  putchar('>');
  //a= read(stdin, foo, 2); // NO
  a= read(0, foo, 2); // blocking read (till return)

  printf("read=%d and '%s'\n", a, foo);

  a= getchar();
  printf("getchar=%d and '%c'\n", a, a);

#endif


  for(a=32767; a>0; --a) {

// SWITCH is faster 2.98s 
#ifndef ONE
#ifdef TWO
    // 2.98s
    switch(a) {
    case 0: x+= 44; break;
    case 1: x+= 27; break;
    case 2: x+= 12; break;
    case 3: x+= 14; break;
    case 4: x+= 22; break;
    case 5: x+= 01; break;
    case 6:
    case 7: x+= a; break;
    default: ++x; break;
    //default: x++; break; // 3.43s
    }
#else
    // same as TWO above: 2.97s
    switch(a) {
    case 'a': x+= 44; break;
    case 'x': x+= 27; break;
    case 'z': x+= 12; break;
    case 'Q': x+= 14; break;
    case 'F': x+= 22; break;
    case 0: x+= 01; break;
    case 32:
    case 42: x+= a; break;
    default: ++x; break;
    //default: x++; break; // 3.43s
    }
#endif
#else
    // 3.62s
    if (a==0) x+= 44; else
    if (a==1) x+= 27; else
    if (a==2) x+= 12; else
    if (a==3) x+= 14; else
    if (a==4) x+= 22; else
    if (a==5) x+= 01; else
    if (a==6 || a==7) x+= a;
    else ++x;
#endif
  }
  printf("a=%d\n", a);

  return 0;
//  return 7;
}
