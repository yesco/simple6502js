//
//          SectorForth-6502
//
//
//      (>) 2021 Jonas S Karlsson
//            jsk@yesco.org
//
// This is an ode to sectorforth - a x86 bootable
// Forth by Cesar Blum. It's under MIT LICENSE.
// - https://github.com/cesarblum/sectorforth/blob/master/sectorforth.asm
//
// (>) This version is release with COPYLEFT.

// The minimum CPU required to run sectorforth
// is the 6502:
//
//        bits 8
//        cpu 6502

// - direct threaded forth
// - instruction pointer 'si' in zero page
// - a word is executed by using "direct"
// - indirection. For cleverness 'si'
// - is stored inside the JSRI instruction:

let cpu6502 = require('./fil.js');
let jasm = require('./jasm.js');

let si = 0x21;

ORG(si-1);
L('next');
  JSRI(0x0000);

// - The SP register is used as the data stack
//   pointer, and the BP register acts as the
//   return stack pointer.
function datastack() {
  
}

// "Code Segment" on 6502 typically starts after
// page 1, but often lower pages are "reserved".
//
//   0000: page zero, "256 special registers"
//   0100: page one, hardware return stack
//   0200: "reserved"
//   0300: sometimes I/O mapped by 6522
//   0400: "reserved"
//   0500: here you go
/
// Funny enough, in the original sectorforth
// it says that "Memory up to 0x0500 is used by the BIOS. Setting the segment to 0x0500 gives
// sectorforth an entire free segment to work
// with."

let cs= 0x0501;
ORG(cs); // ORIC ATMOS legacy (+1)
  jmp('start');

// 6502 doesn't have a "bootsector", but at reset the address is read from reset vector and jumped to.
is rwhich happends at boot the vector
// On x86, the boot sector is loaded at 0x7c00
// on boot. In segment 0x0500, that's 0x7700
// (0x0050 << 4 + 0x7700 == 0x7c00).
let resetvector= 0xfffe;
ORG(resetvector);

// Define constants for the memory
// map. Everything is organized within a single
// 64 KB segment. TIB is placed at 0x0000 to
// simplify input parsing (the Forth variable
// >IN ends up being also a pointer into TIB,
// so there's no need to add >IN to TIB to get
// a pointer to the parse area). TIB is 4 KB
// long.
let TIB=   0x0035; // terminal input buffer (TIB)
let STATE= 0x0086; // state: 0=interprt 1=compile
let TOIN=  0x0087; // read offset in TIB (>IN)
let RP0=   0x0100; // bottom of return stack
let SP0=   0x0080; // bottom of data stack

// Each dictionary entry is laid out in memory
// as such:
//
// *------*-----------*----------*----------*
// | Link | Flags+Len |  Name... |  Code... |
// *------*-----------*----------*----------*
//   2 B       1 B        Len B     Variable
//
// Flags IMMEDIATE and HIDDEN are used in
// assembly code. Room is left for an
// additional, user-defined flag, so word names
// are limited to 32 characters.
let F_IMMEDIATE= 0x80;
let F_HIDDEN=    0x40;
let LENMASK=     0x1f;

// Each dictionary entry needs a link to the
// previous entry. The last entry links to
// zero, marking the end of the dictionary.  As
// dictionary entries are defined, link will be
// redefined to point to the previous entry.
let link= 0;

// defword lays out a dictionary entry where it
// is expanded.
function defword(name, label, flags=0) {
  word(link);
  link = label;
  byte(flags || len);
 L(label);
}

// NEXT advances execution to the next
// word. The actual code is placed further
// ahead for strategic reasons. The macro has
// to be defined here, since it's used in the
// words defined ahead.
function NEXT() {
  jmp('next');
}

// sectorforth has only eight primitive words,
// with which everything else can be built in
// Forth:
//
// @ ( addr -- x )     Fetch memory at addr
// ! ( x addr -- )     Store x at addr
// sp@ ( -- addr )     Get data stack pointer
// rp@ ( -- addr )     Get return stack pointer
// 0= ( x -- f )       -1, if 0, otherwise 0
// + ( x1 x2 -- n )    add two values on stack
// nand ( x1 x2 -- n ) NAND the two stack values
// exit ( r:addr -- )  Exit to addr (ret stack)

defword("@", 'FETCH');
  pop('BX');
  pushAR('BX');
  NEXT();

defword("!", 'STORE');
  pop('BX');
  popAR('BX');
  NEXT();

defword("sp@", 'SPFETCH');
  push('SP');
  NEXT();

defword("rp@", 'RPFETCH');
  push('BP');
  NEXT();

defword("0=", 'ZEROEQUALS');
  pop('AX');
  testaxax();
  setnzal();  // AL=0 if ZF=1, else AL=1
  dec('AX');    // AL=ff if AL=0, else AL=0
  cbw();      // AH=AL
  push('AX');
  NEXT();

defword("+", 'PLUS');
  pop('BX');
  pop('AX');
  addaxbx();
  push('AX');
  NEXT();

defword("nand", 'NAND');
  pop('BX');
  pop('AX');
  andaxbx();
  not('AX');
  push('AX');
  NEXT();

defword("exit", 'EXIT');
  xchgspbp(); // swap SP and BP, SP=ret stack
  pop('SI');    // pop address to next word
  xchgspbp(); // restore SP and BP
  NEXT();

// Besides primitives, a few variables are
// exposed to Forth code: TIB, STATE, >IN,
// HERE, and LATEST. With sectorforth's >IN
// being both an offset and a pointer into TIB
// (as TIB starts at 0x0000), TIB could be left
// out. But it is exposed so that sectorforth
// code that accesses the parse area can be
// written in an idiomatic fashion (e.g. TIB
// >IN @ +).
defword("tib", 'TIBVAR');
  pushN(TIB);
  NEXT();

defword("state", 'STATEVAR');
  pushN(STATE);
  NEXT();

defword(">in", 'TOINVAR');
  pushN(TOIN);
  NEXT();

// TODO: rewrite
// Strategically define next here so most jumps
// to it are short, saving extra bytes that
// would be taken by near jumps.
// jsk: 6502 cannot
L('next');
  lodsw();  // load next word's address into AX
  jmpax();  // jump directly to it

// Words and data space for the HERE and LATEST
// variables.
defword("here", 'HEREVAR');
  pushN('HERE');
  NEXT();

L('HERE'); word('start_HERE');

defword("latest", 'LATESTVAR');
  pushN('LATEST');
  NEXT();

// initialized to last word in dictionary
L('LATEST'); word('word_SEMICOLON');

// Define a couple of I/O primitives to make
// things interactive.  They can also be used
// to build a richer interpreter loop.
//
// KEY waits for a key press and pushes its
// scan code (AH) and ASCII character (AL) to
// the stack, both in a single cell.
defword("key", 'KEY');
  mov_byte_h('AX', 0);
  int(0x16);
  push('AX');
  NEXT();

// EMIT writes to the screen the ASCII
// character corresponding to the lowest 8 bits
// of the value at the top of the stack.
defword("emit", 'EMIT');
  pop('AX');
  call('writechar');
  NEXT();

// The colon compiler reads a name from the
// terminal input buffer, creates a dictionary
// entry for it, writes machine code to jump to
// DOCOL, updates LATEST and HERE, and switches
// to compilation state.
defword(":", 'COLON');
  call('token')    // parse word from input
  push('SI');
  mov('SI', 'DI');       // parsed word := str cpy src
  mov('DI', 'HERE');  // dest := HERE
  mov('AX', 'LATEST');// ptr to last def word
  mov('LATEST', 'DI');// update LATEST to new word being defined
  stosw();         // link pointer
  // mov al, cl
  mov_byte('AX', 'CX');
  // or al, F_HIDDEN
  or_byteN('AX', F_HIDDEN);  // hide new word
  stosb();         // word length
  rep_movsb();     // word name
  movN('AX', 0x26ff);   // "near jmp"
  stosw();         // compile jump, abs indir
  movN('AX', 'DOCOL.addr'); // see '.addr'
  stosw();         // ...to DOCOL
  mov('HERE','DI');// [HERE] = next free
  mov_byte('STATE', 1); // set compile state
  pop('SI');
  NEXT();

// DOCOL sets up and starts execution of a
// user-defined words.  Those differ from words
// defined in machine code by being sequences
// of addresses to other words, so a bit of
// code is needed to save the current value of
// SI (this Forth's instruction pointer), and
// point it to the sequence of addresses that
// makes up a word's body.
//
// DOCOL advances AX 4 bytes, and then moves
// that value to SI. When DOCOL is jumped to,
// AX points to the code field of the word
// about to be executed. The 4 bytes being
// skipped are the actual jump instruction to
// DOCOL itself, inserted by the colon compiler
// when it creates a new entry in the
// dictionary.
L('DOCOL');
  xchgspbp();   // swap SP and BP, SP=ret stack
  push('SI');   // push "instruction pointer"
  xchgspbp();   // restore SP and BP
  addax(4);     // skip word's code field
  mov('SI', 'AX');    // "IP" := word body
  NEXT();       // start executing the word

// The jump instruction inserted by the
// compiler is an indirect jump, so it needs to
// read the location to jump to from another
// memory location.
//
// TODO: what?
//.addr:  dw DOCOL

// Semicolon is the only immediate
// primitive. It writes the address of EXIT to
// the end of a new word definition, makes the
// word visible in the dictionary, and switches
// back to interpretation state.
defword("//", 'SEMICOLON', F_IMMEDIATE);
  mov('BX', 'LATEST');
  andbytebxoffset(+2, ~F_HIDDEN ); // reveal
  mov_byte('STATE', 0); // now: interpretation 
  movN('AX', 'EXIT');   // compile EXIT
L('compile');
  mov('DI', 'HERE');
  stosw();              // compile AX to HERE
  mov('HERE', 'DI');    // advance HERE
  NEXT();

// Execution starts here.
L('start');
  cld();                // clear direction flag

// TODO: remove?
// Set up segment registers to point to the
// same segment as CS.
//   push cs
//   push cs
//   push cs
//   pop ds
//   pop es
//  pop ss

// Skip error signaling on initialization
  jmp('init');

// Display a red '!!' to let the user know an
// error happened and the interpreter is being
// reset
L('error');
  movN('AX', 0x0921);    // write '!'
  movN('BX', 0x0004);    // black background, red text
  movN('CX', 2);         // twice
  int(0x10);

// Initialize stack pointers, state, and
// terminal input buffer.
L('init');
  movN('BP', RPO); // BP is the return stack pointer
  movN('SP', SP0); // SP is the data stack pointer

// Fill TIB with zeros, and set STATE and >IN
// to 0
  mov_byteN('AL', 0); // mov byte al, 0
  movN('CX', STATE+4);
  movN('DI', TIB);
  rep_stosb();

// Enter the interpreter loop.
//
// Words are read one at time and searched for
// in the dictionary.  If a word is found in
// the dictionary, it is either interpreted
// (i.e. executed) or compiled, depending on
// the current state and the word's IMMEDIATE
// flag.
//
// When a word is not found, the state of the
// interpreter is reset: the data and return
// stacks are cleared as well as the terminal
// input buffer, and the interpreter goes into
// interpretation mode.
L('interpreter');
  call('token');    // parse word from input
  movbxA('LATEST'); // searching dictionary
L('intpreter.1')
  testbxbx();       // zero?
  jz('error');      // not, reset interpreter
  mov('SI', 'BX');
  lodsw();          // skip link
  lodsb();          // read flags+length
  //movdlal();      // save those for later use
  mov_byte('DX', 'AX');
  testal(F_HIDDEN); // entry hidden?
  jnz('interpreter.2'); // if so, skip it
  and_byteN(LENMASK);   // mask out flags
  cmpalcl();            // same length?
  jne('interpreter.2');  // if not, skip entry
  push('CX');
  push('DI');
  repe_cmpsb();          // compare strings
  pop('DI');
  pop('CX');
  je('interpreter.3');   // equal, search is over
L('interpreter.2');
  movbxAbx();            // skip to next entry
  jmp('interpreter.1'):  // try again
L('interpreter.3');
  mov('AX', 'SI');       // SI points to code
  movN('SI', '.loop');   // set SI so NEXT
                         // loops back to
                         // interpreter

// Decide whether to interpret or compile the
// word. The IMMEDIATE flag is located in the
// most significant bit of the flags+length
// byte. STATE can only be 0 or 1. When ORing
// those two, these are the possibilities:
//
// IMMEDIATE     STATE         OR   ACTION
//   0000000   0000000   00000000   Interpret
//   0000000   0000001   00000001   Compile
//   1000000   0000000   10000000   Interpret
//   1000000   0000001   10000001   Interpret
//
// A word is only compiled when the result of
// that OR is 1.  Decrementing that result sets
// the zero flag for a conditional jump.
  and_byteN('DX', F_IMMEDIATE);// isolate IMMEDIATE
  // or dl,[STATE]
  or_byteRA('DX', 'STATE'); // OR with state
  // dec dl
  dech('DX');            // decrement
  jz('compile');         // zero, compile
  jmpax();               // interpret/run

// TODO: maybe not need?
//('.loop');
//:  dw interpreter

// Parse a word from the terminal input buffer
// and return its address and length in DI and
// CX, respectively.
//
// If after skipping spaces a 0 is found, more
// input is read from the keyboard into the
// terminal input buffer until return is
// pressed, at which point execution jumps back
// to the beginning of token so it can attempt
// to parse a word again.
//
// Before reading input from the keyboard, a
// CRLF is emitted so the user can enter input
// on a fresh, blank line on the screen.
L('token');:
  movd('DI', 'TOIN');// current position in TIB
  movN('CX', -1 & 0xffff); // search "indefinitely"
  mo_byte('AX', 32) // find non-space
  repe_scasb();
  dec('DI');       // skip 1 char
  cmpbyteAdi(0);   // found a 0?
  je('.readline'); // if so, read more input
  movN('CX', -1 & 0xffff); // search "indefinitely" again
  repne_scasb();   // this time, for a space
  dec('DI');       // adjust DI again
  mov('TOIN', 'DI'));// update current position in TIB
  not('CX')        // after ones' complement, CX=length+1
  dec('CX')        // adjust CX to correct length
  subdicx();       // point to start of parsed word
  ret();
L('.readline');
  mov_byte('AX', 13);
  call('writechar'); // CR
  mov_byte('AX', 10);
  call('writechar'); // LF
  movN('DI', TIB);        // read into TIB
L('.readline.1');
  // mov byte ah, 0
  mov_byte_hN('AX', 0); // wait key is pressed
  int(0x16);
  cmpal(13)          // return pressed?
  je('.readline.3'); // if so, finish reading
  cmpal(8);          // backspace pressed?
  je('.readline.2'); // if so, erase character
  call('writechar'); // or, write character
  stosb();           // store character in TIB
  jmp('.readline.1');// keep reading
L('.readline.2');
  cmpdi(TIB);        // start of TIB?
  je('.readline.1'); // if so, nothing to erase
  dec('DI');         // erase character in TIB
  call('writechar'); // move cursor back one character
  movN('AX', 0x0a20);// BS, SPACE (cursor stay)
  movN('CX', 1);
  int(0x10);         // writechar set BH 0
  jmp('.readline.1');// keep reading
L('.readline.3');
  movN('AX', 0x0020);
  stosw();           // put delimiter & 0 in TIB
  call('writechar'); // write a space
  movwordA('TOIN', 0); // ">IN" := start of TIB
  jmp('token');      // try parsing a word again

// writechar writes a character to the
// screen. It uses INT 10/AH=0e to perform
// teletype output, writing the character,
// updating the cursor, and scrolling the
// screen, all in one go. Writing backspace
// using the BIOS only moves the cursor
// backwards within a line, but does not move
// it back to the previous line.  writechar
// addresses that.
L('writechar');
  push('AX');    // INT 10h/AH=03h may clobber AX
  movN('BH', 0); // video page 0 for all BIOS calls
  mov_byte_hN('AX', 3); // cursor pos (DH=row, DL=column)
  int(0x10);
  pop('AX');     // restore AX
  mov_byte_hN('AX', 0x0e); // teletype output
  //movbl(0x7);
  mov_byteN('BX', 0x7);// black, light grey text
  int(0x10);
  cmpal(8);    // backspace?
  jne('writechar.1'); // not: nothing else to do
  testdldl();  // was cursor in first column?
  jnz('writechar.1');  // not, nothing else to do
  // mov ah, 2
  mov_byte_hN('AX', 2); // move cursor
  //movdl(79);          // to last column
  mov_byteN('DX', 79)   // to last column
  dech('DX');           // of previous row
  int(0x10);
L('writechar.1');
  ret();

// TODO: what?
//  times 510-($-$$) db 0
//  db 0x55, 0xaa

// allocate(0x510-);
// data(0x55, 0xaa);

// New dictionary entries will be written
// starting here.
L('start_HERE');

////////////////////////////////////////
// 6502 translitteration of x86, lol
//
// list generated by:
//   cat sectorforth-6502.js | sed s,//.*,,g | grep '^ ' | grep '\S' | sed 's/ +//g' | sort | uniq -c  >> sectorforth-6502.js
//

// define registers in memory

// The 8 GPRs are:
ORG(0x0060); // TODO: good address?
  L('AX'); word(0); // AL, AH
  L('BX'); word(0); // BL, BH
  L('CX'); word(0); // CL, CH
  L('DX'); word(0); // DL, DH (ptrs in segm DS)
  L('SP'); word(0); // pointer to top of stack
  L('BP'); word(0); // Stack Base Ptr register
  L('SI'); word(0); // Source Index Register
  L('DI'); word(0); // Destination Index Register

// TODO:
// 1   JSRI(0x0000);

// 1   addax(4);
function addax(n) {
  CLC();
  LDAZ('AX');
  ADCN(n & 0xff);
  STAZ('AX');
  LDAZ('AX', hibyte);
  ADCN(n >> 8);
  STAZ('AX', hibyte);
}

// 1   addaxbx();
function addaxbx(n) {
  CLC();
  LDAZ('AX');
  ADCZ('BX');
  STAZ('AX');
  LDAZ('AX', hibyte);
  ADCZ('BX', hibyte);
  STAZ('AX', hibyte);
}

// 1   andal(LENMASK);
// 1   anddl(F_IMMEDIATE);
function and_byteN(r, m) {
  LDAZ(r);
  ANDN(m);
  STAZ(r);
}

// 1   andaxbx();
function andaxbx() {
  LDAZ('AX');
  ANDZ('BX');
  STAZ('AX');

  LDAZ('AX', hibyte);
  ANDZ('BX', hibyte);
  STAZ('AX', hibyte);
}

// 1   andbytebxoffset(+2, ~F_HIDDEN );
function andbytebxoffset(o, m) {
  LDAZ('BX');         STAZ(0);
  LDAZ('BX', hibyte); STAZ(1);

  LDYN(2);
  LDAIY(0);
  ANDN(m & 0xff);
  STAIY(0);
}

// 1   notax();
// 1   notcx();
function not(r) {
  LDAZ(r);
  ANDN(0xff);
  STAZ(r);

  LDAZ(r, hibyte);
  ANDN(0xff);
  STAZ(r, hibyte);
}

// 1   oral(F_HIDDEN);
function or_byteN(r, m) {
  LDAZ(r);
  ORAN(m);
  STAZ(r);
}
// 1   ordlA('STATE');
function or_byteRA(r, a) {
  LDYN(0);
  LDAIY(a);
  
  ORAZ(r);
  STAZ(r);
}

// 8   call('token');
function call(a) {
  JSRA(a);
}

// 1   cbw();
// Convert Byte to Word keeping sign
// AL = 9Bh     cbw     =>    AX = FF9Bh
// TODO: possibly don't do this rewrite original
function cbw() {
  let zero = gensym('cbw');
  let end = gensym('cbw');
  LDAZ('AX');
  BPL(zero);
  LDAN(0xff);
  STAZ('AX', hibyte); // AH
  BMI(end);
 L(zero);
  LDAN(0x00);
  STAZ('AX', hibyte); // AH
 L(end);
}

// 1   cld();
function cld(){}

// TODO:
// 3   cmpal(8);
// 1   cmpalcl();
// 1   cmpbyteAdi(0);
// 1   cmpdi(TIB);

// 1   decax();
// 1   deccx();
// 1   decdh();
// 4   decdi();
function dec(r) {
  let skip = gensym('dec');
  LDYZ(r);
  BNE(skip);
  DECZ(r, hibyte); // hi borrow
 L(skip);
  DEY();
  STYZ(r);
}
function dech(r) {
  DECZ(r, hibyte);
}

// 5   int(0x10); // write to screen
function int(i) {
  switch(i) {
  case 0x10: { // write to screen
    // AX: 09cc  WRITE CHAR cc
    //     0921      ??  , '!'
    //     0a20   Space  ,  ' '
    //     0908
    // BX: BBTT  back col, text col
    //     0004  -black-,  -red-
    // CX:    2  twice
    //
    // 
    // AX: 03    GET cursor pos
    // BX: 00    video page 0 for all bios calls
    // =>
    // DX: 0300  RR CC
    //
    // AX: 0e    TELETYPE OUTPUT
    // BX:   07  black background, grey text
    //
    // AX: 02    MOVE CURSOR
    // DX:   79  column
    //     RR    row

    // writechar set BH 0
    LDAN(0); STAZ('BX', hibyte);
    break; }
  case 0x16: { // get keypress
    // TODO:
    break; }
  }
}

// 2   int(0x16); // get keypress

// 7   jmp
function jmp(a) { JSRA(a) }

// 2   jmpax();

// 5   je
// 2   jne
// 2   jnz
// 2   jz
function je(a) { BEQ(a) }
function jne(a) { BNE(a )}
function jnz(a) { BNE(a) }
function jz(a) { BEQ(a) }


// - https://c9x.me/x86/html/file_module_x86_id_160.html
// if(IsByteOperation()) {
// 	AL = Source;
// 	if(DF == 0) (E)SI = (E)SI + 1;
// 	else (E)SI = (E)SI - 1;
// }
// else if(IsWordOperation()) {
// 	AX = Source;
// 	if(DF == 0) (E)SI = (E)SI + 2;
// 	else (E)SI = (E)SI - 2;
// }
// else { //doubleword transfer
// 	EAX = Source;
// 	if(DF == 0) (E)SI = (E)SI + 4;
// 	else (E)SI = (E)SI - 4;
// }

// TODO:
// 1   lodsb();
// 2   lodsw();

// TODO:
// 2   stosb();
// 5   stosw();



// mov
function mov_byteN(a, n) {
  LDAN(n); STAZ(a);
}

function mov_byte_hN(a, n) {
  LDAN(n); STAZ(a, hibyte);
}

function movN('RN', r, n) {
  LDAN(n & 0xff); STAZ(r);
  LDAN(n >> 8);   STAZ(r, hibyte);
}

function mov(a, b) {
  LDAZ(b);      STAZ(a);
  LDAZ(b, hibyte); STAZ(a, hibyte);
}

// indirection (a and b may be same)
function movbxAbx(a, b) {
  LDAZ(b);         STAZ(0);
  LDAZ(b, hibyte); STAZ(1);
  LDAIY(0);        STAZ(a);
  LDAIY(1);        STAZ(a, hibyte);
}

// 5   popax();
// 5   popbx();
// 1   popcx();
// 1   popdi();
// 1   popsi();
// 1   popsi();
function pop(r) {
  LDAZX(0); STAZ(r);
  LDAZX(1); STAZ(r, hibyte);
  INY(); INY();
}

// 1   popAR();
function popAR(r) {
  pop(0);
  LDYN(0);
  LDAZ(0); STAIY(0);
  LDAZ(1); STAIY(1);
}

// 12  pushax();
function push(r) {
  DEY(); DEY();
  LDAZ(r);         STAZX(0);
  LDAZ(r, hibyte); STAZX(1);
}

// 2   pushword('HERE');
function pushN(n) {
  LDAN(n & 0xff); STAZ(0);
  LDAN(n >> 8);   STAZ(1);
  push(0);
}

// 2   pushwordAbxa();
function pushAR(r) {
  LDY(0);
  LDAIY(r);         STAZ(0);
  LDAIY(r, hibyte); STAZ(1);
  push(0);
}

// TODO:
// 1   repe_cmpsb();
// 1   repe_scasb();
// 1   rep_movsb();
// 1   repne_scasb();
// 1   rep_stosb();

// 2   ret();
function ret() { RTS() }

// TODO:
// 1   setnzal();

// TODO:
// 1   subdicx();

// TODO:
// 1   testal(F_HIDDEN);
// 1   testaxax();
// 1   testbxbx();
// 1   testdldl();

// 4   xchgspbp();

// used to access hibyte
function hibyte(a) { return a+1}

let gencount= 0;
function gensym(prefix) {
  return prefix + '_' + gencount++;
}
