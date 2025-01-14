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
  #define COMSHOW(a)
#endif // COMPRESS_PROGESS

#ifdef COMPRESS_DEBUG
  #define COMDEBUG(a) a
#else
  #define COMDEBUG(a)
#endif // COMPRESS_DEBUG

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

int deep, maxdeep;

int dematch2(signed char* z) {
  signed char i= *z; int a, b;
  //printf("DEMATCH2: %d \"%s\"\n", mmmlen, z, mmm);
  if (mmmlen <= 0) return 0;
  if (i >= 0) return *z==*mmm++? 1: 0;
  else {
    if (++deep > maxdeep) maxdeep= deep;
    if (!(a= dematch2(z+i  ))) return 0;
    if (!(b= dematch2(z+i+1))) return 0;
    --deep;
    return a+b;
  }
}

int dematch(signed char* z, char* m, int len) {
  deep= 0;
  mmm= m; mmmlen= len;
  return dematch2(z);
}

// Compress a stream of BYTES of LENgth
//
// Returns: a pointer to the result
//   first two bytes are compresslength
char* compress(char* o, int len) {
  char *s= o;
  // TODO: realloc as we go?
  signed char *res= malloc(len+2); // lol, is it enough? (>127...)
  signed char *dict= res+2, *de= dict, *d, *p, *best, c;
  int n= 0, r, max;
  int ol= len;

#ifdef COMPRESS_PROGRESS
  char isHires= (curmode==HIRESMODE);
  char showSkipped= isHires? 64: 32;
  char showCompressed= isHires? 64+1: 128+'<';
#endif

  // Store first char of compressed string,
  // speeds up test, NOT!
  char firstchar[128]={0};

  assert(res);

  maxdeep= 0;

  //gotoxy(0,25);
  while(len>0) {
    c= *s;

    COMDEBUG(printf("  - %3d%% %4d/%4d\n\n", (int)((n*10050L)/(s-o)/100), (int)(s-o), (int)ol));

    #ifdef COMPRESS_PROGRESS

      #ifdef HIRESSCREEN
        if (isHires) 
      #else
        if (0) 
      #endif
        {
          gotoxy(0,25); printf("%3d%% => %d,deep=%2d %02x @ %d/%d ", (int)((n*10050L)/(s-o)/100), n, maxdeep, *s, (int)(s-o), (int)ol);
        } else {
          // update progress during hires to debug
          printf(STATUS "=>%3d%% %d @ %4d/%4d\n\n" RESTORE, (int)((n*10050L)/(int)(s-o)/100), n, (int)(s-o), (int)ol);
        }
    #endif

    // TODO: handle....
    if (c&128) c &= 127;
    assert(!(c&128));

    COMDEBUG(printf("  @ %d: %3d $%02x '%c'\n", (int)(s-o), c, c, c));

    // sliding dictionary
    d= de-128;
    //d= de-128+5; //TODO hmmm

    if (d<dict) d= dict;

    // search from xo for N matching characters of s
    max= 0;
    best= NULL;

    //printf(">>> '%s'\n", s);

    for(p= de-2; p>=d; --p) {
      *de= (signed char)(p-de);
      COMDEBUG(printf("      try idx:%3d\t\"", (signed char)*de);deprint(de);printf("\"\n"););

      // incorrect!?!?!?!? not complete
      // ANY FASTER? benchmark...
      //if (de>dict+128 && firstchar[((int)(*de+de))&0x7f] != *s) continue;
      // NO- lol, slower!!!!

      //gotoxy(0,26); printf("Try: %02x @ %d \n", *s, *de);
      //getchar();

      r= dematch(de, s, len); // correct (!) and faster?
      // r= match(p, s, len); // error on some data!

      if (r>max) { max= r; best= p; }
    }
    p= best;

    //firstchar[((int)de)&0x7f]= *s; // lol, raw!

    //*s= '-'; // to show progress, but this messes up compressing?
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
          s[max-1]= showCompressed;
          for(i=0; i<max-1;++i) s[i]= showSkipped;
        } );
      
      s+= max;
      len-= max;
    } else {
      COMDEBUG(printf("    => plain char= %d %02x '%c'\n", *s, *s, *s));
      *de= *s; ++de;
      // Text inverts
      // Hires keeps set bit, or if none then inverts, this keeps image visible
      COMSHOW( if (isHires) { if (*s==64) *s= 64+1; } else *s ^= 128; );

      ++s;
      --len;
    }
    //getchar();

    ++n;
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

// hires squares 42%, Z= 27067 D= 734 hs
char* old_decomp(char* z, char* d) {
  signed char i= *z;
  if (i >= 0) *d=i,++d;
  else d=old_decomp(z+i, d),d=old_decomp(z+i+1, d);
  return d;
}
 
// Compresz: Z=3400 D=112 hs (Z=2893 w/o COMPRESS_PROGRESS 18% faster)
// Sherlock: Z=20030 D=95 hs
char* old_decompress(char* z, char* r) {
  int len= *(uint16_t*)z;
  char* d;
  d= r; z+= 2;
  while(len--) d= old_decomp(z,d),++z;
  return r;
}

//#define decompress(a,b) old_decompress(a,b)
#define decompress(a,b) static_unroll_decompress(a,b)
// static tmp
// TODO: create a set typed of these..., in zero page!
char* dest;

// Compresz: Z=3410 D=67 hs (decompress double speed!)
//             3078   67
//                    58 static i in sdecomp, z+=i
//
// Sherlock: Z=20028 D=58 hs
//                     59
//                     54 static i - 7.5%
// --HIRES--
//                   Z=27067           D=734 hs orig
//                   Z=1969 (?)        D=543 hs (no unroll top)
// Rotating squares: => 42% 3376 Z=15m D=449 hs
//                                     D=399 hs 32% w static i,+=i
//
// 63% faster than old original

void sdecomp(char* z) {
  static signed char i;
  i= *z;
  if (i >= 0) *++dest=i;
  else sdecomp(z+=i),sdecomp(z+1);
}
char* static_unroll_decompress(char* z, char* d) {
  int len= *(uint16_t*)z;
  dest= d-1;
  //if (!r) r= malloc(len); // TODO: wrong! lOL we don't know original length!
  z+= 2; --z;
  while(len--)
    if ((signed char)(*++z)>=0) *++dest= *z;
    else sdecomp(z);
  return d;
}

// 35% faster than old original
// 21% slower compared to unrolled
char* static_not_unrulled_decompress(char* z, char* d) {
  int len= *(uint16_t*)z;
  dest= d-1;
  //if (!r) r= malloc(len); // TODO: wrong! lOL we don't know original length!
  z+= 2;
  while(len--) sdecomp(z),++z;
}


// make your own stack, faster? not?
// not working... lol

char* stack[128];

char* ydecompress(char* z, char* d) {
  int len= *(uint16_t*)z;
  char** se= stack+128, ** sp= se;
  signed char c;
  char *topz, *p;
  //if (!r) r= malloc(len); // TODO: wrong! lOL we don't know original length!
  p= d; z+= 2;
  while(sp!=se || len) {
    if (len<=0) break;
    printf(" [%d:%d] ", len, se-sp);

    assert(sp<=se);
    // next to process
    if (sp==se) {
      c= *z,++z,--len;
      printf(" {%c;%d} ", c, c); }
    else {
      z= *sp;
      c= *z; ++sp;
      if (sp==se) z= topz;
    }
    // simple char
    if (c>=0) *p=c,++p,putchar(c);
    // or compressed token - push destination
    else {
      printf(" [T:%d] ", c);
      if (sp==se) topz= z;
      *--sp= z+c; // second of bi-token
      *--sp= z+c-1;   // first of bi-token
    }
  }
  return d;
}

