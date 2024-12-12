#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

// characters ordered in terms of frequency - "Oxford stuff"
// " eariotnslcudpmhgbfywkvxzjq"

// least frequent letters
//   B  1.49
//   V  1.11
//   K  0.69
//   ---- the rest so improbable!
//   X  0.17
//   Q  0.11
//   J  0.10
//   Z  0.07

// The 14 punctuation marks in English are period (called “full stop” in the UK), question mark, exclamation point, comma, colon, semicolon, dash, hyphen, brackets, braces, parentheses, apostrophe, quotation mark, and ellipsis.

// https://www3.nd.edu/~busiforc/handouts/cryptography/Letter%20Frequencies.html#quadrigrams
/*
1. that (8709261, 0.761242%)
2. ther (6916008, 0.604501%)
3. with (6565513, 0.573866%)
4. tion (6314428, 0.551919%)
5. here (4285164, 0.374549%)
6. ould (4232202, 0.369920%)
7. ight (3540253, 0.309440%)
8. have (3324067, 0.290544%)
9. hich (3252540, 0.284292%)
10. whic (3247213, 0.283826%)
11. this (3161481, 0.276333%)
12. thin (3093756, 0.270413%) // probably just "thing" ?
13. they (3002324, 0.262421%)
14. atio (3001919, 0.262386%)
15. ever (2982572, 0.260695%)
16. from (2958372, 0.258580%)
17. ough (2899649, 0.253447%)
18. were (2643859, 0.231089%)
19. hing (2630750, 0.229944%) // probably just "thing" ?
20. ment (2555284, 0.223347%)
*/

/* these don't yield much more compression
Trigrams
Of 1,699,542,842 trigrams scanned:
1. the (59623899, 3.508232%)
2. and (27088636, 1.593878%)
3. ing (19494469, 1.147042%)
4. her (13977786, 0.822444%)
5. hat (11059185, 0.650715%)
6. his (10141992, 0.596748%)
7. tha (10088372, 0.593593%)
8. ere (9527535, 0.560594%)
9. for (9438784, 0.555372%)
10. ent (9020688, 0.530771%)
11. ion (8607405, 0.506454%)
12. ter (7836576, 0.461099%)
13. was (7826182, 0.460487%)
14. you (7430619, 0.437213%)
15. ith (7329285, 0.431250%)
16. ver (7320472, 0.430732%)
17. all (7184955, 0.422758%)
18. wit (6752112, 0.397290%)
19. thi (6709729, 0.394796%)
20. tio (6425262, 0.378058%)
*/

// Since strings are still zero terminated ('  ' == '\0'),
//   two spaces (or any nibble 0) can NOT be encoded as '  ',
//   but as ' U ', for more, see REPEPAT

#define CORE       " eariotnslcUSNPD"      // U=Upcase next letter (auto after .), "SN PD" - shifters
#define COREs      " eariotnslc     "      // U=Upcase next letter (auto after .), "SN PD" - shifters
#define  UCORE     " EARIOTNSLC     "      //   Upcase letters, 'Uu' => toggle sticky Upcase "sn pd" - shifters
#define SECOND     "udpmhgbfywkvxzjq"      // the rest of alphabet
#define  USECOND   "UDPMHGBFYWKVXZJQ"      //   upcase 'US?'

// TODO:
//#define SECOND     "udpmhgbfywkvZQR8"      // the rest of alphabet Zees Quads Repeat utf-8 'S8'
//#define  USECOND   "UDPMHGBFYWKVzqr8"      //   upcase 'US?'
//#define THIRD      "zxjq????????????"      // tertary  letters/map +12 encodings, DELTA? 'SZ?'
//#define  UTHIRD    "ZXJQ???????????1"      //   upcase 


#define NUMS       " 0123456789.,+-E"      // numbers, sticky till '\0' (not give space), prefix U - nonstick
#define PUNCT      ".,:;-'\"/<>(){}[]"     // ., assumes spaces before, unless 'U', 2 nilbbles 'P.' PROGRAMMING/HTML
#define  UPUNCT    "?!#%_`&=@^|~\\\n\t\b"; // ?! assumes space after, 'UP?', \h=backspace!

// TODO: END string encoding === 'N ' !!

char chars[]      = COREs UCORE SECOND USECOND;

char  core[16]    = CORE;
char   Ucore[16]  = UCORE;

// These are secondary maps
char  Second[16]  = SECOND;
char   USecond[16]= USECOND;
char  Nums[16]    = NUMS;
char  Punct[16]   = PUNCT;
char   UPunct[16] = UPUNCT;

// Dictionary of most common words, 2 nibbles 'D?'
// Space is assumed before and after, double implicitly removed
char* Dict[16]= { 
  // most common words (>= 4 nibbles -> 2 nibbles)
// - https://en.m.wikipedia.org/wiki/Most_common_words_in_English 'D?'
  "the", "be", /*"to"*,*/ "of", "and", /*"a",*/ /*"in",*/ "that",                        // 5  8
  "have", /*"I",*/ /*"it",*/ "for", "not", /*"on",*/ /*"he",*/ "with",                   // 4  9
  /*"as",*/ "you", /*"do"*,*/ /*"at",*/ "this", "but", "his", "by", "from",              // 6 15
  "they", //"we", "say", "her", "she", "or", "an", "will", "my", "one", "all", "would",  // 1 16
};
#define DICT     "\x10" "the"   "\x11" "be"   "\x12" "of"   "\x13" "and"  \
  "\x14" "that"  "\x15" "have"  "\x16" "for"  "\x17" "not"  "\x18" "with" \
  "\x19" "you"   "\x1a" "this"  "\x1b" "but"  "\x1c" "his"  "\x1d" "by"   \
  "\x1e" "from"  "\x1f" "they"

// Unicode is prefied by 2 nibbles 'DU' (also can use for single 8-bit char)

// This is a tertiary map, thus: 3 nibbles, 1.5 byte, 'DR4'
char Repeat[16]= "456789??????????"; // Repat 4-9 times, 10 
  // --- URL
  // "https://", ".com", "www.", ".html", "index",   // 5
  // --- HTML
  // "<h3", "<h2", "<p", "<li", "<a href=\"'         // 5

// This is tertiary map, thus: 3 nibble, 1.5 byte, 'DS?'
char* Seqs[16]= {
  // quadrams
  "tion", "ould", "ight", "hich", "thing",           // 5  
  "atio", "ever", "ough", "ment"                     // 4  9
  // trigrams - not worth it (maybe 25%?)
  // others
  "...",                                             // 1 10
  "&nbsp;", "&lt;", "&gt;", "&amp;", "&quot;",       // 5 15
  "fuck",                                            // 1 16 - for English ... or "ing "
};

char* maps[]= { core, Ucore, Second, USecond, Nums, Nums, Punct, UPunct, (char*)Dict, (char*)Dict };


typedef unsigned char uchar;
  
char* compress(char* s) {
  char *r= calloc(strlen(s)*2, 1), *p=r;
  char c,*m;
  uchar j,k,nibble;
  uchar U,map;
  uchar C=0, o=0,i=2;
  uchar space=0,lastnibble=0;
  char* d;

#define OUTNIBBLE(nibble) do { \
    o|= (nibble); \
    printf("  [c='%c' $%02X U=%d map=%d] => nibble %d\to=%2x   '%c'", c, c, U, map, nibble, o, CORE[nibble]); \
    if (--i) o<<= 4; \
    else { printf("   => %02x ", o); *++p=o,o=0,i=2; } \
    lastnibble= nibble; \
    putchar('\n'); \
    } while (0);

  --p;
  while((c= *s)) {

    // try dictionary
    if ((space= *s==' ')) ++s;
    for(k=0; k<16; ++k) {
      d= Dict[k];
      // TODO: store length in array
      if (0==strncasecmp(d, s, strlen(d))) {
        OUTNIBBLE(15); OUTNIBBLE(k);
        s+= strlen(d);
        continue;
      }
    }
    
    if (space) --s;

    // find map of char
    m= strchr(chars, c);
    if (!m) {
      printf("-- %%ERROR: can't find char '%c' (%d, %02x)\n", c, c, c);
      exit(1);
    }

    // Encode
    j= m-chars;
    nibble= j&15;
    map= j>>4;
    U= map&1;
    map/=2;

    if (U) { putchar(' '); OUTNIBBLE(12); }
    if (map) { putchar(' '); OUTNIBBLE(11+map); }
    // can't have two 0 in a row (sometimes)
    if (i && nibble==0 && lastnibble==0) OUTNIBBLE(12); 
    OUTNIBBLE(nibble);
    ++s;
  }
  
  OUTNIBBLE(13); OUTNIBBLE(0); // 'N ' -- END! (non-ambigous)
  if (i) OUTNIBBLE(0);
  return realloc(r, strlen(r)+1);
}

char* decompress(char* cs) {
  char *r= calloc(strlen(cs)*4, 1), *p= r;
  uchar* s= (uchar*)cs;
  // states
  char i= 2, m= 0, C= 0, U= 0; // CapsLock
  uchar nibble, c;
  char* map;

  --p;
  while (*s && i) {
    nibble= --i? *s>>4: *s&15;
    printf("[nibble=%2d] ", nibble);
    if (!i) ++s,i=2;

    // Change map?
    if (m<2 && nibble>=11) {
      // 'U' upcase & caps-lock
      if (nibble==11) {
        if (U) C=1-C,U=0; // toggle U if 'UU'
        else U= 1-C; // opposite Caps
        m= 0;
      } else m= (nibble-11)*2; // select map SNPD

      // get next nibble
      continue; 
    }

    // get char
    map= maps[m+U];
    c= map[nibble];

    printf("[i=%d C=%d U=%d m=%d nibble=%2d] => '%c'\n", i, C, U, m+U, nibble, c);
    *++p= c;

    U=0;m=0;
  }

  // adjust to actual size
  return realloc(r, strlen(r)+1);
}

//char* d= decompress("\x11\xc1\x02\xc2\x0c\x20");

void oneline(char* s) {
  char *c, *d, *p;
  int sl,cl,dl;

  printf("TEXT[%3d]: >%s<\n\n", sl= (int)strlen(s), s);

  c= compress(s);
  printf("COMP[%3d]: >", cl= (int)strlen(c));
  p= c;
  while(*p) printf("%02x ", *p++);
  printf("<\n\n");

  d= decompress(c);
  printf("DCMP[%3d]: >%s<\n\n", dl= (int)strlen(d), d);

  printf("\n>%s:%d:%d:%d%%\n", s, sl, cl, (int)((cl*10000L+4000)/sl/100)); // 4000? why not 5000?
  printf(">%s:\n", d);

  if (dl!=sl) { printf("--CONVERSION FAILED!\n"); }
  //assert(dl==sl);
  
  free(c); free(d); free(p);
}

int main(void) {
  //char *s= "eE aAAaa foo";
  //char *s= "Hello My name is Jonas S Karlsson";
  //char *s= "hello my name is jonas s karlsson";
  char* c= NULL; size_t l= 0;

  printf("CHARS= >%s<\n", chars);

  while (getline(&c, &l, stdin)>=0) {
    oneline(c);
  }


  return 0;
}
