// Hires RLE Compressor (HRC) 1.0 tool by Symoon 10/2019
// (with bits from Fabrice F. TAP files tools)
// Produces a RLE compressed HIRES screen TAP file that will self-extract.
// Start address must be somewhere near the HIRES area (#9FFF-#BF3F), and end address must
//  be between #BF3F included (end of Hires picture) and #BFDF included (end of bottom TEXT lines)
// Will keep the 3 text lines if they exist, but won't compress them.
// Will keep the loading name of the input file.
// Will not compress if final size is bigger than original size (the self-extracting
//  routine is about 68 bytes long).
/*
Parameters:
-Rxx : relocate the 4 bytes used in page 0. Value between $00 and $FC; default is $00-$03.
*/

/*
CONVERTING 8 BITS => CHAR
The portable way to do this (ensuring that you get 0x00 0x00 0x00 0xaf everywhere) is to use shifts:

unsigned char bytes[4];
unsigned long n = 175;

bytes[0] = (n >> 24) & 0xFF;
bytes[1] = (n >> 16) & 0xFF;
bytes[2] = (n >> 8) & 0xFF;
bytes[3] = n & 0xFF;
*/


#include <stdio.h>
#include <string.h>


// Programs sizes, in bytes.
#define init_routine_size   28
#define loop_routine_size   40

char version_num[] = "v1.0";
char version_date[] = "10/2019";

FILE *in,*out;
int start, end, prog_size, file_size;
int start_compressed, end_compressed, compressed_screen_size;
int start_compressed_screen;
int COMPRESS = 0;
int userrelocate = 0;
int prognum=0;
int fileproblem=0;
int HIRES=0;
int repeat=0;
float stattotal = 0;
float statnormal = 0;
float statRLE = 0;
float statdictionary = 0;
int dico[256]; //Dictionary table: unused bytes by ascending value order
long dico_length = 0; // amount of bytes following the 1st one (which is element 0 of the table)
int dico_start_value = 0; // 1st byte of the repetitions sequence
int dico_start_pos = 0; // position in the dico table of the 1st byte of the repetitions sequence
int plus128flag = 0;  // flag telling if the +128 trick must be in the code
int magicnumber;      // number added to the bytes to give values 0, 1, 2, 3...
unsigned char header[9];
unsigned char Mem[64*1024],name[40],compressed_screen[9*1024];
int sequence_normal[256][3];    // byte value, amount of sequential unused bytes following, start position
int sequence_plus128[256][3];   // byte value, amount of sequential unused bytes following ignoring bit 7, start position


unsigned char init_routine[init_routine_size]=
{  0xA9,0x00,      //0  LDA ll		Set reading address in page 0 (in 00-01 by default)
   0x49,0x00,      //2  EOR $FF or 00	Set by program, if ll was a forbidden byte, invert it using FF
   0x85,0x00,      //4  STA $00	 	(#0000, updated according to the compression result)
   0xA9,0x00,      //6  LDA LL		LL can't be a forbidden byte (range: $A0-$BF)
   0x85,0x01,      //8  STA $01
   0xA9,0xFF,      //10 LDA $dd-1	Set destination address -1 in page 0 (-1 because incremented before writing)
   0x49,0x00,      //12 EOR $FF or 00	Set by program, if dd-1 was a forbidden byte, invert it using FF
   0x85,0x02,      //14 STA $02		 (#9FFF by default but updated, according to each TAP file)
   0xA0,0x9F,      //16 12 LDY $DD	range: $9F-$BF; 9F is forbidden so store DD +1 to avoid it
   0x88,           //18 DEY		and remove 1 to get the real value back
   0x84,0x03,      //19 STY $03
   0xA2,0x00,      //21 LDX #$00	Set X to 0
   0xA0,0x01,      //23 LDY #$01	Set Y to 1
   0x4C,0x47,0xBF  //25 JMP $BF47	And jump to the beginning of decompression loop
};

unsigned char loop_routine[loop_routine_size]=
{  0x00,           //0  BF40	xx		byte used to mark the end of HIRES screen/decompression loop
                   //				(its value will depend on the bytes used for counters)
   0xE6,0x00,      //1  BF41	INC ll		add 1 to reading address
   0xD0,0x02,      //2  BF43	BNE +2
   0xE6,0x01,      //5  BF45	INC LL
   0xA1,0x00,      //7  BF47	LDA (ll LL,X)	ENTER HERE with X =0 and Y = 1
   // ------ Check if it's a counter
   0x0A,           //9  BF49	ASL *or CLC*	ASL ($0A), so *2 if "plus128" sequence, CLC ($18) if normal sequence
   0x69,0xD0,      //10 BF4A	ADC xx		add magicnumber (256-sequence_start_value, *2 if plus128 sequence)
                   //				(these 3 bytes convert the counter bytes into their value: 0,1,2,3,...)
   0xF0,0x19,      //12 BF4C	BEQ +25		if counter = 0, then exit (RTS)
   0xC9,0x10,      //14 BF4E	CMP xx		(is it a counter between 0 and xx-1) Reminder: If the C flag is 1,
                   //				 then A (unsigned) >= NUM (unsigned) and BCS will branch
   0x90,0x10,      //16 BF50	BCC+16		jump if it's a counter
   // ------ Store a value
   0xA1,0x00,      //18 BF52	LDA (ll LL,X)	else restore A by re-reading the last one stored
   0xE6,0x02,      //20 BF54	INC dd		increase by 1 the storage address
   0xD0,0x02,      //22 BF56	BNE +2		(incrementing before reading so the reading address points on
   0xE6,0x03,      //24 BF58	INC DD		 the latest stored A value, if needed again)
   0x81,0x02,      //26 BF5A	STA (dd DD,X)	Store A
   0x88,           //28 BF5C	DEY		 (Y times)
   0xD0,0xF5,      //29 BF5D	BNE -11		loop to storage address incrementation
   0xC8,           //31 BF5F	INY		restore Y counter to 1 (0 loop)
   0x10,0xDF,      //32 BF60	BPL -33		go back reading A (at the very beginning to increment the reading address)
   // ------ That was a counter
   0xA8,           //34 BF62	TAY		set counter value
   0xA1,0x02,      //35 BF63	LDA (dd DD,X)	read again the latest stored value, to repeat it
   0x90,0xED,      //37 BF65	BCC -19		go back store A (to "INC dd", the carry shouldn't have changed so BCC is OK)
   // ------ Exit
   0x60            //39 BF67	RTS
};


void creation_dico()
//*********************************************************************************************
//**** In order to have repetition counters without using extra bytes, HRC will look for  *****
//****  unused bytes in the original HIRES picture. It will then search for the longest   *****
//****   sequence of consecutive unused bytes, and will use them as repetition values.    *****
//****      For instance if values 34, 35, 36, 37 are unused, they will be used as:       *****
//****  34 = end of compression, 35 = 1 repeat (unused), 36 = 2 repeats, 37 = 3 repeats   *****
//****  The more conscutive unused bytes there are, the more efficient the compression.   *****
//****  To avoid display problems, bytes affecting TEXT/HIRES and frequency are ignored.  *****
//*********************************************************************************************

{ int i, j, k, h, indice, val;
  long tout[256][2];                     // byte value, hits in the HIRES screen.
  long tout_128[256][2];                 // same than above but ordered by: byte, byte+128, byte+1, byte+129, ...

// tables initialization
  for (i=0;i<=255;i++)
  { tout[i][0]=i;
    tout[i][1]=0;
    tout_128[i][1]=0;
    sequence_normal[i][0]=0;
    sequence_normal[i][1]=0;
    sequence_normal[i][2]=0;
    sequence_plus128[i][0]=0;
    sequence_plus128[i][1]=0;
    sequence_plus128[i][2]=0;
    dico[i]=0;
  }


// exclude values that affect the screen display (TEXT/HIRES attributes, or 50/60Hz frequency)
  for (i=152;i<=159;i++)
  { tout[i][1]=1;             // set to 1, so they are considered as being in use
  }
  for (i=24;i<=31;i++)
  { tout[i][1]=1;             // set to 1, so they are considered as being in use
  }
	

//read the whole file
// prog_size pre-calculated in previous function
  for (i=0;i<prog_size;i++)   // count the used bytes, and update the table
  { val=Mem[i];
    tout[val][1]++;           // increse by one the counter each time the byte is met in the file
  }

// duplicate the bytes usage into the special sequence table
  for (i=0;i<=127;i++)                       // this is the second table for special sequence ignoring bit 7
  { tout_128[i*2][0]=i;                      // normal byte
    tout_128[i*2][1]=tout[i][1];
    tout_128[(i*2)+1][0]=i+128;              // next one is normal byte +128
    tout_128[(i*2)+1][1]=tout[i+128][1];
  }



// display table
//    for (i=0; i<=255; i++) {
//        printf("Valeur: %ld  Occur: %ld   | Valeur+128: %ld  Occur: %ld\n", tout[i][0], tout[i][1], tout_128[i][0], tout_128[i][1]);
//    }

// check the unused bytes and calculate the amount of consecutive unused bytes for the normal order
  j=0;
  for (i=0;i<=255;i++)                     // check the whole bytes, in usual order
  {  if (tout[i][1]==0)                    // if the byte is never used
     {  sequence_normal[j][0]=tout[i][0];  // start a new sequence with this byte value
        sequence_normal[j][1]=0;           // initialize it with a 0 length (no following unused bytes detected yet)
        sequence_normal[j][2]=i;           // and with the position in the table
        i++;                               // check next byte in the file
        
        while ((i<=255)&&(tout[i][1]==0))  // loop as long as next bytes are unused
        { sequence_normal[j][1]++;         // for each unused byte, increase the sequence length by 1
          i++;                             // check next byte in the table
        }
        j++;                               // one used byte has been detected, ending the sequence. On to next one.
     }
  }


// Check the unused bytes, ignoring bit 7, and calculate the amount of consecutive unused bytes.
// So the sequence will be like: n, (n+128), n+1, (n+128)+1, n+2, (n+128)+2, ...
// This is done because it's quite easy to use this sequence in ASM code, so it may give
//  longer sequences. Only do this with first 128 bytes (don't start by a higher byte).
  j=0;
  for (i=0;i<=255;i++)                          // this type of sequence must start with a byte < 128
  {  if (i%2!=0) i++;                           //  so that the 1st value can be evaluated as a zero (end of Hires screen)
     if (tout_128[i][1]==0)                     //  as tout_128 is orded by n, n+128, ..., only start with even positions
     {  sequence_plus128[j][0]=tout_128[i][0];  // if the byte is never used, start a new sequence with this byte value
        sequence_plus128[j][1]=0;               // initialize it with a 0 length (no unused bytes following yet)
        sequence_plus128[j][2]=i & 0xFF;        // and with the position in the table
        i++;

        while ((i<=255)&&(tout_128[i][1]==0))   // loop as long as next bytes are unused
        { sequence_plus128[j][1]++;             // for each unused byte, increase the sequence length by 1
          i++;                                  // check next byte in the table
        }
        j++;                                    // one used byte has been detected, ending the sequence. On to next one.
     }
  }


// Ok, we now have two tables (sequence_normal and sequence_plus128) holding unused bytes
//  and how many unused bytes follow. We have to get the longest sequence.

  dico_start_value=0;
  dico_start_pos=0;
  dico_length=sequence_normal[0][1];

  for (i=1;i<=255;i++)                           // look first in the "normal" table
  { if (sequence_normal[i][1]>dico_length)       // if a sequence is larger than the previously longest one
    { dico_length=sequence_normal[i][1];         // then update with its length (minus one, the 1st element was not counted)
      dico_start_value=sequence_normal[i][0];    // and update the starting byte value (1st byte of the unused ones)
      dico_start_pos=sequence_normal[i][2];      // and the position in the table of the starting byte value
    }
  }

  plus128flag = 0;
  for (i=0;i<=255;i++)                           // now look in the table with unused bytes on 7 bits
  { if (sequence_plus128[i][1]>dico_length)      // if a sequence is larger than the previously longest one
    { dico_length=sequence_plus128[i][1];        // then update with its length (minus one, the 1st element was not counted)
      dico_start_value=sequence_plus128[i][0];   // and update the starting byte value (1st byte of the unused ones)
      dico_start_pos=sequence_plus128[i][2];     // and the position in the table of the starting byte value
      plus128flag = 1;                           // and indicate it's a special sequence using 7 bits
    }
  }

// Now, we know which table holds the longuest sequence of unused bytes.
// Let's copy their values in DICO in sequential order

  j=0;
  for (i=dico_start_pos;i<dico_start_pos+dico_length+1;i++)  // copy the sequence into DICO table
  {  if (plus128flag==0)                                    // the sequence is in the normal table
     {  dico[j]=tout[i][0];
     }
     else                                                  // the sequence is in the "plus128" table
     {  dico[j]=tout_128[i][0];
     }
     j++;
  }

// DICO DONE !
// Display the final table
  printf("---\n");
  printf("* File %i \"%s\": HIRES screen detected (%i bytes, #%0004X-#%0004X)\n", prognum, name, prog_size, start, end);
  printf("* Sequence start: %i ($%02X)   Length: %03i   +128 (y/n): %c\n", dico_start_value, dico_start_value, dico_length+1, 110+plus128flag*11);
//  printf(" ---\n");
//  for (i=0;i<=dico_length;i++) printf("dico[%i]= %i ($%02X)\n",i,dico[i],dico[i]);

}


void update_routines()
{
// Now we can calculate the magic number which, added to each sequence byte,
//  will convert the sequence into 0, 1, 2, 3, ... (repetition counters)
// We will adapt the code of the loop routine according to the sequence type, too:
// - normal requires CLC, +128 requires ASL
// - CMP value uses the amount of elements in the sequence (for instance with 0..15, use CMP 16)
// And adapt the code of the INIT routine with the TAP file and compressed data addresses

  // Update loop routine

  magicnumber = (255 - dico_start_value +1)*(1+plus128flag);   // *2 for plus128 sequence
  loop_routine[11]=magicnumber & 0xFF;      // keeps only first 8 bits

  // printf("Magicnumber = %i.\n",loop_routine[11]);

  if (plus128flag==1)                       // the sequence is +128
  {  loop_routine[9]=0x0A;                  // then use ASL to skip 7th bit and use it as carry
  }
  else
  {  loop_routine[9]=0x18;                  // else don't skip and clear carry: use CLC
  }

  loop_routine[15]=(dico_length+1) & 0xFF;  // CMP max value of the unused bytes sequence
  loop_routine[0]=dico_start_value & 0xFF;  // "0" to stop the decompression loop

  // Update init routine   (start_compressed_screen calculated in compress())
  // Some special bytes and code modifications can be required if the bytes read
  //  are "forbidden" (i.e. in $18-$1F or $98-$9F range). Those bytes are attributes
  //  that can scramble the screen if loaded into the HIRES area (Hz or TEXT/HIRES switches)

  if (forbidden(start_compressed_screen & 0xFF))           // reading address
  { init_routine[1]=(start_compressed_screen & 0xFF) ^ 0xFF; // XOR FF to invert if forbidden byte
    init_routine[3]=0xFF;                                    // FF to restore original value
  }
  else
  { init_routine[1]=start_compressed_screen & 0xFF;
    init_routine[3]=0x00;
  }
  init_routine[7]=(start_compressed_screen >> 8) & 0xFF;    // can't be a forbidden byte (range: $A0-$BF)

  if (forbidden((start-1) & 0xFF))           // destination address -1 (because incremented before writing)
  { init_routine[11]=((start-1) & 0xFF) ^ 0xFF; // XOR FF to invert if forbidden byte
    init_routine[13]=0xFF;                      // FF to restore original value
  }
  else
  { init_routine[11]=(start-1) & 0xFF;
    init_routine[13]=0x00;
  }
  init_routine[17]=(((start-1) >> 8) & 0xFF) + 1;  // ( = initial uncompressed screen address)
                                                   // +1 to avoid forbidden $9F. ASM code will do -1

}




// Test if the program is a HIRES screen
void test_HIRES()
{ int i, j;

  HIRES=0;

  // prog_size pre-calculated in previous function
  // Start address must be somewhere in the HIRES area (normally #A000-#BF3F, actually #9FFF-#BF3F;
  // #9FFF for Oric-1 screens that sometimes begin with a RTS so the HIRES screen can be loaded into
  // a program), and end address must be between #BF3F included (end of Hires picture) and #BFDF
  // included (end of bottom TEXT lines)

  if ((start>=0x9FFF)&&(start<=0xBF3F)&&(end>=0xBF3F)&&(end<=0xBFDF)) HIRES=1; // HIRES

  if ((start>=0x9FFF)&&(end<0xBF3F)) HIRES=-1; // HIRES but not matching requirements (end address)

}



// compress the HIRES screen
void compress()
{ int i, j, k;
  int screen_size=0;
  int repet=0;
  int prev=-1;
  int val=-1;

  // test if the HIRES screen can be compressed
  COMPRESS=0;
  compressed_screen_size=0;

  // prog_size pre-calculated in previous function
  // Start address must be somewhere between #9FFF-#BF27; #BF27 because the init routine will
  //  take 23 bytes room so compressing will be useless for such a small screen

  if ((start>=0x9FFF)&&(start<=0xBF27)) COMPRESS=1; // end address tested before by HIRES check

  if (COMPRESS==1)
  {  screen_size=0xBF3F-start+1;
     j=0;
     for(i=0;i<=screen_size;i++)           // only then HIRES screen is compressed, not TEXT area
     {  prev=val;
        if (i!=screen_size) val=Mem[i];    // check newly read value (unless it's the last loop)
        if ((val==prev)&&(i!=screen_size)) // if similar to the previous one (and not end of loop), don't write it,
        {  repet++;                        //  just increase the counter
        }
        else
        {  if (repet>0)                   // if different or end of loop, get rid of previous byte repetitions (if any)
           {  // calculate the repetition bytes
              for (k=0;k<repet/dico_length;k++)          // use bytes according to dictionary of unused bytes
              {  compressed_screen[j]=dico[dico_length]; //  X times the maximum
                 j++;
              }
              if (repet%dico_length==1)                  // for a single last repetition,
              {  compressed_screen[j]=prev & 0xFF;       // store the byte value
                 j++;
              }
              if (repet%dico_length>1)                   // plus the rest
              {  compressed_screen[j]=dico[repet%dico_length];
                 j++;
              }
              repet=0;                                // repetitions have been processed, so zero them
           }
           if (i!=screen_size) compressed_screen[j]=val & 0xFF;  // finally store the newly read value
           if (i!=screen_size) j++;                              // (if not end of loop!)
        }
     }
     compressed_screen_size=j;
  }

  // check if the picture compressed enough to be smaller. If not, don't compress.
  if (compressed_screen_size + init_routine_size + loop_routine_size >= screen_size) COMPRESS=0;

  if (COMPRESS==0)
  {  printf("-!- HIRES screen \"%s\" NOT compressed (would not save room) -!-\n",name);
     printf("---\n");
  }
  else
  {
     printf("* HIRES area compressed from %i bytes to %i.\n",screen_size, compressed_screen_size + init_routine_size + loop_routine_size);
     printf("---\n");
     start_compressed = 0xBF3F - (compressed_screen_size + init_routine_size - 1);
     start_compressed_screen  = 0xBF3F - (compressed_screen_size - 1);
     if (end > 0xBF67)                  // calculate end of file
     {  end_compressed=end;             // if inital file has TEXT lines, set end address with them
     }
     else
     {  end_compressed=0xBF67;      // if not, end file after Loop Routine
     }
  }
}



void relocate()
{
  // actually relocate: change location in page 0 in ASM code.
  init_routine[5]= userrelocate;         // maybe should use  & 0xFF ?
  init_routine[9]= userrelocate+1;
  init_routine[15]= userrelocate+2;
  init_routine[20]= userrelocate+3;

  loop_routine[2]= userrelocate;
  loop_routine[6]= userrelocate+1;
  loop_routine[8]= userrelocate;
  loop_routine[19]= userrelocate;
  loop_routine[21]= userrelocate+2;
  loop_routine[25]= userrelocate+3;
  loop_routine[27]= userrelocate+2;
  loop_routine[36]= userrelocate+2;
}


forbidden(int tested_val)
{  if (((tested_val>=0x18)
   && (tested_val<=0x1F))
   || ((tested_val>=0x98)
   && (tested_val>=0x9F)))
   { return 1;}
   return 0;
}

/*   ************* FORBIDDEN BYTES *************
DEC	HEX	BIN		Effect on screen
---	---	---		----------------
24	#18	00011000	text at 60Hz
25	#19	00011001	text at 60Hz
26	#1A	00011010	text at 50Hz
27	#1B	00011011	text at 50Hz
28	#1C	00011100	graphics at 60Hz
29	#1D	00011101	graphics at 60Hz
30	#1E	00011110	graphics at 50Hz
31	#1F	00011111	graphics at 50Hz
152	#98	10011000	text at 60Hz
153	#99	10011001	text at 60Hz
154	#9A	10011010	text at 50Hz
155	#9B	10011011	text at 50Hz
156	#9C	10011100	graphics at 60Hz
157	#9D	10011101	graphics at 60Hz
158	#9E	10011110	graphics at 50Hz
159	#9F	10011111	graphics at 50Hz
*/


init(int argc, char *argv[])
{
  if (argc<3) return 1;
  if (argv[1][0]=='-') {
    if (feed_parameters(argv[1])) return 1;
  }

  if (strcmp(argv[argc-2],argv[argc-1])==0)
  {  printf("ERROR: Destination file must be different from input file ! (%s)\n\n", argv[argc-2]);
     fileproblem=1;
     return 1;
  }

  in=fopen(argv[argc-2],"rb");
  if (in==NULL) {
    printf("Cannot open %s file (does not exit, or in use)\n\n",argv[argc-2]);
    fileproblem=1;
    return 1;
  }
  out=fopen(argv[argc-1],"wb");
  if (out==NULL) {
    printf("Cannot create %s file (currently in use?)\n\n",argv[argc-1]);
    fileproblem=1;
    return 1;
  }
  return 0;
}


int feed_parameters(char *param)
{ char *paramnum;

  switch (param[1]) {
    case 'r':
    case 'R':
      if (strlen(param)>2)
      {  paramnum = param +2;
         userrelocate=(int)strtol(paramnum, NULL, 16);
         if ((userrelocate < 1)||(userrelocate > 252))      // 252=higher address to store the required 4 bytes.
         {  printf("Bad relocation parameter: %s\n", param);
            printf("Example: -r05 relocates HRC variables in $05 (in page 0).\n");
            printf("              (default page 0 use is $00).\n");
            fileproblem=1;
            return 1;
          }
      }
      else
      {  printf("Bad relocation parameter: %s.\n", param);
         printf("Example: -r05 relocates HRC variables in $05 (in page 0).\n");
         printf("              (default page 0 use is $00).\n");
         fileproblem=1;
         return 1;
       }
      break;
    default:
      printf("Bad parameter: %s\n", param);
      printf("Usage: [-rxx] <input.TAP file> <output.TAP file>\n");
      printf("(run the program without parameters for help)\n");
      return 1;
  }
  return 0;
}


main(int argc,char *argv[])
{
  int i, j;
  unsigned char valin;

  if (init(argc,argv)) {
    if (fileproblem==0)
    { printf("\nUsage: HRC [-rxx] <input.TAP file> <output.TAP file>\n\n");
      printf("Produces self-extracting RLE compressed HIRES TAP file from any HIRES picture\n");
      printf("from the inpt file. Set the Oric in HIRES to load back the compressed files.\n");
      printf("Will work with ROM 1.1 from tape or disk, and ROM 1.0 from disk (not tape\n");
      printf("because of the bug displaying 'Loading' in the middle of HIRES screen).\n\n");
      printf("Options: -rXX 'relocate': you can choose the exact page 0 location for HRC\n");
      printf("              working variables (4 bytes). Must be in hexadecimal, for instance\n");
      printf("              '-r9F', '-r01', ... Default uses '-r00' (so #00-#03).\n\n");
      printf("Notes:\n");
      printf(" - input file start address must be somewhere in the HIRES area (#9FFF-#BF3F)\n");
      printf(" - input file end address must be between #BF3F included (end of Hires picture)\n");
      printf("    and #BFDF included (end of bottom TEXT lines)\n");
      printf(" - HRC will keep the bottom text lines if they exist, but won't compress them\n");
      printf(" - HRC will keep the loading name of the input file\n");
      printf(" - HRC will search for all HIRES pictures in a TAP file, skipping programs\n");
      printf(" - << HRC will not compress if final size is bigger than original size >>\n");
    }
    printf("(%s - %s)\n",version_num,version_date);
    exit(1);
  }

// Check if variables have to be relocated
  relocate();

// Loop, for each program in the TAP file
// Check if each of them is a HIRES screen.
  while (!feof(in)) {
    do
    { valin=0; // avoids fake RLE when end address program goes beyond the end of file.
      if (fgetc(in)==0x16)
      {  if (feof(in)) break;
         valin=fgetc(in);        // read synchro (0x24 included)
         if (feof(in)) break;
         if (valin!=0x24) fseek(in, -1, SEEK_CUR);
      }
    } while ((valin!=0x24)&&(!feof(in)));
    if (feof(in)) break;
 
    if (valin==0x24)        // a 0x16 0x24 sequence has been found, this is not exactly the ROM sequence, which is
    {                       // 0x16 0x16 0x16 0x16 (anything in between) 0x24; hoping this won't give problems

// 1- Read header, name and program, calculate size
      prognum++;
      for (i=0;i<9;i++) header[i]=fgetc(in);  // header
      start=header[6]*256+header[7];
      end=header[4]*256+header[5];

      for (i=0;i<40;i++) name[i]=0;   // initialisation
      i=0;                            // name, hoping it won't be over 40 chars. 16 max in theory
      while (((name[i++]=fgetc(in))!=0)&&(!feof(in)));   // but ROM allows unlimited size, not reading over 16

      prog_size=0;
      for (i=0;i<(end-start)+1;i++)
      {  Mem[i]=fgetc(in);  // program
         if (feof(in)) break;  // sometimes the last part of the TAP is shorter than the addresses difference.
         prog_size++;  // so calculate the actual real size
      }
      if (prog_size!=((end-start)+1)) printf("\n*Warning*: program %i size does not match the addresses difference.\n", prognum);


// 2- Test: if it's not a HIRES screen, skip it

      test_HIRES();

      if (HIRES != 1)
      {  if (HIRES==0) printf("-!- Skipping file %i \"%s\", not a HIRES screen (#%04X-#%04X) -!-\n",prognum, name, start, end);
         if (HIRES==-1) printf("-!- Skipping file %i \"%s\", end address (#%04X) not >= #BF3F -!-\n",prognum, name, end);
      }
      else
      {


// 3- Create program dictionary

        creation_dico();

// 4- Compress the screen

        compress();
        if (COMPRESS==1)
        {
// 5- update the Oric assembler routines, according to the HIRES screen

          update_routines();

// 6- Build the output TAP file
          // update header
          header[4]= (end_compressed >> 8) & 0xFF;    // update header's program end address
          header[5]= end_compressed & 0xFF;           //  with end of compressed file address
          header[6]= (start_compressed >> 8) & 0xFF;  // update header's program start address
          header[7]= start_compressed & 0xFF;         //  with init routine address

          // emit header
          for (i=0;i<6;i++) putc(0x16,out);           // 5 synchro bytes
          putc(0x24,out);                             // start byte
          for (i=0;i<3;i++) putc(header[i],out);      // header start (unused bytes and data type)
          putc(0xC7,out);                             // set AUTO-START, or the screen won't uncompress ;)
          for (i=4;i<9;i++) putc(header[i],out);      // header end (addresses and 00)
          for (i=0;name[i];i++) putc(name[i],out);    // emit program name. Smart C code
                                                      // (not by me): stops when name[i]=0x00
          putc(0x00,out);                             // end of header

          // emit init routine
          for (i=0;i<init_routine_size;i++) putc(init_routine[i],out);

          // emit compressed picture
          for (i=0;i<compressed_screen_size;i++) putc(compressed_screen[i],out);

          // emit loop routine
          for (i=0;i<loop_routine_size;i++) putc(loop_routine[i],out);

          // if there are data after the loop routine, emit them (the 3 TEXT lines, if they exist!)
          if (end > 0xBF67)
          {  for(i=0xBF67-start+1;i<end-start+1;i++) putc(Mem[i],out);
          }

        } // end of compression treatment
      }  // end of HIRES screen treatement
    }   // end of input TAP program treatment
  }    // end of while

  fclose(in);
  fclose(out);

//  printf("Compression stats: %.2f%% none - %.2f%% RLE - %.2f%% dictionary.\n\n", statnormal*100/stattotal, statRLE*100/stattotal, //statdictionary*100/stattotal);
  printf("HRC %s (c) %s --- File(s) converted, using bytes in #%04X-#%04X.\n",version_num, version_date, userrelocate, userrelocate+3);

}
