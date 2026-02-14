// Multi Assignment
word a,b,c;
word main() {

  a=b=c=14;

  // this works fine
  a=(b=(c=13)+1)+1;

  // this not: no COMPLEX in rhs of +
  // a=1+(b=1+(c=13));

  // more difficult (actually not legal:)
  // a=b=1+c=13;

  return a+b+c;
}

