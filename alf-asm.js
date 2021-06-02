// TODO: simple6502.js
let cpu6502 = require('./fil.js');
let jasm = require('./jasm.js');

ORG(0x0501);


L('start');
  LDXN(0x00);
  JSRA('winc');    
  JMPA('end');

L('winc');
  INCZX(0);
  BNE(rel('winc1'));
  INCZX(2); // TODO: BUG, doesn't care arg!
L('winc1');
  next();

L('end');
L('halt');
  JMPA('halt');

console.log(jasm.getChunks());
console.log(jasm.getHex(1,1,1));
console.log(jasm.getHex(0,0,0));

// ALForth helpers
function next() {
  RTS();
  // TODO: typically goto "next"
}





let cpu = cpu6502.cpu6502(); // hmmm "call it..?"
let m = cpu.state().m;

jasm.burn(m, jasm.getChunks());

// crash?

let start = 0x501; // TODO: get from label?
cpu.reg('pc', start);
console.log(cpu.state());

console.log('BCC=' + BCC.toString(), BCC);
console.log('BNE=' + BNE.toString(), BNE);
console.log('BEX=' + DEX.toString(), DEX);
console.log('JMPA=' + JMPA.toString(), JMPA);


//cpu6502.dump(0x501, 16); which mem?
cpu.run(10, 1);
console.log(cpu.dump(0x0000, 2));

console.log('INCZX=' + INCZX.toString(), INCZX);
