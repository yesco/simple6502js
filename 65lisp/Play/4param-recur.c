// cc65: 125 Bytes    356 B .sim    440 .tap
// -------------------------------------------
//   931c -   0
// 48379c - 100    (/ (- 48379 931) 100.0) = 474.48c
//
// fun:  
// main: 19 B

// vbcc: 242 Bytes    -               - 
// 
// main: 28 B - reverse arguments! (normal CC, not cc65)

int fun(int a, int b, int c, int d) {
  return a? fun(a-1, b+1, c*2, d/2): a+b+c+d;
}

int main() {
  return fun(0,0,1,65535u);
}
