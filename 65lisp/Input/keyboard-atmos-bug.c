// keyboard input char
word i, s, c;
// remove comment to compile,
// here edit edits using different addresss
// than input initilzied?
// works fine on ./rawmcr Input/keyboard-atmos-bug.c
char input[]="123456";
word main() {
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

