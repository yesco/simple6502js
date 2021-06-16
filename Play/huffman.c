#include <stdio.h>
#include <stdlib.h>

long arr[256];
long freq[256] = {0};

int cmp(const char* a, const char* b) {
  return freq[arr[*b]] - freq[arr[*a]];
}

int main() {
  // init
  for(int i=0; i<256; i++) {
    arr[i]= i;
    // using initial freq 1 allows
    // for "better balanced" non-used
    // chars (if included) (optimal?)
    freq[i]= 1;
  }

  // freq
  int c;
  while((c= getc(stdin)) != -1)
    freq[c]++;
//    // make used hcars more important
//    freq[c]+=1000;
  
  printf("\n");

  // process len 
  int len= 256;
  while(len > 1) {
    // sort
    qsort(arr, len, sizeof(*arr), cmp);

    printf("pos value  freq\n");
    printf("===============\n");
    for(int i=0; i<256; i++)
      printf("%3d %5d %5d\n", i, arr[i], freq[arr[i]]);
    return 0;

    // combine least weighted two
    // TODO: extra indexing by arr[] ?
    int second = arr[len-2];
    int first = arr[len-1];

    printf("--- BRANCH: %3d %5d %5d %5d %5d\n", len, second, first, freq[second], freq[first]);

    freq[second]+= freq[first];
    
    // reuse it to form pair, LOL
//    arr[len-2]= (second<<16) + first;

    len--;
  }

  //fputc(i, stdout);
  //fprintf(stderr, "%d ", i);
  for(int i=0; i<256; i++) {
    long d = arr[i];
    if (1) {
      printf("%3d %3d %5d\n", i, d, freq[d]);
    } else if (isprint(c)) {
      printf("%02x   %c  %02x\n", c, c, i);
    } else {
      printf("%02x  %02x  %02x\n", c, c,i);
    }
  }
}
