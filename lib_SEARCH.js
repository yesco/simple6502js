//               READLINE-65
// 
//          (>) 2021 Jonas S Karlsson
//                jsk@yesco.org
//
let terminal = require('./terminal-6502.js');
let jasm = require('./jasm.js');

let start = 0x501;

function lib_LINKEY() {
  // A: key, X: table zpaddress
  // => BEQ: if found Y: index
  //    BNE: if not found
  // First variant:  b26  c27 + n*17
  // Inline (next f): i8 c2+ 9n
  // Current: i3 b16 c28+ 10n
L('LINKEY');
  // A: key, X: table zpaddress
  // => Z: match offset in Y
  //    C: no match (?)
  // zero terminated table
  LDYZX(0); STYZ(0); // i3 b16 c28+ 10n
  LDYZX(1); STYZ(1);
  LDYN(0xff);
L('_linkey.next'); // c10
  INY();
  CMPIY(0);
  BCC('_linkey.next');
  RTS();
  // BEQ if found
  // BNE if !found
  // Y is offset, A is still char
}

function lib_iLINKEY(table) {
  let next = gensym('_linkey');
  // A: key        // i8 c2+ 9n
  LDYN(0xff);
L(next); // c9
  INY();
  CMPAY(table);
  BCC(next);
  // BEQ if found
  // BNE if !found
  // Y is offset, A is still char
}

function lib_BINKEY(table) {
  // A: key, Y: table zpaddress
  // => X: index (trashes AY)
L('BINKEY');
  

  RTS();
}

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


////////////////////////////////////////
//  TEST
function test() {
ORG(0x70); L('TABLE');  word('keys');

ORG(0x300);
L('searching'); string('searching...');
L('found'); string('found');
L('fail');  string('FAIL!');
L('keys'); string('0123456789ABCDEFGHIJKMNOPQRSTUVWXYZ'); byte(0xff);

ORG(start);

  putl('searching');

  LDXN('TABLE');
  LDAN(ord('A'));
  LDAN(17);
  LDAN(ord('Z'));
  LDAN(ord('a'));
  // A: key, X: table zpaddress
  JSRA('LINKEY');
  // => BEQ: if found Y: index
  //    BNE: if not found
  BNE('failed');
  putl('found');
  terminal.TRACE(jasm, ()=>{ process.exit() });
  BRK();

 L('failed');
  TYA();
  LDYN(0); JSRA(terminal.aputd);
  putl('fail');
  terminal.TRACE(jasm, ()=>{ process.exit() });
  BRK();

  library(lib_LINKEY);
}

////////////////////////////////////////
// RUN
var cpu = terminal.cpu6502();
var m = cpu.state().m;

test();

// crash and burn
jasm.burn(m, jasm.getChunks());
cpu.reg('pc', start);
cpu.setTraceLevel(3);
cpu.setOutput(1);
cpu.run(-1);