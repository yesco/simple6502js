#include <stdio.h>
#include <unistd.h>

#include <conio.h>

int main() {//int argc, char** argv) {
  char foo[16]= {0};
  int a;

  //clrscr(); // in conio but linker can't find (in sim?)
  //kbhit();

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

  return 7;
}
