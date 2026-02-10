// keyboard input char
word i, s, c;
char input[7]={0};
word main() {
  do {
    c= kbhit();
    if (c) putchar(c=getchar());
    else putchar('.');
  } while(c<'z');

  putz("before: "); puts(input);

  putz("Name: ");
  fgets_edit(input, sizeof(input), stdin);
  putchar('\n');
  putz("Your name is: "); puts(input);
  putchar('\n');

  putz("Change it: ");
  fgets_edit(input, sizeof(input), stdin);
  putchar('\n');
  putz("New name: "); puts(input);
}

