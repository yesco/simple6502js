// Proposed new atom to store bytecode and assembly too

typedef struct Atom { // 12 Bytes=3x4, aligned x..x01
  D val;  // car - global value
  D next; // cdr - next symbol in hash, or SIZE if array
  D xxx;
  void* ptr; // binary data possibly (maybe malloced?)
  char jmp[3]; // (JMP|JSR|JMPi|RTS) 0xCODE
  char n;    // type/number parameters
}

// TYPE:
//   '0' '1' '2' '3' '4' '5' '6' '7' '8' - number of evalled arguemnts, normal function
//   'n' - counted as in vararg? uNlimited, not evalled
//   '-' - doesn't apply, special rule on symbol name
//
// if have op

// TODO: how do we know the TYPE? lol, high 2 bits of N?
//       Do we need to know type???

//   00 = normal symbol/value
//   01 = prim op
//   10 = bytecode
//   11 = asm

// or by function:
//   0 = 

// Types:
//   symbol only  - CAR: val   CDR: name  RUN: jsr lisp            N: args   (ax= argumentslist, env?)
//   prim op      - CAR: o     CDR: name  RUN: jmp OP/jmp DO-OP    N: args   (ax= tos) (calling next)
//   string       - CAR: self  CDR: self  RUN: jsr prinf(?)        N: args   (ax= arglist..)
//   bytecode     - CAR: self  CDR: name  RUN: jsr runbytecode     N: args   (ax= tos)
//   compiled     - CAR: self  CDR: name  RUN: jmp asm             N: args   (ax= tos)
//     trace      - CAR: self  CDR: name  RUN: jsr trace           N: args   (ax= tos)

//   array        - CAR: self  CDR: nelem RUN: RTS [2B: addr]      N: capacity/8 (max nelem)

//   longnum      - CAR: 15b   CDR: 15b   RUN: RTS [2B: 16b]       N: exp?   (ax= tos?)

//EVAL (a args...):
//  - local var --> RUN (how to know? a-z?, A-Z is outer?, using "frame")
//  - not cons  --> CAR (global var, prim, string, bytecode... etc.... give self!)
//  - ELSE      --> JMP addr+4   == APPLY!

//CDR: name => string
//  00000000 xxxxxxx0 == one char == char*2
//  xxxxxxxx xxxxxxx0 == aligned char*
//  xxxxxxxx xxxxxx01 == atom?
//  xxxxxxxx xxxxxx11 == cons?

// complicated. lol

// (/ 21 (log 10)) = 9 digits

//LONGNUM:
//  30b decimal number + 16b = 46b ... (/ 46 (log 10)) = 19.98
//   8b exponent (10**exp)   =  8b

//BIGNUM:
//  0-200: n*2  => 0-100: 7B =14 digits, or 12 digits, 2 exp
//  RTS need to keep... lol





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
