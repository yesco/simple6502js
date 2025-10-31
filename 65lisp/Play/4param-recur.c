// cc65: 125 Bytes    356 B .sim    440 .tap
// -------------------------------------------
//   931c -   0
// 48379c - 100    (/ (- 48379 931) 100.0) = 474.48c
//
// fun:  
// main: 19 B

// vbcc: 242 Bytes    -               - 
// --------------------------------------------
// 
// fun:
//   11 B - sp+= 8;
//   44 B - 4 x save reg0-8
//    9 B - IF
//   79 B - (a-1: 17 B  ;  b+1: 17 B  ; *2: 19 B; /2: 26 B)
//    3 B - JSR
//    3 B - jmp "ret"
//   49 B - return a+b+c+d;  !!! ?
//   11 B - sp+= 8
//    4 B - preserve r31, rts
// ========
//  213 B !!!!!    (+ 11 44 9 79 3 3 49 11 4) WTF?
//
// VBCC:   generates costly code?
// 
// main: 28 B - reverse arguments! (normal CC, not cc65)


// MeteoriC CC02
// cc02: 138 bytes - non working (just prediction)
//      (using _X rule which is cc65)
//      
// ================================================
//
// fun:
//   15 B  = IF
//   34 B  =    return a+b+c+d
//   54 B  =    params!!! 
//
// TODO: return fun(...)   => jmp TAILRECURSION!
//
// main: 31 B ( possibly put 0 in Y and remember?)
//   (+ (* 4 (+ 4           3))             3) = 31
//            lda/ldx  pha/txa/pha         jsr
//  
// (+ 15 34 54 31) = 134 
//
// missing:
//   10 B - swap zp variables / stack 
//
// + library ( swapparams 20B ))
//
// OK, so cc02 would be quite slow... much more copying
// or actually .... hmmmmm?


int fun(int a, int b, int c, int d) {
  // swap c and d usage to see changes in
  // reused in vbcc?
  return a? fun(a-1, b+1, d*2, c/2): a+b+c+d;
}

int main() {
//  return fun(100,0,1,65535u);
// cc02 max 22
  return fun(22,0,1,65535u);
}
