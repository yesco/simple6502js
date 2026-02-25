// space between '[]' and '=' 
char ok[]= {'b', 'a', 'r', 0}; 
char not[] = {'b', 'a', 'r', 0};

word main() {
  puts(ok);
  not[2]= 'x';
  puts(not);
  return 0;
}
