#include <stdio.h>

// characters ordered in terms of frequency - "Oxford stuff"
// " eariotnslcudpmhgbfywkvxzjq"

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

char  core[16]    = " eariotnslcSNUPD"; // U=Upcase next letter (auto after .), "SN PD" - shifters
char   Ucore[16]  = " EARIOTNSLCsnupd"; //   Upcase letters, 'Uu' => toggle sticky Upcase "sn pd" - shifters

// These are secondary maps
char  Second[16]  = "udpmhgbfywkvxzjq"; // the rest of alphabet
char   USecond[16]= "UDPMHGBFYWKVXZJQ"; //   upcase 'US?'
char  Nums[16]    = " 0123456789.,+-E"; // numbers, sticky till '\0' (not give space), prefix U - nonstick
char  Punct[16]   = ".,:;-'\"/<>(){}[]"; // ., assumes spaces before, unless 'U', 2 nilbbles 'P.'
char   UPunct[16] = "?!#%_`&=@^|~\\\n\t\b"; // ?! assumes space after, 'UP?', \h=backspace!

// Dictionary of most common words, 2 nibbles 'D?'
// Space is assumed before and after, double implicitly removed
char* Dict[16]= { 
  // most common words (>= 4 nibbles -> 2 nibbles)
// - https://en.m.wikipedia.org/wiki/Most_common_words_in_English 'D?'
  "the", "be", /*"to"*,*/ "of", "and", /*"a",*/ /*"in",*/ "that",           // 5  8
  "have", /*"I",*/ /*"it",*/ "for", "not", /*"on",*/ /*"he",*/ "with",      // 4 12
  /*"as",*/ "you", "do", /*"at",*/ "this", "but", // "his", "by", "from",   // 7 19
  // "they", "we", "say", "her", "she", "or", "an", "will", "my", "one", "all", "would",

  // Secondary quotes -> tertirary map
  "REPEAT", "SEQS", "UTF-8",                                                // 3
};
// Unicode is prefied by 2 nibbles 'DU' (also can use for single 8-bit char)

// This is a tertiary map, thus: 3 nibbles, 1.5 byte, 'DR4'
char Repeat[16]= "456789??????????"; // Repat 4-9 times, 10 
  // URL
  // "https://", ".com", "www.", ".html", "index",   // 5
  // HTML
  // "<h3", "<h2", "<p", "<li", "<a href=\"'         // 5

// This is tertiary map, thus: 3 nibble, 1.5 byte, 'DS?'
char* Seqs[16]= {
  // quadrams
  "tion", "ould", "ight", "hich", "thing", "they",// 6    "thinG" lol
  "atio", "ever", "ough", "ment"                  // 4 10
  // trigrams - not worth it (maybe 25%?)
  // others
  "&nbsp;", "&lt;", "&gt;", "&amp;", "&quot;",    // 5 15
  "fuck",                                         // 1 16 - for English
};
  
int main(void) {
  return 0;
}
