////////////////////////////////////////////////////
// from Play/128dict.c

// 68% 632/932  (1080? of sherlock.txt English)
//  8%  89/1080 Of "Compress" with increasing spaces between
//  1%  18/1080 of a screenful of "a"s!
//  6%  66/1080 of paper+ink blank screen, BUT WRONG!

// TODO: move where?

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
char match(char* d, char* s) {
  signed char i= 0, dc, sc, n= 0, r;

  for(i=0; i<2; ++i) {
    sc= s[i]; if (!sc) return 0;
    dc= d[i]; if (!dc) return 0;
    if (dc >= 0) {
      // simple char
      //printf("\t- match char: '%c' '%c' -> %d\n", dc, sc, dc==sc);
      if (dc!=sc) return 0;
      ++n;
    } else {
      // dictionary entry
      //printf("\t- match dic entry: %d\n", dc);
      r= match(d+i+dc, s+n);
      if (!r) return 0;
      n+= r;
    }
  }
  //printf("  -----> N=%d\n", n);
  return n;
}

// TODO: add bytes as parameter
char* compress(char* o) {
  char *dict= calloc(strlen(o)+1, 1), *de= dict;
  char *s= o, *d= o, *p, r, max, *best;
  int n= 0;
  int ol= strlen(o);

  gotoxy(0,25);
  while(*s) {
    assert(*s<128);
//gotoxy(0,25); printf("%d: %3d $%02x '%c'  ", s-o, *s, *s, *s);
//gotoxy(0,26); printf("         ");
    // sliding dictionary
    d= de-128;
    if (d<dict) d= dict;
    // search from xo for N matching characters of s
    max= 0;
    best= NULL;
    //printf(">>> '%s'\n", s);
    for(p= de-2; p>=d; --p) {
//      gotoxy(0,26); printf("try idx: %3d                 ", de-p);
      //printf(STATUS32 "%04x%04x", p, d);
      //printf("  %ld ? '%.5s'\n", p-de, p);
      r= match(p, s);
      //if (r) break;
      if (r) {
        //printf("    n=%d [%.*s]\n", r, r, s);
        if (r>max) { max= r; best= p;
//break; // give up at first match - fast
//printf(STATUS "Zng: %4d/%4d => %4d  max=%3d (%02x,%02x) " RESTORE,
//       s-o, ol, p-dict, max, s[0], s[1]);
        }
      }
    }
    p= best;

    // match
    if (max) {
      ////printf("%.*s< @%3d -> %d\n", max, s, -(int)(de-p), (unsigned char)-(int)(de-p+128));
      //printf("[" INVERSE "%.*s" ENDINVERSE "]", max, s);
      // TODO: is full range used?
signed char x;x=
      *de = -(char)(de-p); ++de;
 //gotoxy(0,26); printf("max=%2d idx=%d      ", max, x);

if (x>=0) {
  gotoxy(0,25);
  printf(STATUS "ZERROR: %d %02x %02x", x, de[x], de[x+1]);
  exit(1);
}

s[max-1]=128+'<';
      { char i;
        for(i=0; i<max-1;++i) s[i]=32;
      }
      s+= max;
    } else {
//    gotoxy(0,26); printf("plain char= %d %02x '%c' max=%2d idx=%d      ", *s, *s, *s);
     ////printf("%c\n", *s);
      //putchar(*s);
      *de= *s; ++de;
*s ^= 128;
      ++s;
    }
    ++n;
    //printf("\n%3d%% %4d/%4d\n", (int)((n*10050L)/(s-o)/100), s-o);
  }
  printf(STATUS "%3d%% %4d/%4d" RESTORE, (int)((n*10050L)/ol/100), n, (int)ol);
  //assert(strlen(dict)==n);
  
  return realloc(dict, strlen(dict)+1); // shrink
}

char* decomp(char* z, char* d) {
  signed char i= *z;
  if (i >= 0) *d=i,++d;
  else d=decomp(z+i, d),d=decomp(z+i+1, d);
  return d;
}

char* decompress(char* z, char* d) {
  while(*z) d= decomp(z,d),++z;
  return d;
}

