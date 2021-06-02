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

// PROBLEM:
// - explosion in combinations m x y
// + SWEET16 have only 16 regs
// + (maybe this is good to gen SW16?)
// + stack machine doesnt deal w reg

// - x and y are preserved
// - a is almost always trashed

// (3)
// - n2m
// - n2x
// - n2y

// (5)
// -   m2m
// - m2x  x2m
// - m2y  y2m

// (3)
// - x2y  y2x
// -   x0y

// (6)
// - minc mdec (m2inc m2dec)
// - xinc xdec (x2inc m2dec)
// - yinc ydec (y2inc m2dec)

// (10+10=20) ADD SUB
// - mADDn mADDm mADDx mADDy
// - xADDn xADDm xADDy
// - yADDn yADDm yADDx

// (10)
// - mMULn mMULm mMULx mMULy
// - xMULn xMULn xMULy
// - yMULn yMULn yMULx

// (10)
// - ?div?

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

function minc(a) {
  let l = gensym();

  inc(a);
  BNE(l);
  inc(a+1);
L(l);  
}
function xinc() { // b6 c9+5
  let l = gensym();

  INCZX(0);
  BNE(l);
  INCZX(1);
L(l);  
}
function yinc() {
  if (1) { // b8 c11+5
    TXA();
    xinc();
    TAX();
  } else { // b17 c22
    LDAAY(0);
    CLC();
    ADCN(1);
    STAAY(0);

    LDAAY(1);
    ADCN(0);
    STAAY(1);
  }
}

function mdec(a) {
  let l = gensym();

  lda(a);
  BNE(l);
  dec(a+1);
L(l);
  dec(a);
}

function xdec() { // b6 c9+5
  let l = gensym();

  LDAZX(0)
  BNE(l);
  DECZX(1);
L(l);  
  DECZX(0);
}
function ydec() {
  if (1) { // b8 c11+5
    TXA();
    xdec();
    TAX();
  } else { // b17 c22
    LDAAY(0);
    SEC();
    SBCN(1);
    STAAY(0);

    LDAAY(1);
    SBCN(0);
    STAAY(1);
  }
}

function mADDn(a, n) {
  LDAA(a);
  CLC();
  SBCN(n & 0xff);
  STAA(a);

  LDAA(a+1);
  ADCN(n >> 8);
  STAA(a+1);
}
function xADDn(n) {
  LDAZX(0);
  CLC();
  ADCN(n & 0xff);
  STAZX(0);

  LDAZX(1);
  ADCN(n >> 8);
  STAZX(1);
}
function yADDn(n) {
  LDAAY(0);
  CLC();
  ADCN(n & 0xff);
  STAAY(0);

  LDAAY(1);
  ADCN(n >> 8);
  STAAY(1);
}

function mADDm(z, a) {
  lda(z);
  CLC();
  adc(a);
  sta(z);
  
  lda(z+1);
  adc(a+1);
  sta(z+1);
}
function xADDm(a) {
  LDAXZ(0);
  CLC();
  adc(a);
  STAXZ(0);
  
  LDAXZ(1);
  adc(a+1);
  STAXZ(1);
}
function yADDm(a) {
  LDAAY(0);
  CLC();
  adc(a);
  STAAY(0);
  
  LDAAY(1);
  adc(a+1);
  STAAY(1);
}

function mADDx(a) {
  lda(a);
  CLC();
  ADCZX(0);
  sta(a);
  
  lda(a+1);
  ADCZX(1);
  sta(a+1);
}
function mADDy(a) {
  lda(a);
  CLC();
  ADCAY(0);
  sta(a);
  
  lda(a+1);
  ADCAY(1);
  sta(a+1);
}

////////////////////////////////

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

function inc(a) {
  if (a < 256) {
    INCZ(a);
  } else {
    INCA(a);
  }
}

function cmp(a) {
  if (a < 256) {
    CMPZ(a);
  } else {
    CMPA(a);
  }
}

function dec(a) {
  if (a < 256) {
    DECZ(a);
  } else {
    DECA(a);
  }
}

function adc(a) {
  if (a < 256) {
    ADCZ(a);
  } else {
    ADCA(a);
  }
}

// - http://www.6502.org/source/interpreters/sweet16.htm
function SWEET16() {
// 0x?n - all registers (16)
L('SET');  // Rn = N

L('LD');   // A = Rn
L('ST');   //     Rn = A

L('LDI');  // A = M[Rn++]
L('STI');  //     M[Rn++] = A

L('LDDI'); // A = W[Rn++++]
L('STDI'); //     W[Rn++++] = A

L('POPI'); // A = M[--Rn]
L('STPI'); //     M[--Rn] = A

L('ADD');  // A += Rn
L('SUB');  // A -= Rn

eL('POPDI');// A = W[----Rn]

L('CPR');  // A - Rn => flags
L('INR');  // Rn++
L('DCR');  // Rn--

// 0x0? - no registers
L('RTN');

L('BR');

L('BNC');
L('BN');

L('BP');
L('BM');

L('BZ');
L('BNZ');

L('BM1');
L('BNM1');

L('BK');

L('RS');
L('BS');

}
