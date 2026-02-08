// keyboard input
word i, s, c;
word main() {
  return 3+4;
  do {
    c= kbhit();
    if (c) putchar(c);
    else putchar('.');
  } while(c==0);
  //} while(c!=27);
  // while(' '<c); // hangs?
}

