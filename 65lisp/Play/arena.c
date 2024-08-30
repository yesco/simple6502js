// Simple arena, blockwise allocation (for 6502)
//
// (>) 2024 Jonas S Karlsson, jsk@yesco.org

#define ARENA_N 16
#define ARENA_LEN 256

typedef struct Arena {
  char* p[ARENA_N];
  char pos[ARENA_N];
} Arena;

// Return pointer to contigous area
int Aalloc(Arena* a, char* s, int m) {
  int r= 0;
  char *r= 0, *p;
  assert(m>0);
  for(int i=0; i<ARENA_N; ++i) {
    // TODO: faster to store bytes left?
    int v= ARENA_LEN - a->pos[i];
    if (v <= m) {
      r+= a->pos[i];
      if (s && m>0) memcpy(a->p[i] + a->pos[i], s, m);
      a->pos[i]+= m;
      return r;
    }
    r+= ARENA_LEN;
  }
  assert(!"%%Aalloc: ran out of slots");
}

char* Aget(Arena* a, int i) {
  char p= i/256, o= i&0xff;
  assert(p<ARENA_N);
  return a->p[i] + o;
}
