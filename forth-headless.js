//          HEADLESS FORTH
//
//               6502
//
//          Jonas S Karlsson
//
// What is headless? It usually means
// without UI. This FORTH "embryo" has
// no UI, no dictionary.
//
// Postulate: 6502 was created to run
// FORTH code natively, see:
//
// ' 0 1 3 dup + 7 33 2* 42 drop 77 bye'
//
// To execute it: store it in memory
// then just "JMP address"!
//
// Yes, it works! WTF! How?
// 
// ' ' or 0x20 is, wait, JSR!
//
// So space is a subroutine call, now
// we only need to store our words at
// the address as given by the first
// two letters!
//
// Special case 
//  '  ' (2 spaces) => RET-1, RTS
//  - 2 letters RTS
//  - n letters RET+n-2, RTS
//  - 1 letter, store as ' L'
//  - numbers - BRK!
//  - ' + ' also gives BRK
//  - capture BRK
//    - if number push on stack
//    - if single letter do '  L'
// 
// NOTICE: All UR memory are belong
//  Headless Forth (or very fragmented)
// - Unsupported words give BRK
// - ':' not defined == strcpy!
//

// FB post
// - https://m.facebook.com/groups/6502CPU/permalink/2949669985302588/?ref=content_filter
// HEADLESS FORTH!
//
// So, did you know that 6502 can run forth source code natively?
//
// Imagine writing:  ' 2 dup 3 + 2* =0 42 dup drop bye'
//
//And then just jump to as if it is machine code! And who says it isn't?
//
// So, let's do it!
//
// I've prototyped an embryo of functions; and they work, as does 2 digit numbers,  it's a fun idea, but probably I won't go any further... (used my jsasm + js codegen)
//

let cpu6502 = require('./fil.js');
let jasm = require('./jasm.js');
let aputc = 0xfff0;
let aputd = 0xfff2;
let aputs = 0xfff4;
let output = 1; // show 'OUTPUT: xyz'

let start = 0x0501;

// MUST have a leading space...
let program = 

' 0 1 2 3 74 11 12 13 14 42 17 bye';

//1232312323
// '   0     1 2 7 42 3 2 1 0 1 2 3 4 5 6 7 8 9 22 22 77 22 77 13 13 13 22 22 77 drop 13 1+ 1+ dup 2* 2* + dup dup bye'


;




/// ASM:BEGIN ------------------------

ORG(start);
 L('PROGRAM'); string(program);

ORG(start+1024);
 L('BRK');

 // ' 74' comes here
 PLA(); STAZ(0); // lo = first digit '7'
 
 SEC();
 SBCN(ord('0')+2); // pc+=2 by jsr
 STAZ(2); // 07
 
 push();  STAZX(0); // 07 on stack
 LDAN(0); STAZX(1);

 PLA(); STAZ(1); // hi = second digit '4'

 SEC();
 SBCN(ord('0'));
 STAZ(3); // 04

 push();  STAZX(0); // 04 on stack
 LDAN(0); STAZX(1);

 // 0,1:lohi = '4','2'  2,3: 4,2
 PLP();

 // look at first char
 LDAZ(0);
 CMPN(ord(' '));
 BNE('BRK_1');
 // TODO: back one more step
 JMPA('RTS_goback');
L('BRK_1');
 
 // look at second char
 LDAZ(1);
 CMPN(ord(' '));
 BNE('BRK_2');
 JMPA('RTS_goback');

L('BRK_2');
 // TODO: it's not all nubmers....
 pull();
 LDAZ(2); // first number
 CLC(); ROL(); // ASL()?
 STAZ(0); // 2 x number
 CLC(); ROL(); CLC(); ROL(); // 8x number
 CLC();
 ADCZ(0); // 2x + 8x = 10x !
 ADCZ(3);!
 
          STAZX(0);
 LDAN(0); STAZX(1);

 RTS();
 

// catch brk!
ORG(0xfffe);
 L('BRKVEC');
 word('BRK');
 

// HI zero page data stack:
//   don't trash X in impl.
function push() { DEX(); DEX(); }
function pull() { INX(); INX(); }

F('1+', ()=>{
  INCZX(0);
  BNE('_1+');
  INCZX(1);
 L('_1+');
});

F('2*', ()=>{
  ASLZX(0);
  ROLZX(1);
});

F('2/', ()=>{
  CLC();
  RORZX(1);
  RORZX(0);
});

F('', ()=>{
  NOP(); // LOL: we don't even need one!
});


F('+', ()=>{
  CLC();
  LDAZX(0); ADCZX(2); STAZX(2);
  LDAZX(1); ADCZX(3); STAZX(3);
  pull();
});

F('=0', ()=>{
  CLC();
  LDAZX(0); ORAZX(1);
  BEQ('=0_zero'); // and A is zero => -1 !
  LDAN(0xff); // => 0
 L('=0_zero');
  EORN(0xff);
  STAZX(0); STAZX(1);
});

F('dup', ()=>{
  push();
  LDAZX(2); STAZX(0);
  LDAZX(3); STAZX(1);
});

F('drop', ()=>{
  pull();
});

F('bye', ()=>{
  BRK();
});

ORG(0x1000);
L('RTS_goback');
    // lo
    PLA();
    TAY();
    BNE('_RTS_goback');
    // hi
    PLA();
    SEC();
    SBCN(1);
    PHA();
   L('_RTS_goback');
    // lo
    DEY();
    TYA();
    LDYN(0);
    PHA();
    RTS();

L('RTS_goforward');
    // lo
    PLA();
    CLC();
    ADCZ(0);
    TAY();
    // hi
    PLA();
    ADCN(0);
    PHA();
    // lo
    TYA();
    PHA();
    RTS();


// --- numbers

// assume Y is always zero!
for(let n = 0; n <= 9; n++) {
  let a = 0x2000 + n + 48;
  ORG(a);
//  print(n, hex(4,a));
//  L(''+a);
  INY();
  //let i = 10-n; print("EOR ", i, (i^0xff)-245);
}
TYA();
EORN(0xff);
SEC();
SBCN(245);
push();
         STAZX(0);
LDAZ(0); STAZX(1);
LDYN(0);
JMPA('RTS_goback');

// it doesn't fit
if (0) {
// x0
for(let n = 0; n <= 9; n++) {
  let a = 0x3000 + n + 48;
  ORG(a);
  INY();
  let i = 10-n; let x = (i^0xff)-245;
  print(n, hex(4,a), i, x, 10*x);
}
TYA();
CLC(); ROL(); // ASL?
EORN(0xff);
SEC();
SBCN(245);
// multiply by 10
STAZ(0);
CLC(); ROL(); // ASL?
CLC(); ROL(); // ASL?
ADCZ(0);

push();
         STAZX(0);
LDAZ(0); STAZX(1);
LDYN(0);
RTS();
}

/// ASM:END ------------------------

let cpu = cpu6502.cpu6502();
let m = cpu.state().m;

jasm.burn(m, jasm.getChunks());

//cpu.reg('x', 0);
cpu.reg('s', 0xff);
cpu.reg('pc', start);

// trace
print(cpu.run(-1, 0, patcher));

// see all non-zero memory!
cpu.dump(0, 65536/8, 8, 1);
print();
printstack();
print();

function patcher(pc, m, cpu) {
  let l = F.addrs[pc];
  if (l) {
    printstack();
    princ("\t\t\t\t");
    princ(l.padEnd(10, ' '));
    princ("'" + F.a2two[pc] + "'  ");
    print();
  }
}

function tracer(c, h) {
  cpu.tracer(c, h);
}




/// Code Generation Functions ------
function printstack() {
  let x = cpu.reg('x');
  princ(`  <${(0x101-x)>>1}> `)
  while(x < 0xff) {
    princ(cpu.w(x));
    princ(' ');
    x+=2;
  }
  print();
}

function F(name, code) {
  F.names = F.names || {};
  F.addrs = F.addrs || {};
  F.a2two = F.a2two || {};

  let two = name.substr(0, 2).padEnd(2, ' ');

  if (F.names[two]) throw `%% conflict with two letters start: ${F[two]}`;

  let a = ord(two[0]) + ord(two[1]) * 256;
 ORG(a);
 L(name);
  // generate code
  code();

  // generate return address to skip all chars but make sure we return to a space (= 0x20 == JSR!)
  switch(name.length) {
  case 0: // we save one space
  case 1: // go back one space
    JMPA('RTS_goback');
    break;
  case 2: // perfect!
    RTS();
    break;
  default: // skip extra letters (assume correct)
    LDAN(name.length - 2);
    STAZ(0);
    JMPA('RTS_goforward');
    break;
  }

  let bytes = jasm.address() - a;
  // TODO: test for overlap?

  F.names[two] = '  @' + hex(4, a) +
    ' # ' + (''+bytes).padStart(2) + '  ' +
    "'" + two + "'    " + name;
  F.addrs[a] = name;
  F.a2two[a] = two;
}

function ord(c) { return c.charCodeAt(0)}
function chr(c) { return String.fromCharCode(c)}
function print(...r) { return console.log(...r)}
function princ(s) { return process.stdout.write(''+s);}

Object.values(F.names).sort().forEach(v=>{
  print(v);
});
