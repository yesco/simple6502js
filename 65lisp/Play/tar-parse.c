// "Generated" by grok

/* minimal tar parser - only stdio.h and stdlib.h */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TFILE '0'
#define TDIR '5'
#define TSYM '2'

void dofile(FILE* f, char type, unsigned long long size, char* name) {
  const char *typestr = "unknown";
  
  if (type == TFILE)     typestr = "file";
  else if (type == TDIR) typestr = "directory";
  else if (type == TSYM) typestr = "symlink";
  
  printf("%12llu bytes (%s) %s\n", size, typestr, name);
}

int main(int argc, char **argv) {
  FILE *f = (argc > 1) ? fopen(argv[1], "rb"): 0;
  if (!f) f = stdin;

  char block[512];
  while (fread(block, 1, 512, f) == 512) {
    // Check for end of archive (two empty blocks)
    int empty = 1;
    for (int i = 0; i < 512; i++) if (block[i]) { empty = 0; break; }
    if (empty) {
      fread(block, 1, 512, f); // second empty block b end
      break;
    }

    // ustar header fields (all offsets in octal
    char name[100] = {0};
    char size_str[12] = {0};
    char type = block[156];

    memcpy(name, block + 0,   100); name[99] = '\0';
    memcpy(size_str, block + 124, 12); size_str[11] = '\0';

    // Remove trailing spaces and nulls from name
    for (int i = 99; i >= 0; i--) {
      if (name[i] == ' ' || name[i] == '\0') name[i] = '\0';
      else break;
    }

    // Convert octal size to unsigned long long
    unsigned long long size = 0;
    for (int i = 0; size_str[i]; i++) {
      if (size_str[i] >= '0' && size_str[i] <= '7')
        size = size * 8 + (size_str[i] - '0');
    }

    // allow dofile to read the file
    int pos= ftell(f);

    dofile(f, type? type: '0', size, name);

    // reset file pos
    fseek(f, pos, SEEK_SET);

    // Skip data blocks (rounded up to 512 bytes)
    unsigned long long blocks = (size + 511) / 512;
    fseek(f, blocks * 512, SEEK_CUR);
  }

  if (f != stdin) fclose(f);
  return 0;
}
