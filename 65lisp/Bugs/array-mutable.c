// arrays are immutable???
char arr[]={'b', 'a', 'r', 0};

word main() {
  puts(arr);
  arr[2]= 'x';
  puts(' ');
  puts(arr);
  return 0;
}
