// SOUND-RAW
//
// (BASIC) ROM-less sounds in plain C
//
// (C) 2024 Jonas S Karlsson
//

// Various resources used...

// - https://forum.defence-force.org/viewtopic.php?t=692
//
// ORIC uses a 14 byte table to play it's built-in sounds
//
//   Now, what is the meaning of each byte of the table ?
//   Simply, they correspond to the AY-3-8912 registers :
//   - 0 and 1 : tone (pitch) on channel A (n between 0 and 4096) (12 bits)
//   - 2 and 3 : tone (pitch) on channel B (between 0 and 4096) (12 bits)
//   - 4 and 5 : tone (pitch) on channel C (between 0 and 4096) (12 bits)
//
//   note:n=real_period/16/T0 (TO=1µS for Oric) or in short Frequency=1MHz/16/n (n=0 acts as n=1)
//
//   Possible frequencies are in range from 62500Hz (n=1) down to approx. 15.26Hz (n=4095)
//
//   - 6 : period of the noise generator (between 0 and 31)
//         note: only bits 0 to 4 are used, Frequency=1MHz/16/n (n=0 acts as n=1)
//
//   - 7: Channels activation
//        bit 0: channel A
//        bit 1: channel B
//        bit 2: channel C
//        bit 3,4 et 5 mixing of the noise into the three primary channels
//        becarefull: bit=0 means "activated" bit=1 means NOT activated, for the 6 bits
//        (note: bit 6 is the port A direction and bit 7 the port B direction, not used for sound generation)
//
//    - 8,9,10 --> volume A,B,C (0 to 16)
//      more precisely :
//      - bits 0 to 3 (amplitude): maximum amplitude or volume (0 to 15)
//      - bit 4 (modulation) : 0 -->fixed amplitude 1-->amplitude controlled by B0-B3 and the envelop generator
//      Note : The volume is non-linear. The "real world" amplitude can be computed like this :
//
//      real_world_amplitude = max / sqrt(2)^(15-n),
//
//      This amplitude corresponds to the voltage output to a speaker. (15 --> max/1, 14 --> max/1.414, 13 --> max/2, etc...)
//
//    - 11 and 12 --> Envelope step frequency - sound duration - (0 to 65535)
//      note:Frequency=1MHz/16/n (n=0 acts as n=1)
//
//      Depending on the envelope shape, the volume is incremented from 0 to 15,
//      or decremented from 15 to 0. In either case it takes 16 steps to
//      complete, the completion time for 16 steps is therefore:
//
//      T = n*256 / 1MHz      ;with n in range 1..65535 (256µs .. 16.7 seconds)
//
//    - 13 --> envelop (0 to 15) note:only bits 0 to 3 are used.
//      According to wikipedia (french) :
//      bits 0 to 3 permit to control the sound envelop
//        but only 10 are available because only
//        B2 is taken into account when B3 is equal to zero :
//
//        B3 - Continue   
//        B2 - Attack     0=\ 1=/
//        B1 - Alternate  
//        B0 - Hold
//
//        Binary  Hex      Shape
//        00XX    00h-03h  \_________  (same as 09h)
//        01XX    04h-07h  /_________  (same as 0Fh)
//        1000    08h      \\\\\\\\\\
//        1001    09h      \_________  (volume remains quiet)
//        1010    0Ah      \/\/\/\/\/
//        1011    0Bh      \"""""""""  (volume remains high)
//        1100    0Ch      //////////
//        1101    0Dh      /"""""""""  (volume remains high)
//        1110    0Eh      /\/\/\/\/\
//        1111    0Fh      /_________  (volume remains quiet)
//
//        Registers+envelops :
//        - http://download.abandonware.org/magazin ... e%2021.jpg


// - https://forum.defence-force.org/viewtopic.php?t=30
// 
// AY Crudentials: Accessing the AY
//
//   Post by Twilighte » Fri Jan 20, 2006 9:58 pm
//   
//   The AY-3-8912 is not memory mapped in the Oric and the method
//   of accessing it is obscure (to say the least).
//
//   However, with a little knowledge, it is easy enough to write
//   and read from any register.
//   
//   The AY-3-8912 is linked to the system by the way of one
//   data/register port and 2 control lines.
//
//   The control lines are known as CA2 and CB2 since they are
//   held within the VIA 6522 and may be set/reset in Memory location $030C.
//
//   The Data/Register Port is also used by the Printer Port (Which may
//   also be attached to a joystick interface) and appears at location $030F.
//   
//   The control line Register (Also known as the PCR) actually
//   controls the behaviour of CA1,CA2,CB1 and CB2, but for the
//   most part, we can get away with 3 values directly poked into
//   this location.
//
//   The three values are...
//
//     $DD == $030F is inactive
//     $FD == $030F holds data for a preset Register
//     $FF == $030F holds a Register number
//   
//   The AY-3-8912 has 15 Registers numbered $00 to $0E:
//
//     00 Bits 0 to 7(0-255) - Pitch Register LSB Channel A
//     01 Bits 0 to 3(0-15) - Pitch Register MSB Channel A
//
//     02 Bits 0 to 7(0-255) - Pitch Register LSB Channel B
//     03 Bits 0 to 3(0-15) - Pitch Register MSB Channel B
//
//     04 Bits 0 to 7(0-255) - Pitch Register LSB Channel C
//     05 Bits 0 to 3(0-15) - Pitch Register MSB Channel C
//
//     06 Bits 0 to 4(0-31) - Noise Pulsewidth
//
//     07 Bit 0(0-1) - Link Pitch A to Output D/A converter A
//     07 Bit 1(0-1) - Link Pitch B to Output D/A converter B
//     07 Bit 2(0-1) - Link Pitch C to Output D/A converter C
//     07 Bit 3(0-1) - Link Noise to Output D/A converter A
//     07 Bit 4(0-1) - Link Noise to Output D/A converter B
//     07 Bit 5(0-1) - Link Noise to Output D/A converter C
//
//     08 Bits 0-3 (0-15) - D/A Converter Amplitude(Volume) A
//     08 Bit  4 - Envelope Generator controls Amplitude of A
//
//     09 Bits 0-3 (0-15) - D/A Converter Amplitude(Volume) B
//     09 Bit  4 - Envelope Generator controls Amplitude of B
//
//     0A Bits 0-3 (0-15) - D/A Converter Amplitude(Volume) C
//     0A Bit  4 - Envelope Generator controls Amplitude of C
//
//     0B Bits 0 to 7(0-255) Envelope Generator Period Counter LSB
//     0C Bits 0 to 7(0-255) Envelope Generator Period Counter MSB
//
//     0D Bits 0 to 3(0- 15) Envelope Generator Cycle Register
//   
// So to write the value of 15 into register 8 (Volume of channel A)
// the following code could be used...
//
//     LDA #8        'Set the register to 8
//     STA $030F
//     LDA #$FF
//     STA $030C
//     LDA #$DD
//     STA $030C
//     LDA #15       'Set the Value for this register
//     STA $030F
//     LDA #$FD
//     STA $030C
//     LDA #$DD      'Reset the state of the control lines
//     STA $030C
//
// Note: it is assumed that when starting, the control register is $DD
//
// It is also worth mentioning that when setting the register,
// the last value in $030C is taken so in some scenarios it is unneccasary
// to set the control lines inactive whilst setting the Register.
//
// Dbug--------------------------------------------------
//
// I was checking my old replay code, and I found out that instead
// of FD and DD I have EC and CC:
//
//     sta VIA_ORA
//     lda #$EC
//     sta VIA_PCR
//     lda #$CC
//
// What's the actual difference and the impact?
//
// T--------------------------------------------------
//
// Hi there.
//
// Both bits of code will work equally well. The difference is in
// the CA1 and CB1 control bits in the PCR of the 6522 VIA. Bit 0 of
// the PCR (at location $30C on Oric) relates to CA1 which is the
// 'ACK' line of the printer port and bit 4 relates to CB1 which
// is connected to the Tape In circuitry.
//
// Neither should make any difference as both the printer and tape
// routines in ROM set up the 6522 VIA anyway.
//
// I guess the only way it could make a difference is if the VSYNC-
// hack is implemented (on a real Oric!) as it's fed through the tape input.
//
// I hope I haven't made this ten times more boring than it needed be!
// 
// T
// 
// T: Dbug, you have the advanced user guide,
// refer to page 38 and see that it controls four lines.



// TODO: http://twilighte.oric.org/twinew/sending.htm
// - potential extra information: shift register CB2 use for samples!

// Arcade sounds on ORIC ATMOS
//
// - https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://www.youtube.com/watch%3Fv%3DOtZxezhC_TU&ved=2ahUKEwjL4-GdwvyKAxVOZWwGHauoGF4QtwJ6BAgkEAE&usg=AOvVaw0VLKivbKXYm8p9xeMnIBWK


/* ORIC-ROM code:

$FA86:

PHP                                     This routine takes X and Y
SEI                                     as the low and high halves of
STX   $14                               the start address of a table
STY   $15                               to send data to the sound
LDY   #$00                              chip from.
LDA   ($14),Y                           14 bytes are sent to the 8912
TAX                                     starting with register 0 and
TYA                                     working up in order until
PHA                                     register D. The data from
JSR   $F590                             the table is used starting
PLA                                     from the low address.
TAY
INY                                     The I/O port is not written
CPY   #$0E                              to.
BNE   <a href="https://iss.sandacite.com/tools/oric-atmos-rom.html#LFA8E">$FA8E</a>
PLP
RTS

$F590 WRITETOAY:

PHP                                     WRITE X TO REGISTER A OF 8912
SEI
STA   $030F                             Send A to port A of 6522.
TAY
TXA
CPY   #$07                              If writing to register 7, set
BNE   $F59D                             1/0 port to output.
ORA   #$40

$F59D:

PHA
LDA   $030C                             Set CA2 (BC1 of 8912) to 1,
ORA   #$EE                              set CB2 (BDIR of 8912) to 1.
STA   $030C                             8912 latches the address.
AND   #$11                              Set CA2 and CB2 to 0, BC1 and
ORA   #$CC                              BDIR in inactive state.
STA   $030C
TAX
PLA
STA   $030F                             Send data to 8912 register.
TXA
ORA   #$EC                              Set CA2 to 0 and CB2 to 1,
STA   $030C                             8912 latches data.
AND   #$11                              Set CA2 and CB2 to 0, BC1 and
ORA   #$CC                              BDIR in inactive state.
STA   $030C
PLP
RTS

*/


// ORIC Predefined Sounds (from BASIC ROM)
//   we want to keep these 14 bytes sounds as a constant string
//   this allows the compiler to remove it if not used!

#define PING         "\x18\x00\x00\x00\x00\x00\x00\x3e\x10\x00\x00\x00\x0f\x00"
#define SHOOT        "\x00\x00\x00\x00\x00\x00\x0f\x07\x10\x10\x10\x00\x08\x00"
#define EXPLODE      "\x00\x00\x00\x00\x00\x00\x1f\x07\x10\x10\x10\x00\x18\x00"
#define PONG         "\xee\x02\x00\x00\x00\x00\x00\x3e\x10\x00\x00\xd0\x07\x00"

// Flying related
#define AHELICOPTER  "\xa8\xbf\x00\x03\xb8\xbf\x0e\x00\x00\x00\xa7\xc2\x4c\xb0"
#define HELICOPTER   {168,191,0,3,184,191,14,0,0,0,167,194,76,176}
#define HELICOPTER2  {206,108,231,36,137,112,70,182,170,239,83,246,12,165}
#define HELI_DISTANT {14,136,132,12,140,0,69,173,0,5,208,4,169,192}
#define COCKPIT      {150,0,152,46,4,255,255,112,7,80,0,102,5,65}
#define TURBOPROP    {32,2,140,0,5,132,14,136,132,12,140,0,69,173}

// Machines
#define ELECTRICITY  {0,4,0,184,0,3,120,190,12,0,0,0,167,194}
#define ENGINE       {1,5,193,7,7,8,7,8,53,151,47,151,0,152}

// Metal
#define HAMMER_ANVIL {32,134,250,96,0,0,0,0,0,0,31,7,16,16}

// 
//      A,B,C:  note: n=real_period/16/T0 (TO=1µS for Oric)
//              Frequency=1MHz/16/n (n=0 acts as n=1)
//
//      Env-freq = T = n*256 / 1MHz      ;with n in range 1..65535 (256µs .. 16.7 seconds)
//      Va,Vb,Vc = real_world_amplitude = max / sqrt(2)^(15-n)
//
//                                      0-31 NNNcba     (Mod)vvvv   T      0-15
//                       0   1   2   3   4   5   6   7   8   9  10  11  12  13
//                      Al  Ah  Bl  Bh  Cl  Ch  N4  Ch  Va  Vb  Vc Env-freq ENV
#define PONG2        "\xEE\x02\x00\x00\x00\x00\x00\x3E\x10\x00\x00\xD0\x07\x00"
#define PCHH         "\x00\x00\x00\x00\x00\x00\x01\x37\x10\x00\x00\xD6\x0B\x00"
#define APONG2       "\xEE\x02\x00\x00\x00\x00\x00\x3E\x10\x00\x00\xD0\x07\x00"

#define SILENCE      "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"


extern int T=0;
extern int nil=0;
extern int doapply1=0;
extern int print=0;

#ifdef BASIC_ROM

void fx(char* sound) {
  __AX__= sound;
  //  __AX__= 0xFAA7; // a: a7 x: fa
  asm("pha"); // stack: a7
  asm("txa"); // a= fa
  asm("tay"); // y= fa
  asm("pla"); // a= a7
  asm("tax"); // x= a7
  // PING from ORIC BASIC ROM
  //asm("ldx #$a7");
  //asm("ldy #$fa");
  asm("jsr $FA86");
}

#else

void setAYreg(char r, char v) {
  *(char*)0x030f= r;       // Set the register
  *(char*)0x030c= 0xff;    //   toggle
  *(char*)0x030c= 0xdd;    //   toggle
  *(char*)0x030f= v;       // Set the Value for this register
  *(char*)0x030c= 0xfd;    //   toogle
  *(char*)0x030c= 0xdd;    //   toggle Reset the state of the control lines
}

void setAYword(char ch, unsigned int w) {
  setAYreg(ch*2,   w & 0xff);
  setAYreg(ch*2+1, w >> 8);
}

void sfx(char* fourteenbytes) {
  char i=0;
  for(; i<14; ++i) {
    setAYreg(i, *fourteenbytes);
    ++fourteenbytes;
  }
}

#endif // BASIC_ROM

// PLAY 0,0,0,0 - silence
//
// SOUND(ch, period, vol:0-15)
//  ch: 1,2,3 - tone
//       4,5,6 - noise

void sound(char ch, unsigned int period, char vol) {
  if (1 <= ch && ch<= 3) {
    setAYword(ch*2-2, period);
    setAYreg(8+ch, vol);
  }
}

// n=real_period/16/T0 (TO=1µS for Oric) or in short
// Frequency=1MHz/16/n (n=0 acts as n=1)
// (/ 1000000 16) so ... 62500/hz (/ 62500 440)=142

#define DIVHZ 62500L // 1000000/16

void freq(char ch, unsigned int hz, char vol) {
  sound(ch, DIVHZ/hz, vol); // TODO: rounding?
}


// MUSIC(ch:1-3, octave:0-6, note, vol:0-15)
//
// Note, piano layout:
// 
//     2  4     7  9 11  
//
//    C# D#    F# G# A#
//   C  D  E  F  G  A  H
//
//   1  3  5  6  8 10 12
// 
// If volume level zero is chosen on SOUND or MUSIC, then the
// output is directed to the envelope section of the PLAY command.
// Both SOUND and MUSIC are switched on by PLAY. Note length can
// be controlled by WAIT statements and the sound is switched off
// by PLAY 0,0,0,0.

// - https://newt.phys.unsw.edu.au/jw/notes.html
//
//    A7 =3136 (!)
//    A6 =1568 (!)
//    A5 = 880 Hz
//
// -- one base octave
//
// B= B4 = 493.88     (12) // H
//         466.16     (11)
// A= A4 = 440    Hz  (10)
//         415.30     (9)
// G= G4 = 392        (8)
//         369.99     (7)
//    F4 = 349.23     (6)
//    E4 = 329.63     (5)
//         311.13     (4)
//    D4 = 293.67     (3)
//         277.18     (2)
//    C4 = 261.6      (1)
// -- end
//    B3 = 246.94
//    C3 = 220    1/2!
//    C2 = 110
//    C1 = 
//
// C4..B4
//
// unsigned int hfreq= {26160, 27718, 29367, 31113, 32963, 34923, 36999, 39200, 41530, 44000, 46616, 49388};
// unsigned int pitch= {239, 225, 212, 200, 189, 178, 168, 159, 150, 142, 134, 126}


// C1..B1
//unsigned int hfreq= {32703, 34648, 36708, 38891, 41203, 43654, 46249, 48999, 51913, 55000, 58270, 61735};

// bigger values easier to halve - higher precision
// but this isn't perfrect frequency by math?

// (/ 62500000 34648.0)
// (/ 1911 8.0) = 239 close enougn!
unsigned int hpitch[]= {1911, 1804, 1703, 1607, 1517, 1432, 1351, 1276, 1204, 1136, 1073, 1012}; 

void music(char ch, char oct, char note, char vol) {
  // loop for >> but do we want this many tables?
  sound(ch, hpitch[note-1] >> (oct-1), vol);
}

// PLAY(tone_enable, noise_enable, envelope, env_period)
//
//   tone:  A=1, B=2, C=4 => A+C==5 all=7
//   noise: similar to tone for each channel
//   env_period: 0..32767

// T= n*256 / 1MHz = (1..65535) (256us..16.7s), 0.ls==380
void play(char tonemap, char noisemap, char env, unsigned int env_period) {
  setAYword(11, env_period);         // env period
  setAYreg(13, env);                 // set envelope
  setAYreg(7, tonemap + noisemap*8); // channel activation
}

// -- example from ORIC manual
// 
//  10 REM ** TUNE **
//  20 FOR N= 1 TO 11
//  30   READ A,B
//  40   MUSIC 2,3,A,0
//  50   PLAY 3,0,7,2000  ' 500 ms ? (1M/p)
//  60   WAIT B           ' B   hs
//  70   PLAY 0,0,0,0
//  80 NEXT N
// 100 DATA 5,30, 5,30, 7,30, 8,75, 5,75
// 110 DATA 8,60, 10,30, 7,60, 5,30, 3,30, 5,180

// -- introductory programming oric-1
//
// 10 LET PERIOD = 25
// 20 SOUND 1,PERIOD,12
// 30 LET PERIOD = PERIOD + 1
// 40 IF PERIOD = 150 THEN EXPLODE ELSE GOTO 20
// 50 STOP

// ------------------------------------------------------------

#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "conio-raw.c"

//#include <conio.h>
//void wait(unsigned int ms) { long w= ms*7L; while(--w); }

char KLAVIATUR[]= "awsedftgyhuj";

//  10 REM ** TUNE **
//  20 FOR N= 1 TO 11
//  30   READ A,B
//  40   MUSIC 2,3,A,0
//  50   PLAY 3,0,7,2000  ' 500 ms ? (1M/p)
//  60   WAIT B           ' B   hs
//  70   PLAY 0,0,0,0
//  80 NEXT N
// 100 DATA 5,30, 5,30, 7,30, 8,75, 5,75
// 110 DATA 8,60, 10,30, 7,60, 5,30, 3,30, 5,180

void p(char n, unsigned int w) { 
  printf("%d", n);
  music(2,3,n,0);
  play(3,0,7,2000);
  putchar('W');
  wait(w);
  putchar('.');
}

void tune() {
  p(5,30); p(5,30); p(7,30); p(8,75); p(5,75);
  p(8,60); p(10,30); p(7,70); p(5,30); p(3,30); p(5,180);
}

void main() {
  char c, *p;

  sfx(PING);
  tune();
  sfx(PING);
  sfx(SILENCE);

  // TODO: keys not working after sound! need some cleanup/setup?
  printf("\nPIANO> ");
  while((c= tolower(cgetc()))!='q') {
    putchar(c);
    if (c==' ') play(0,0,0,0);
    else if (c=='p') sfx(PING);
    else {
      p= strchr(KLAVIATUR, c);
      if (p) {
        printf(" [%d] ", p-KLAVIATUR+1);
        music(1, 3, p-KLAVIATUR+1, 6);
        play(1, 0, 0, 2000);
      }
    }
    putchar('>');
  }

  while(1) {
    printf("Hello Sound!\n");
    sfx(PING);
    sfx(APONG2);
    //fx(AHELICOPTER);
    //wait(1000);
    wait(100);
  }
}
