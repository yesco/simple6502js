PROGRAM = '123 ...'; // test space
PROGRAM = '34+.';
// +1 inc at 4th position
// TODO: bug? 153 wrap around (CTRL-R)
PROGRAM = '9`\0048765432102@d.1+d.2!2@...........h.';
PROGRAM = '73-.';
PROGRAM = '1234567RRrr.......';
PROGRAM = '1234567RR.....r.r.';

PROGRAM = '34..34s..';
PROGRAM = '1<<<<<<<<.  9>d.>d.>d.>d.>d.';

PROGRAM = '17=.12=.  33=.55=.  71=.76=.';
PROGRAM = "12345'A'B'C........";

// TODO: * mul not working
PROGRAM = `
9
  11*.. 01*..  10*.. 22*.. 33*..
  99*.. 88*.. 77*.. 44*..

 .`;


// r stack
PROGRAM = '1234567RR.....r.r.';
PROGRAM = '1234567RRrr.......';


// ( ) loop
PROGRAM = '123(4.])567';

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
// - r and R, and move printcontrol (590 +69)
//
//
//
// TODO:  60 bytes next()==BRK 30 nexts
// TODO  120 bytes CMP,BCC (4b) x 30 OPS
//           (can do a ' '..'@' (32 B)
//           (offset jmptable make compact)
//           - 23 routines ( don't count num)
//           - 256/23 => 11
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
  let aa = typeof a==='string' && a.length==1? ord(a) : a;
  console.error("DEF", a, aa, optJmp);
  let tryother = gensym('_is_not_'+a+'_$'+cpu.hex(2,aa));
  let match = gensym('OP_'+a+'_$'+cpu.hex(2,aa));

  enddef();

  L(gensym('_test_'+a+'_$'+cpu.hex(2,aa)));

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

ORG(S+ 0x8f); L('top');
ORG(S+ 0xbf); L('rstack');
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
  LDXN('rstack', lo); STXA('rp');

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

L('OP_Run');
  PHA(); {
    LDAN(ord('\n')),LDYN(0),JSRA(putc);
    LDAN(ord('\n')),LDYN(0),JSRA(putc);
  } PLA();
  LDYN(0xff);
 L('decstate'); 
  INCA('state');
  next();
  //JMPA('decstate');

L('OP_List');
  TYA(),PHA(); {
    LDAN(ord('\n')),JSRA(putc);
    LDXN(0xff);
    LDAN(S, lo), LDYN(S, hi), JSRA(puts);
  } PLA(), TAY();
  LDAN(0);
  next();
  BEQ('compiling');

L('OP_BackSpace');
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
  def(0x7f, 'OP_BackSpace');
  def(ctrl('H'), 'OP_BackSpace');
  def(ctrl('L'), 'OP_List');
  def(ctrl('R'), 'OP_Run');
//  def(';', 'decstate');
  def('[', 'incstate'); 
//  def(']', 'decstate');
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

  // -- "interpretation" or running
  // LOL: we incstate by dec!
  // neg num can test with BIT!
  def(0x00); DEY(),L('incstate'),DECA('state');
  def(' '); // do not interpret as number! lol
  def(10); // do not interpret as number! lol

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

  // TODO: those wanting PLP,TSX could share...
  // --- Symbol based operators
  // (mostly arith, logic, short!)
  // (and it fit in 256 bytes?)
  // (if so make an page offset jmp table for 32)
  //
  def('+'); PLP(),TSX(),CLC(),ADCAX(S);
  def('-'); PLP(),TSX(),CLC(),SBCAX(S),EORN(0xff); // haha CLC turns it around!
  def('&'); PLP(),TSX(),      ANDAX(S);
  def('|'); PLP(),TSX(),      ORAAX(S);
  def('^'); PLP(),TSX(),      EORAX(S);
  def('~'); EORN(0x44);
  // :~dN;
  // :&N~;
  // :|~s~N;

  def('.'); STYA('token'),LDYN(0),JSRA(putd),LDYA('token'),PLA();
  def(';'); TAY(),PLA();
  // (+ 13 15 12 12 12 9 1 10 0 10 7 11 13 10 9)
  // = 144 bytes


  // add more symbols here!

  def('<'); CLC(),ROL(); // TODO: ASL(); save 1B
  def('>'); CLC(),ROR(); // TODO: LSR()
  // ?=
  // ?<
  // ?>
  // ?~=
  // ?~<
  // ?~>

  def('='); { // sign function! fun to write...
    PLP(),TSX(),CMPAX(S);   
    
    // Had to do some thing about this one...
    //
    // N  Z  C               C  !Z         -2
    // --------              ===== ordered ===
    // ?  0  0      A < M    0  1   1      -1
    // 0  1  1      A = M    1  0   2       0
    // ?  0  1      A > M    1  1   3      +1

    PHP();             // b12 c17
    LDAN(-2 & 0xff);   // offset -2
    BCC('_cskip');
    ADCN(1);           // if carry add 2! 
    L('_cskip');

    PLP();             // using original flags
    BEQ('_zskip');
    CLC();
    ADCN(1);           // if equal add 1
    L('_zskip');

    // A: -1 if <    0 if =    +1  if  >
    next();
  }

  // TODO:color\ make a JSR "getc" that echoes?
  def("'"); PHA(),INY(),LDAAY(S),JSRA(putc); // got the char!

  def('*'); {

    // 19 bytes only! avg 130 cycles
    // - https://www.lysator.liu.se/~nisse/misc/6502-mul.html
    // same as:
    // - https://llx.com/Neil/a2/mult.html
  L('mul');

    PHA();

    STYA('token'); {
      TSX();

      LDAN(2); STAAX(S+1);
      LDAN(3); STAAX(S+2);
      
      // factors in factor1 and factor2
      LDAN(0);
      LDYN(9);
     L('_mul');
      LSRAX(S+1);
      BCC('_mul_no_add');
      CLC();
      ADCAX(S+2);
      L('_mul_no_add');
      ROR();
      RORAX(S+1);
      DEY();
      BNE('_mul');
      STAAX(S+2); // hi result factor2
      // low result in factor1

      // check that the right stack offset!
      // yes...
      //LDAN(7); STAAX(S+1);
      //LDAN(8); STAAX(S+2);
      
    } LDYA('token');
    
    PLA(); // lo
    
    next();
  }

let div=`

  def('/'); {
    LDAN(0)      // Initialize REM to 0
    STA(REM)n
        STA REM+1
        LDX #16     ;There are 16 bits in NUM1
L1      ASL NUM1    ;Shift hi bit of NUM1 into REM
        ROL NUM1+1  ;(vacating the lo bit, which will be used for the quotient)
        ROL REM
        ROL REM+1
        LDA REM
        SEC         ;Trial subtraction
        SBC NUM2
        TAY
        LDA REM+1
        SBC NUM2+1
        BCC L2      ;Did subtraction succeed?
        STA REM+1   ;If yes, save it
        STY REM
        INC NUM1    ;and record a 1 in the quotient
L2      DEX
        BNE L1
  }
`;

  def('('); {
    PHA();
    R_BEGIN(); {
      // push "ip"
      TYA(),PHA();
    } R_END();
    PLA();
  }

  def(')'); {
    PHA();
    R_BEGIN(); {
      // restore "ip"
      // (jumps back to just after '(')
      PLA(),TAY(),PHA();
    } R_END();
    PLA();
  }

  def(']'); {
    PHA();
    R_BEGIN(); {
      // drop "ip"
      PLA();

     L('_]');
      INY(),LDAAY(S);
      terminal.TRACE(jasm, ()=>{
        //princ(' <skip: '+chr(cpu.reg('x'))+'> ');
      });
      CMPN(ord(')'));
      BNE('_]');
    } R_END();
    PLA();
  }


  if(0) { // dispatch and next for these 


  def('"');
  def('#');
  def('$');
  def('%');

  def('/');

  def(',');

  def(':');
  def(';');
  def('?');
  }
  
  // --- letter commands
  def('S'); TSX(),TXA();
  def('r'); {
    // TODO: too big, and not callable
    L('R>');
    
    PHA();
    R_BEGIN(); {
      PLA();
    } R_END();
  }
  def('R'); {
    // can only push A
    L('>R');

    R_BEGIN();{
      PHA();
    } R_END();
    PLA();

  }
  def('z'); ORAN(0xff);
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

  def('s'); STAA('token'),PLA(),TAX(),LDAA('token'),PHA(),TXA(); // b10 c19
  // EOR swap def('s');TSX(),STAAX(S),EORAX(S+1),EORAX(S),STAAX(S+1),EORA(S); // b13 c18

  // -- printers and formatters
  def('`', 'printval');
  // TODO: comment? cna be used as headline

  enddef();

  CPXN(31),BCS('printcontrol');

  // assume it's a number, lol
  // TODO: check

L('number');
  PHA(),TXA(),SEC(),SBCN(ord('0'));

// TODO: remove
// search for function
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

  // control codes, quote them!
L('printcontrol');
  PHA(),TYA(),PHA(); {
    LDAN(ord('<')),JSRA(putc);
    TXA(),LDYN(0),JSRA(putd);
    LDAN(ord('>')),JSRA(putc);
  }; PLA(),TAY(),PLA();
  next();

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

function R_BEGIN() {
  TSX(),STXA('sp'),LDXA('rp'),TXS();
}

function R_END() {
  TSX(),STXA('rp'),LDXA('sp'),TXS();
}

////////////////////////////////////////
// RUN
var cpu = terminal.cpu6502();
var m = cpu.state().m;

test();

let l = jasm.getLabels();

if (0) {
  print(jasm.getHex(0,0,0));
  process.exit();
} else if (1) {
  let lasta, last;
  Object.keys(l).forEach(x=>{

    // skip local labels
    if (x.match(/^_/)) return;
    if (x.match(/_$/)) return;

    let a = l[x];
    let len = lasta ? a - lasta : '-';
    
    if (last) {
      print(last.padEnd(30,' '), hex(4,a),
            "\t", len.toString().padStart(4));
    }

    lasta = a;
    last = x;

  });

}

print();

console.log("FORTH:", l.FORTH_END-l.FORTH_BEGIN);
console.log("TOTAL:", jasm.address()-l.FORTH_END);

print('-'.repeat(40));
print();

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

