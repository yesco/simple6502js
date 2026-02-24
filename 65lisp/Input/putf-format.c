// putf? - format functions
int main() {
//  putz(">     42<\n="); putfu(42, 7, 0, "=\n\n");
//  putz(">   0042<\n="); putfu(42, 7, 4, "=\n\n");
//  putz(">0000042<\n="); putfu(42, 7, 7, "=\n\n");
//  putz(">0042   <\n="); putfu(42,-7, 4, "=\n\n");
//  putz(">002a   <\n="); putfx(42,-7, 4, "=\n\n");
//  putz(">   002a<\n="); putfx(42, 7, 4, "=\n\n");
  putz(">    foO<\n="); putfs("foO", 7, 0, "=\n\n");
  putz(">foO    <\n="); putfs("foO",-7, 0, "=\n\n");
  putz(">     fo<\n="); putfs("foO", 7, 2, "=\n\n");
  putz(">fo     <\n="); putfs("foO",-7, 2, "=\n\n");
  putchar('\n');
}
