//#define COMPRESS_PROGRESS

//#define COMPRESS_DEBUG

// dummys
void gotoxy(int a, int b) {}
int cgetc() { return 0; }
int curmode;
#define HIRESMODE 0
#define STATUS ""

#include "compress.c"

char buff[64*1024], uzbuff[64*1024];
int len;

int main(int argc, char** argv) {
  char* name= argv[1];
  Compressed* z;
  char dez= (0==strstr(argv[0],"decompress"))
    || (0==strstr(argv[0],"ujz"));

  FILE* f= fopen(name, "r");
  len= fread(buff, 1, sizeof(buff), f);
  fclose(f);

  fprintf(stderr, "LEN:\t%d\n", len);



  // try find way to reduce hi-bits!
  // 399 bytes compressed basmlisp.bin (438 bytes)
  //
  // Nothing obvious...
  // and if there were we could only save 7x bytes...
  if (0)
  for(int i=0; i<len; ++i) {
    char b= buff[i];

    switch(4) {
#define N 16
    case 4: if ((b & (N-1))< (N/2)) b ^= 128; break;

    case 3: // parity
      b ^= (b ^ (b>>1) ^ (b>>2) ^ (b>>3)
            ^ (b>>4) ^ (b>>5) ^ (b>>6))
        ? 0 : 128;
      break;
      // => 398 (reverse: 423)
    case 2: if (!(b& 64 )) b^= 1<<7; break;
      // 1 => 410 429
      // 2 => 423 405
      // 4 => 414 417
      // 8 => 402 431
      // 16=> 415 422
      // 32=> 409 422
      // 64=> 404 427
      //128=> 364 --- LOL
    case 1: if (b& 128 ) b^= 1<<7; break;
      // 1 => 410
      // 2 => 423
      // 4 => 414
      // 8 => 402
      // 16=> 415
      // 32=> 409
      // 64=> 404
      //128=> 364 --- LOL
    default: break;
    }

    buff[i]= b;
  }

  if (dez) {
    // decompress given file
    z= buff;
  } else {
    //  Compressed* z= compress(buff, len);
    z= compress(buff, len);
    assert(z);

    fprintf(stderr, "Z:\t%d\n", z->len);
  
    for(int i=0; i < z->len; ++i) {
      putchar(z->data[i]);
    }
  }

  // print decompressed on stderr
  // compare decompression correctness
  decompress(z, uzbuff);
  
  for(int i=0; i < z->origlen; ++i) {
    if (dez)
      putchar(uzbuff[i]);
    else
      fputc(uzbuff[i], stderr);
  }

  int res= memcmp(buff, uzbuff, len);
  if(dez)
    fprintf(stderr, "\n\n----Decomp => %d %s\n",
            res, res?"FAILED":"OK");
  

/*

  char dec[8016]={0};
  decompress(z, dec);
  printf("%s: => %4d => %4d == %s\n", name, (int)*(uint16_t*)z, -1, 0==memcmp(hisc, dec, 8000)?"OK":"FAILED");  

  printf("\nDEC:\n");
  for(int j=0; j<8000; ++j) printf("%02x", dec[j]);   putchar('\n');
*/

  return 0;
}
