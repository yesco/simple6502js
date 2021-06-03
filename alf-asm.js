// TODO: simple6502.js
let cpu6502 = require('./fil.js');
let jasm = require('./jasm.js');
let aputc = 0xfff0;



// ALF - ALphabet  F O R T H


{
  ORG(0x0501);

L('start');
  LDXN(0x00);
  JSRA('WINC');
  JSRA('WINC2');

  LDXN(0x02);
  JSRA('WDEC');

  JMPA('end');


L('WINC2');
  JSRA('WINC');
L('WINC');
  INCZX(0);
  BNE('winc1');
  INCZX(1);
L('winc1');
  next();

L('WDEC2');
  JSRA('WDEC');
L('WDEC');
  LDAZX(0);
  BNE('wdec1');
  DECZX(1);
L('wdec1');
  DECZX(0);
  next();

L('end');
  BRK();
L('halt');
  JMPA('halt');




}






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

// install traps!
function patch(pc, m, cpu) {
  let op= m[pc], d;

  // get effective address
  switch(op) {
    case 0x4c: // jmpa
    case 0x20: d= cpu.w(pc+1); break; // jsra
    case 0x6c: d= cpu.w(cpu.w(pc+1)); break; // jmpi
    // case 0x40: case 0x60: // TODO: rts/rti - look on stack?
    default: return;
  }

  // traps
  switch(d) {
    case 0xfff0: { // putc
      _putc(cpu.reg('a'));

      // just go to next instruction
      cpu.reg('pc+=3'); 

      // for jsr - no need to rts
      if (0x20) return 1; 

      // if jmpa jmpi - simulate rts!
      d= PL()+(PL()<<8);
      cpu.reg('pc',d);
      return 1; }
    case 0xfff2: // getc (no wait)
    case 0xfff4: //
    case 0xfff6: //
    ////////////////////////////////////////
    case 0xfff8: // ABORT 6502C
    case 0xfffa: // NMI
    case 0xfffc: // RESET
    case 0xfffe: // IRQ/BRK
  }
  return; // plesae go on
}

function _putc(a) {
  process.stdout.write(
    String.fromCharCode(cpu.reg('a')));
}


// crash?

let start = 0x501; // TODO: get from label?
cpu.reg('pc', start);
console.log(cpu.state());

//console.log('BCC=' + BCC.toString(), BCC);
//console.log('DEX=' + DEX.toString(), DEX);
//console.log('JMPA=' + JMPA.toString(), JMPA);

//cpu6502.dump(0x501, 16); which mem?
console.log(cpu.run(-1, 1, patch));
console.log();
console.log(cpu.dump(0x0000, 2));

//console.log('INCZX=' + INCZX.toString(), INCZX);
console.log('BNE=' + BNE.toString(), BNE);
