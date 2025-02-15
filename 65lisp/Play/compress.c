#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>

// HUFFMAN encoding of 4*sweden.html + sherlock-all.txt ==> 4561022/7325099 == 62.27% only
//
//   "eatinosrhld\"cumwpfg./-y><=bk,v20_%1IS3Ax8T:9F;CH4B5E'M&W76+DN\nPjR?LOG()z#qY...J.\\][.!\tVUZK....}{^...............Q............X..."

// Huffman on sweden.html - 67%
// huffman on sherlock-all.txt - 57% lol

// engrams encoding savings (128-255 char is token pointing to n-gram)
//   i.e. we encode the 128 most frequent n-grams:
//   from all.txt 2231980/7325099
//
// -- 2-gram     2231980  -> 30.47% savings "only"0
// -- 3-gram     1323610
// -- 4-gram     1071429
// -- 5-gram      928160
// -- 6-gram      796490
// -- 7-gram      628248
// -- 8-gram      546119
// -- 9-gram      496024
// -- 10-gram     439749


// characters ordered in terms of frequency - "Oxford stuff"
// " eariotnslcudpmhgbfywkvxzjq"

// char freq on wikipedia:Sweden HTML
//               50% of 'e'      50% of 'o'
// "eati nsr\"l  oc/pd><=-hmfwg  u2.k0b_%..."


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

/* Sherlock Holmes collected works 3M2B or so.

  nibbles    freq       word
  =======  ======       ==============
  252847    36121	the
  139329    17416	and
  100540    11171	that
   94170    15695	to
   83724    16745	of
   68712     9816	was
   66567    16642	i
   64296    10716	in
   63618    10603	it
   62663    15666	a
   56237     9373	you
   54782     7826	his
   50964    10193	he
   44176     5522	have
   42266     6038	had
   41936     5242	with

   39798     6633	is
   38331     4259	which
   35510     3228	there
   35114     2926	holmes
   32879     4697	for
   31645     3516	this
   30952     3095	said
   29537     3692	not
   28452     4742	as
   27696     4616	at
   24461     4077	but
   23304     2913	from
   21941     2194	would
   21583     2398	been
*/


// Since strings are still zero terminated ('  ' == '\0'),
//   two spaces (or any nibble 0) can NOT be encoded as '  ',
//   but as ' U ', for more, see REPEPAT

// tr -cd "A-Za-z" # filter to only get these letters!

#ifdef FOO
  #define ONE        " eariotnslcudpS8"      // ' a...p' Second utf-8
  #define ONEs       " eariotnslcudp  "      // ' a...p' Second utf-8
  #define  TWO       "mhgbfywkvxzjqNPD"
  #define  TWOs      "mhgbfywkvxzjqN  "
#else
  // RUN: cat sherlock.txt | (clang Play/compress.c && ./a.out) | grep -a '^>' | less
  //        55% 1968427/3544339

  // -- most common character by frequency:
  // " eta onhs irdl umwc fyg, p.b\" vIkH '-TWM ?SAx BYq! CNjL D0EP ..."
  //   XXX XX X XXXX    X    

  // 'd' here saves 2% !
  // 'u' here saves 1% !
  #define ONE        " eariotnslcduDS8"      //  you want 'd' to be here! D=" the "
  #define  ONEs      " eariotnslcdu   "      //

  //  ., saves 1%
  //  "  saves 1%
  //  q  isn't even 1%...  ... TODO: we need Repeat Delta
//  #define TWO        "pmhgbfywkvq.,\"N"
//  #define  TWOs      "pmhgbfywkvq.,\"N"
// for sherlock, this is -1%, for html saves 2%
  #define TWO        "pmhgfyw</>.,\"N"
  #define  TWOs      "pmhgfyw</>.,\"N"

  // TODO: P is secondary, using only 8 utf-8 quoting costs 1% more...
  //   cost/savings much bigger for program/html?
  // - cost savings for sherlock is only 1%
  #define THREEs     "_=:;-'\"/<>(){}[]"    
  #define FOURs      "?!#%_`&=@^|~\\\n\t\b"
#endif

//char chars12[]     = ONEs TWOs THREEs;
char chars12[]     = ONEs TWOs;

char* onedict[]=   {
  // --- most common english words, ordered by savings in sherlock!
  // 63% - 55% => saves 8%, saves 1% on sweden.html
  " the ", " and ", " that ", " to ", " of ", " was ", " I ", " in ",   // saves 5%
//  " it ", " you ", " his ", " he ", " have ", " had ", " with ", " this ", // saves 3%
  " it ", " a ", " you ", " his ", " he ", " have ", " had ", " with ", // saves 3%
  // " a " was replaced by " this ", any better ? " this " not as probable as " a "

  // saves 2% only
  // " is ", " which ", " there ", " for ", " said ", " not ", " as ", " at ",
  // " but ", " from ", " would ", " been ", " my ", " were ", " could ", " upon ",

  // - saves 1% only
  // " we ", " one ", " him ", " all ", " me ", " what ", " your " , " be ",
  //" are ", " no ", " on ", " will ", " some ", " very ", " then ", " her ",

  // --- saves 1% only
  //  " when ", " should ", " so ", " man ", " into ", " little ", " she ", " well ",
  //  " an ", " out ", " before ", " they ", " out ", " has ", " more ", " down ",

  // --- URL & HTML - 16 saves 6% for sweden.html
  // TODO: switch map... hmmm, cost? (need to steal secondary token, increase 1%)
  // 'SS#' - 'SS'=toggle '#' is entry number
/*
  "https://", ".com", "www.", ".html", "/index",               // 5    - 1% savings
  "<h3", "<h2", "<p", "<li", "<a href=\"", "</",               // 6 11 - 1% savings
  " id=\"", " name=\", ", " class=\"",                         // 3 14 - 3% savings!
  "><", "\">",                                                 // 2 16
*/
  // ".org", // 1% on wikipedia, lol
/*
  // -- saves 2% for sweden.html
  "</li>", "span", "div"

  // --- prefixes - 16 - saves only 1%
  "tion", "ould", "ight", "hich", "thing",                     // 5
  "atio", "ever", "ough", "ment",                              // 4  9
  // html encoding
  // TODO: add "&#" ?
  "...",                                                       // 1 10
  // sweden.html saves 1% 
  "&nbsp;", "&lt;", "&gt;", "&amp;", "&quot;",                 // 5 15
  "fuck",                                                      // 1 16 - for English ... or "ing "
*/
};
  
// (/ (+  252847  139329  100540   94170   83724   68712   66567   64296   63618   62663   56237   54782   50964   44176   42266   41936 ) 2)
// = 643413 bytes saved (?)

// TODO: idea of 16 last seen symbols ordered by last accessed, can pick 1/16 cheaply

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
    // can't have two 0 in a row (if would create \0)
    if (i && nibble==0 && lastnibble==0) OUTNIBBLE(12); 
    OUTNIBBLE(nibble);
    ++s;
  }
  
  OUTNIBBLE(13); OUTNIBBLE(0); // 'N ' -- END! (non-ambigous)
  if (i) OUTNIBBLE(0);
  return realloc(r, strlen(r)+1);
}

char* compress12(char* s) {
  char *r= calloc(strlen(s)*2, 1), *p=r;
  char c,*m;
  uchar j,k,nibble;
  uchar map;
  uchar C=0, o=0,i=2;
  uchar space=0,lastnibble=0,lastchar='.';
  char* d;

#undef OUTNIBBLE
#define OUTNIBBLE(nibble) do { \
    o|= (nibble); \
    printf("  [c='%c' $%02X last='%c' map=%d] => nibble %d\to=%2x   '%c'", c, c, lastchar, map, nibble, o, ONE[nibble]); \
    if (--i) o<<= 4; \
    else { printf("   => %02x ", o); *++p=o,o=0,i=2; } \
    lastnibble= nibble; \
    lastchar= c; \
    putchar('\n'); \
    } while (0);

  --p;
 next:
  while((c= *s)) {
    // Savings (+ 53 10 24 3) = 71 bytes total improved...

    // Dictionary of only " the ", lol
    //printf(">>>%.15s ...\n", s);
    
    //  63% 2250821/3544339
    //  60% 2143233/3544339 before only get THE AND WHICH
    //  55% 1949339/3544339 (- 2250821 1949339) = 301482 bytes half of expected? hmmmm? THE already done?

    if (lastchar==' ' && c==' ') {
      ++s;
      lastchar= 0;d
      continue;
    }

    //  3544339 sherlock.txt
    //  1317604 sherlock-all.txt.gz (/ 1317604 3544339.0) = 37%
    if (1) { // 658 -> 605: 53 bytes
      char k;

      if (1)
      for(k= 0; k<sizeof(onedict)/sizeof(onedict[0]); ++k) {
        d= onedict[k];
        // it's ok to skip space (if first) TODO: verify
        //printf("--- s='%c' and d='%c'\n", *s, *d);
        if (*s!=' ' && *d==' ') d++;

        // TODO: precompute strlen...
        if (0==strncasecmp(d, s, strlen(d))) {
          putchar('D'); OUTNIBBLE(13); OUTNIBBLE(3);
          lastchar= ' ';
          s+= strlen(d)-1;
          goto next;
        }
      }
    }

    // auto space after . , 634 -> 624: 10 bytes
    // TODO: ? ! : ; ???
    if ((lastchar=='.' || lastchar==',') && c==' ') { ++s; continue; }
    // TODO: detect that space follows for sure
      
    // find map of char
    m= strchr(chars12, c);
    if (!m) {

      // Numbers (nibbles: start, each digit..., end "12" => 4, "12"   648 -> 624: 24 bytes
      if (strchr("0123456789.,+-eE;", c) && strchr("0123456789.,+-eE;", s[1])) {
        // 'N' is secondary, this means one more byte
        putchar('S'); OUTNIBBLE(15);
        putchar('N'); OUTNIBBLE(15);

        while((c=*s) && strchr("0123456789.,+-eE;", c)) {
          // TODO: actual encoding
          putchar(' '); putchar('n'); OUTNIBBLE(15);
          ++s;
        }
        putchar('N'); OUTNIBBLE(15);

        continue;
      }

      // after ., auto space and auto: 629 -> 624: 3 bytes, lol
      // 
      // 1961260/3544339
      // 1947256/3544339  (/ (- 1961260 1947256) 3544339.0) = 0.4% only
      if (0 && (lastchar=='.' || lastchar==',') && isupper(c)) {
        c= tolower(c); // no need to quote
        m= strchr(chars12, c);
        //printf("UPPER, lastwas '%c' now '%c'\n", lastchar, c);
      }

      // TODO: delta unicode from last code-point?
      //   or just output replacement bytes? (not enought?)
      if (!m) {
        //printf("UTF-8, lastwas '%c' now '%c'\n", lastchar, c);
        // TODO: utf-8
        putchar('U'); OUTNIBBLE(15);
        putchar('T'); OUTNIBBLE(15);
        putchar('F'); OUTNIBBLE(15);
        //print("-- %%ERROR: can't find char '%c' (%d, %02x)\n", c, c, c);
        //exit(1);
        ++s;
        continue;
      }
    }

    // Encode
    j= m-chars12;
    nibble= j&15;
    map= j>>4;

    if (map) { putchar(' '); OUTNIBBLE(14); }
    // can't have two 0 in a row (if would create \0)
    if (i && nibble==0 && lastnibble==0) { OUTNIBBLE(15);OUTNIBBLE(15); }

    OUTNIBBLE(nibble);
    ++s;
  }
  
  if (!i) OUTNIBBLE(13);
  OUTNIBBLE(0); OUTNIBBLE(0); // 'N ' -- END! (non-ambigous)
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
  char *c=0, *d=0, *p=0;
  int sl,cl,dl;

  printf("TEXT[%3d]: >%s<\n\n", sl= (int)strlen(s), s);

//  c= compress(s);
  c= compress12(s);
  printf("COMP[%3d]: >", cl= (int)strlen(c));
  p= c;
  while(*p) printf("%02x ", *p++);
  printf("<\n\n");

  //d= decompress(c);
  if (d) printf("DCMP[%3d]: >%s<\n\n", dl= (int)strlen(d), d);
    
  //printf("\n>%s:%d:%d:%d%%\n", s, sl, cl, (int)((cl*10000L+4000)/sl/100)); // 4000? why not 5000?
  printf("\n>%3d%% %4d/%4d\t>%s<\n\n", (int)((cl*10050L)/sl/100), cl, sl, s); // 4000? why not 5000?
  //printf(">%s:\n", d);

  if (dl!=sl) { printf("--CONVERSION FAILED!\n"); }
  //assert(dl==sl);
  
//  free(c); free(d); free(p);
}

int main(void) {
  //char *s= "eE aAAaa foo";
  //char *s= "Hello My name is Jonas S Karlsson";
  //char *s= "hello my name is jonas s karlsson";
  char* c= NULL; size_t l= 0;

  //printf("CHARS= >%s<\n", chars);

  while (getline(&c, &l, stdin)>=0) {
    if (*c=='\\') { printf(">  %s\n", c); continue; }

    // TODO: should we count \n... it gives 3 nibbles, lol
    c[strlen(c)-1]= 0;

    oneline(c);
  }


  return 0;
}
