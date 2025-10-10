int _z;

#define FROM   (_z=
#define SHL  ,  _z<<=
#define PLUS ,  _z+=
#define OD   )

#include <stdio.h>

int main(void) {
  int r= 17;
  int n= WITH r SHL 2 PLUS r SHL 3 END;
  int x= PIPE r SHL 2 PLUS r SHL 3 DONE;
  printf("%d => %d\n", r, n);
}
