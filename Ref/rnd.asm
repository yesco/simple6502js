There were a few speed bumps creating this version of the game. Implementing the random number generator had me stumped for a while. This is the algorithm I found on a retro programming website:

rand_val^=rand_val<<7;
rand_val^=rand_val>>9;
rand_val^=rand_val<<8;
The output of the generator in assembly was correct for many cycles then diverged from the C version at some point. This caused the randomly generated map to look close but not identical to the other versions. (Testing the output in Python, I realized the interesting property that this algorithm generates every 16-bit value exactly once before repeating.) This algorithm is convenient on an 8-bit architecture since shifting a 16-bit value left 7 is the same as shifting the low byte right just once and moving it to the high byte. Shifting 9 right on the next line is also very efficient since it's equivalent to switching the high byte to the low byte then shifting right once. The 65(C)02 can only shift one bit at a time, so reducing these arguments to one-bit shifts makes them much more efficient. The problem I ran into was that shifting right once to accomplish the shift left by 7 needs to shift in a bit to fill the most significant bit of the 16-bit value during the single shift right. Because I missed this, the random values happened to be right for a while before diverging.

http://www.retroprogramming.com/2017/07/xorshift-pseudorandom-numbers-in-z80.html

Great stuff! I ported this to C64, 30 cycles without the RTS. I didn't need what is equivalent to the second lda a,l / rra because 6502 EOR does not touch carry:

rng_zp_low = $02
rng_zp_high = $03
; seeding
LDA #1 ; seed, can be anything except 0
STA rng_zp_low
LDA #0
STA rng_zp_high
...
random
LDA rng_zp_high
LSR
LDA rng_zp_low
ROR
EOR rng_zp_high
STA rng_zp_high ; high part of x ^= x << 7 done
ROR ; A has now x >> 9 and high bit comes from low byte
EOR rng_zp_low
STA rng_zp_low ; x ^= x >> 9 and the low part of x ^= x << 7 done
EOR rng_zp_high
STA rng_zp_high ; x ^= x << 8 done
RTS

Retro Programming

Saturday, 22 July 2017
16-Bit Xorshift Pseudorandom Numbers in Z80 Assembly
Xorshift is a simple, fast pseudorandom number generator developed by George Marsaglia. The generator combines three xorshift operations where a number is exclusive-ored with a shifted copy of itself:

/* 16-bit xorshift PRNG */

unsigned xs = 1;

unsigned xorshift( )
{
    xs ^= xs << 7;
    xs ^= xs >> 9;
    xs ^= xs << 8;
    return xs;
}
There are 60 shift triplets with the maximum period 216-1. Four triplets pass a series of lightweight randomness tests including randomly plotting various n × n matrices using the high bits, low bits, reversed bits, etc. These are: 6, 7, 13; 7, 9, 8; 7, 9, 13; 9, 7, 13.

7, 9, 8 is the most efficient when implemented in Z80, generating a number in 86 cycles. For comparison the example in C takes approx ~1200 cycles when compiled with HiSoft C v1.3.

