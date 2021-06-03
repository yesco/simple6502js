// TODO: simple6502.js
let cpu6502 = require('./fil.js');
let jasm = require('./jasm.js');
let aputc = 0xfff0;
let aputs = 0xfff2;
let aputd = 0xfff4;



// ALF - ALphabet  F O R T H

{
  // -- zero page variables
  ORG(0x00); L('R0');        word(0); // 00
             L('R1');        word(0); // 02
             L('R2');        word(0); // 04
             L('R3');        word(0); // 06
             L('R4');        word(0); // 08
             L('R5');        word(0); // 0a-0b
  // (ORIC uses...)

  // - FREE

  // ORIC 79 bytes input buffer
  ORG(0x35); L('INPUT_BUF'); allotTo(0x84);
  // testing: simple program!
  ORG(0x35); /* INPUT_BUF */ string('D+D.');

  // Forth
  ORG(0x85); L('NEXTPTR');   word('INPUT_BUF');

  // - FREE

  ORG(0xbf); L('DSTACK');    allotTo(0xfe); // 32*2
  ORG(0xff); L('DPTR');      byte(0xff);

  // - FREE

// program code

ORG(0x0501); L('reset');
  // make sure
  CLD();
  // init stack
  LDXN(0xff); TXS();
  // TODO: setup vectors


//////////////////////////////
 L('start');
  LDXN(0x00);
  //JSRA('WINC');
  //JSRA('WINC2');

  //LDXN(0x02);
  //JSRA('WDEC');

  // Init
  LDYN(0);

  JSRA('MAIN');

  JMPA('end');


 L('MAIN_zero');
  RTS();

 L('drop_next');
  inx2();

 L('next');
  INY();

  let drop= ()=>JMPA('drop_next');

  tabcod('MAIN', {
    // 11 Forth  Functions defined!
    '+' : function(){ // plus
      CLC()
      LDAZX(0); ADCZX(2); STAZX(2);
      LDAZX(1); ADCZX(3); STAZX(3);
      return drop;
    },

    '-' : function(){ // minus
      JSRA('Rminus');
//      SEC()
//      LDAZX(0); SBCZX(2); STAZX(2);
//      LDAZX(1); SBCZX(3); STAZX(3);
      return drop;
    },

    '&' : function(){ // and
      LDAZX(0); ANDZX(2); STAZX(2);
      LDAZX(1); ANDZX(3); STAZX(3);
      return drop;
    },

    '_' : function(){ // or
      LDAZX(0); ORAZX(2); STAZX(2);
      LDAZX(1); ORAZX(3); STAZX(3);
      return drop;
    },

    '^' : function(){ // eor
      LDAZX(0); EORZX(2); STAZX(2);
      LDAZX(1); EORZX(3); STAZX(3);
      return drop;
    },

    Not(){ // not
      LDAZX(0); EORN(0xff); STAZX(0);
      LDAZX(1); EORN(0xff); STAZX(1);
    },

    '=' : function(){ // = equal
      JSRA('Rminus');
      LDAZX(0);
      ORAZX(1);
      BEQ('inv'); // zero (A=0)

     L('false');
      LDAN(0xff); //     => false 0
     L('inv'); // A=0 => true -1
      EORN(0xff);
      STAZX(0);
      STAZX(1);
      return;
    },

    '<' : function(){ // < less than
      JSRA('Rminus');
      BMI('true');
      BPL('false');
     L('true');
      LDAN(0);
      JMPA('inv'); // => 1
    },

    '>' : function(){ // > greater than
      JSRA('Rminus');
      BEQ('false');
      BNE('true');
    },

    // TODO: put instruction before that also need to "drop"
    '\\' : function(){ // drop
      return drop;
    },

    Dup (){ // dup
      dex2(); // push
      LDAZX(2); STAZX(0);
      LDAZX(3); STAZX(1);
    },

    '.'	: function(){ // print
      save_ay(()=>{
        LDAZX(0);
        LDYZX(1);
        JSRA(aputd);
      });
      return drop;
    },

    default (){
      // TODO:: try parse number
    },
  })

  // TODO: Report ERROR as no match?
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

L('Rminus');
  SEC();
  // start w lo
  LDAZX(2);
  SBCZ(0);
  STAZX(2);
  // equal, now test lo
  LDAZX(3);
  SBCZX(1);
  STAZX(3);
  RTS();


L('MULTI_zero');
  RTS();

tabcod('MULTI', {
  A(){
    LDAN(65);
    JSRA(aputc);
  },
  B(){
    LDAN(66);
    JSRA(aputc);
  },
  C(){
    LDAN(66);
    JSRA(aputc);
  },
  default(){ // lol
  }});
  
L('end');
  BRK();
L('halt');
  JMPA('halt');




}






print(jasm.getChunks());
print(jasm.getHex(1,1,0));
print(jasm.getHex(0,0,0));

let cpu = cpu6502.cpu6502(); // hmmm "call it..?"
let m = cpu.state().m;

jasm.burn(m, jasm.getChunks());

// crash?

let start = 0x501; // TODO: get from label?
cpu.reg('pc', start);
print(cpu.state());

//console.log('BCC=' + BCC.toString(), BCC);
//console.log('DEX=' + DEX.toString(), DEX);
//console.log('JMPA=' + JMPA.toString(), JMPA);

//cpu6502.dump(0x501, 16); which mem?
let labels = jasm.getLabels();
let a2l = {};
Object.keys(labels).forEach(k=>a2l[labels[k]]=k);

print(cpu.run(-1, trace, patch));
print();
print(cpu.dump(0x0000, 2));

//print('INCZX=' + INCZX.toString(), INCZX);
print('BNE=' + BNE.toString(), BNE);


// --- ALForth helpers

function trace(c, h) {
  let l = a2l[h.ipc];
  if (l) {
    print("\n---------------> ", l);
  }

  cpu.tracer(cpu, h);

  l = a2l[h.d];
  if (l) {
    print("                      @ ", l);
  }
}

// install traps for putc!
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
  case 0xfff0: _putc(cpu.reg('a')); break;
  case 0xfff2: _putd((cpu.reg('y')<<8)+cpu.reg('a')); break;
  case 0xfff4: _puts((cpu.reg('y')<<8)+cpu.reg('a')); break;
  case 0xfff6: _getc(); break; // TODO:
    ////////////////////////////////////////
  case 0xfff8: return; // ABORT 6502C
  case 0xfffa: return; // NMI
  case 0xfffc: return; // RESET
  case 0xfffe: return; // IRQ/BRK
  default: return;
  }

  // just go to next instruction
  cpu.reg('pc+=3'); 
  
  // for jsr - no need to rts
  if (0x20) return 1; 

  // if jmpa jmpi - simulate rts!
  d= PL()+(PL()<<8);
  cpu.reg('pc',d);
  return 1;
}

function _putc(a) {
  process.stdout.write(
    String.fromCharCode(a));
  return a;
}

function _puts(a) {
  let c = 0;
  while((c < 128) && (c=m[a++]))
    _putc(c);
}

function _putd(d) {
  process.stdout.write(''+d);
}
  
// code gen

function next() {
  if (1) {
    JMPA('next');
  } else {
    // expensive!
    RTS();
  }
}

function ord(c) { return c.charCodeAt(0)}
function ch(c) { return String.fromCharCode(c)}
function print(...r) { return console.log(...r)}

// generate a "switch" from assoc list
// does order matter?
//
// you have to have a near label NAME_zero
function tabcod(name, list, nxt= next) {
 L(name);
  LDAIY('NEXTPTR');
  BEQ(name+'_zero');

  Object.keys(list).forEach(k=>{
    let cod= list[k];
    
    if (1) {
      // take +1 penalty at each test, but can handle any length!

      let nexttest = '_'+name+'_after_'+k;

      if (k !== 'default') {
       L('_'+name+'_test_'+k);
        // take first letter
        CMPN( ord(k) );
        BNE(nexttest);
      }

      // generate code and 'next'
     L(name+'_op_'+k);
      (cod() ||nxt)();

      // skip to here
      if (k !== 'default')
        L(nexttest);
    } else {
      // take +1 penalty only if match
      BEQ( name+'_'+k );
      // TODDO after cases need generate cod
    }
  });
}

// typically used in stack manipulation
function inx2() { INX(); INX(); }
function dex2() { DEX(); DEX(); }

function save_a(f) {
  PHA(); {
    f();
  } PLA();
}

function save_ax(f) {
  save_a(()=>{
    TXA(); PHA(); {
      f();
    } PLA(); TAX();
  });
}

function save_ay(f) {
  save_a(()=>{
    TYA(); PHA(); {
      f();
    } PLA(); TAY();
  });
}

function save_axy(f) {
  save_ax(()=>{
    TYA(); PHA(); {
      f();
    } PLA(); TAY();
  });
}

function save_axyp(f) {
  save_axy(()=>{
    PHP(); {
      f();
    } PLP();
  });
}
