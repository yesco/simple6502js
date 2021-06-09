// TODO: simple6502.js
let cpu6502 = require('./fil.js');
let jasm = require('./jasm.js');

ORG(0x0501);


L('start');
	LDXN(0x42);
L('next');
	DEX();
        JMPA('start');
        //JMPA('start');
// TODO: doesn't write address!
        BRK();
        BNE('next');

L('fie');
        LDAN(3);
        LDAN(3, (v)=>v*v);
        LDAN(3);
L('foo');
        LDAN('foo', lo);
        LDAN('foo', hi);
        LDAN('bar', hi); // forward!
        LDAN('bar', (v)=>hi(v)*hi(v)); // delaye

L('bar');
        LDAN(0xbe);
        LDAN(0xef);

L('fish');
        LDAN(0xff);

L('string');
        string("ABC");

L('sverige');
        string("Svörigä");

L('char');
        char('j');
        char('ö');
L('copy');
        char('©');

L('here');
	BNE('here');
	LDAN(0x42);
	BNE('there');
	RTS()
L('there');
	RTS()
L('end');

console.log(jasm.getChunks());
console.log(jasm.getHex(1,1,1));
console.log(jasm.getHex(0,0,0));


let cpu = cpu6502.cpu6502(); // hmmm "call it..?"
let m = cpu.state().m;

jasm.burn(m, jasm.getChunks());

// crash?

let start = 0x501; // TODO: get from label?
cpu.reg('pc', start);
console.log(cpu.state());
console.log(cpu.dump(start));

console.log('BCC=' + BCC.toString(), BCC);
console.log('BNE=' + BNE.toString(), BNE);
console.log('BEX=' + DEX.toString(), DEX);
console.log('JMPA=' + JMPA.toString(), JMPA);


//cpu6502.dump(0x501, 16); which mem?
cpu.run(10, 1);

function burn(m, chunks) {
  chunks.forEach(c=>{
    let a = c.shift();
    let lab = c.shift();

    let b;
    while (typeof (b = c.shift()) == 'number') {
      m[a++] = b;
    }
  });
}











process.exit(0);







if (typeof require !== 'undefined') {
   // nodejs not browser   
   if (!module.parent) {
     // invoked as program
     console.log('invoked as program...');
     simORIC();
   } else {
     // required by other code as module
     console.log('invoked as module...');
  }

  //if (process.argv[2] !== 'test') {
  //  ORIC(process.argv[2]);
  //  return;
  //else {
  //  // let cpu = cpu6502();
  //}     
} else {
  // most likely browser
  console.log('included in browser...');
}
