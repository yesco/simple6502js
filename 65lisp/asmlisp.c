// Dummys for ./r script LOL
//int T,nil,doapply1,print;

// 2434 bytes with printf, 
// #include <stdio.h>

extern void initlisp();

// from conio-raw.c
#define TEXTSCREEN ((char*)0xBB80) // $BB80-BF3F
#define SCREENROWS 28
#define SCREENCOLS 40
#define SCREENSIZE (SCREENROWS*SCREENCOLS)
#define SCREENLAST (TEXTSCREEN+SCREENSIZE-1)

// empty main: 284 Bytes
void main() {
  //printf("Hello World!\n");
  
  *TEXTSCREEN= 'A';
  
  initlisp();

}
