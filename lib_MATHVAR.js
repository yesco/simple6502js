// 21 byte 32-bit multiply from:
// - http://forum.6502.org/viewtopic.php?f=2&t=5017
// not sure if much more efficient
// - http://www.6502.org/source/integers/32muldiv.htm

// lib_MATHVAR
// ===========
// Variable Size Math, "pascal-nums"
// - each value has 0-255 bytes significand
// - little endian
// - stored with length prefix (1 byte)
//   (same as pascal string/malloced string!)
// -   0 is stored as (0)
// -   1 is stored as (1, 1)
// - 255 is stored as (1, 255)
// - 258 is stored as (2, 2, 1)
// - 64K is stored as (5, 0, 0, 0, 0, 1)


// 32bit multiply and 'variable bit' multiply
// -- CT32X04 -- 2017, jsii
// (not thoroughly tested)
// Uses .AXY +0
// 
// Operation:  C = A * B  (A B 32+bits)
//   where C = 64 bit result
//         (or 'variable bit' result) (see below)
//
// Howto:
// 
// Y = 33, 25, 17 or 9, for example. 
//     (33 -> 32 bit operation,
//      25 -> 24 bit operation,
//      17 -> 16 bit operation,
//       9 ->  8 bit operation)
//

let utilty = require('./utility.js');
let terminal = require('./terminal-6502.js');
let jasm = require('./jasm.js');

let start = 0x501;

ORG(0x61); allotTo(0x6d);

ORG(0x61); L('#1');
ORG(0x61); L('result32'); // $61--$68 - 8 bytes
ORG(0x62); L('result24'); // $62--$67 - 6 bytes
ORG(0x63); L('result16'); // $63--$66 - 4 bytes
ORG(0x64); L('result8');  // $64--$65 - 2 bytes
ORG(0x6a); L('#2');

ORG(start);
{
  // (format "%x" (* 47114711 42424242))
  // "719e743b7a87e"
  // 4711

L('start');
  let bits = 8;

  LDAN(0x30); // #1 = 0x30
  STAZ('#1'); 

  LDXN(0x67); // #2 = 0x67
  STXZ('#2');

  let savcyc = 0;
  terminal.TRACE(
    jasm, ()=>savcyc=cpu.state().cycles);

  bits = 64;
  LDYN(bits+1);
  JSRA('mul32');

  terminal.TRACE(jasm, ()=>{
    print('cycles', cpu.state().cycles-savcyc);
  });
  // Not the most performant...
  // -1           - (29K)
  //  0 bits .  107 (+ 92)
  //  1         199 (+ 92)
  //  2         291 (+ 92)
  //  3         383 (+ 92)
  // below is valid:
  //  8 bits = 1003 cycles!
  // 16 bits = 1739 cycles
  // 24 bits = 2475 cycles
  // 32 bits = 3211 cycles!
  // 65        6755 (not valid)
  // result XA = (19, 80) = 4944
  LDAZ('result8'); // lo
  LDYZ('result8', inc) // hi
  
  JSRA(terminal.aputd);
  LDAN(10),JSRA(terminal.aputc);

  NOP();
  NOP();
  terminal.TRACE(jasm, ()=>process.exit(0));
  BRK();

L('mul32'); // b25
  LDXN(0x09);

  // shift result value one bit right
L('_mul.shift');
  RORZX(0x60); // 69--61
  DEX();
  BNE('_mul.shift');

  BCC('_mul.nocarry');
  
  // add #2
  LDXN(0xFC); // using zero page wrap address

  CLC();
L('XMEX00');

  LDAZX(0x69); // 65--68
  ADCZX(0x6E); // 6a--6d
  STAZX(0x69);
  INX();
  BNE('XMEX00');

L('_mul.nocarry');
  DEY();
  BNE('mul32');
  RTS();
}

////////////////////////////////////////
// RUN
var cpu = terminal.cpu6502();
var m = cpu.state().m;

let l = jasm.getLabels();

// crash and burn
jasm.burn(m, jasm.getChunks());
console.log({start});

cpu.setLabels(l);

cpu.setTraceLevel(2);
cpu.setTraceLevel(1);
cpu.setTraceLevel(0);

cpu.setOutput(1);
cpu.setOutput(0);

cpu.reg('pc', start);
cpu.run(-1);
