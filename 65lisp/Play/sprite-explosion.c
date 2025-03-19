//#include "../bits.h"

// This is a sequence of 6 frames of explosion,
// it can be activated by moving 6 pixels starting
// from div6[x]= 0.

char explosion0[]= {
  5, 24,
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ______ ______ ______
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ______ ______ ______
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ______ ______ ______
_RED__ ______ ______ ______ ______
_YELLO ______ ___x_x x_____ ______
_WHITE ______ __x_x_ xxx___ ______
_RED__ ______ _____x ______ ______
_YELLO ______ ____xx _x____ ______
_WHITE ______ __xx_x _xx___ ______
_RED__ ______ ____x_ x__x__ ______
_YELLO ______ __x___ xx____ ______
_WHITE ______ _xx__x xxx___ ______
_RED__ ______ ____x_ x_____ ______
_YELLO ______ __x___ ______ ______
_WHITE ______ ______ ______ ______
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ______ ______ ______

};

char explosion1[]= {
  5, 24,
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ______ ______ ______
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ______ ______ ______
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ___xx_ xx__x_ ______
_RED__ ______ ____xx __x___ ______
_YELLO ______ __x_xx x_xx__ ______
_WHITE ______ ____x_ __xxx_ ______
_RED__ ______ __xx_x _x_x_x ______
_YELLO ______ ___x_x __xxx_ ______
_WHITE ______ xx___x _x_xxx ______
_RED__ ______ ___x_x x_xx__ ______
_YELLO ______ ____xx x_____ ______
_WHITE ______ _____x x_____ ______
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ______ ______ ______
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ______ ______ ______

};

char explosion2[]= {
  5, 24,
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ______ ______ ______
_RED__ ______ ______ ______ ______
_YELLO ______ ____x_ _x____ ______
_WHITE ______ _x_x__ x_x___ ______
_RED__ _____x ___x_x x_x_xx ______
_YELLO ___xx_ x___x_ xx__x_ ______
_WHITE __x_xx _x_xx_ __x_xx ______
_RED__ ____x_ _xx_x_ x_x_x_ ______
_YELLO _____x x_xx_x _x_x_x x_____
_WHITE _____x ___xx_ _xx___ xx____
_RED__ ____x_ __x_x_ xx_x_x ______
_YELLO ___x_x ___x_x x_xx_x x_____
_WHITE ______ _xx_x_ __x_x_ _x____
_RED__ ___xx_ x_xx_x xx___x ______
_YELLO ______ __x_x_ xx_xx_ x_____
_WHITE _____x _x_xx_ _xx__x _xx___
_RED__ ______ ____x_ x_x___ x_____
_YELLO ______ ______ x____x ______
_WHITE ______ ______ __x___ ______
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ______ ______ ______

};

char explosion3[]= {
  5, 24,
_RED__ ______ ___x_x xx____ ______
_YELLO ______ ______ ______ ______
_WHITE ______ ____x_ __x_x_ ______
_RED__ ____x_ xx_xxx _xxx_x xx____
_YELLO _____x x_x__x x_x_x_ x_____
_WHITE ______ ______ ______ x_____
_RED__ __x_xx x_x_xx xx__xx _xx_x_
_YELLO ___xx_ _x__xx x__xx_ x_xx__
_WHITE x_____ x__xxx ____x_ ______
_RED__ ______ x_xx_x x_xx_x x_x_xx
_YELLO __xxx_ _x_xx_ x_xx_x _xxx__
_WHITE ____x_ ______ _x____ _x_x__
_RED__ x_x_x_ __x_xx xx__xx x_x_x_
_YELLO __x_xx _x__x_ xx_xx_ xx_xx_
_WHITE x___x_ ___x__ ___xx_ ______
_RED__ _xx_x_ x__xx_ xx_xxx _xxx_x
_YELLO ___x_x x___x_ x__xx_ xx____
_WHITE ___x__ ______ ___x__ ______
_RED__ ___x_x ___xx_ x_xx_x x__xxx
_YELLO ____x_ xx_xx_ x_x_xx x_____
_WHITE _____x x__x__ _xx___ ______
_RED__ ____x_ x_xx_x xx_xx_ x_x___
_YELLO ______ ____xx _x____ ______
_WHITE ______ _____x __x___ ____x_

};

char explosion4[]= {
  5, 24,
_RED__ ______ ______ ______ ______
_YELLO ______ ______ ______ ______
_WHITE xx____ _x____ ______ ______
_RED__ ______ ______ xxxx__ ______
_YELLO ______ x_xxx_ x_x___ ______
_WHITE __xxx_ __x__x xxxx__ _x__x_
_RED__ ______ xxx_x_ __xxx_ xx____
_YELLO _____x _xx_xx _xx_x_ _x____
_WHITE ______ _____x __xx__ _xx___
_RED__ ____xx xx_x_x x____x xxxx__
_YELLO ____x_ xxx_x_ _xx_xx __x___
_WHITE ___x__ _x_x__ __x___ x_____
_RED__ ___xxx _x___x _xxxx_ xxxx__
_YELLO ___xx_ x_xx_x x__x__ xxx___
_WHITE ___xx_ x_____ ___x__ ______
_RED__ ___xx_ x_x__x xxx_xx _xx___
_YELLO _____x x__x_x __xxx_ x__x__
_WHITE ___x_x __xxx_ _x_xx_ xx__x_
_RED__ ______ xx_xxx _x__x_ xx_x__
_YELLO ______ __x_xx xx_x__ x_____
_WHITE ____xx _x_x__ _x__x_ __xx_x
_RED__ ______ ___xx_ _x_xx_ ______
_YELLO ______ _x_x__ __x___ _x____
_WHITE __x__x ______ x_____ ______

};

char explosion5[]= {
  5, 24,
_WHITE ______ _____x ______ ______
_YELLO _____x __xx__ _x____ ______
_WHITE ____xx ____xx x___xx x_____
_WHITE ______ ___x__ _x_x__ x_x___
_YELLO ______ x_____ _x__x_ ______
_WHITE __x___ _xx_x_ x___xx x__x__
_WHITE ___xx_ _x____ _x___x _xx___
_YELLO ______ x_____ x___x_ ____x_
_WHITE ______ x__x__ __xx__ x_xx__
_WHITE __xxx_ __x__x _x__x_ _xx_x_
_YELLO ______ xx____ _x___x ____x_
_WHITE x___x_ __x_x_ xx_xx_ __xx__
_WHITE __x___ x__x__ _xx___ _x____
_YELLO ____x_ ___x_x _x____ ______
_WHITE _xx___ x_xx__ x___x_ ____xx
_WHITE __xxx_ _xx___ _x___x _xxx__
_YELLO ____x_ _x____ _x____ ______
_WHITE __x__x _x_x__ ___x_x _x_x__
_WHITE ____x_ ____x_ x__x__ _x_xx_
_WHITE ___xx_ __xx__ __xx__ __x___
_WHITE x_x___ ____x_ _x__x_ xx_x__
_WHITE ____xx __xxx_ __xxx_ x_x___
_YELLO _____x ______ ___x_x ______
_WHITE ______ __x___ xx____ ______
};

char* explosion[6]= {
  explosion0,  explosion1,  explosion2,
  explosion3,  explosion4,  explosion5,
};

