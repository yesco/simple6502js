#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <assert.h>

//float s= 1.0001;
int n= 256; // 2 digits precision! lol
float s;

float* dict= NULL;

typedef int jfloat16;

float jtof(jfloat16 j) {
  // TODO: use dict
  return pow(s, j);
}

jfloat16 ftoj(float f) {
  // TODO: use dict
  return round(log(f)/log(s));
}

void putj(jfloat16 j) {
  int e= j/n;
  int m= j%n;
  printf("%dj%d\t", m, e);
  printf("%d\t", ftoj(jtof(j)));
  printf("%g\t", jtof(j));
  printf("%.4ge%d\t", dict[m], e);
}

jfloat16 jmul(jfloat16 a, jfloat16 b) {
  return a+b;
}

jfloat16 jdiv(jfloat16 a, jfloat16 b) {
  return a-b;
}

jfloat16 jadd(jfloat16 a, jfloat16 b) {
  if (a<b) return jadd(b, a);
  int d= labs((long)a-(long)b);
  //int j= (a+b)/2;
  int x= 0;

  if(d<= 17) return a+ 77; // 2
  if(d<= 45) return a+ 45; // 
  if(d<=100) return a+ 22; // 
  if(d<=199) return a+ 15; // 
  if(d<=256) return a+ 11; // 10
  return a;
}

int main(int argc, char** argv) {
  dict= malloc(sizeof(*dict)*n);
  s= pow(10, 1.0/(n));
  // -- init
  float f= 1.0;
  int i=0;
  //while(f < 10.0 && i < n) {
  while(i < n) {
    dict[i]= f;
    //printf("%g\t", f); putj(i); putchar('\n');
    f*= s; i++;
  }
  printf("\n\ncount= %d\n\n", i);
  assert(i==n);

  // additon
  jfloat16 j= ftoj(1.0);
  for(int i=0; i<256; i++) {
    float x= jtof(i);
    jfloat16 s= ftoj(1+x);
    printf("%d\t%g\t%d\t", i, x, s-j); putj(s-j);
    putchar('\n');
  }


  // interaction
  float in;
  double p= 1, sum= 1; // lol (don't do <0 yet)
  int jp= 0, js= 0;
  f= 1.0;
  do {
    printf("\n> ");
    if (0>fscanf(stdin, "%g", &in)) break;
    p*= in; sum+= in;
    int j= ftoj(in);
    putj(j); putchar('\n');
    jp= jmul(jp, j);
    js= jadd(js, j);
    putchar('\n');
    printf("sum:\t");  putj(js); printf("\t(%lg)\n", sum);
    printf("prod:\t"); putj(jp); printf("\t(%lg)\n", p);
  } while (1);

  return 0;
  // -- 
  for(int i= 0; i<32768; i+= 16) {
    putj(i); putchar('\n');
  }
}
