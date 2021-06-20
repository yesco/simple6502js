//                   lib_SYS
//                      -
//            SYStem Request Library
//
//
//         (<) 2021 Jonas S Karlsson
//                jsk@yesco.org
//
//


//              TODO: implement!
//

// Using BRK [req [data...]] you invoke a SYStem
// routine.
// 
// Compared to JSR direct addr:
// - future portable libary functions
// - save 1 byte per call
// - use JSR lib if want save BRK for other op
// - auto-generate jmp table
// - automaic setup of address
// - all registers saved
// - optionally restore (selectable)regs at exit
// - library for skipping pascal-data (len, ...)
// - library for skipping asciiz-data (.., 0)
// - library for push literal on Xstack
// - library for push inline-data addr on Xstack
// - library for loading YAX of address

// FEATUES:
// - a single byte default request (just BRK!)
//   enables code saving for common operations.
//   (this restricts "req" to non-op-codes)
//   (this could be a 
// - "req" is restricted to NON-OP-codes!
//   AFTER generating SYS_HANDLER
// - address after BRK (of "req") saved in ZP:0,1
// - registers A,X,Y,P are saved to ZP:2,3,4,5

// NON-OP-codes:

// " - push literal string on stack (addres+len)
// # - push literal number on stack
// ' - push literal char/byte on stack
// + - add literal number on stack
// /
// : - start of inline code
// ; - EXIT (not next)
// < - print string at address following
// ? - print literal string

// B - Binary Search (sorted list after)
// C - Commando (linear search) rel JMP
// D - Direct JMP table
// G - On X Goto (n, 0,1,2...,n-1, defaultcode)

// K - Kall
// O - OS

// R - Restore registers on stack
// S - Save registers on stack
// T - Table lookup (table after)
// W - Wait

// Z - Zero/Fill
// [ - Begin/Start
// \ - Slash/Remove/Delete
// _ - Longname/Under

// b
// c
// d
// g

// k
// o

// r
// s
// t
// w

// z
// {
// |
// DEL (0xf)


02, 03, 04, 07
0a, 0b, 0c, 0f

12, 13, 14, 17,
1a, 1b, 1c, 22, //  ..."   - good for inline str!
23, 27, 2b, 2f, //  #'+/

32, 33, 34, 37, //  2347
3a, 3b, 3c, 3f, //  :;<?

42, 43, 44, 47, //  BCDG
    4b,     4f, //   K O - look like 0...

52, 53, 54, 57, //  RSTW
5a, 5b, 5c, 5f, //  Z[\_

62, 63, 64, 67, //  bcdg
    6b,     6f, //   k o

72, 73, 74, 77, //  rstw
7a, 7b, 7c, 7f, //  z{| DEL

82, 83,     87,
    8b,     8f,

92, 93,     97,
    9b, 9c, 9f,

    a3,     a7,
    ab,     af,

b2, b3,     b7, //  23 7 (inverse video?)
    bb,     bf, //   ; ?

c2, c3,     c7, //    and so on...
    cb,     cf,

d2, d3, d4, d7,
da, db, dc, df,

e2, e3,     e7,
    eb,     ef,

f2, f3, f4, f7,
fa, fb, fc, ff,



// System request w BRK
// n: must be choosen not to ber an OP-code!
// 
// SYS() with no arg MUST be followed by
// an OP-code, this is the "default" case
// to save to do an implicit NEXT!
function SYS(n) {
  // make sure BRK pushed address won't be
  // 00 because then we can't dec low byte
  // to get address. This simplifies code,
  // and gives speed-up.
  if ((jasm.address()+2) % 256 == 0) {
    NOP();
  }

  if (typeof n === 'undefined') {
  }
}

// generate this before DEFAULT code!
// (so it'll fall-through...)
function SYS_HANDLER() {
  
  // save registers A,X,Y,P to ZP 2,3,4,5
  STAZ(2),STXZ(3),STYZ(4)

  // Save status register first
  PLA(),STAZ(5);

  // copy BRK return address to ZP 0,1
  // decrease by one; make it point
  // at "n" after BRK.
  PLA(),TAX(),DEX(),STXZ(0); // lo
  PLA(),STAZ(1); // hi

  // load "n"
  LDXN(0);
  LDAXI(0);
  INX();
  // A is now "n", X=0
  
  // inline ':'-definition!
  CMPN(ord(':')),BNE('_SYS_not_:'); {
  
  } L('_SYS_not_:');


  // inline ':'-definition!
  CMPN(ord(':')),BNE('_SYS_not_:'); {
  
  } L('_SYS_not_:');


  // DEFAULT ("n' is an OP-code)
  // => NEXT()
  //BNE('NEXT');

  // FALLTHROUGH to 'NEXT'!
}
