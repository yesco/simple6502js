// - https://forum.defence-force.org/viewtopic.php?t=692

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
//        B2 - Attack
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

// ORIC Predefined Sounds (from BASIC ROM)

#define PONG    {238,2,0,0,0,0,0,62,16,0,0,208,7,0}
#define PING    {24,0,0,0,0,0,0,62,16,0,0,0,15,0}
#define SHOOT   {0,0,0,0,0,0,15,7,16,16,16,0,8,0}
#define EXPLODE {0,0,0,0,0,0,31,7,16,16,16,0,24,0}

// Flying related
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
//                                                  0-31 NNNcba     (Mod)vvvv   T      0-15
//                       0    1    2    3    4    5    6    7    8    9   10  11   12    13
//                      Al   Ah   Bl   Bh   Cl   Bh   N4   Ch   Va   Vb   Vc Env-freq   ENV 
#define PONG2        {0xEE,0x02,0x00,0x00,0x00,0x00,0x00,0x3E,0x10,0x00,0x00,0xD0,0x07,0x00}
#define PCHH         {0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x37,0x10,0x00,0x00,0xD6,0x0B,0x00}

#define soundfx(soundtableadr)  ldx #<soundtableadr:ldy #>soundtableadr:jmp $FA86
