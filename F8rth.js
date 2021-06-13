//      -*- truncate-lines: true; -*-
//
//               READLINE-65
// 
//          (>) 2021 Jonas S Karlsson
//                jsk@yesco.org
//
let utilty = require('./utility.js');
let terminal = require('./terminal-6502.js');
let jasm = require('./jasm.js');

let putc = terminal.aputc;
let putd = terminal.aputd;
let puts = terminal.aputs;
let getc = terminal.agetc;

let start = 0x501;

// TODO: if not this, hang!
//process.exit(0);

let brk= 0;
function next() {
  if (brk) {
    // use only 1 saves 2 bytes!
    // (little slower)
    BRK();
  } else {
    JMPA('NEXT'); // 3 bytes :-(
  }
}

let last;

function def(a, optJmp) {
  let aa = typeof a==='string'? ord(a) : a;
  let tryother = gensym('is_not_'+a+'_$'+cpu.hex(2,aa));
  let match = gensym('MATCH_'+a+'_$'+cpu.hex(2,aa));

  enddef();

  L(gensym('test_'+a+'_$'+cpu.hex(2,aa)));

  CMPN(aa);
  if (optJmp) {

    L(match);
    BEQ(optJmp);
    last= undefined; // ! supress

  } else {
    
    L(match);
    BNE(tryother);
    last= tryother;
    // the words def comes after
    // ... till the next def!
  }
}


function enddef() {
  if (last) {
    next();
    L(last);
  }
  last= undefined;
}

////////////////////////////////////////
//  TEST
function test() {

ORG(0x0100); // This is ALL of our (user) memory!

// verything is relative the stack
// (so we can use PHA(), PLA(), lol)
// (DON'T JSR/RTS any, you hear?)
let S = 0x0100;

ORG(S+ 0xbf); L('top');
ORG(S+ 0xcf); L('rstack');
ORG(S+ 0xef); L('stack');

//variables
ORG(S+ 0xfa); L('token'); // or save Y
ORG(S+ 0xfb); L('latest');
ORG(S+ 0xfc); L('here');
ORG(S+ 0xfd); L('state');
ORG(S+ 0xfe); L('sp'); // TODO: maybe not?
ORG(S+ 0xff); L('rp');

ORG(S); string('3d.4d.+.');

// separate code (ROM) & RAM
// == Harward Architecture
ORG(start);
  // init stack pointers
  LDXN('stack', lo); TXS();
  LDXN('rstack', lo); STAA('rp');

  // modify BRK as short cut for JMPA('next'); (save 2 bytes/call)
  LDAN('NEXT', lo); STAA(cpu.consts().RESET);
  LDAN('NEXT', hi); STAA(cpu.consts().RESET, inc);

  // init other stuff
  LDAN(0); STAA('token');
  LDAN(0); STAA('latest');
  LDAN(0); STAA('here');
  LDAN(0); STAA('state');

  // init state of interpreter
  LDAN(0xff); TAY(); // ip! -1 since we'll INY()
  next();

// -- state is true thus we're "compiling" for letters that are
// there own OP-codes we're just editing! Here is editor commands!
//
// Basically, all these words are "IMMEDIATE"
L('redisplay');
  TYA(),PHA(); {
    LDAN(ord('\n')),JSRA(putc);
    LDXN(0xff);
    LDAN(S, lo), LDYN(S, hi), JSRA(puts);
  } PLA(), TAY();
  LDAN(0);
  BEQ('compiling');
L('BackSpace');
  CPYN(1),BMI('NEXT');
  LDAN(8);
  JSRA(putc);
  //CPYN(2),BMI('compiling');
  DEY()
  LDAN(32),JSRA(putc),
  LDAN(8),JSRA(putc),
  LDAN(0),STAAY(S), // null out last char
  JMPA('compiling');
L('waitkey'),
  JSRA(getc),
  BEQ('waitkey'),

L('compiling');
  if(1)
  terminal.TRACE(jasm, ()=>{
    return;
    process.stdout.write('['+cpu.reg('a')+']');
    return;
    console.log('compiling', {
    });
    //cpu.dump(S, 256/8, 8, 1);
  });

  def(0x7f, 'BackSpace');                     // DEL // TODO: not working
  def(0x08, 'BackSpace');                     // BS
  def(12, 'redisplay');                       // CTRL-L redisplay
  def(';', 'decstate');                       // ; end def
  def('[', 'incstate')                        // [
  def(']', 'decstate')                        // ]
  def(0x00, 'waitkey')                        // nothing, wait for key!
  enddef();

  
  // echo TODO: not of control chars? lol, good for BS...
  JSRA(putc)
  //JMPA('compiling');
  // stuff the key in memory!
  terminal.TRACE(jasm, ()=>{
    return;
    cpu.dump(S, 16);
    console.log("STATE:",  m[jasm.getLabels().state]);
  });

  STAAY(S);

  // TODO: search for words... if user can define IMMEDIATE?

  // next (can't just fallthroug: gunk removed...)
  if (brk) BRK();

L('NEXT');
  if (brk) { PLP(),PLP(),PLP() } // drop BRK crap

  INY();
  LDAAY(S);

L('interpret'); // A has our word

  terminal.TRACE(jasm, ()=>{
    //process.stdout.write('.');
    //if (1) return;
    let ss= jasm.getLabels()['state'];;
    console.log('interpret', {
      Y: hex(2,cpu.reg('y')),
      A: chr(cpu.reg('a')),
      '#': cpu.reg('a'),
      state: m[ss],
    });
    //cpu.dump(ss);
  });

  LDXA('state');
  BNE('compiling');

  terminal.TRACE(jasm, ()=>{
    //if (1) return;
    console.log('--interpret', {
      A: chr(cpu.reg('a')),
    });
  });

  // -- "interpretation" or running
  def(0x00); L('incstate'),INCA('state');
  def(']'); L('decstate'),DECA('state');

  // same "minimal" 8 as sectorforth!
  def('@'); PLA(),TAX(),LDAAX(S),PHA();        // @
  def('!'); PLA(),TAX(),PLA(),STAAX(S);        // !
  def('S'); TSX(),TXA(),PHA();                 // sp@
  def('R'); LDAZ('rp',lo),PHA();               // rp@
  def('z'); PLA(),ORAN(0xff),PHA();;           // 0=
  def('+'); PLA(),TSX(),CLC(),ADCAX(S+1),STAAX(S+1); // +
  def('N'); PLA(),TSX(),ANDAX(S+1),EORN(0xff),STAAX(S+1); // Nand
  // ... and it also defines these
  def('b'); next()                             // Bye
  //def('B'); LDAN('tib'),PHA();               // tiB
  def('T'); LDAA('state'),PHA();               // sTate
  //def('I'); LDAN('>in'),PHA();               // >In
  def('h'); LDAAX('here'),PHA();               // Here
  def('L'); LDAAX('latest'),PHA();             // Latest
  def('K'); L('K'),JSRA(getc),BEQ('K'),PHA();  // Key
  def('e'); PLA(),JSRA(putc);                  // Emit
  def(':'); colon(),INCA('state');             // :
  def('C'); compile();                         // Compile
  def('x'); PLA(),                             // eXecute
  // --- jsk additions
  // TODO: all words that start with PLA...
  def('d'); PLA(),PHA(),PHA();                 // Dup
  def('\\'); PLA(),PHA(),PHA();                // drop
  def('s'); PLA(),TAX(),PLA(),TAY(),TXA(),PHA(),TYA(),PHA(); // Swap
  def('.'); PLA(),STYA('token'),LDYN(0),JSRA(putd),LDYA('token'); // .
  def(';'); PLA(),TAY();                       // EXIT word ("RTS")
  enddef();
  // assume it's a number, lol
  // TODO: check
  SEC(),SBCN(ord('0')),PHA();

// TODO: remove
next();

  L('ENTER_not_a_primitive_try_user_defined');
  // -- ENTER If not a primitive, then it's "interpreted" ends with ;
  STXA('token');

  // save data stack
  TSX(); STXA('stack'); {
    // restore rstack
    LDXA('rstack'); TXS(); {
      TYA(),PHA(); // save "ip"
    } TSX(); STXA('rstack');
  } LDXA('stack'); TXS();

  LDXA('token');
  // Find word from token (TODO:' ?)
  LDYA('latest');

L('find');
  TXA(); // get token
  CMPAY(S+1); // 0: "ptr to next word", 1: "token/name", 2: "code"
  BEQ('found');
  LDAAX(S); // link
  TAY();
  BNE('find');
  // 0 is end
  // TODO: ERROR: not found!
L('error');
  JSRA(putc);
  LDAN(ord('?')),JSRA(putc);
  LDAN(ord('\n')),JSRA(putc);
  next();

L('found');
  INY(); // !! skip ptr,
  next();

  function colon() {
  }
  function docolon() {
  }
  function compile() {
  }

}

////////////////////////////////////////
// RUN
var cpu = terminal.cpu6502();
var m = cpu.state().m;

test();

console.log("CODESIZE:", jasm.address()-start);
// crash and burn
jasm.burn(m, jasm.getChunks());
console.log({start});

// debug stuff
let labels = jasm.getLabels();
delete labels.waitkey;
cpu.setLabels(labels);

cpu.setTraceLevel(2);
cpu.setTraceLevel(1);
cpu.setTraceLevel(0);

cpu.setOutput(1);

cpu.reg('pc', start);
cpu.run(-1);
