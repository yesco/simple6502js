// inc ++, dec --
word i;
word main() {
  i= 40;
  // = all returns 42, size of program

  // pre/post no matter!
//  return ++i + 1; // 34
//  return i++ + 2; // 34
  
//  return --i + 3; // 36 WORST!
  return i-- + 2; // 34 also good!

  // pre/post no matter!
//  ++i; return i+1; // 34
//  i++; return i+1; // 34
  // yes, -- is more expensive
//  i--; return i+3; // 36
//  --i; return i+3; // 36 not better
}
