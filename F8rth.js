PROGRAM = '123 ...'; // test space
PROGRAM = '34+.';
// +1 inc at 4th position
// TODO: bug? 153 wrap around (CTRL-R)
PROGRAM = '9`\0048765432102@d.1+d.2!2@...........h.';
PROGRAM = '73-.';


///PROGRAM = '19s..11111`A56789@d.1+9s!fish\n';
// PROGRAM = '9876543210..........'; test stack and print



//      -*- truncate-lines: true; -*-
//
//               READLINE-65
// 
//          (>) 2021 Jonas S Karlsson
//                jsk@yesco.org
//
// Preimise:
// - looking at sectorforth, other x86 etc 
//   it seems too easy to make an 16 bit on 16.
// - So, I wanted to make a PURE 8-bit Forth.
// = a mini-variant of ALF (ALphabetic Forth)
// - How "small" can it get?
//
// Peculiarities:
// - 8 bit can only address 2^8 = 256 bytes.
// - The page is the fixed STACK page 0x0100!
// - The stack ops are used for data
//   (compared to a ZP-stack, less INC*2,DEC*2)
// - Data stack is small, Return is very smaller.
// - Y register is "ip" (in 0x100 page)
// - A register keeps TOS (Top Of Stack)
//   (this works out as all action is in A)
// - X register stores the token (can trash)

// History:
// - started out minimal with sectoforth style
// - added more words
// - added editors in compile mode (= edit)
// - def(8, jmp) = saved 7*3 (in chained)
// - A is TOS, X is token, 15 ops saved 30B (489)
// - moving stuff around, 
// - adding ` print ineline value (508 +44)
//   (to much growth: implement as word?)

let utilty = require('./utility.js');
let terminal = require('./terminal-6502.js');
let jasm = require('./jasm.js');

let putc = terminal.aputc;
let putd = terminal.aputd;
let puts = terminal.aputs;
let getc = terminal.agetc;

let start = 0x501;

let trace = 0;

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

// xterm/ansi
let BLACK= 0, RED= 1,     GREEN= 2, YELLOW= 3,
    BLUE=  4, MAGNENTA=5, CYAN=  6, WHITE=  7;

function amber() { return '[38;5;214m'; }
function cursorOff() { return '[?25l'; }
function home() { return gotorc(0, 0); }
function cls() { return '[2J' + home; }
function cursorOn() { return '[?25h'; }
function gotorc(r, c) { return '['+r+';'+c+'H'; }
function fgcol(c) { return '[3'+c+'m'; }
function bgcol(c) { return '[4'+c+'m'; }
function inverseOn() { return '[7m'; }
function underscoreOn() { return '[4m'; }
function boldOn() { return '[1m'; }
// you can only turn all off! :-(
function off(){ return'[m'; }

console.log(
  'text', fgcol(GREEN), 'fish',
  bgcol(YELLOW), 'crap',
  off(), fgcol(BLUE), 'input',
  inverseOn(), 'output', off());

console.log(
  fgcol(GREEN), '34+.',
  boldOn()+fgcol(WHITE), '7777777',
  off()+inverseOn()+' '+off(),
)

console.log(
  fgcol(GREEN), '34+.',
  fgcol(WHITE), '7777777',
  fgcol(RED), '7777777',
  boldOn()+fgcol(RED), '7777777',
  off()+inverseOn()+' '+off(),
)

console.log(
  boldOn()+fgcol(WHITE),
  '34+.',
  fgcol(GREEN),
  '7777777',
)

console.log(
  fgcol(GREEN), '34+.',
  amber(), '7777777',
  off()+inverseOn()+' '+off(),
);

function ctrl(c) {
  return ord(c.toUpperCase())-64;
}

let last;

function def(a, optJmp) {
  let aa = typeof a==='string'? ord(a) : a;
  let tryother = gensym('is_not_'+a+'_$'+cpu.hex(2,aa));
  let match = gensym('MATCH_'+a+'_$'+cpu.hex(2,aa));

  enddef();

  L(gensym('test_'+a+'_$'+cpu.hex(2,aa)));

  CPXN(aa);
  if (optJmp) {

    BEQ(optJmp);
    last= undefined; // ! supress

  } else {
    
    BNE(tryother);
    last= tryother;
    // the words def comes after
    // ... till the next def!
    L(match);
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

ORG(S); string(PROGRAM);

// separate code (ROM) & RAM
// == Harward Architecture
ORG(start);
L('FORTH_BEGIN');
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

L('Run');
  PHA(); {
    LDAN(ord('\n')),LDYN(0),JSRA(putc);
    LDAN(ord('\n')),LDYN(0),JSRA(putc);
  } PLA();
  LDYN(0xff);
  JMPA('decstate');

L('List');
  TYA(),PHA(); {
    LDAN(ord('\n')),JSRA(putc);
    LDXN(0xff);
    LDAN(S, lo), LDYN(S, hi), JSRA(puts);
  } PLA(), TAY();
  LDAN(0);
  next();
  BEQ('compiling');

L('BackSpace');
  // nothing to delete?
  CPYN(1),BMI('NEXT');
  //CPYN(2),BMI('compiling');

  PHA(); {
    // delete on screen (BS+SPC+BS) // b12
    // (TODO: optimize with a putsi)
    LDAN(8),JSRA(putc);
    LDAN(32),JSRA(putc);
    LDAN(8),JSRA(putc);

    // null out last char
    DEY();
    PHA(); {
      LDAN(0),STAAY(S);
    } PLA();
  }
  next();
  JMPA('compiling');

L('waitkey'),
  PHA();
  L('_waitkey');
    JSRA(getc),
  BEQ('_waitkey'),
  TAX();
  PLA();
  // X now contains keystroke, A retains TOS

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

  // Check editing first
  def(0x7f, 'BackSpace');
  def(ctrl('H'), 'BackSpace');
  def(ctrl('L'), 'List');
  def(ctrl('R'), 'Run');
  def(';', 'decstate');
  def('[', 'incstate'); 
  def(']', 'decstate');
  def(0x00, 'waitkey');
  enddef();

  // echo TODO: not of control chars? lol, good for BS...
  PHA(); {
    TXA(),JSRA(putc);
    STAAY(S);
  } PLA();

  terminal.TRACE(jasm, ()=>{
    if (!trace) return;
    nl();
    cpu.dump(S, 16);
    console.log("STATE:",  m[jasm.getLabels().state]);
  });

  // TODO: search for words... if user can define IMMEDIATE?

  // next (can't just fallthroug: gunk removed...)
  if (brk) BRK();

L('NEXT');
  if (brk) { PLP(),PLP(),PLP() } // drop BRK crap

  INY();
  LDXAY(S);

L('interpret'); // A has our word

  terminal.TRACE(jasm, ()=>{
    if (!trace) return;
    //process.stdout.write('.');
    //if (1) return;
    let ss= jasm.getLabels()['state'];;
    console.log('interpret', {
      Y: hex(2,cpu.reg('y')),
      X: chr(cpu.reg('x')),
      A: chr(cpu.reg('a')),
      '#': cpu.reg('a'),
      state: m[ss],
    });
    //cpu.printStack();
    //cpu.dump(ss);
  });

  let echo = 1;
  if (echo) {
    // TODO: don't cheat!
    terminal.TRACE(jasm,()=>princ(fgcol(GREEN)));
    PHA(); TXA();
    JSRA(putc);
    // TODO: don't cheat!
    terminal.TRACE(jasm,()=>princ(fgcol(WHITE)));
    PLA();
  }

  BITA('state');
  BMI('compiling');

  terminal.TRACE(jasm, ()=>{
    if (!trace) return;
    console.log('--interpret', {
      X: chr(cpu.reg('x')),
    });
  });

  // TODO: those wanting PLP,TSX could share...

  // -- "interpretation" or running
  // LOL: we incstate by dec!
  // neg num can test with BIT!
  def(0x00); DEY(),L('incstate'),DECA('state');
  def(']'); L('decstate'),INCA('state');

  // do not interpret as number! lol
  def(32);

  // same "minimal" 8 as sectorforth!
  def('@'); TAX(),LDAAX(S);
  def('!');

TAX(),PLA(),

terminal.TRACE(jasm, ()=>{
  print('<<<<',{a: cpu.reg('a'), x: cpu.reg('x'), 2: m[S+2]});
});

STAAX(S),PLA(),

console.log('STAAX', STAAX.toString());
terminal.TRACE(jasm, ()=>{
  print('>>>',{
    a: cpu.reg('a'),
    x: cpu.reg('x'),
    2: m[S+2],
    d: cpu.hex(4,cpu.reg('d')),
    });
});
  def('S'); TSX(),TXA();
  def('R'); LDAZ('rp',lo);
  def('z'); ORAN(0xff);

  def('+'); PLP(),TSX(),CLC(),ADCAX(S);
  def('-'); PLP(),TSX(),CLC(),SBCAX(S),EORN(0xff); // haha CLC turns it around!
  def('&'); PLP(),TSX(),      ANDAX(S);
  def('|'); PLP(),TSX(),      ORAAX(S);
  def('^'); PLP(),TSX(),      EORAX(S);
  def('~'); EORN(0x44);
  // :~dN;
  // :&N~;
  // :|~s~N;

  def('N'); TSX(),PLP(),ANDAX(S+1),EORN(0xff);
  // ... and it also defines these
  //def('B'); PHA(),LDAN('tib');
  //def('T'); PHA(),LDAA('state');
  //def('I'); PHA(),LDAN('>in');
  //def('h'); PHA(),LDAAX('here');
  def('h'); PHA(),TYA(); // if in compilation...
  def('L'); PHA(),LDAAX('latest');
  def('K'); PHA(),L('K'),JSRA(getc),BEQ('K');
  def('e'); JSRA(putc),PLA();

  //def(':'); colon(),INCA('state');
  //def('C'); compile();

  def('x'); TAX(),PLA(),JMPA('interpret');

  // --- jsk additions
  def('d'); PHA();
  def('\\'); PLA();
  def('s'); TSX(),EORAX(S+1),EORA(S+1),STAA(S+1),EORA(S+1); // b13 c18
  //def('s'); STYA('token'),TAX(),PLA(),TAY(),TXA(),PHA(),TYA(),LDYA('token'); // b10 c23
  def('.'); STYA('token'),LDYN(0),JSRA(putd),LDYA('token'),PLA();
  def(';'); TAY(),PLA();

  // -- printers and formatters
  def(96, 'printval');
  // TODO: comment? cna be used as headline

  enddef();

  // control codes, quote them!
L('quotecontrol');
  CPXN(31),BCC('number');
  PHA(),TYA(),PHA(); {
    LDAN(ord('<')),JSRA(putc);
    TXA(),LDYN(0),JSRA(putd);
    LDAN(ord('>')),JSRA(putc);
  }; PLA(),TAY(),PLA();
  next();
  // assume it's a number, lol
  // TODO: check
  L('number');
  PHA(),TXA(),SEC(),SBCN(ord('0'));

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

//   (to much growth: implement as word?)
L('FORTH_END');

L('printval');
  PHA(); {
    // TODO: make section for commands where A Y is saved

    // next byte
    INY(),LDXAY(S);

    // nightmare! (on stack A Y X)
    PHA(),TYA(),PHA(),TXA(),PHA(); {
      LDAN('resultColor', lo),LDYN('resultColor', hi),LDXN(0xff),JSRA(puts);
      // dup, putd
      PLA(),PHA(),LDYN(0),JSRA(putd);
      LDAN('colorOff', lo),LDYN('colorOff', hi),LDXN(0xff),JSRA(puts);
    } PLA(),TAX(),PLA(),TAY(),PLA();

    // or print hex ???
    //PLA(),LSR(),LSR(),LSR(),LSR(),CLC(),ADCN(ord('0')),JSRA(putc);
    //PLA(),ANDN(0x0f),CLC(),ADCN(ord('0')),JSRA(putc);
  } PLA();
  next();

  function colon() {
  }
  function docolon() {
  }
  function compile() {
  }
  
}

L('resultColor'); string(amber());
L('colorOff'); string(off());

////////////////////////////////////////
// RUN
var cpu = terminal.cpu6502();
var m = cpu.state().m;

test();

let l = jasm.getLabels();

console.log("FORTH:", l.FORTH_END-l.FORTH_BEGIN);
console.log("TOTAL:", jasm.address()-l.FORTH_END);

// crash and burn
jasm.burn(m, jasm.getChunks());
console.log({start});

// remove l.waitKey!
delete l._waitkey;

cpu.setLabels(l);

cpu.setTraceLevel(2);
cpu.setTraceLevel(1);
cpu.setTraceLevel(0);

cpu.setOutput(1);
cpu.setOutput(0);

trace = 1;
trace = 0;

cpu.reg('pc', start);
cpu.run(-1);
