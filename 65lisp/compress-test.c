#define STATUS ""
#define RESTORE ""

///#define COMPRESS_PROGRESS

#define COMPRESS_DEBUG
#include "compress.c"

int test(char* in) {
  in= strdup(in);
  printf("\n------ \"%s\"\n\n", in);
  char big[64*1024]= {0};
  char* out= compress(in);
  printf("\ncompressed\n");
  decompress(out, big);
  int r= strprefix(in, big);
  printf("\n   IN[%ld]:\t\"%s\"\n  OUT[%ld]:\t...\n  DEC[%ld]:\t\"%s\"\n   strprefix=%4d\n", strlen(in), in, strlen(out), strlen(big), big, r);
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
    if (r!=100) {
      printf("ERROR ---------------------------- ERROR\n");
      exit(1);
    }
  }

  char* sherlock= "THE COMPLETE SHERLOCK HOLMES Arthur Conan Doyle Table of contents A Study In Scarlet The Sign of the Four The Adventures of Sherlock Holmes A Scandal in Bohemia The Red-Headed League A Case of Identity The Boscombe Valley Mystery The Five Orange Pips The Man with the Twisted Lip The Adventure of the Blue Carbuncle The Adventure of the Speckled Band The Adventure of the Engineer's Thumb The Adventure of the Noble Bachelor The Adventure of the Beryl Coronet The Adventure of the Copper Beeches The Memoirs of Sherlock Holmes Silver Blaze The Yellow Face The Stock-Broker's Clerk The \"Gloria Scott\" The Musgrave Ritual The Reigate Squires The Crooked Man The Resident Patient The Greek Interpreter The Naval Treaty The Final Problem The Return of Sherlock Holmes The Adventure of the Empty House The Adventure of the Norwood Builder The Adventure of the Dancing Men The Adventure of the Solitary Cyclist The Adventure of the Priory School The Adventure of Black Peter The Adventure of Charles Augustus Milverton The Adventure of the Six Napoleons The Adventure of the Three Stor";
  test(sherlock);

  return 0;
}
