word a,b;
word main(){
  a= 7; b= 3;
  return (a==(b+4)) && ((a-b)==(b+1)); // ok
  return (a==b);
  return a==b;
  return 7==a; // ok
  return 3==4; // ok
  return (3); // ok
  return (3+3); // ok
}

