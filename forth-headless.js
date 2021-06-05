// Since ' ' is 0x20 is JSR:
//   why don't we make a forth that dispatches
//   onto those locations?
//   96x96 possible destinations = 9K, lol
//
// Yeah, it's going to fragment memory...
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

' 22 22 77 22 77 13 13 13 22 22 77 drop 13 1+ 1+ dup 2* 2* + dup dup bye'


;




/// ASM:BEGIN ------------------------

ORG(start);
 L('PROGRAM'); string(program);

// HI zero page data stack:
//   don't trash X in impl.
function push() { DEX(); DEX(); }
function pull() { INX(); INX(); }

F('22', ()=>{
  push();
  LDAN(22); STAZX(0);
  LDAN(0);  STAZX(1);
});

F('77', ()=>{
  push();
  LDAN(77); STAZX(0);
  LDAN(0);  STAZX(1);
});

F('13', ()=>{
  push();
  LDAN(13); STAZX(0);
  LDAN(0);  STAZX(1);
});

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


/// ASM:END ------------------------

let cpu = cpu6502.cpu6502();
let m = cpu.state().m;

jasm.burn(m, jasm.getChunks());

//cpu.reg('x', 0);
cpu.reg('s', 0xff);
cpu.reg('pc', start);


print(cpu.run(-1, 1, patcher));

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
