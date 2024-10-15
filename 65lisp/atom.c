// Proposed new atom to store bytecode and assembly too

typedef struct Atom { D val; AtomBin bin; } Atom;

typedef struct AtomBin {
  char jmp[3]; // JMP CO DE
  char op;
  char n; // oops is a char! - n 0-9
  char data[]; // variable sized
  // AB CD:  name \0
  // CO DE:  start of actual code, CODE used in FIXED call
  // ..len
}

// 0. Atom/Prim    jmp[0]==0 ==> normal atom, ptr
// 1. Normal atom: jmp=op=n=0          data=NAME\0   
// 2. Prim func:   jmp=0, op,n=OP,N    data=NAME\0  jmp= jmp addr? no return?
// 3. Lisp func:   val=CONS, jmp=CALL  data=NAME\0  jmp= jsr CALL retrieve addr
// 4. Trace func:  val=CONS, jmp=TRACE data=name\0  jmp= jsr TRACE wrap call, or run lisp?

// 1. 5 byte overhead for just word atoms :-( most will not even have value? just paramnames?
// 2. 3 byte overhead for prim 

AtomBin:

  00 '\0' 
  20 ' '  JSR CALL  = 3  for lisp!
  20 ' '  JSR TRACE = 3  during tracing (doesn't return)
  4c 'L'  JMP CO DE = 3  normal trampoline
  6c 'l'  JMP (CODE)= 3  late binding? mode changeable? cleanup routines?
  60 '`'  RTS       = 1 // identity function! STR->STR!, num, lol
