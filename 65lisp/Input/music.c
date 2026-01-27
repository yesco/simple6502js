// Music API (ORIC)

word z;
word wait(word cs) {
  while(cs--) {
    z= 400; do ; while(z--);
  }
}

word i;
word main() {
  for(i= 3; i--; ) {
    tick(); wait(30);
    tick(); wait(30);
    tick(); wait(30);
    tock(); wait(60);
  }
  ping();   wait(100);
  shoot();  wait(100);
  zap();    wait(100);
  explode();wait(100);
// TODO: examples
//  play();
//  music();
//  sound();
}
