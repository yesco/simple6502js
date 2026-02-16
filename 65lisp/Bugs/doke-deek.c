// couldn't get doke/deek to work on word vars
// had to resort to byte manipulation below
word arr, idx, ptr;

word my_doke(word idx, word val) {
  ptr = idx * 2;
  poke(arr + ptr, val);

  ptr = ptr + 1;
  if (val < 256) {
    poke(arr + ptr, 0);
  } else {
    poke(arr + ptr, val >> 8);
  }

  return 0;
}

word my_deek(word idx) {
  ptr = idx * 2;
  return deek(arr + ptr);
}

word main() {
  arr = xmalloc(4);
  doke(42, 300);
  doke(arr, 300);
  my_doke(0, 300);
  my_doke(1, 88);

  putu(my_deek(0));
  putchar(' ');
  putu(my_deek(1));
  return 0;
}
