/* unlz77.c depacks a file packed with lz77.c */
/* Alain Brobecker - 2009/01/21 */

/*
For each control byte in packed file:
  * 0: end
  * 1...MaxNoPk: byte is NbNoPk followed by NbNoPk non packed bytes
  * MaxNoPk+1...255: byte is NbPk-MinPk+MaxNoPk+1 followed by a byte containing offset -1
Usually MaxNoPk=127 so that we check for signs of control bytes */


#include <stdio.h>  /* file functions, etc... */
#include <stdlib.h> /* exit(), malloc() */


#define MaxNoPk 127
#define MinPk 3
#define MaxPk (255-(MaxNoPk+1)+MinPk)
#define MinOffset 1
#define MaxOffset (MinOffset+255)

/* Global variables */
FILE *f;

int   zlen,   len;
char *zbuff, *buff;
char *src;
int   zp,     p;

int c, Offset;
char ctrl;

/***************************************************************************/
int main(argc,argv) int argc; char *argv[]; {
  if (argc!=3) { printf("usage: unlz77 infile outfile\n"); exit(1); }

  // get length of infile
  f= fopen(argv[1], "rb");
  if (!f) { printf("error: %s not found\n",argv[1]); exit(1); }
  fseek(f, 0, 2); // 2 for EOF
  zlen=(int) ftell(f);

  fseek(f, 0, 0); // 0 for SOF
  zbuff= malloc(zlen);
  fread(zbuff, 1, zlen, f);
  fclose(f);

  printf("packed file length=%d\n", zlen);
  
  // allocate memory and load file
  len= MaxPk*(zlen+1)/2;
  buff= malloc(len);
  printf("max unpacked file length=%d\n", len);
  
  // unpack file
  zp= 0;
  p= 0;

  ctrl=zbuff[zp];
  while(ctrl!=0) {
    zp++;

    // Set adress to copy from (in zbuff or in buff)
    // ctrl in [1;MaxNoPk] then there are non packed
    // bytes in zbuff
    if (ctrl <= MaxNoPk) {
      // jsk: copy plain data

      src= zbuff+zp;

      // next ctrl
      zp+= ctrl;
      // ctrl in [MaxNoPk+1;255] then there are packed bytes

    } else {
      // jsk: copy reused data extracted data

      ctrl= ctrl+MinPk-(MaxNoPk+1); // nb of bytes to copy
      Offset= zbuff[zp]+1;
      src= buff+p-Offset;

      // next is a ctrl
      zp++;
    }

    // copy
    for(c=0; c<ctrl; c++) {
      buff[p]= src[c];
      p++;
    }

    ctrl= zbuff[zp];
  }

  // save resulting file
  f= fopen(argv[2], "wb");
  fwrite(buff, 1, p, f);
  fclose(f);
  printf("unpacked file length=%d\n", p);
    
  exit(0);

}
