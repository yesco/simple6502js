// keyboard input char - works ./rawmcr
word i, s, c;
char input[7]={0};
word main() {
  // where the hell is this writing?
  strcpy(input, "foobar");
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

