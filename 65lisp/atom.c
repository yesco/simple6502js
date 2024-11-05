// Proposed new atom to store bytecode and assembly too

typedef struct AtomBin {
  char jmp[3]; // JMP CO DE
  char op; // (may be optional)
  char n; // oops is a char! - n 0-9
  char data[]; // variable sized
  // AB CD:  name \0
  //   (align: 0b...0) (add NOP if not?)
  // CO DE:  start of actual code, CODE used in FIXED call
  // ..len
}

typedef struct Atom { D val; AtomBin* bin; } Atom;
// Alternative AtomBin* bin:
//   bin<128   == Actual ascii name? (not callable function, can be changed)
//   bin<256   == ... reserved for future use ... (lol)
//   bin<2048  == ... offset name into array (no dealloc)
//   bin       == ... actual pointer to AtomBin (for resizeable byte compilations, asm changes)


// 0. Atom/Prim    jmp[0]==0 ==> normal atom, ptr
// 1. Normal atom: jmp=op=n=0          data=NAME\0   
// 2. Prim func:   jmp=0, op,n=OP,N    data=NAME\0  jmp= jmp addr? no return?
// 3. Lisp func:   val=CONS, jmp=CALL  data=NAME\0  jmp= jsr CALL retrieve addr
// 4. Trace func:  val=CONS, jmp=TRACE data=name\0  jmp= jsr TRACE wrap call, or run lisp?

// 1. 5 byte overhead for just word atoms :-( most will not even have value? just paramnames?
// 2. 3 byte overhead for prim 

AtomBin:

  00 '\0' 
  20 ' '  JSR CALL  = 3  for lisp! (allows to capture here address)
  20 ' '  JSR TRACE = 3  during tracing (doesn't return)
  4c 'L'  JMP CO DE = 3  normal trampoline
  6c 'l'  JMP (CODE)= 3  late binding? mode changeable? cleanup routines?
  60 '`'  RTS       = 1 // identity function! STR->STR!, num, lol
