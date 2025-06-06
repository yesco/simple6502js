//#define MAIN
//#include "conio-raw.c"

#include <stdlib.h>
#include <stdio.h>

// save computrons
#define RESULT() ++nres
//#define RESULT() result()


// - printint very costly...
//#define DOPRINT(a) 
#define DOPRINT(a) a

// dummy
char nil, T, print, doapply1;

#define NV 16

char lastop= 0, lastlast= 0;
int nv= 0, v[NV]= {0}, nres= 0;
long sum[NV]= {0};
char is[NV]= {0}, isum[NV]={0};

// var: $1..$9
// TODO: $a $b... named (how to assign? "as $a" ?)
int var(char n) {
  char i= 0;
  if (n>='0' && n<='9') n-= '0';
  if (n<31) {
    while(n) {
      while(i<NV && !is[++i]);
      --n;
      if (i>=NV) return -1;
    }
    printf(" [var n=%d, i=%d =>%d] ", n, i, v[i]);
    return v[i];
  }
}

// already this costly
void result() {
  char i;
  ++nres;
  DOPRINT(printf("=> "));
  for(i= 1; i<=nv; ++i) {
    if (!is[i]) continue;
    DOPRINT(printf("%d ", v[i]));
    isum[i]= 1;
    sum[i]+= v[i];
  }
  putchar('\n');
}

void printsum() {
  char i;
  printf("SUM[%d]=> ", nres);
  for(i= 1; i<=NV; ++i) {
    if (!isum[i]) continue;
    printf("%ld ", sum[i]);
  }
  putchar('\n');
}

void panda(char* cmd);

void op(char c, char* cmd) {
  //printf("\n[OP(%c) %c]\n", c, lastop); //result();

  // TODO: is[] is slow and crude better have (out ....)
  switch(lastop) {
  case 0: lastop= c; return;
    // binop
    // TODO: pa, pb shifting???
  case '+': v[nv+1]= v[nv-1]+v[nv]; break;
  case '-': v[nv+1]= v[nv-1]-v[nv]; break;
  case '*': v[nv+1]= v[nv-1]*v[nv]; break;
  case '/': v[nv+1]= v[nv-1]/v[nv]; break;

    // .. 1_10 == 1..10
  case '_': { 
    int end= v[nv], * p= v+ ++nv, snv= nv;
    int slastlast= lastlast, slast= lastop;
    if (!cmd || !*cmd) return;
    //is[nv]= 1;
    ++cmd;
    for(*p= v[nv-2]; *p <= end; ++(*p)) {
      nv= snv;
      //lastlast= slastlast; lastop= slast;
      lastop= 0; lastlast= 0;
      //printf("--------- %d (..%d): c=%c lastop=%c cmd=\"%s\"\n", *p, end, c?c:'?', lastop, cmd);
      panda(cmd);
    }

    // backtrack... (fail)
    nv= snv-1;
    //is[nv]= 0;
    lastlast= '_';
    lastop= 0;
    return;
  }
    

    // one arg
  case 's': v[nv+1]= v[nv]*v[nv]; break;

  default: printf("Illegcal command: '%c'\n", c); exit(1);
  }

  is[++nv]= 1;

  lastlast= lastop;
  lastop= c;
}

// TODO: make parser to output objectlog?
void panda(char* cmd) {
  char c;
  // TOOD: set/reset (string) stack-heap

  //printf("%% panda> %s\n", cmd);

  --cmd;
 next:
  if (lastlast=='_') return;
  //printf("\n%% P: '%c' %d\n", cmd[1], cmd[1]);

  switch(c= *++cmd) {
  case 0:   is[nv]= 1; op(0, cmd); RESULT(); return;
    // formatting
  case ' ': goto next;
  case ';': op(0, cmd); goto next;            // no value
  case ',': op(0, cmd); is[nv]= 1; goto next; // value

    // print string
    // TODO: accumulate/set as output value in parsing stake
#ifdef FOO
    // TODO: NOT CORRECT!
  case '"': case '\'': {
    char q= c;
    while((c=*++cmd) && c!=q) putchar(c);
    goto next;
  }
#endif

    // pos ref
  case '$': v[++nv]= var(*++cmd); goto next;

    // numbers and words
  default:
    // TODO: remove op(0) ?
    if (c>='0' && c<='9') { v[++nv]= c-'0';
      // removed and crashes!
      op(0, cmd);
      goto next; }

    // is an op - delay
    op(c, cmd);
    goto next;
  }
}

// TODO: aggregators
// - NO fish
// - SUM all
// - PRODUCT all
// - WHERE ... (implied)
// - THOSE THAT / IF

// n is even iff n mod 2 is 0
// n is odd iff not even
// n is even if it mode 2 is 0
// sum all number from 1 to 100
//
// b divides a iff a mod b is 0
// 3 is a factor of 6 iff 3 divides 6
// the factors of the number 6 divides it (cannot)
// 42 is a prime iff it has no factors
// is 42 a prime?
// 42 prime
// 42 factors => 2 7 3


//int main(int argc, char** argv) {
int main(void) {
//  char* cmd= "1, 2, 3 + 4, 5 s, 6 + 7, 1 _ 9, 8";
//  char* cmd= "1, 2, 3 + 4, 5 s, 6 + 7, 1 _ 9 + 1, 8";
//  char* cmd= "1_2, 4_5";
//  char* cmd= "1_9 + 9, 1_9 + 8";
//  char* cmd= "1_9 + 9, 1_9 + 8, 1_9 + 7";
  char* cmd= "1_9 + 9, 1_9 + 8, 1_9 + 7, 1_9";
//  char* cmd= "1_9, 1_9";
//  char* cmd= "1_9, '*', 1_9"; // TODO: wrong, need "heap"

//  char* cmd= "9, $1, $1+$2, $3, 8, $1, $3";

  printf("Panda> %s\n", cmd);
  panda(cmd);

  printsum();

  return 42;
}

/*
  from minisquel/object.txt

  about 70 functions

CONTROL

t	true, done/exit
f	fail, exit
j	jump relative
g	goto absolute
o	OR
	AND = imlicit!
	
:=	set variable


NUMBERS

+
-
*
/
%
^	a^b / pow / **

|	or bitwise (52 bits)
&	and bitwise (52 bits)
xo	xor bitwise (52 bits)

N=
N!


COMPARE

!=	<>
=	==
<	
>
<=	!>
>=	!<


LOOPS

i 	to
i	iota
i	fromto

i B E		iota: i 1 10= 1..10
d B E S		dota: i 1 10 0.1
l F f...	line: l FILE field ...

F FILE fname	FILE, fopen(fname)


PRINTING

ou	out "columns" w header (first time)
.	print list of values formatted
p	print no formatting
n	newline


STRINGS

S=
S!

CO	concat
AS	ascii
CA	char
CI	charindex
LE	left
RI	right
LO	lower
UP	upper
LN	length
LT	ltrim
RT	rtrim
TR	trim
ST	str

li	like
il	ilike

ts	timestamp



XML EXTRACTION FUNCTIONS

xt	xmlpath
xt	jsonpath        duckdb: foo->'$foo.bar[2].fie'  ->> for VARCHAR
xt      extract
xt      get



MATH FUNCTIONS

sr	sqrt
si	sin
co	cos
ta	tan

ab	abs
ac	acos
as	asin
at	atan
a2	atan2
cr	dbrt
ce	ceil
de	degrees
fl	floor
ep	exp

ie	isfinite
ii	isinf
in	isnan

ln	log
lg	log10
l2	log2

pi	PI
po	pow ** ^

rd	radians
ra	random
ri	srandom/init
sg	sign

*/
