#define STATUS ""
#define RESTORE ""

char curmode= 0;
#define HIRESMODE 30

//#define COMPRESS_PROGRESS

//#define COMPRESS_DEBUG
#include "compress.c"

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

int test(char* in) {
  in= strdup(in);
  printf("\n------ \"%s\"\n\n", in);
  char big[64*1024]= {0};
  Compressed* out= compress(in, strlen(in)+1); // include the \0
  printf("\ncompressed: len=%d\n", out->len);
  decompress(out, big);
  int r= strprefix(in, big);
  printf("\n   IN[%ld]:\t\"%s\"\n  OUT[%ld]:\t...\n  DEC[%ld]:\t\"%s\"\n   strprefix=%4d\n   maxdeep=\t%d\n", strlen(in), in, (long)out->len, strlen(big), big, r, maxdeep);

  if (r<0 || strlen(in)!=strlen(big)) {
    printf("ERROR ---------------------------- ERROR\n");
    printf("IN:  '%c' %3d %02x\n",  in[-r], in[-r],   in[-r]);
    printf("BIG: '%c' %3d %02x\n", big[-r], big[-r], big[-r]);
    exit(1);
  }    
  return r;
}

int main() {
  test("");
  test("a");
  test("ab");
  test("abc");
  test("abcd");
  test("abcde");
  test("abcdef");
  test("abcdefg");

  test("aba");
  test("abab");
  test("ababab");
  test("abababab");
  test("ababababab");
  test("abababababab");
  test("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"); // 100

  char* s= calloc(101,1);
  int i;
  for(i= 1; i<128; ++i) {
    memset(s, i, 100);
    int r= test(s);
  }


  char* sherlock= "THE COMPLETE SHERLOCK HOLMES Arthur Conan Doyle Table of contents A Study In Scarlet The Sign of the Four The Adventures of Sherlock Holmes A Scandal in Bohemia The Red-Headed League A Case of Identity The Boscombe Valley Mystery The Five Orange Pips The Man with the Twisted Lip The Adventure of the Blue Carbuncle The Adventure of the Speckled Band The Adventure of the Engineer's Thumb The Adventure of the Noble Bachelor The Adventure of the Beryl Coronet The Adventure of the Copper Beeches The Memoirs of Sherlock Holmes Silver Blaze The Yellow Face The Stock-Broker's Clerk The \"Gloria Scott\" The Musgrave Ritual The Reigate Squires The Crooked Man The Resident Patient The Greek Interpreter The Naval Treaty The Final Problem The Return of Sherlock Holmes The Adventure of the Empty House The Adventure of the Norwood Builder The Adventure of the Dancing Men The Adventure of the Solitary Cyclist The Adventure of the Priory School The Adventure of Black Peter The Adventure of Charles Augustus Milverton The Adventure of the Six Napoleons The Adventure of the Three Stor";
  test(sherlock);

  // TODO: this one fails! WTF?
  #define FOOBAR "foobar                                  "
  char *foobar= FOOBAR FOOBAR FOOBAR FOOBAR;
  test(foobar);

  // Classic poem? 50 words repeated in different orders.
  // 177 chars -> 106+2 chars 
  // same as LZSS (similar to LZ77)
  char *sam="I am Sam\n\nSam I am\n\nThat Sam-I-am!\nThat Sam-I-am!\nI do not like\nthat Sam-I-am!\n\nDo you like green eggs and ham\n\nI do not like them, Sam-I-am.\nI do not like green eggs and ham.";
  test(sam);

  // Also, for graphics: 8000K with 64 (gclear()) 733 bytes processed, 137 generated... 
  // hang on hires-raw.c ???
  char* hisc= calloc(8000,1);
  memset(hisc, 0, 8000);
  for(i=1; i<=8000; ++i) {
    memset(hisc, 64, i);
    Compressed* z= compress(hisc, i);
    assert(z);
    char dec[8016]={0};
    //memset(dec, xff, 8000);
    decompress(z, dec);
    printf("HIRES: len=%4d => %4d => %4d == %s maxdeep=%d\n", i, z->len, (int)strlen(dec), 0==memcmp(hisc, dec, 8000)?"OK":"FAILED", maxdeep);
    for(int j=0; j<8000; ++j) printf("%02x", dec[j]);   putchar('\n');
  }

  // LAMER.tap - 8000 B
  //         zip: 593 B
  //   fileback: 1238 B
  //       symon: 610 B
  //        mine: 531 B + 2B
  //
  // - https://forum.defence-force.org/viewtopic.php?p=11069&hilit=Compressing#p11069

  // Symoon wrote: 
  //   I have results that go, for the simplest screens, to about 200 bytes
  // (empty screen), and up to 4100 bytes for complex ones (4070 for the
  // title screen of Murder On the Atlantic; 3815 for the Théoric's faamous
  // pirate boat).

  // Before wasting (lots of) time writing the decoding routines, can you
  // guys already tell me how this compares to existing methods you'd know on Oric?
  //
  // Hi, these two pictures are in the Oric slideshow "Pushing The Envelope",
  // and were compressed with PictConv:
  // 
  // - Entry #9 '..\build\files\murder_on_the_atlantic.hir'
  //     Loads at address 40960 starts on track 7 sector 6 and is 13 sectors long
  //     (3188 compressed bytes: 39% of 8000 bytes).
  //     Associated metadata: author='Dom' name='Murder on the Atlantic' 
  // - Entry #10 '..\build\files\trois_mats.hir'
  //     Loads at address 40960 starts on track 8 sector 2 and is 17 sectors long
  //     (4222 compressed bytes: 52% of 8000 bytes).
  //     Associated metadata: author='Vasiloric' name='Sailing ship'
  //
  // HRC: 40 B depacking routine!
  // filepack: 115 B
  char* name= "LAMER.tap";

  FILE* f= fopen(name, "r");
  fread(hisc, 1, 20, f); // skip 20 bytes header!
  fread(hisc, 1, 8000, f);
  fclose(f);

  printf("\nHISC:\n");
  for(int j=0; j<8000; ++j) printf("%02x", hisc[j]);   putchar('\n');

  Compressed* z= compress(hisc, i);
  assert(z);
  char dec[8016]={0};
  decompress(z, dec);
  printf("%s: => %4d => %4d == %s\n", name, (int)*(uint16_t*)z, -1, 0==memcmp(hisc, dec, 8000)?"OK":"FAILED");  

  printf("\nDEC:\n");
  for(int j=0; j<8000; ++j) printf("%02x", dec[j]);   putchar('\n');

  return 0;
}
