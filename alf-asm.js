// TODO: simple6502.js
let cpu6502 = require('./fil.js');
let jasm = require('./jasm.js');
let aputc = 0xfff0;
let aputd = 0xfff2;
let aputs = 0xfff4;
let output = 1; // show 'OUTPUT: xyz'

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

ORG(0x14);   L('tmp_a');     byte(0);
ORG(0x15);   L('tmp_x');     byte(0);
ORG(0x16);   L('tmp_y');     byte(0);

  // - FREE

  // ORIC 79 bytes input buffer
ORG(0x35); L('INPUT_BUF'); allotTo(0x84);
  // testing: simple program!
ORG(0x35); /* INPUT_BUF */ string('0.1.2.3D+D.');

  // Forth
ORG(0x85);
  L('NEXT_BASE');   word('INPUT_BUF');
  L('NEXT_Y');      data(0);
  L('STATE');       data(0);

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
  // init stack
  LDXN(0xff);
  //JSRA('WINC');
  //JSRA('WINC2');

  //LDXN(0x02);
  //JSRA('WDEC');

 L('interpret');
  // Init
  LDYN(0);

  JSRA('MAIN');

  JMPA('end');


 L('MAIN_zero');
  RTS();

 L('drop2_next');
  drop();

 L('drop_next');
  drop();

  // This is a Alphabet Forth ("byte coded")
  // maxlen of interpreted routine = 255!
 L('next');
  TRACE(printstack);

  INY();

  let drop_next= ()=>JMPA('drop_next');
  let drop2_next= ()=>JMPA('drop2_next');
  let number= ()=>JMPA('number');

  tabcod('MAIN', {

    // 24 Forth  Functions defined!

    // TODO:
    // - $K key or ck?
    // - cw - word skip space, read next word "store" it ( == addr len ) NOT z-terminated
    // - cf find word  WROD DOUBLE FIND >CFA
    // - ca Code Address ?
    // - create ct ?
    // - ':'
    // - ';'
    // - ','  !!!! first!
    // - [ immediate go into immediatem mode - update STATE = 0
    // - ] immediate go into compiling mode - update STATE = 1
    // - Quit is "reset" ? loops Interpret

    // - inefficient, lol
    // TODO:we know(?) Z/!Z, use BNE... ???
    // depends on codegen... if if if=> z=1...
    '0': function(){ return number},
    '1': function(){ return number},
    '2': function(){ return number},
    '3': function(){ return number},
    '4': function(){ return number},
    '5': function(){ return number},
    '6': function(){ return number},
    '7': function(){ return number},
    '8': function(){ return number},
    '9': function(){ return number},

    Emit(){
      LDAZX(0);  JSRA(aputc);
      return drop_next;
    },

    '(_begin': function(){
      // simple does it
      TYA(); PHA();
    },

    ')_again': function(){
      PLA(); TAY();
      // start over at '('
      JMPA('MAIN');
      return ()=>0; // none
    },

    ']_stop': function(){
      // TODO: long: move out, JSRA?

      LDAZ('STATE');
      BNE('forceend');

      // inside '[' (immediate mode)
      LDAZ(0x80);
      BNE('set_state');

      // running mode (!imm)
      // drop loop tooken
     L('forceend');
      PLA(); // 0 means no more loop => exit!
      BNE('leave');

      // ] exit
      RTS();

      // leave - go to matching ')'
      // TODO: handle ]]]] (unrolll+leave)
      STXZ('tmp_x'); // 
      LDXN(0);
     L('leave');
      INY();
      LDAIY('NEXT_BASE');

      CMPN(ord('('));
      BNE('not(');
      INX();

     L('not(');
      CMPN(ord(')'));
      BNE('leave');
      
      DEX();
      // more to go!
      BNE('leave');

      // we found matching )
      STXZ('tmp_x');
      // just go to next!
    },

    '[_immediate': function(){
      LDAZ(0);
     L('set_state');
      STAZ('STATE')
    },

    '@_fetch': function(){
      STYZ('tmp_y'); {
        TXA(); TAY(); {
          // m[addr]          addr
          LDAIY(0);           STAZ('tmp_a');
          LDAIY(1);    
          // now can replace the pointer
                              STAZX(1);
          LDAZ('tmp_a');      STAZX(0);
        }
      } LDYZ('tmp_y');
    },

    '!_store': function(){
      STYZ('tmp_y'); {
        TXA(); TAY(); {
          // data              // addr
          LDAZX(2);            STAIY(0);
          LDAZX(3);            STAIY(1);
        }
      } LDYZ('tmp_y');
      return drop2_next;
    },

    '+_plus' : function(){
      CLC()
      LDAZX(0); ADCZX(2); STAZX(2);
      LDAZX(1); ADCZX(3); STAZX(3);
      return drop_next;
    },

    '-_minus' : function(){
      JSRA('Rminus');
//      SEC()
//      LDAZX(0); SBCZX(2); STAZX(2);
//      LDAZX(1); SBCZX(3); STAZX(3);
      return drop_next;
    },

    '&_and' : function(){
      LDAZX(0); ANDZX(2); STAZX(2);
      LDAZX(1); ANDZX(3); STAZX(3);
      return drop_next;
    },

    '__or' : function(){
      LDAZX(0); ORAZX(2); STAZX(2);
      LDAZX(1); ORAZX(3); STAZX(3);
      return drop_next;
    },

    '^_xor' : function(){
      LDAZX(0); EORZX(2); STAZX(2);
      LDAZX(1); EORZX(3); STAZX(3);
      return drop_next;
    },

    Not(){
      LDAZX(0); EORN(0xff); STAZX(0);
      LDAZX(1); EORN(0xff); STAZX(1);
    },

    '=_equal' : function(){
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

    '<_less_than' : function(){
      JSRA('Rminus');
      BMI('true');
      BPL('false');
     L('true');
      LDAN(0);
      JMPA('inv'); // => 1
    },

    '>_greater_than' : function(){
      JSRA('Rminus');
      BEQ('false');
      BNE('true');
    },

    // TODO: put instruction before that also need to "drop"
    '\\_drop' : function(){
      return drop_next;
    },

    Dup (){ // dup
      push();
      LDAZX(2); STAZX(0);
      LDAZX(3); STAZX(1);
    },

    '._print': function(){
      save_ay(()=>{
        LDAZX(0);
        LDYZX(1);
        JSRA(aputd);
      });
      return drop_next;
    },

    'C_prefix': function(){
      INY();
      JMPA('CCC');
      return ()=>0; // nothing
    },

    'R_prefix': function(){
      INY();
      JMPA('RRR');
      return ()=>0; // nothing
    },

    default (){
      // TODO:: try parse number
    },
  })

  // TODO: Report ERROR as no match?
  JMPA('end');

L('number');
  SEC();
  SBCN(ord('0'));
  // A = 0..9
  push();
           STAZX(0);
  LDAN(0); STAZX(1);
  // TODO: read more digits...

  next();

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


L('CCC_zero');
  RTS();

tabcod('CCC', {
  '!_C!': function(){
    STAZ('tmp_y'); {
      TXA(); TAY();

      // only lo byte
      LDAZX(2);  STAIY(0);

    } LDAZ('tmp_y');
    return drop2_next;
  },

  '@_C@': function(){
    STAZ('tmp_y'); {
      TXA(); TAY();

      // only lo byte
      LDAIY(0);  STAZX(0);
      // set hi = 0
      LDAN(0);   STAZX(1);

    } LDAZ('tmp_y');
    return drop_next;
  },

  'M_CMOVE': function() {
    // TODO: 
  },

  R_CR(){
    LDAN(10);
    JSRA(aputc);
  },

  default(){ 
    // TODO: give error?
  }});
  
L('RRR_zero');
  RTS();

tabcod('RRR', {
  '<_R<_>R': function(){
    LDAZX(1);  PHA();  // hi first
    LDAZX(0);  PHA();  // lo
    return drop_next;
  },

  '>_R>_R>': function(){
    push();
    PLA();  STAZX(0);
    PLA();  STAZX(1);
  },

  default(){
    // TODO:
  },
});


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

// (called after instruction)
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

function printstack() {
  let x = cpu.reg('x');
  princ(`  DSTACK[${(0x101-x)/2}]: `)
  while(++x < 0x100) {
    princ(hex(4, cpu.w(x++)));
    princ(' ');
  }
  print();
}

function TRACE(f) {
  TRACE[jasm.address()] = f;
}

// install traps for putc!
// (called before instruction)
function patch(pc, m, cpu) {
  (TRACE[pc] || (()=>0))();

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

function _putc(c) {
  if (output) princ("OUTPUT: ");
  process.stdout.write(chr(c));
  if (output) print();
  return a;
}

function _puts(a) {
  if (output) princ("OUTPUT: ");
  let c = 0;
  while((c < 128) && (c=m[a++]))
    process.stdout.write(chr(c));
  if (output) print();
}

function _putd(d) {
  if (output) princ("OUTPUT: ");
  process.stdout.write(''+d);
  if (output) print();
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
function princ(s) { return process.stdout.write(''+s);}

// generate a "switch" from assoc list
// does order matter?
//
// you have to have a near label NAME_zero
function tabcod(name, list, nxt= next) {
 L(name);
  LDAIY('NEXT_BASE');
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

// data stack manipulation
// (stack grows down)
function drop() { INX(); INX(); }
function push(v) {
  if (v)
    throw "%% push no arg: just make spacec";
  DEX(); DEX();
}

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
