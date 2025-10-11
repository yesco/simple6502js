int _z;

#define WITH   (  _z     =
#define PIPE   @Can't use PIPE in normal C!
#define DO(op) ,  _z op##=
#define END    )

#define SHL    DO(<<)
#define SHR    DO(>>)
#define PLUS   DO(+)
#define MINUS  DO(-)
#define MUL    DO(*)
#define DIV    DO(/)
#define MOD    DO(%)



#include <stdio.h>

int main(void) {
  int r= 17;
  // How to write muliiplication of 40
  int pony=      ((r<<2)+r)<<3;  // ugly
  int noprio=    r<<2+r<<3;      // "incorrect C"
//int noprio :=  r<<2+r<<3;      // alt incompat syntax
  int with=      WITH r SHL 2 PLUS r SHL 3 END; // makes clear macro
//int dod=       with r mul 4 plus r mul 8 end;
  int pipe= PIPE r<<2+r<<3;      // "incorrect C"
//int dod=       with(r)mul(4)plus(r)mul(8)end; // busy
  printf("------------------------------\n");
  printf("%d => %d %d %d %d\n", r, pony, noprio, with, pipe);
  printf("------------------------------\n");
}
