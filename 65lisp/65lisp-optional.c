#define PRINTARENA() ;
#ifndef PRINTARENA
  #define PRINTARENA printarena

void printarena() {
  char* a= arena;
  printf("ARENA: ");
  while(a<arptr) {
    if (*a==HATOM) NL;
    if (*a==' ') printf("_  ");
    else if (*a>' ' && *a<127) printf(" %c ", *a);
    else printf("%X%X ", (*a)>>4, (*a)&0xf);
    ++a;
  }
  putchar('\n');
}

// search arena, this could save next link...
// TODO: won't work, as aligned ptr now
void* searchatom2(char* s) {
  char* a= arena;
  a= arena;
  // TODO: more efficient
  while(*s && a<arptr) {
    if (0==strcmp(s, a+4)) return a;
    a+= 4+1+strlen(a+4); // TODO: should be 1???
  }
  return NULL;
}

// slower, lol!
// TODO: won't work, as aligned ptr now
void* searchatom(char* s) {
  char *a= arena, *p, *aa;
  while(a<arptr) {
    aa= a;
    a+= 4;
    p= s;
    //printf("\t%d '%s'\n", aa-arena, a);
    while(*a && *a==*p) {
      ++p; ++a;
    }
    if (!*a && *a==*p) return aa;
    while(*a) ++a;
    ++a;
  }
  return NULL;
}
#endif // PRINTARENA

// ---------------- ARRAY / VECTOR

#ifdef ARRAY

// unsafe, eval twice, lol
#define ISARR(x) (isatom(x)&&HTYP(x)==HARRAY)

#define ARROFF 3
#define ARRSTEP 16

L mkarr(L dim, L val) {
  size_t n= num(dim);
  size_t bytes= (n+ARROFF)*sizeof(L), i;
  char *p= zalloc(bytes+4), *orig= p;
  L* a;
  if (n==0) n= ARRSTEP;
  if (!isnum(dim)) error("Array dimensions", dim);

  do {
    *p++= HARRAY;
  } while(!isatom((L)p));
  a= (L*)p;

  *a++ = MKNUM(0); // 1. CAR = length
  *a++ = MKNUM(n); // 2. CDR = size
  *a++ = (L)orig; // 3. save orig mem ptr

  // fill
  for(i= ARROFF; i<n+ARROFF; ++i) *a++ = val;

  return (L)p;
}

void arrfree(L arr) {
  if (!ISARR(arr)) error("Not array", arr);
  HTYP(arr)= HFREE;
  free((char*)((L*)arr)[2]);
}

L arrpush(L arr, L val) {
  L* a= (L*)arr; int n, z;
  if (!ISARR(arr)) error("Not array", arr);
  n= a[0];
  z= a[1];
  n+= 2; // LOL inc num:1 !
  // TODO: groiw
  if (n>=z) error("Array full", arr);
  a[0]= n;
  return *(L*)(ARROFF-2+arr+n)= val;
}

L arrpop(L arr) {
  L* a= (L*)arr; int n;
  if (!ISARR(arr)) error("Not array", arr);
  n= a[0]-2; // LOL dec. num:1 !
  if (n<=0) error("Array empty", arr);
  a[0]= n;
  return *(L*)(ARROFF+2+arr+n);
}

#endif // ARRAY
