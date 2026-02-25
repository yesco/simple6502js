// putf? - format functions
int main() {
  puts("--- %u ---");
  putz(">42     <\n="); putfu(42,-7, 0, "=\n\n");
  putz(">     42<\n="); putfu(42, 7, 0, "=\n\n");
  putz(">4711   <\n="); putfu(4711,-7, 0, "=\n\n");
  putz(">   4711<\n="); putfu(4711, 7, 0, "=\n\n");
//  puts("--- %0u ---");
//  putz(">   0042<\n="); putfu(42, 7, 4, "=\n\n");
//  putz(">0000042<\n="); putfu(42, 7, 7, "=\n\n");
//  putz(">0042   <\n="); putfu(42,-7, 4, "=\n\n");
//  puts("--- %x ---");
//  putz(">002a   <\n="); putfx(42,-7, 4, "=\n\n");
//  putz(">   002a<\n="); putfx(42, 7, 4, "=\n\n");
  puts("--- %d ---");
  putz(">-1     <\n="); putfd(-1,-7, 0, "=\n\n");
  putz("> -32767<\n="); putfd(-32767, 7, 0, "=\n\n");
  puts("--- %s ---");
  putz(">    foO<\n="); putfs("foO", 7, 0, "=\n\n");
  putz(">foO    <\n="); putfs("foO",-7, 0, "=\n\n");
  putz(">     fo<\n="); putfs("foO", 7, 2, "=\n\n");
  putz(">fo     <\n="); putfs("foO",-7, 2, "=\n\n");
  putchar('\n');
}
