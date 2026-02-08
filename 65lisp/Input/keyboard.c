// keyboard input
word i, s, c;
word main() {
  do {
    c= kbhit();
    if (c) putchar(c);
    else putchar('.');
  } while(1);
  //} while(c!=27);
  //} while(c==0); // compile error!
  // while(' '<c); // hangs?
}

