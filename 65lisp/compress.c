////////////////////////////////////////////////////
// from Play/128dict.c

// 68% 632/932  (1080? of sherlock.txt English)
//  8%  89/1080 Of "Compress" with increasing spaces between
//  1%  18/1080 of a screenful of "a"s!
//  6%  66/1080 of paper+ink blank screen, BUT WRONG!

// TODO: move where?

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <stdint.h> // uint8_t, uint16_t, uint32_t

// This visualizes compressing text/hires screen
// (but also destroyes the source data)
#ifdef COMPRESS_PROGRESS
  #define COMSHOW(a) a
#else
  #define COMSHOW(a) do {} while(0)
#endif // COMPRESS_PROGESS

#ifdef COMPRESS_DEBUG
  #define COMDEBUG(a) a
#else
  #define COMDEBUG(a)
#endif // COMPRESS_DEBUG

int strprefix(char* a, char* b) {
  int i= 0;
  while(*a && *b) {
    if (*a!=*b) return -i;
    ++i;
    ++a,++b;
  }
  if (*a || *b) return -i;
  return i;
}

// Match using a DICTIONARY of length 2 pointed at for a STRING
//
// Returns:
//   0 - failed to match
//   n - matched n chars
int match(char* d, char* s, int len) {
  signed char i= 0, dc, sc;
  int n=0, r;

  for(i=0; i<2; ++i) {
    if (!(sc= s[i])) return 0;
    if (!(dc= d[i])) return 0;
    if (dc >= 0) {
      // simple char
      //printf("\t- match char: '%c' '%c' -> %d\n", dc, sc, dc==sc);
      if (dc!=sc) return 0;
      ++n;
      if (!--len) return 0;
    } else {
      // dictionary entry
      //printf("\t- match dic entry: %d\n", dc);
      r= match(d+i+dc, s+n, len);
      if (!r || r>len) return 0;
      n+= r;
      len-= r;
    }
  }
  //printf("  -----> N=%d\n", n);
  return n;
}

void deprint(char* z) {
  signed char i= *z;
  if (i >= 0) putchar(i);
  else {deprint(z+i);deprint(z+i+1);}
}

char* mmm= NULL;
int mmmlen= 0;

int dematch2(char* z) {
  signed char i= *z; int a, b;
  //printf("DEMATCH2: %d \"%s\"\n", mmmlen, z, mmm);
  if (mmmlen <= 0) return 0;
  if (i >= 0) return *z==*mmm++? 1: 0;
  else {
    if (!(a= dematch2(z+i  ))) return 0;
    if (!(b= dematch2(z+i+1))) return 0;
    return a+b;
  }
}

int dematch(char* z, char* m, int len) {
  mmm= m; mmmlen= len;
  return dematch2(z);
}

// Compress a stream of BYTES of LENgth
//
// Returns: a pointer to the result
//   first two bytes are compresslength
char* compress(char* o, int len) {
  char *res= malloc(len*2+2); // lol, is it enough? (>127...)
  // TODO: realloc as we go?
  char *dict= res+2, *de= dict;
  char *s= o, *d= o, *p, *best;
  signed char c;
  int n= 0, r, max;
  int ol= len;

  // Store first char of cmopressed string,
  // speeds up test
  char firstchar[128]={0};

  //gotoxy(0,25);
  while(len>0) {
    c= *s;

    // TODO: handle....
    if (c&128) c &= 127;
    assert(!(c&128));

    COMDEBUG(printf("  @ %d: %3d $%02x '%c'\n", (int)(s-o), c, c, c));

    // sliding dictionary
    d= de-128;
    if (d<dict) d= dict;

    // search from xo for N matching characters of s
    max= 0;
    best= NULL;

    //printf(">>> '%s'\n", s);

    for(p= de-2; p>=d; --p) {
      *de= (p-de);
      COMDEBUG(printf("      try idx:%3d\t\"", (signed char)*de);deprint(de);printf("\"\n"););

      // incorrect!?!?!?!? not complete
      // ANY FASTER? benchmark...
      //if (de>dict+128 && firstchar[((int)(*de+de))&0x7f] != *s) continue;
      // NO- lol, slower!!!!

      r= dematch(de, s, len); // correct (!) and faster?
      // r= match(p, s, len); // error on some data!

      if (r>max) { max= r; best= p; }
    }
    p= best;

    //firstchar[((int)de)&0x7f]= *s; // lol, raw!

    // -- encode best match
    if (max) {
      // for debug only
      signed char x; COMDEBUG(printf("    => %.*s< @%3d -> %d\n", max, s, -(int)(de-p), (unsigned char)-(int)(de-p+128))); x=
                                                                                                         *de = (signed char)(p-de); ++de;

      if (x>=0) {
        printf(STATUS "ZERROR: %d %02x %02x\n", x, de[x], de[x+1]);
        exit(1);
      }

      COMSHOW( {
          char i;
          s[max-1]=128+'<';
          for(i=0; i<max-1;++i) s[i]=32;
        } );
      
      s+= max;
      len-= max;
    } else {
      COMDEBUG(printf("    => plain char= %d %02x '%c'\n", *s, *s, *s));
      *de= *s; ++de;
      COMSHOW( *s ^= 128 );

      ++s;
      --len;
    }

    ++n;
    COMDEBUG(printf("  - %3d%% %4d/%4d\n\n", (int)((n*10050L)/(s-o)/100), (int)(s-o), (int)ol));

    #ifdef __ATMOS__
      // update progress during hires to debug
      printf(STATUS "=>%3d%% %d from %4d/%4d\n\n" RESTORE, (int)((n*10050L)/(int)(s-o)/100), n, (int)(s-o), (int)ol);
      // if def hires...
      //  gotoxy(0,26);
      //  printf("%3d%% %4d/%4d (n=%d)", (int)((n*10050L)/(s-o)/100), (int)(s-o), (int)ol, n);
    #endif
  }

  COMDEBUG(printf(STATUS "=>%3d%% %4d/%4d\n\n" RESTORE, (int)((n*10050L)/ol/100), n, (int)ol));
  //assert(strlen(dict)==n);

  // store length
  *(uint16_t*)res= n;
  
  return realloc(res, n+2); // shrink
}

// TODO: return pointer to struct

typedef struct compressed {
  uint16_t len;
  uint16_t origlen;
  char data[];
} compressed;

char* decomp(char* z, char* d) {
  signed char i= *z;
  if (i >= 0) *d=i,++d;
  else d=decomp(z+i, d),d=decomp(z+i+1, d);
  return d;
}

char* decompress(char* z, char* r) {
  int len= *(uint16_t*)z;
  char* d;
  //if (!r) r= malloc(len); // TODO: wrong! lOL we don't know original length!
  d= r; z+= 2;
  while(len--) d= decomp(z,d),++z;
  return d;
}

