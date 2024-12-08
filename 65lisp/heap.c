%currently not used by lisp.c, therefore moved out here...

//#define HEAP
#ifdef HEAP
// ---------------- HEAP
// TODO: Too much code === 550 bytes!!!!
//
// Heap of various variable size data for lisp types.

// The OBJ are linked for use by mark() during GC.
// Code needs to be added per type to the
// mark() and sweep().
//
// Use 

#define isobj(x) (((x)&0x03)==1)

typedef struct OBJ {
  // We put twolisp values first, this makes it
  // safe to use CAR/CDR on the pointer
  L info; // CAR: a link to used other lisp val
  struct OBJ* next; // CDR: enumeration of all OBJ for GC marking
  struct OBJ* prev; // to be able to unlink it from list :-(
  void* origptr; // for free! :-(
  char data[];
} OBJ;

OBJ* objList= NULL;

// similar to isatom, actually atom is "subtype"
// but little special.

// Test if x lisp value is a OBJ of TYP.
// 
// If TYP is 0, then test not HFREE
// This function is expensive, so last test?
// if typ==0 return 
char isTyp(L x, char typ) {
  if (!isobj(x)) return 0;
  return typ? HTYP(x)==typ: HTYP(x)!= HFREE;
}

OBJ* newObj(char typ, void* s, size_t z) {
  // We add 4 bytes, one extra for type, and 3 to align
  // If this is considered wasteful: don't use for small!
  char *orig= (char*)malloc(z+sizeof(OBJ)+4), *p= orig;
  OBJ *prev= objList, *o;
  assert(orig);

  // Prepend at least one type byte
  do {
    *p++= typ;
    // align to 0x01
  } while(!isobj((L)p));

  o= (OBJ*)p;
  o->origptr= orig;
  o->info= nil;

  // Hook it up
  o->prev= NULL;
  o->next= objList;
  if (objList) {
    assert(objList->prev);
    objList->prev= o;
  }
  
  memcpy(o->data, s, z);
  
  return o;
}

void forgetObj(L x) {
  // TODO: verify valid obj?

  // Unlink
  OBJ *o= (OBJ*)x;
  if (o->prev) o->prev->next= o->next;
  if (o->next) o->next->prev= o->prev;
  o->next= NULL;
  o->prev= NULL;

  HTYP(x)= HFREE;
}

#endif // HEAP
