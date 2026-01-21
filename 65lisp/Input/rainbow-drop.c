// Rainbow-drop (ORIC)
word a,j,b,e,d,s,i,q;

word main() {
  b= 40960; e= b+8000;
  hires(); //poke(e+120-1,30);//lol
  d= 1; s= 1;
 A:
  s+= d;
  // change direction?
  if (s<50) ; else d= 0-d;
  if (s<2)  d= 0-d; else ;
  // one frame, for 8 colors
  a= b; i= 8; while(i--) {
    // draw s rows of each color
    j= s; q= 16+i; while(--j) {
      if (a<e) poke(a, q);
      a+= 40;
    }
  }
  while(a<e){ poke(a, 16); a+=40; }
//  i=s<<2; i=210-i; while(--i);
  goto A;
}
