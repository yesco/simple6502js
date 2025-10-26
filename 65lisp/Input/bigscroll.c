// abcDefGHijKLMNOPQRstuvwxyz  VARS
word S(){ i=b; while(i<e){ // Scroll
  poke(b, peek(b+1)); ++i; } }
word D(){ a= c <<3 +46080; // charDef
  s=peek(a);++a; t=peek(a);++a;
  u=peek(a);++a; v=peek(a);++a;
  w=peek(a);++a; x=peek(a);++a;
  y=peek(a);++a; z=peek(a);++a; }
word L(){ s<<=1;t<<=1;u<<=1;v<<=1;
          w<<=1;x<<=1;y<<=1;z<<=1; }
word B(){ if (e&1) v= f; else v= 16;
  poke(a, v); a+= 40; }
word P(){e=s;B();e=t;B();e=u;B();e=v;
B();e=w;B();e=x;B();e=y;B();e=z;B();}
word N(){c=poke(h);++h;D();L();L();}
word main(){ putchar(12);
  b= 48000+360; e=b+320; f=17; j=0
  g= "Hello ORIC ATMOS 48K"; h= g;
A:
  if(!j--){ if(!poke(h)){ h=g; j=6; }
            N(); }
  S(); a= b+39; P();
  goto A;
}
