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
  BCS('_linkey.next');
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
  BCS(next);
  // BEQ if found
  // BNE if !found
  // Y is offset, A is still char
}

function lib_BINKEY(table) {
  // A: key, X: table zpaddress
L('BINKEY');
  LDYZX(0),STYZ(0);
  LDYZX(1),STYZ(1);

  LDYN(0),STYZ(2);

  TAX();
  // first byte is N items
  LDYN(0),LDAIY(0),TAY();
  INCZ(0),BNE('_BINKEY.inc'),INCZ(1),L('_BINKEY.inc');

  CLC();
 L('_BINKEY'); L('_BINKEY.toobig');
  // half the interval size
  TYA(),LSR(),TAY();
  BEQ('_BINKEY.fail');
  TXA();
  // compare first choice at Y
  CMPIY(0);
  terminal.TRACE(jasm, ()=>print(
    'binkey', {
      b: m[0],
      w: m[2],
      a: cpu.reg('a'),
      x: chr(cpu.reg('x')),
      y: cpu.reg('y'),
      c: chr(m[cpu.w(0)+cpu.reg('y')]),
      flags: cpu.flags(),
    }));
  //BEQ('_BINKEY.toobig');
  BEQ('_BINKEY.found');
  BCC('_BINKEY.toobig');
 L('_BINKEY.toosmall');
  // change the base
  TYA(),SEC(),ADCZ(2),STAZ(2);
  TYA(),SEC(),ADCZ(0),STAZ(0); // lo
//  LDAZ(1),ADCZ(1),STAZ(1); // hi
  BNE('_BINKEY'); // always
 
 L('_BINKEY.fail'); // TODO: just means done?
  // TODO: how to signal not found?
  SEC();
  // need to fallthrough to get right index!!!
 L('_BINKEY.found');
  TYA(),SEC(),ADCZ(2),TAY();
  terminal.TRACE(jasm, ()=>print(
    'BINKEY', {
      b: m[0],
      w: m[2],
      a: cpu.reg('a'),
      x: chr(cpu.reg('x')),
      y: cpu.reg('y'),
      c: chr(m[cpu.w(0x70)+cpu.reg('y')]),
      flags: cpu.flags(),
    }));
  RTS();

  // BCS failed
  // BCC found. [0],Y=0  points at it
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
function test_LIN() {
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
//  TEST
function test_BINKEY() {
ORG(0x70); L('TABLE'); word('keys');

let keys = "*@MQY^cegir";
print('KEYS: === "',keys,'"');
ORG(0x300);
L('keys'); pascalz(keys);
for(let i=1; i<64; i++) data(0);
L('searching'); string('searching...');
L('found'); string('found');
L('fail');  string('FAIL!');

//L('keys'); string('0123456789ABCDEFGHIJKMNOPQRSTUVWXYZ'); byte(0xff);

ORG(start);

  putl('searching');

  LDXN('TABLE');
  LDAN(ord('A'));
  LDAN(17);
  LDAN(ord('Y'));
  LDAN(ord('Y'));
  LDAN(ord('Q'));
  LDAN(ord('r'));
  LDAN(ord('c'));
  LDAN(ord('^'));
  LDAN(ord('@'));
  LDAN(ord('*'));
  // A: key, X: table zpaddress
  JSRA('BINKEY');
  BCS('failed');
  putl('found');
  terminal.TRACE(jasm, ()=>{ process.exit() });
  BRK();

 L('failed');
  TYA();
  LDYN(0); JSRA(terminal.aputd);
  putl('fail');
  terminal.TRACE(jasm, ()=>{ process.exit() });
  BRK();

  library(lib_BINKEY);
}



////////////////////////////////////////
// RUN
var cpu = terminal.cpu6502();
var m = cpu.state().m;

//test_LIN();

test_BINKEY();

// crash and burn
jasm.burn(m, jasm.getChunks());
cpu.reg('pc', start);
cpu.setTraceLevel(3);
cpu.setTraceLevel(0);
cpu.setOutput(1);
cpu.run(-1);
