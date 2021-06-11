//               READLINE-65
// 
//          (>) 2021 Jonas S Karlsson
//                jsk@yesco.org
//
let terminal = require('./terminal-6502.js');
let jasm = require('./jasm.js');

// generate asm for readline
// => A: count
// TODO: maybe len is not static?
// uses all registers
function readline(buffer, len) {
L('READLINE');
  LDXN(0);
  BEQ('_readline.next'); // always!

L('_readline.redraw');
  putc('\\');
  putc('\n');

// X contains length
L('EDITLINE');
  // enforce length
  LDAN(0);
  STAAX(buffer);

L('_readline.print');
  TXA(); PHA(); {
    putl(buffer);
  } PLA(); TAX();

L('_readline.next');
  // zero out next char!
  LDAN(0);
  STAAX(buffer);

L('_readline.wait');
  // wait for key
  JSRA(terminal.agetc);
  BEQ('_readline.wait');
    
  // return
  CMPN(0x0d);
  BEQ('_readline.rts'); // Z set!

  // backspace/DEL
  CMPN(0x7f);
  BNE('_readline.1');
  // TODO: remove one test by change 0
  CPXN(1);
  BCS('_readline.next'); 
  DEX();
  putc(0x08); // BS
  putc(' ');
  putc(0x08);
  BNE('_readline.next');

L('_readline.1');
  // CTRL-L re-draw
  CMPN(ord('L')-64);
  BEQ('_readline.redraw')

  // CTRL-U empties line
  CMPN(ord('U')-64);
  BNE('_readline.3');
  LDXN(0);
  BEQ('_readline.redraw');

L('_readline.3');
  // CTRL-X cancel
  CMPN(ord('X')-64);
  BNE('_readline.4');
  putc('\\');
  putc(0x0a);
  LDXN(0); // Z set!
  STXA(buffer);
L('_readline.rts');
  // make sure Z flag correct if jmp here
  RTS();

L('_readline.4');
  // TODO: full editing:
  // - CTRL-A
  // - CTRL-F
  // - CTRL-B
  // - CTRL-E
  // - CTRL-D

  // ignore other control chars
  CMPN(ord(' ')-1);
  BCS('_readline.next');

  // full?
  CPXN(len);
  BCC('_readline.next');
    
  // add
  STAAX(buffer);
  INX();

  // echo
  JSRA(terminal.aputc);

  BNE('_readline.next'); // always!
}




let start = 0x501;

////////////////////////////////////////
//  TEST
{
ORG(0x400);
L('prompt'); string('INPUT> ');
L('edit'); string('EDIT> ');
L('input'); allot(80);
L('help'); string(`
READLINE-65
===========
D  E  M  O
- maxlen
- return
- backspace
- CTRL-L redraw
- CTRL-X abort
- CTRL-U empty
- CTRL-
- EDITLINE preset value

`);

ORG(start);
L('start');

  putl('help');

L('readeditloop');
  putl('prompt');
  putc(0x07);
  
  JSRA('READLINE');
  TXA(); PHA();
  putc('\n');

  // print result
  putc('=');
  putl('input');
  putc('<');
  putc('\n');

  putl('edit');
  LDXN(2); // keep two chars
  PLA(); TAX();
  JSRA('EDITLINE');
  putc('\n');
  putc('\n');

  // print result
  putc('=');
  putl('input');
  putc('<');
  putc('\n');

  BNE('readeditloop');
  
  putc(0x0a);
  BRK();

  library(readline, 'input', 5);
}

////////////////////////////////////////
// RUN
let cpu = terminal.cpu6502();
let m = cpu.state().m;
//cpu.setTraceLevel(traceLevel);

// crash and burn
jasm.burn(m, jasm.getChunks());
cpu.reg('pc', start);
cpu.setTraceLevel(2);
cpu.run(-1, 1, 1);



////////////////////////////////////////
//  library
function library(lib, ...args) {
  let a = jasm.address();
  lib(...args);
  let len = jasm.address() - a;
  console.log('=LIBRARY:', lib.name, len, 'bytes');
}

function putl(label) {
  LDXN(0xff);
  LDAN(label, lo);
  LDYN(label, hi);
  JSRA(terminal.aputs);
}

function putc(c) {
  if (typeof c==='string')
    c = c.charCodeAt(0);
    
  LDAN(c);
  JSRA(terminal.aputc);
}

function ord(c) {
  return c.charCodeAt(0);
}


// TODO: if not this, hang!
//process.exit(0);

