// Hello World! - loops

word i;

word spaces(word n) {
  while(n--) putchar(' ');
}

word main(){
  for(i=0; i<150; ++i) {
    spaces(i);
    printf("%s","Hello World!");
  }
}

