// numeric C constants
word nl(){ putchar('\\n'); }

word p(word n){
  putu(n);
  putchar(' ');
}

int main() {
  p(17); p(42); p(55555); nl();
  p(-17); p(-42); p(-55555); nl();
  p(0x11); p(0x2a); p(0xd903); nl();
  p(0x11); p(0X2A); p(0XD903); nl();
  p(0x11); p('*'); p(0XD903); nl();
  p(0b10001); p(0B101010); p(0b1101100100000011); nl();
  p(021); p(052); p(0154403); nl();
}
