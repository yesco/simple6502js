// Word CPU (synthentic instructions)
//
// In practice we need a 16 bit CPU
//
// We have few conventions:
// - prefix 'w' for word
// - prefix 'x' or 'y' for
//   id of zero page "reg".
// - 'z' means extra arg for
//   fixed reg address (a/zp)
// - Address can be a/zp:
//   code generated is adopted.
//
// - n2m
// - n2x
// - n2y

// -   m2m
// - m2x  x2m
// - m2y  y2m

// - x2y  y2x
// -   x0y

function n2m(z, n) { // b8+2
  LDAN(n & 0xff);   sta(z);
  LDAN(n >> 8);     sta(z+1);
}
function n2x(n) { // b8
  LDAN(n & 0xff); STAZX(0);
  LDAN(n >> 8);   STAZX(1);
}
function n2y(n) { // b10, no ZP
  LDAN(n & 0xff); STAAY(0);
  LDAN(n >> 8);   STAAY(1);
}
// - to minimize code size could choose to generate JSR! (b5+2)
// - or use byte code! (b2+2) !!!
//   n2m needs 4 codes (bb,bw,wb,ww)
//   others 2

function m2m(z, a) { // b8+4
  lda(a);   sta(z);
  lda(a+1); sta(z+1);
}
function m2x(a) { // b6+4
  lda(a);   STAZX(0);
  lda(a+1); STAZX(1);
}
function m2y(a) { // b6+4
  lda(a);   STAAY(0);
  lda(a+1); STAAY(1);
}


function x2y() {
  LDAZX(0); STAAY(0);
  LDAZX(1); STAAY(1);
}
function y2x() {
  LDAZY(0); STAZX(0);
  LDAZY(1); STAZX(1);
}
function x0y() {
  bswapxy(0);
  bswapxy(1);
}

// - wyTXx(a)
// - wxySW() - swap



function ni() {
  throw "%% Not implemented!\n");
}

// most assemblers do this already
function lda(a) {
  if (a < 256) {
    LDAZ(a);
  } else {
    LDA(a);
  }
}

function sta(a) {
  if (a < 256) {
    STAZ(a);
  } else {
    STA(a);
  }
}

// swap zp bytes at index x and y
function bswapxy(o) {
  // x = x ^ y;
  LDAZX(o); EORAY(o); STAZX(o);
  // y = x ^ y;
  EORAY(o); STAAY(o);
  // x = x ^ y;
  EORZX(o); STAZX(o);
}



