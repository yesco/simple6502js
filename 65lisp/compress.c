// ORIC Live Compression program
//
// https://youtube.com/watch?v=sIxJ1Xs4NrY&feature=shared
// 
////////////////////////////////////////////////////
// from Play/128dict.c

// 68%  632/932  (1080? of sherlock.txt English)
//       
//  8%   89/1080 Of "Compresz" with increasing spaces between
//       92/ 417 RLE
//  1%   18/1080 of a screenful of "a"s! 
//       13/  28 RLE
//  6%   66/1080 of paper+ink blank screen, BUT WRONG!
//       23/ 162 RLE
//
//  42% 3376/8000 hires rotating squares 25m  = 1500s             DZ=734 hs
//                           w lastchar 16m40 = 1000s 63% faster  DZ=399 hs (449 w progress)
//  40% 3250/5148 RLE  w progress       14m33 =  873s 72% faster! DZ=250 hs not unRLEed...
//       (/ 3376 3250.0) 3.9% better compression, but 15% faster 

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

// Compressed data is returned as a pointer to memory of this type
typedef struct Compressed {
  char J; char K; // 'J' 'K'
  uint16_t len;
  uint16_t origlen;
  uint16_t addr;
  char data[];
} Compressed;

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

// TODO: maybe figure out why this one gives error
// in encoding? or just delete. lol
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

#define RLE_REPEAT 15

// RLE estimator...
char bits[256/8+1]; // 32+1 bytes
char bitmask[]= { 1,2,4,8, 16,32,64,128 };
int bestprefix, bestn;

unsigned int RLE(char* s, unsigned int len) {
  char* d= s;
  int n=0, current=-1, ol= len;
  int r;

  memset(bits, 0, sizeof(bits)); bits[sizeof(bits)-1]= 0xff;

  ++len;
  while(--len) {
    // repeats?
    r= 0;
    current = *s;
    bits[((char)current)>>3] |= bitmask[((char)current) & 0x07];
    while(len-r-1>0 && s[++r]==current);
    // assuming have N bytes as RPT_N codes
    if (current==RLE_REPEAT) {
      // Can't fit it!
      if (d+1>=s) {
        gotoxy(0,0); printf("%%%%ERROR: %04x+1>=%04x: can't fit 15 ", d, s);
        cgetc(); return ol;
      }
      n+= 2;
      *d= RLE_REPEAT; d++;
      *d= 0; d++;
      s++;
    } else if (--r>=4) {  // RLE_REPEAT char n (n<128, not 23..31)
      s+=r; len-=r;
      while(r>0) {
        n+= 3;
        *d= RLE_REPEAT; ++d;
        *d= current; ++d;
        // Only output < 128, no hib as that is dictionary ref
        if (r>127) { *d= 127; ++d; r-= 127; }
        else if (r>=24 && r<= 31) { *d= 23; ++d; r-= 23; } // attributes
        else { *d= r; ++d; r= 0; }
      }
    }
    else { *d= *s; ++n; ++s; ++d; }
  }

  // free char values, sequences >= 4
  if (curmode==HIRESMODE) gotoxy(0,26); else gotoxy(0,0);

  current= -1; bestprefix= -1; bestn= 0;
  for(r= 0; r<128; ++r) { // not test hibitters
    if (bits[((char)r)>>3] & bitmask[((char)r) & 0x07]) {
      if (current>=0 && r-current>=4) {
        // report
        if (r-current>bestn) { bestprefix= current; bestn= r-current; }
        printf("%02x#%d ", current, r-current);
      }
      current= -1;
    } else {
      if (current>=0) ;
      else current= r;
    }
  }
  printf("%02x#%d ", current, r-current);
  cgetc();
  return n;
} 

// TODO: not correct... for "last line"
unsigned int unRLE(char* s, int len, unsigned int expected) {
  char i, c, * p= s+(expected-len), * d= s-1;
  int n= 0;
  
  // not compressed?
  assert(len>=0);
  if (len==expected) return len;

  // More easy to do from front, so move it down!
  memmove(p, s, len);
  memset(s, 0, expected-len);

  ++len; --p;
  while(--len > 0) { // length of RLE_REPEAT char n (n<128)
    if (d==p) break;
    if ((*++d= *++p)==RLE_REPEAT) {
      len-= 2;
      c= *++p; --d;
      i= *++p; n+= i;
      do { *++d= c; } while (--i);
    } else ++n;
  }
  if (d!=p) { gotoxy(0,0); printf("%%ERROR unRLE: p!=d %04x != %04x n=%d ", p, d, n); cgetc(); }
  return n;
}

// Compress a stream of BYTES of LENgth
//
// Returns: a pointer to the result
//     first two bytes are compresslength
//   NULL if fail to allocate
//   NULL if not compress to less!

// Store last char of compressed string,
// speeds up test, NOT!
char lastchar[128];
int  length[128];

Compressed* compress(char* o, int len) {
  char *s= o;
  // TODO: realloc as we go?
  int size= len;
  Compressed* res= (Compressed*)malloc(size+sizeof(Compressed));
  signed char *dict= (signed char*)(res->data), *de= dict, *d, *p, *best, c;
  int n= 0, r, max;
  int ol= len;
  int ll,li;

#ifdef COMPRESS_PROGRESS
  char isHires= (curmode==HIRESMODE);
  char showSkipped= isHires? 64: 32;
  char showCompressed= isHires? 64+1: 128+'<';
#endif

  memset(lastchar, 0, sizeof(lastchar));
  memset(length, 0, sizeof(length));

  if (!res) return NULL;

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

    // Too big compreseed result: FAIL!
    // TODO: set lower threshold? 90% at last?
    if (n>=size) { free(res); return NULL; }

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
      if (de>dict+128) {
        li= ((int)(*de+de))&0x7f;
        ll= length[li];
        if (ll>len) continue;
        if (lastchar[li] != s[ll]) continue;
      }

      //gotoxy(0,26); printf("Try: %02x @ %d \n", *s, *de);
      //getchar();

      r= dematch(de, s, len); // correct (!) and faster?
      // r= match(p, s, len); // error on some data!

      if (r>max) { max= r; best= p; }
    }
    p= best;

    li= ((int)(de))&0x7f;
    length[li]= max;
    lastchar[li]= s[max];

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

  // store meta-data
  res->J= 'J'; res->K= 'K';
  res->len= n;
  res->origlen= ol;
  res->addr= (unsigned int)o;
  
  return (Compressed*)realloc(res, n+sizeof(Compressed)); // shrink it
}

// hires squares 42%, Z= 27067? D= 734 hs

char* old_decomp(char* z, char* d) {
  signed char i= *z;

  if (i >= 0) *d=i,++d;
  else d=old_decomp(z+i, d),d=old_decomp(z+i+1, d);
  return d;
}
 
// Compresz: Z=3400 D=112 hs (Z=2893 w/o COMPRESS_PROGRESS 18% faster)
// Sherlock: Z=20030 D=95 hs
char* old_decompress(Compressed* zz, char* r) {
  char *z= zz->data, *d= r;
  int len= zz->len;

  while(len--) d= old_decomp(z,d),++z;
  return r;
}

//#define decompress(a,b) old_decompress(a,b)
#define decompress(a,b) static_unroll_decompress(a,b)
// Compresz: Z=3410 D=67 hs (decompress double speed!)
//             3078   67
//                    58 static i in sdecomp, z+=i
//           Z=3487 w lastchar... Hmmm, worse?

// Sherlock: Z=20028 D=58 hs
//                     59
//                     54 static i - 7.5%
//           Z=16693 w NO PROGRESS, before lastchar
//           Z=14754 w lastchar! PROGRESS (29% overhead)
//           Z=11411 w lastchar, no progress -46%

// --HIRES--
//                   Z=27067           D=734 hs orig
//                   Z=1969 (?)        D=543 hs (no unroll top)
//
// Rotating squares: => 42% 3376 Z=15m D=449 hs
//                                     D=399 hs 32% w static i,+=i
//
//                               Z=16m40s=1000,00 hs=1ks lastchar+upate screen
//                                  - 63% faster than old original!
//
//                          4740 B RLE encoded (estimate)

// static tmp
// TODO: create a set typed of these..., in zero page!
char* dest;

void sdecomp(char* z) {
  static signed char i;
  i= *z;
  if (i >= 0) *++dest=i;
  else sdecomp(z+=i),sdecomp(z+1);
}

// Decompress to give address
//
// if address==NULL: use memory location remembered in zz.
//
// Returns: pointer to decompressed memory location
char* static_unroll_decompress(Compressed* zz, char* d) {
  char* z= zz->data;
  int len= zz->len;
  if (!d) d= (char*)(zz->addr);
  dest= d-1;
  z+= 2; --z;
  while(len--)
    if ((signed char)(*++z)>=0) *++dest= *z;
    else sdecomp(z);
  return d;
}

// Decompressed to a newly allocated memory
//
// Returns: pointer to decompressed memory location
//   or NULL if fail to allocate
char* newdecompress(Compressed* zz) {
  char* d= malloc(zz->origlen);
  return d? decompress(zz, d): NULL;
}

// 35% faster than old original
// 21% slower compared to unrolled
char* static_not_unrulled_decompress(Compressed* zz, char* d) {
  char* z= zz->data;
  int len= zz->len;

  dest= d-1;
  //if (!r) r= malloc(len); // TODO: wrong! lOL we don't know original length!
  z+= 2;
  while(len--) sdecomp(z),++z;
  return d;
}


// make your own stack, faster? not?
// not working... lol

char* stack[128];

char* ydecompress(Compressed* zz, char* d) {
  char* z= zz->data;
  int len= zz->len;
  char** se= stack+128, ** sp= se;
  signed char c;
  char *topz, *p;
  //if (!r) r= malloc(len); // TODO: wrong! lOL we don't know original length!
  p= d; z+= 2;
  while(sp!=se || len) {
    if (len<=0) break;
    printf(" [%d:%d] ", len, (int)(se-sp));

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

