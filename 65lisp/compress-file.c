//#define COMPRESS_PROGRESS

//#define COMPRESS_DEBUG

// dummys
void gotoxy(int a, int b) {}
int cgetc() { return 0; }
int curmode;
#define HIRESMODE 0
#define STATUS ""

#include "compress.c"



char buff[64*1024];
int len;

int main(int argc, char** argv) {
  char* name= argv[1];
  Compressed* z;

  FILE* f= fopen(name, "r");
  len= fread(buff, 1, 8000, f);
  fclose(f);

  printf("LEN:\t%d\n", len);

//  Compressed* z= compress(buff, len);
  z= compress(buff, len);
  assert(z);

  printf("Z:\t%d\n", z->len);
  
/*

  char dec[8016]={0};
  decompress(z, dec);
  printf("%s: => %4d => %4d == %s\n", name, (int)*(uint16_t*)z, -1, 0==memcmp(hisc, dec, 8000)?"OK":"FAILED");  

  printf("\nDEC:\n");
  for(int j=0; j<8000; ++j) printf("%02x", dec[j]);   putchar('\n');
*/

  return 0;
}
