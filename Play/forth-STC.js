//                GOOTSTRAP-65
// 
//          (>) 2021 Jonas S Karlsson
//                jsk@yesco.org
//
let terminal = require('./terminal-6502.js');
let jasm = require('./jasm.js');

let start = 0x501;


////////////////////////////////////////
// Word defintion

var latest= 0;

function DEF(name, optProg) {
  // --- header
  // link to prev def
  let start = jasm.address();
L(name+'_DEF');
  word(latest);
  latest = start;
  // Code Offset Destination
  byte(name, (_=>(a=>a-_))(jasm.address));
  // pretty bytes (may be used)
  chars(': ');
  string("'");

  // --- end of header start of COD
L(name);

  if (optProg) {
    JSRA('INTERPRET');
    optProg.forEach(x=>{
      if (typeof x === 'number') {
        data(x);
      } else if (typeof x === 'string') {
        string(optProg);
      } else {
        throw `"%% DEF('${name'}) unknown type '${typeof x} of: ${x}`;
      }
    });
  } else {
    JSRA('ENTER');
    // it's up to coder to generate native code
    // after the DEF (like ;CODE)
  }
}



////////////////////////////////////////
//  Bootstrapping Forth
function bootstrap() {

// Zero Page
ORG(0);
  // genera use register 0-F

ORG(10);
  // base address of current word executing
  L('BASE');     word(0);
  L('IN');       word(0);
  L('LATEST');   word(0);
  L('STATE');    byte(0);
  L('HERE');     word(0);

ORG(start);
  JMPA('boot');

  DEF('boot'); {
    // init stack and return stack
    LDXN(0xff),TXS();
    // init input
    LDAN('input', lo),STAZ('IN');
    LDAN('input', hi),STAZ('IN', inc);
    // init here
    LDAN('INITIAL_HERE', lo),STAZ('HERE');
    LDAN('INITIAL_HERE', hi),STAZ('HERE', inc);
    
    JMAP('quit');
  }

  DEF('IN_reset'); {
    LDAN(0), STAZ('IN'),STAZ('IN', inc);
  }

  // reset reset the return stack
  // data strack remains
  DEF('quit'); {
    // clear the return stack
    TXA(),LDXN(0xff),TXS(),TAX();
    // reset state
    LDAN(0),STAZ('STATE');

    JSRA('IN_reset');

    JSRA('INTERPRET');
  }
  
  DEF('abort'); {
    // clear the data stack
    JMPA('quit');
  }

  L('tail_push_A'); {
             STAZX(0);
    LDAN(0); STAZX(1);
    RTS();
  }

  // Returns in A register
  L('_getc'); {
    JSRA(terminal.agetc);
    BEQ('_key');
    RTS();
  }

  // Reads next char from in
  // device.
  //
  // Zero if ENTER or END
  L('in'); {
    LDAN('IN');
    ORAN('IN', inc);
    BEQ('_key');
    // otherwise read from buffer
    // TODO: have vector to call
    LDAIY('IN');
    BNE('key_push');
   L('key_IN_finished'):
    JSRA('IN_reset');
    JMPA('tail_push_A');

   L('_key');
    JSRA('_getc');
   L('key_push');
    JMPA('tail_push_A');
  }

  DEF('key'); {
    JSRA('in');
    JMPA('tail_push_A');
  }

  function drop() {
    INX(),INX();
  }

  function push() {
    DEX(),DEX();
  }
  
  function put_AS() {
           STAZX(1);
    PLA(); STAZX(0);
  }

  function tail_put_AS() {
    JMPA('tail_put_AS'):
  }

  function tail_pop_put_AS() {
    JMPA('tail_put_AS'):
  }

  L('tail_pop_put_AS'); { //
    drop();
    // Fallthrough!
  } L('tail_put_AS'); { // replace TOS
    put_AS();
    RTS();
  }

  DEF('plus'); {
    CLC();
    LDAZX(0),ADCZX(2),PHA(); // lo
    LDAZX(1),ADCZX(3); // hi
    tail_pop_put_AS();
  }

  function tail_literal(v) {
    LDAN(v, lo),PHA(); // lo
    LDAN(v, hi); //hi
    tail_push_AS();
  }

  DEF('here'); {
    tail_literal('HERE');
  }

  DEF('pad'); {
    JSRA('here');
    literal(80);
    tail_push_AS();
  }

  // read a line and return it when
  // either IN finished or '\n' or
  // user hits RETURN.
  DEF('accept'); {
    // TODO: actually not needed!
    BRK();
    JSRA('pad');

    JSR('key');
    //BNE(
    RTS();
  }

  L('skip_space'); {
    JSRA('in'); // => A
    // zero, end of input
    BEQ('_skip_spaces_return');

    CMPN(ord(' '));
    BEQ('skip_space');
    
    CMPN(ord('\t'));
    BEQ('skip_space');
    
    // return
    CMPN(10);
    BEQ('skip_space');
    
   L('_skip_space_return');
    RTS();
  }
    
  // read a word
  // TODO: supposed to take a string w delims?
  DEF('word'); {
    JSRA('pad');

    // We just peek on the stack
    LDAX(0),STAZ(0);
    LDAX(1),STAZ(1);

    JSRA('skip_spaces');

    LDAYN(0);

   L('_word');
    // zero terminate at first!
    LDAN(0),STAIY(0);

    // end
    JSRA('in'); // => A
    BNE('word_return');

    // return
    CMP(10);
    BEQ('word_return');
    
    // full?
    CPYN(80);
    BCS('_word'); // ignore key

    // echo
    JSRA(terminal.aputc);

    // store it
    STAIY(0);
    INY();
    BNE('_word');

   L('word_end');
    // it's allready on the stack!
    RTS();
  }

  // find a word
  DEF("'"); {
    // TODO:
    BRK();
  }

  DEF('INTERPRET'); {
    JSRA('word');
    
    BITZ('STATE');
    BNE('compile');

    JMPA('INTERPRET');
    // immediate
   L('compile'):

    JMPA('INTERPRET');
  }

  // Def of 'def'!
  immDEF(':'); {
    JSR('create');
    // TODO:
    BRK();
  }

  immDEF(';'); {
    // TODO:
    BRK();
  }

  DEF('LASTDEF'); RTS();
  
  // Do NOT put any DEFs after here!

  // call user defined string input that
  // is parsed;

  // TODO: this could be overwritten,
  // possibly by putting here here!
  // But that would be a bit risky...
  // Also, at "boot" we like to restart
  // reading it, so for now; keep it.
  input();

L('INITIAL_HERE');

}

// let's do it, generate:

boostrap();

// user supplied high-level functions,
// but still part of boot image
function input() {
  string(': sqr dup * ;');
  // ...
}



////////////////////////////////////////
// RUN
let cpu = terminal.cpu6502();
let m = cpu.state().m;
//cpu.setTraceLevel(traceLevel);

// crash and burn
jasm.burn(m, jasm.getChunks());
cpu.reg('pc', start);
cpu.setTraceLevel(2);
cpu.run(-1, 1, 1);



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

