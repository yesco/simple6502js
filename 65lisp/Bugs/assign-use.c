word zd,z,zz,zo;

word main() {
  zo= 40; z= 83; zz=1;
  zd= z-zz-zo; putu(zd);
  // assignement is an expression
  return putu(zd= z-zz-zo);
}
