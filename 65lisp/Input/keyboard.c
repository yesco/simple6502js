// keyboard input
word i, s, c;
char input[7]={0};
word main() {
  puts("End with 'z'");
  do {
    c= kbhit();
    if (c) putchar(getchar());
    else putchar('.');
  } while(c<'q');
  //} while(c!=27); // < >  problem, lol
  //} while(c==0); // compile error!
  // while(' '<c); // hangs?

  // fgetc
  putz("Name: ");
  fgets(input, sizeof(input), stdin);
  putchar('\n');
  putz("Your name is: "); puts(input);

  // fgetc_edit
  putz("Change it: ");
  fgets_edit(input, sizeof(input), stdin);
  putchar('\n');
  putz("New name: "); puts(input);
}

