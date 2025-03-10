// Bouncy spites in hires graphics

// This is a prototype of ORIC ATMOS hires sprites.
//
// * N sprites

#define N 7
//#define N 10
//#define N 1

// * higher number sprite is above lower numbers
//   (drawing order low-high)

// * 8 sprites collision detection

// #define COLLISION

// * optional protected foreground (sprites "behind")
//    7) inverse hi-bit set = don't overwrite
//       23-25% speed-loss w OVERWRITE (OVERWRITE)
//       faster w more foreground!

//#define PROTECT_HIBIT

//    6) 6th bit==0 (== not normal pixels)
//       ??% speed-loss (w OVERWRITE)a

//#define PROTECT_6BIT

// - 3 methods of update (TODO: definable/sprite)
//    w) OVERWRITE (bitblt)
//       Use: when background empty
//            many small (?)
//            non-overlapping sprites (otherwise flickrs)
//            all sprites moving (fast)
//            (ink) color attributes ok
//               (don't mix with protect?)

#define COLORATTR

//    x) XORWRITE (and undraw, 2x cost basically)
//       Use: preserve background (inverts sprite pixels)
//            sprites moves occasionally
//            no color attributes
//          TODO: clever update: merge old+new
//    m) MASKWRITE (using mask, 4x?)
//       Use: using mask for precision-sprites
//            few detailed (main character?)
//            perfect overlap w other sprites
//            can be transparent
//            preserves background
//          TODO: save background
//          TODO: color attributes

// "Tomorrow, tomorrow, tomorrow".... story girl boy...
// creating movie, diable, fictional RPG gmae inside the novel - erh???

#define MAIN
#include "../hires-raw.c"

char T,nil,doapply1,print;

#include "../bits.h"

// To scroll sideways need one empty cell to the right
#define SCROLLABLE

//#define BIGG

//#define WIDER
//  7.39fps loss of fps -30% fps
//  8.29fps w drawsprite loop in asm
// 10.62fps - normal xor
// 12.73fps !- normal xor w drawsprite loop in asm!

// TALLER
//  6.13fps ever more costly: -42% fps
//  7.57fps w - drawsprite loop in asm!
// 10.62fps - normal xor

// ----------------------------- SPRITES

#define _BLACK  0,
#define _RED__  1,
#define _GREEN  2,
#define _YELLO  3,
#define _BLUE_  4,
#define _MAGN_  5,
#define _CYAN_  6,
#define _WHITE  7,

#define IBLACK  128+0,
#define IRED__  128+1,
#define IGREEN  128+2,
#define IYELLO  128+3,
#define IBLUE_  128+4,
#define IMAGN_  128+5,
#define ICYAN_  128+6,
#define IWHITE  128+7,


char oric_thin[]= {
  6, 9,
__xxxx x_x_xx xxxx__ _x___x xxxx__ ______
_x____ _x__x_ ____x_ _x__x_ ____x_ ______
x_____ x_x_x_ _____x _x_x__ ______ ______
x____x __x_x_ ____x_ _x_x__ ______ ______
x___x_ __x_xx xxxx__ _x_x__ ______ ______
x__x__ __x_x_ xx____ _x_x__ ______ ______
_xx___ _x__x_ __xx__ _x__x_ ____x_ ______
_xxxxx x___x_ ____xx _x___x xxxx__ ______
xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx ______
66
};

/*
// TODO: cannot have colors in the middle...
char oric_thin_color[]= {
  7, 10,
_WHITE __xxxx x___xx xxxx__ _xx___ xxxxx_ ______
_RED__ ______ xx____ _WHITE _xx__x _____x ______
_WHITE x_____ __x_xx _____x _xx_x_ ______ ______
_RED__ ____xx _WHITE ____x_ _xx_x_ ______ ______
_WHITE x_____ __x_xx xxxx__ _xx_x_ ______ ______
_RED__ ___xx_ _WHITE xx____ _xx_x_ ______ ______
_WHITE x_____ __x_xx _xxx__ _xx_x_ ______ ______
_RED__ _xx___ _WHITE __xxx_ _xx__x _____x ______
_WHITE xxxxxx x___xx ____xx _xx___ xxxxx_ ______
_RED__ xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx ______
66
};
*/

char oric_thin_color[]= {
  7, 12,
_WHITE __xxxx x___xx xxxx__ _xx___ xxxxx_ ______
_RED__ _____x xxxx__ ______ ______ ______ ______
_WHITE xx____ _xx_xx ___xx_ _xx_xx ____xx ______
_RED__ ____xx xx____ ______ ______ ______ ______
_WHITE xx____ _xx_xx xxxx__ _xx_xx ______ ______
_RED__ ___xxx x_____ ______ ______ ______ ______
_WHITE xx____ _xx_xx _xxx__ _xx_xx ____xx ______
_RED__ __xxxx ______ ______ ______ ______ ______
_WHITE _xxxxx xx__xx ___xxx _xx___ xxxxx_ ______
_RED__ _xxx__ ______ ______ ______ ______ ______
_RED__ _xxxxx xxxxxx xxxxxx xxxxxx xxxxxx ______
_RED__ xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx ______
66
};

char oric_wide_color[]= {
  9, 12,
_CYAN_ __xxxx IIIIxx __xxxx IWHITE ___xx_ ___xxx xxxxx_ ______
_RED__ ______ ___xx_ _WHITE ______ x__xx_ _xx___ _____x ______
_WHITE xx____ ______ x_xx__ ______ x__xx_ _xx___ ______ ______
_RED__ ______ _xx___ _WHITE ______ x__xx_ _xx___ ______ ______
_WHITE xx____ ______ x_xxxx xxxxxx ___xx_ _xx___ ______ ______
_RED__ _____x x_____ _WHITE _xx___ ___xx_ _xx___ ______ ______
_WHITE xx____ ______ x_xx__ __xx__ ___xx_ _xx___ ______ ______
_RED__ ___xxx _WHITE x_xx__ ___xx_ ___xx_ _xx___ ______ ______
_WHITE x_____ ______ x_xx__ ____xx ___xx_ _xx___ _____x ______
_CYAN_ IxxIII IWHITE x_xx__ _____x x__xx_ __xxxx xxxxx_ ______
_RED__ xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx ______
_RED__ xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx ______
66
};


char sinclair_color[]= {
  10, 7,
_WHITE ______ _x____ ______ ______ ___x__ ______ _x____ ______ ______
_WHITE ______ ______ ______ ______ ___x__ ______ ______ ______ ______
_WHITE xxxxxx x_x_xx xxxxxx _xxxxx xx_x_x xxxxxx _x_xxx xxxx__ ______
_YELLO x_____ __x_x_ _____x _x____ ___x__ _____x _x_x__ ______ ______
_YELLO xxxxxx x_x_x_ _____x _x____ ___x_x xxxxxx _x_x__ ______ ______
_GREEN ______ x_x_x_ _____x _x____ ___x_x _____x _x_x__ ______ ______
_CYAN_ xxxxxx x_x_x_ _____x _xxxxx xx_x_x xxxxxx _x_x__ ______ ______
66
};

char c64_color[]= {
  7, 13,
_CYAN_ ______ xxxxxx xx____ ______ ______ ______
_CYAN_ ____xx xxxxxx xx____ ______ ______ ______
_CYAN_ __xxxx xxxxxx xx____ xxxxx_ ____xx ______
_CYAN_ _xxxxx ______ _____x _____x ___x_x ______
_CYAN_ xxxx__ ______ _____x ______ __x__x ______
_CYAN_ xxxx__ ______ _____x ______ __x__x ______
_CYAN_ ______ ______ _____x xxxxx_ _xxxxx ______
_RED__ xxxx__ ______ _____x _____x _xxxxx ______
_RED__ xxxx__ ______ _____x _____x _xxxxx ______
_RED__ xxxx__ ______ _____x _____x ____x_ ______
_RED__ __xxxx xxxxxx xx____ xxxxx_ ____x_ ______
_RED__ ____xx xxxxxx xx____ ______ ______ ______
_RED__ ______ xxxxxx xx____ ______ ______ ______
66
};

char disc[]= {

#ifdef BIGG 

#ifdef WIDER
  24/6*2, 24,
//123456 123456 123456 123456
  ______ ______ ______ ______ ______ ______ ______ _____x
  ______ ______ ______ ______ ______ ______ ______ ______
  ______ ______ ______ ______ ______ ______ ______ ______
  ______ ___xxx xxx___ ______ ______ ______ ______ ______
  ______ _xx___ ___xx_ ______ ______ ______ ______ ______
  ______ x_____ _____x ______ ______ ______ ______ ______
  _____x ______ ______ x_____ ______ ______ ______ ______
  ____x_ ______ ______ _x____ ______ ______ ______ ______
  ____x_ ______ ______ _x____ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ___x__ ______ ______ __x___ ______ ______ ______ ______
  ____x_ ______ ______ _x____ ______ ______ ______ ______
  ____x_ ______ ______ _x____ ______ ______ ______ ______
  _____x ______ ______ x_____ ______ ______ ______ ______
  ______ x_____ _____x ______ ______ ______ ______ ______
  ______ _xx___ ___xx_ ______ ______ ______ ______ ______
  ______ ___xxx xxx___ ______ ______ ______ ______ ______
  ______ ______ ______ ______ ______ ______ ______ ______
  ______ ______ ______ ______ ______ ______ ______ ______
  ______ ______ ______ ______ ______ ______ ______ ______

// - bitmask
//123456 123456 123456 123456
//  77,
  42,
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxx_
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx x_____ _____x xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx ______ ______ xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxx_ ______ ______ _xxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxx__ ______ ______ __xxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxx__ ______ ______ __xxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx

  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxx___ ______ ______ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxx__ ______ ______ __xxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxx__ ______ ______ __xxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxx_ ______ ______ _xxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx ______ ______ xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx x_____ _____x xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx xxxxxx
#else // WIDER else TALLER
  24/6, 24*2,
//123456 123456 123456 123456
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ___xxx xxx___ ______
  ______ _xx___ ___xx_ ______
  ______ x_____ _____x ______
  _____x ______ ______ x_____
  ____x_ ______ ______ _x____
  ____x_ ______ ______ _x____
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ____x_ ______ ______ _x____
  ____x_ ______ ______ _x____
  _____x ______ ______ x_____
  ______ x_____ _____x ______
  ______ _xx___ ___xx_ ______
  ______ ___xxx xxx___ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______

  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______


// - bitmask
//123456 123456 123456 123456
//  77,
  42,
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx
  xxxxxx x_____ _____x xxxxxx
  xxxxxx ______ ______ xxxxxx
  xxxxx_ ______ ______ _xxxxx
  xxxx__ ______ ______ __xxxx
  xxxx__ ______ ______ __xxxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx

  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxxx__ ______ ______ __xxxx
  xxxx__ ______ ______ __xxxx
  xxxxx_ ______ ______ _xxxxx
  xxxxxx ______ ______ xxxxxx
  xxxxxx x_____ _____x xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx

  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx

#endif // WIDER
#else // BIGG else ...
#ifdef SCROLLABLE
  // Notice empty column to the right,
  // this is so dimensions are same when scrolled
  // copies to be made
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ xxxxxx ______ ______
  ____xx ______ xx____ ______
  ___x__ ______ __x___ ______
  __x___ ______ ___x__ ______
  _x____ ______ ____x_ ______
  _x____ ______ ____x_ ______
  x_____ ______ _____x ______
  x_____ ______ _____x ______
  x_____ ______ _____x ______
  x_____ ______ _____x ______
  x_____ ______ _____x ______
  x_____ ______ _____x ______
  _x____ ______ ____x_ ______
  _x____ ______ ____x_ ______
  __x___ ______ ___x__ ______
  ___x__ ______ __x___ ______
  ____xx ______ xx____ ______
  ______ xxxxxx ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______

// - bitmask
//123456 123456 123456 123456
//  77,
  42, // indicator of bitmask following
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx ______ xxxxxx xxxxxx
  xxxx__ ______ __xxxx xxxxxx
  xxx___ ______ ___xxx xxxxxx
  xx____ ______ ____xx xxxxxx
  x_____ ______ _____x xxxxxx
  x_____ ______ _____x xxxxxx
  ______ ______ ______ xxxxxx
  ______ ______ ______ xxxxxx
  ______ ______ ______ xxxxxx
  ______ ______ ______ xxxxxx
  ______ ______ ______ xxxxxx
  ______ ______ ______ xxxxxx
  x_____ ______ _____x xxxxxx
  x_____ ______ _____x xxxxxx
  xx____ ______ ____xx xxxxxx
  xxx___ ______ ___xxx xxxxxx
  xxxx__ ______ __xxxx xxxxxx
  xxxxxx ______ xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx

#else // SCROLLABLE

  24/6, 24,
//123456 123456 123456 123456
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ___xxx xxx___ ______
  ______ _xx___ ___xx_ ______
  ______ x_____ _____x ______
  _____x ______ ______ x_____
  ____x_ ______ ______ _x____
  ____x_ ______ ______ _x____
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ___x__ ______ ______ __x___
  ____x_ ______ ______ _x____
  ____x_ ______ ______ _x____
  _____x ______ ______ x_____
  ______ x_____ _____x ______
  ______ _xx___ ___xx_ ______
  ______ ___xxx xxx___ ______
  ______ ______ ______ ______
  ______ ______ ______ ______
  ______ ______ ______ ______

// - bitmask
//123456 123456 123456 123456
//  77,
  42,
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx
  xxxxxx x_____ _____x xxxxxx
  xxxxxx ______ ______ xxxxxx
  xxxxx_ ______ ______ _xxxxx
  xxxx__ ______ ______ __xxxx
  xxxx__ ______ ______ __xxxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx

  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxx___ ______ ______ ___xxx
  xxxx__ ______ ______ __xxxx
  xxxx__ ______ ______ __xxxx
  xxxxx_ ______ ______ _xxxxx
  xxxxxx ______ ______ xxxxxx
  xxxxxx x_____ _____x xxxxxx
  xxxxxx xxx___ ___xxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
  xxxxxx xxxxxx xxxxxx xxxxxx
#endif SCROLLABLE

#endif BIGG
};



// - https://shop.startrek.com/products/star-trek-the-original-series-beverage-containment-system-personalized-travel-mug
char enterprise[]= {
  11, 16,
  _111111 _111111 _111111 _111111 _111111 _1_____ _______ _______ _______ _______ _______
  _111111 _111111 _111111 _111111 _111111 _1_____ _______ _______ ______1 _1_____ _______
  __11111 _111111 _111111 _111111 _111111 _11____ _______ _______ ____111 _111___ _______
  ___1111 _111111 _111111 _111111 _111111 _11____ _______ _______ _111111 _111111 _______
  _______ _______ _______ _______ _11____ _______ _111111 _111111 _111111 _111111 _1111__
  _______ _______ _______ _______ _11____ _______ _111111 _111111 _111111 _111111 _1111__
  _______ _______ _______ _______ _11____ _____11 _11111_ _______ _111111 _111111 _______
  _______ _______ _______ _______ _11____ ___1111 _111___ _______ ____111 _1111__ _______
  _______ _______ _______ _______ _111111 _111111 _11____ _______ ______1 _11____ _______
  _______ _______ _______ ____111 _111111 _111111 _111___ _______ _______ _1_____ _______
  _______ _______ _______ ____111 _111111 _111111 _111_1_ _______ _______ _______ _______
  _______ _______ _______ ___1111 _111111 _111111 _11111_ _______ _______ _______ _______
  _______ _______ _______ ___1111 _111111 _111111 _111111 _1_____ _______ _______ _______
  _______ _______ _______ _______ _111111 _111111 _11111_ _______ _______ _______ _______
  _______ _______ _______ _______ __11111 _111111 _111_1_ _______ _______ _______ _______
  _______ _______ _______ _______ ____111 _111111 _111___ _______ _______ _______ _______

/*
  // nice but very narrow... not good proportions

  6, 15,
  xxxxxx xxxxxx xxxxxx x_____ ______ ______
  _xxxxx xxxxxx xxxxxx xx____ __xx__ ______
  __xxxx xxxxxx xxxxxx x_____ xxxxx_ ______
  ______ ______ xx____ ___xxx xxxxxx xxxxxx
  ______ ______ xx____ ___xxx xxxxxx xxxxxx
  ______ ______ xx____ __xxxx x__xxx xxx___
  ______ ______ xx____ _xxxxx ____xx x_____
  ______ ______ xxxxxx xxxxx_ _____x x_____
  ______ ___xxx xxxxxx xxxxxx x_____ ______
  ______ ___xxx xxxxxx xxxxxx x_x___ ______
  ______ __xxxx xxxxxx xxxxxx xxxx__ ______
  ______ __xxxx xxxxxx xxxxxx x_x___ ______
  ______ ______ xxxxxx xxxxxx x_____ ______
  ______ ______ _xxxxx xxxxxx ______ ______
  ______ ______ ___xxx xxxxx_ ______ ______
*/
};

// TODO: change from _111111 to xxxxxx
//    and _BLACK_ to _BLACK
#define _BLACK_  0,
#define _RED___  1,
#define _GREEN_  2,
#define _YELLOW  3,
#define _BLUE__  4,
#define _MAGN__  5,
#define _CYAN__  6,
#define _WHITE_  7,

char color_enterprise[]= {
  13, 16,
  _RED___ _111111 _111111 _111111 _111111 _111111 _1_____ _______ _______ _______ _______ _______ ______
  _RED___ _111111 _111111 _111111 _111111 _111111 _1_____ _______ _______ ______1 _1_____ _______ ______
  _MAGN__ __11111 _111111 _111111 _111111 _111111 _11____ _______ _______ ____111 _111___ _______ ______
  _MAGN__ ___1111 _111111 _111111 _111111 _111111 _11____ _______ _______ _111111 _111111 _______ ______
  _MAGN__ _______ _______ _______ _______ _11____ _______ _111111 _111111 _111111 _111111 _1111__ ______
  _YELLOW _______ _______ _______ _______ _11____ _______ _111111 _111111 _111111 _111111 _1111__ ______
  _YELLOW _______ _______ _______ _______ _11____ _____11 _11111_ _______ _111111 _111111 _______ ______
  _YELLOW _______ _______ _______ _______ _11____ ___1111 _111___ _______ ____111 _1111__ _______ ______
  _GREEN_ _______ _______ _______ _______ _111111 _111111 _11____ _______ ______1 _11____ _______ ______
  _GREEN_  _______ _______ _______ ____111 _111111 _111111 _111___ _______ _______ _1_____ _______ ______
  _CYAN__ _______ _______ _______ ____111 _111111 _111111 _111_1_ _______ _______ _______ _______ ______
  _CYAN__ _______ _______ _______ ___1111 _111111 _111111 _11111_ _______ _______ _______ _______ ______
  _CYAN__ _______ _______ _______ ___1111 _111111 _111111 _111111 _1_____ _______ _______ _______ ______
  _BLUE__ _______ _______ _______ _______ _111111 _111111 _11111_ _______ _______ _______ _______ ______
  _BLUE__ _______ _______ _______ _______ __11111 _111111 _111_1_ _______ _______ _______ _______ ______
  _BLUE__  _______ _______ _______ _______ ____111 _111111 _111___ _______ _______ _______ _______ ______
};

char BITSRIGHT[]= { 0x3f, 0x1f, 0x0f, 0x07, 0x03, 0x01};
// TODO: 7... lol
char BITSLEFT[] = { 0x00, 0x20, 0x30, 0x38, 0x3c, 0x3e, 0x3f};

// 371cs/100
// 539cs/100 for pixel-left-right (/ 1.0 0.0539) = 18 bps
// 496cs move s, e out
// 495cs row-addr...
void box(char x, char y, char w, char h) {
  char i, b, * l= HIRESSCREEN+ (5*(y-1))*8 + div6[x], * p= l;
  char s= BITSRIGHT[mod6[x]], e= BITSLEFT[mod6[x+w]+1];

  b= div6[w];
  do {
    i= b;
    p= (l+=40)-1;
    *++p ^= s;
    if (i) {
      while(--i) *++p ^= 63-32-1;
      *++p ^= e;
    }
  } while(--h);
}

typedef struct sprite {
  // TODO: higher resolution than this
  int x, y;
  signed char dx, dy; // this could be subpixel/frame

  // current (TODO: remove?)
  char* bitmap;
  char* mask;

  // TODO: move out?
  char* shbitmap[6];
  char* shmask[6];

  // TODO: 
  char bitmaps[6];
  char z; // z order
} sprite;

// Possible ideas:
// - https://chipmunk-physics.net/release/ChipmunkLatest-Docs/#CollisionDetection
// - https://en.m.wikipedia.org/wiki/Collision_detection

// TODO: detect when drawing! (if not 64 then clash?)
//   (requires restore?)
// TODO: use a single pixel detector(?)
//
// TODO: make decision of detection only
//   (assign bit i to sprite only if required)
// TODO: type of sprites, id of sprite
// TODO: detect fine bitmap clash (shifted AND?)
// TODO: detect center of "gravity" collision/distance
// TODO: calculate pixel center of gravity position
// TODO: use callback on sprites "overlap()"
// TODO: pixelbased bounding box to refine overlap
// TODO: and pixels/mask
// TODO: add Z-dimension, further filters it out
// TODO: more than 8 objects?
// TODO: pixel object collision detect (cent of grav?)
// TODO: grid datastructure (expensive)

// Bitmap on X and Y colission detection
//
// main idea:
// - not a grid
// - just 8 sprites - 1 byte col and row
//   40 cols + 25 rows (basically text-screen!)
// - just a bitmap for X/6 and Y/8 extent of sprite
// - sprite bit i is set in Xmap and Ymap
//   for all it's X and Y cell locations
// - updated "every cycle" (all redrawn?)
// - when updating a sprite
//   a) OR the bitmaps for all X positions
//   b) OR the bitmaps for all Y positions
//   c) AND those two resulting bitmaps
//   d) if more than one bit set (in both)
//      then there is a:
//          BOUDNING BOX COLLISION!
//   e) dispatch a a finer checker on either
//      objects (callbacks?)

#ifdef COLLISION

char spxloc[40], spyloc[25];

// This one i O(n^2) use bits method instead?
char spritecollision(sprite* a, sprite* b) {
  if (a->x > b->x) return -spritecollision(b, a);
  {
    int ax1= a->x, ax2= ax1 + a->bitmap[0]*6;
    int ay1= a->y, ay2= ay1 + a->bitmap[1];

    int bx1= b->x, bx2= bx1 + b->bitmap[0]*6;
    int by1= b->y, by2= by1 + b->bitmap[1];

    char r;

    // we know: ax1 < bx1

    // no collision if a << b
    if (ax2 <= bx1) return 0;

    // we know: x-overlaps
    //
    // Possiblities:
    //             00000          00000
    //                    1111111  
    //      55555    77   1111111
    //  ....55555....77...1111111
    //  .............77...1111111
    //  .............77......
    //  .....44444...77......     0000
    //  .....44444...77...8888888
    //  .............77...8888888
    //  .............77......
    //  .............77......
    //  ....666......77....222222
    //      666      77    222222
    //          000                00000
    //
    //
    if (by2 <= ay1) return 0; // above
    if (ay2 <= by1) return 0; // below
    r= 0;
    // TODO: near overlap? adjacent/touch?

    // overlapping
    if (by1 <= ay1) r+= 1; // upper & 1
    if (by2 >= ay2) r+= 2; // lower & 2
    if (bx2 <= ax2) r+= 4; // inner & 4
    return r? r: 8;        // right & 8
  }
}

#endif //COLLISION

int ndraw= 0;

// 409 cs/100 fps? 1.ffps
// 192 cs - memcpy, memset
// 191 cs - sp+= 40 inline
// 201 cs - gfill instead of memset... 5%
// 195 cs - p+=40 in gfill, no calc in erase (2.6%)
// 113 cs - NO ERASE!
// 127 cs - clever Y-erase
// 154 cs - 11 x 16 before 6 x 15 (/ (* 11.0 16) (* 6.0 15)) = 2x!
//
// see main for new bench using 1001 updates

void drawsprite(register sprite* s) {
  static char w, h, *l;
  static char * sp, * msk;
  static char m;
  static char ww;
  static char hh;

  m= mod6[s->x];
  sp=  s->shbitmap[m];
  msk= s->shmask[m];
  w= *sp; h= sp[1];

  ww= 40-w; hh= h;
  l= rowaddr[s->y] + div6[s->x];

  // TODO: clipping?
  *(int*)0x90= sp+2; // sprite byte data
  *(int*)0x92= l;    // screen address + y offset
  *(int*)0x94= msk;  // mask byte data

  // -- ASM: a memcpy w strides, lol (w<256)
  // (be careful to change!)

  switch(0) {

  case 0:
    // - old style overwrite - very fast

    asm("ldy #0"); // y= sprite byte data index
    asm("clc");    // set it for once top!

  nextrow0:
    asm("ldx %v", w); // x= w bytes width

  nextcell0:

#ifdef PROTECT_HIBIT    
    // skip if hibit set
    asm("lda ($92),y"); // a= l[y]
    asm("bmi %g", skip0);
#endif // PROTECT_HIBIT
#ifdef PROTECT_6BIT
    // skip if hibit set
    asm("lda ($92),y"); // a= l[y]
    asm("rol");         // M= a&6bit lol
    asm("bpl %g", skip0);
#endif // PROTECT_6BIT

    // draw
    asm("lda ($90),y"); // a = sp[y];
    asm("sta ($92),y"); // l[y]= a;
  skip0:

    // step
    asm("iny"); // ++y next byte
    asm("dex"); // --x nextcell
    asm("bne %g", nextcell0);

    // step line
    // *(int*)0x92+= 40-w (= ww);
    asm("clc"); // TODO: set it for once at top!
    asm("lda $92");
    asm("adc %v", ww);
    asm("sta $92");
    asm("bcc %g", nott0);

    asm("inc $93");
    asm("clc"); // make it always clear!
  nott0:

    // ... while(--h); // more lines
    asm("dec %v", hh);
    asm("bne %g", nextrow0);
    break;

  case 1:
    // - xor draw/undraw (doesn't disturb backgr)

    asm("ldy #0"); // y= sprite byte data index
    asm("clc"); // set it for once top!

  nextrow1:
    asm("ldx %v", w); // x= w bytes width

  nextcell1:
    // load screen value
    asm("lda ($92),y"); // a = l[y];

    // draw
    asm("eor ($90),y"); // a^= sp[y]; // draw+undraw
    asm("ora #$40");
    asm("sta ($92),y"); // l[y]= a;
  skip1:

    // step
    asm("iny"); // ++y next byte
    asm("dex"); // --x nextcell
    asm("bne %g", nextcell1);

    // step line
    // *(int*)0x92+= 40-w (= ww);
    asm("clc"); // TODO: set it for once at top!
    asm("lda $92");
    asm("adc %v", ww);
    asm("sta $92");
    asm("bcc %g", nott1);

    asm("inc $93");
    asm("clc"); // make it always clear!
  nott1:

    // ... while(--h); // more lines
    asm("dec %v", hh);
    asm("bne %g", nextrow1);
    break;

  case 2:
    // - draw w mask - expensive!

    asm("ldy #0"); // y= sprite byte data index
    asm("clc"); // set it for once top!

  nextrow2:
    asm("ldx %v", w); // x= w bytes width

  nextcell2:
    // load current screen value
    asm("lda ($92),y"); // a = l[y];

    // skips "foreground"
    if (0) {
      // skip inverted cells
      // (case 0): 1837cs - 1680 = 157cs 16% overhead
      asm("bmi %g", skip2);
    } else {
      // skip anything w bit 6 == zero
      // (case 0): 1881cs - 1680 = 201cs 21% overhead
      //  [0,63] (and +128) = non-normal pixels
      asm("rol");
      asm("bpl %g", skip2);
    }

    // draw
    asm("and ($94),y"); // a&= mask[y];
    asm("ora ($90),y"); // a|= sp[y];
    asm("ora #$40");
    asm("sta ($92),y"); // l[y]= a;
  skip2:

    // step
    asm("iny"); // ++y next byte
    asm("dex"); // --x nextcell
    asm("bne %g", nextcell2);

    // step line
    // *(int*)0x92+= 40-w (= ww);
    asm("clc"); // TODO: set it for once at top!
    asm("lda $92");
    asm("adc %v", ww);
    asm("sta $92");
    asm("bcc %g", nott2);

    asm("inc $93");
    asm("clc"); // make it always clear!
  nott2:

    // ... while(--h); // more lines
    asm("dec %v", hh);
    asm("bne %g", nextrow2);
    break;

  }

}

// graphics Pixel fill
// (copied modifyed from hires-raw.c/gfill)
// (don't change attributes/hibit)

// TODO: specialize for spriteerase
//       a) don't want to load fillvalue v all the time
//       b) to go next line step 40-w like drawsprite
//       c) count using var not register
void gpfill(char c, char r, char w, char h, char v) {
  // TODO: adjust so not out of screen?
  // TODO: can share with lores?
  static char ww, hh, vv;

  if (r>= 200) return;
  //char* p= HIRESSCREEN+(5*r)*8+c;
  ww= w; hh= h; vv= v;

  *(int*)0x90= rowaddr[r]+c -1; // -1 because y=w

  asm("ldx %v", hh);

 nextrow:
  //for(; h; --h) {
    //for(cell= w; cell; --cell) p[cell]=v; // 619hs
    //memset(p+= 40, v, w); // 100x 10x10 takes 337hs !

    // specialized memset (w<256)
    asm("lda %v", vv);
    asm("ldy %v", ww);

  next:

#ifdef PROTECT_HIBIT    
    // skip if hibit set
    asm("lda ($90),y"); // a= l[y]
    asm("bmi %g", skip);
#endif // PROTECT_HIBIT
#ifdef PROTECT_6BIT
    // skip if hibit set
    asm("lda ($90),y"); // a= l[y]
    asm("rol");         // M= a&6bit lol
    asm("bpl %g", skip);
#endif // PROTECT_6BIT

    // TODO: move X to var?
    asm("lda %v", vv); // TODO: this slows down...
    asm("sta ($90),y"); // l[y]= 0x40;
  skip:

    // next col
    asm("dey");
    asm("bne %g", next);

    // p+= 40;
    // *(int*)0x90+= 40;
    asm("clc");
    asm("lda #40");
    asm("adc $90");
    asm("sta $90");
    asm("lda $91");
    asm("adc #00");
    asm("sta $91");
    
    // while(--h);
    asm("dex");
    asm("bne %g", nextrow);
}


// TODO: move into "movesprite()"
void erasesprite(sprite* s, int newx, signed char dy) {
  static char xdiv;
  static char* sp;
  xdiv=div6[s->x];
  sp= s->bitmap;

  // for xor, lol
  //drawsprite(s); return;

  // TODO: this doesn't handle overlapping. mask?
  // TODO: clipping?

  // clever
  if (s->dx == 0 || div6[newx]==xdiv) {
    // same x, or same cell (in height)

    // - clear vertically only
    if (!dy) return; // not moved!
    if (dy > 0) {
      // clear below
      gpfill(xdiv, s->y, *sp, dy, 64);
      return;
    } else {
      // clear above
      gpfill(xdiv, s->y+dy+sp[1], *sp, -dy, 64);
      return;
    }
  }
  // TODO: small move left/right
  //} else if one cell to the left
  //} else if one cell to the right

  // Otherwise: fallthrough:

  // -- clear all (flickers little)
  {
    char w= *sp, h= *++sp;
    gpfill(xdiv, s->y, w, h, 64);
    return;
  }
}

#define Z 37

void b(char x, char y) {
  box(x, y, Z, Z);
}

sprite sploc[N];

//#define DISPCOLL 1
#define DISPCOLL 0

int colls= 0;

void spmove() {
  static char i, j, k, c, cx, cy, *px, *py;
  static int newx, newy;
  register sprite* s;
  register char* sp;
  static char spbit= 1;

  // clear sprite locations
  assert(N<8);

#ifdef COLLISION
  memset(spxloc, 0, sizeof(spxloc));
  memset(spyloc, 0, sizeof(spyloc));
  if (DISPCOLL) {
    gfill(0, 190, 40, 8, 64);
    gfill(div6[230], 0, 2, 200, 64);
  }
#endif // COLLISION

  gotoxy(0, 25);

  for(i=0; i<N; ++i) {
    s= sploc+i;
    sp= s->bitmap;

    if (!s->dx && !s->dy) continue;

    // undraw
    // TODO: undraw in opposite order...lol
    // TODO: or, have "backing" snapwhot 8000bytes to pull bytes from...

    // TODO: movesprite();
    
    // update pos
    newx= s->x; newy= s->y;

    // this faster than while? lol
  rex2:
    if ((newx+= s->dx) + 6*sp[0] >= 240 || newx < 0) {
      s->dx= -s->dx; goto rex2;
    }
  rex3:
    if ((newy+= s->dy) + sp[1] >= 200 || newy < 0) {
      s->dy= - s->dy; goto rex3;
    }

    erasesprite(s, newx, newy - s->y);

    // move
    s->x= newx;
    s->y= newy;

    // draw
    ++ndraw;
    drawsprite(s);
      
#ifdef COLLISION
    // collision?
    // disabled:  990cs
    //  enabled: 1760cs !!!
    //           1679cs (w print, sp[0] or k moved out)
    // 
    // doubles the cost - same as drawing sprite!
    // (can we put it inside the spritedraw?)
    // 
    // mark where the sprite is
    // (cheaper than boundary checking but still
    //  expensive)
    // TODO: make it incremental
    //   (together with erasesprite "clever" opt)
    px= spxloc+div6[newx];
    py= spyloc+(newy>>3);
    cx= 0;
    k= sp[0];
    for(j=0; j<k; ++j) {
      cx |= (px[j] |= spbit);
      if (DISPCOLL) {
        gcurx= newx+6*j; gcury= 190+i; gmode= 1; setpixel();
      }
    }
    cy= 0;
    k= sp[1]/8+1;
    for(j=0; j<k; ++j) {
      cy |= (py[j] |= spbit);
      if (DISPCOLL) {
        gcurx= 230+i; gcury= newy+j; gmode= 1; setpixel();
      }
    }
      
    //for(j=0; j<=i; ++j) {
    // 3856cs - 4x overhead!
    //c= spritecollision(s, sploc+i); 

    c= cx&cy;
    // more than one bit set
    if (c&(c-1)) {
      if (1) { // no print to see overhead
        //   print: 1640cs
        // noprint: 1654cs(?) (wow low overhead!)
        k= 1;
        for(j=0; j<8; ++j) {
          if (c & k) {
            putchar('0'+j);
            ++colls;
          }
          k<<= 1;
        }
      }
      putchar('.');
    }

#endif // COLLISION

    spbit<<= 1;
  } // next sprite
  
#ifdef COLLISION  
  if (DISPCOLL)
    for(i=0; i<40; ++i) {
      for(j=0; j<25; ++j) {
        c= spxloc[i] & spyloc[j];
        // more than one bit set?
        if (c&(c-1)) {
          px= HIRESSCREEN+j*8*40+i;
          for(k=0; k<8; ++k) {
            *px ^= 128; px+= 40;
          }
        }
      }
    }

  putchar('<');
#endif COLLISION
}

// shift one step right
void spriteshift(char* bm, char w, char h) {
  char j, * p= bm;
  unsigned int v= 0;
  //while(*p) { // lol, can do!
  do {
    v= 0; j= w;

    #ifdef COLORATTR
      ++p; --j;
    #endif // COLORATTR

    do {
      v<<= 6;
      v|= *p & 63;
      *p= ((v >> 1) & 63)| 64;
      ++p;
    } while(--j);
  } while(--h);
}

void initsprites(char n) {
  char i;

  // init sprites
  for(i=0; i<n; ++i) {
    sprite* s= sploc+i;

    // position
    s->x= 130-130/n*i;
    s->y= 180/n*i;

    //s->dx= 0;
    s->dx= +1;

    s->dy= +i*11/10+1;

    #ifdef COLORATTR
      switch(i%4) {
      case 0: s->bitmap= c64_color; break;
      case 1: s->bitmap= sinclair_color; break;
      case 2: s->bitmap= oric_thin_color; break;
      case 3: s->bitmap= color_enterprise; break;
      }
    #else
      s->bitmap= enterprise;
      s->bitmap= oric_thin;
    #endif // COLORATTR

    // - have mask?
    {
      int markpos= 2+ s->bitmap[0] * s->bitmap[1];
      s->mask= (42==s->bitmap[markpos])?
        s->bitmap+markpos+1: NULL;
    }

    // - create scrollable copies
    s->shbitmap[0]= s->bitmap;
    s->shmask[0]= s->mask;

    if (1)
    { char j; int bytes= s->bitmap[0] * s->bitmap[1] + 3;
      for(j=1; j<6; ++j) {
        char* nw= malloc(bytes);
        memcpy(nw, s->shbitmap[j-1], bytes);
        spriteshift(nw+2, s->bitmap[0], s->bitmap[1]);
        s->shbitmap[j]= nw;

        // TODO: make mask also use +2...
        if (s->mask) {
          nw= malloc(bytes);
          memcpy(nw, s->shmask[j-1], bytes);
          //spriteshift(nw, s->bitmap[0], s->bitmap[1]);
          s->shmask[j]= nw;
        } else {
          s->shmask[j]= NULL;
        }
      }
    }

    // show
    if (1)
    { char j;
      for(j=0; j<6; ++j) {
        s->bitmap= s->shbitmap[j];
        s->mask= s->shmask[j];
        if (s->bitmap) {
          //drawsprite(s);
          //cgetc();
          //erasesprite(s);
        }
      }
      if (s->shbitmap[0]) {
        s->bitmap= s->shbitmap[0];
        s->mask= s->shmask[0];
      }
    }

    drawsprite(s);
  }
}

// N=1:   915cs 109sp/s 10939cfps 
// N=2:   914cs 109sp/s  5481cfps
// N=4:   928cs 108sp/s  2704cfps
// N=7:                  1507cfps
// N=16:                  608cfps

// = (/ (* 11 16 1001 100) 751.0)

// FPS= 105/N !!! these are large 66x16=1056px sprites!

//                          w     h  N
// (/ (* 105.0 1056) (* (* 11 6) 16) 7) = 15.0 fps

// vic 64: 8 sprites 24x21


// N=7 1001 1836 cs 54 hsp/s 778 hfps
// N=7 1001 1446 cs 69 hsp/s 988 hfps - no erase... (-21%)

// - bigger than ever... 11*6 x 16 sprite N=7 sprites
//
// 1001: 2442cs 40sp/s 585cfps - full clear (flicker)
// 1001: 1835cs 54sp/s 779cfps - clever clear (+ 390cs)
// 1001: 1445cs 69sp/s 989cfps - no clear (traces) (21%)
 // 1001: 1699cs 58sp/s 841cfps - drawsprite static vars
//       1689 rowaddr used only initially
//       1627cs -Oi but memcpy still not inlined...
// 1001: 1127cs  88sp/s 1268cfps 13756 Bps (asm memcpy)
// 1001:  978cs 102sp/s 1462cfps 18013 Bps (gfill: asm for memset)
// 1001:  966cs 103sp/s 1480cfps 18237 Bps (gfill: all asm)
// 1001:  952cs 105sp/s 1502cfps 18505 Bps (gfill: value)
// 1001:  751cs 133sp/s 1904cfps 23458 Bps (erase: 27% overhead)
// 1001:  946cs 105sp/s 1511cfps (sprite s pass around)
// 1001: 1599cs  67sp/s  894cfps (xor, i.e. 2x drawsprite, asm)
// 1001: 1270cs  78sp/s 1125cfps (old style, erasesprite, +new asm drawsprite)
// ---- TODO: ^^^----- why is it slower? erasesprite flicker
// 1001:  914cs 109sp/s 1564cfps (eraseclever, asm:drawsrpite) +3.5fps!

// 1001: 1176cs  85sp/s 1215cfps (not moving x)
// 1001: 1169cs  85sp/s 1223cfps (smooth moving x)
//       1171cs  85sp/s 1221cfps 
//        980cs 102sp/s 1459cfps (erasesprite cell opt)
// 1001:  971cs 103sp/s 1472cfps 
// 1001:  961cs 104sp/s 1488cfps (statics in erasesp)
// 1001:  973cs 102sp/s 1469cfps (no protect)

// 1001: 1193cs  83sp/s 1198cfps (protect hibit, 23% w fore!)
// 1001: 1213cs  82sp/s 1178cfps (protect hibit: 25% no fore)
// 1001: 1252cs  79sp/s 1142cfps (protect 6bit: 27% w fore)
// 1001: 1272cs  78sp/s 1124cfps (protect 6bit: 31% no fore)
// 1001: 1283cs  84sp/s 1208cfps (7.5% faster! -"- register sprite, static)
// 1001: 1028cs  97sp/s 1391cfps (COLORATTR enterprise, 2 cols more)
// 1001:  903cs 107sp/s 1537cfps (no protect, no color)

//(/ 1272 973.0)


// collision: TODO: optimize
// 1001: 


// ORIC: 8 sprites 24x24
// (/ (* 105.0 1056) (* (* 4 6) 24) 8) = 24.0 fps!
void main() {
  unsigned int T;

  hires();
  gclear();

  // - draw background
  gfill(0, 0, 1, 200, 0+16+128); // paper

  // - draw foreground!

#ifdef COLORATTR
  // If all sprites have color, sometimes when they
  // overlap, attribute gets overwritten, so hide line!
  // OR define PROTECT_6BIT
  gfill(1, 0, 1, 200, 0+0 +128); // ink: black!
#else
  gfill(1, 0, 1, 200, 0+2 +128); // ink: green
#endif

#ifdef PROTECT_HIBIT
#if 1
  // horiz
  gpfill( 2,  0,  38,  6, 128+1+4+16+64);
  gpfill( 2, 194, 38,  6, 128+1+4+16+64);
  // vert
  gpfill(30,  0,  1, 200, 128+1+4+16+64);
  gpfill(10,  0,  1, 200, 128+1+4+16+64);
#endif
#endif // PROTECT_HIBIT

#ifdef PROTECT_6BIT
#if 1
  // horiz
  gpfill( 2,  0,  38,  6, 1+4+16+32);
  gpfill( 2, 194, 38,  6, 1+4+16+32);
  // vert
  gpfill(30,  0,  1, 200, 128+1+4+16+32);
  gpfill(10,  0,  1, 200, 128+1+4+16+32);
#endif
#endif // PROTECT_6BIT


  initsprites(N);


  T= time();
 again:
  while(ndraw<=1000) {
    spmove();

//cgetc();

    if (0) { // cost 10%?
      unsigned int X= T-time();
      gotoxy(0,25);
      printf("%d: %ucs %ldsp/s %ldcfps  ", ndraw, X, ndraw*100L/X, ndraw*10000L/N/X);
    }
  }

  if (1) {
    unsigned int X= T-time();
    long bytes= ndraw*enterprise[0]*enterprise[1];
    gotoxy(0,25);
    // TODO: Bps is all wrong? why?
    printf("%d: %ucs %ldsp/s %ldcfps %ldBps ", ndraw, X, ndraw*100L/X, ndraw*10000L/N/X, bytes*100L/X);
    printf(" COLLS=%d (should be 673)", colls);
  }

  cgetc();
  ndraw= -32766;
  goto again;
}

