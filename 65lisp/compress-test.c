#define STATUS ""
#define RESTORE ""

//#define COMPRESS_PROGRESS

//#define COMPRESS_DEBUG
#include "compress.c"

int test(char* in) {
  in= strdup(in);
  printf("\n------ \"%s\"\n\n", in);
  char big[64*1024]= {0};
  char* out= compress(in, strlen(in));
  printf("\ncompressed: len=%d\n", *(uint16_t*)out);
  decompress(out, big);
  int r= strprefix(in, big);
  printf("\n   IN[%ld]:\t\"%s\"\n  OUT[%ld]:\t...\n  DEC[%ld]:\t\"%s\"\n   strprefix=%4d\n", strlen(in), in, strlen(out), strlen(big), big, r);

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
  test("aa");
  test("aaa");
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
    char* z= compress(hisc, i);
    assert(z);
    char dec[8016]={0};
    memset(dec, 0xff, 8000);
    decompress(z, dec);
    printf("HIRES: len=%4d => %4d => %4d == %s\n", i, (int)*(uint16_t*)z, (int)strlen(dec), 0==memcmp(hisc, dec, i)?"OK":"FAILED");
    //for(int j=0; j<i; ++j) printf("%02x", dec[j]);   putchar('\n');
  }
  return 0;
}
