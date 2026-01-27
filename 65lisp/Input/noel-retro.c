// Noels Retro Lab BASIC Benchmark

// (- 1677520 954787) 722,733us=0.7s
// => 41748 (only 16 bits0

// --- Hopper 8 MHz, 24 bit/32 bit arithm?
// 424 B  Asm       2320 ms (290)
// 839 B  hopper C  3352 ms (419)
// 199 B  VM        4744 ms (593) (+ 2K VM)
// 142 B  Basic     4096 ms (512)

// 152+B  MC02       723 ms (rt+91 misc+20?)
// Conclusion: Hopper stuff slow!

word i, j, s;
word main() {
  putchar('S');
  for(i=1; i<11; ++i) {
    s= 0;
    for(j=1; j<1001; ++j)
      s+= j;
    putchar('.');
  }
  return s;
}
