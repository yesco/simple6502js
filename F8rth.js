//      -*- truncate-lines: true; -*-

PROGRAM = '123 ...'; // test space
// +1 inc at 4th position
// TODO: bug? 153 wrap around (CTRL-R)
PROGRAM = '9`\0 0 4 8 7 6 5 4 3 2 1 0 2@d.1+d.2!2@...........h.';
PROGRAM = '1 2 3 4 5 6 7RRrr.......';
PROGRAM = '1 2 3 4 5 6 7RR.....r.r.';

PROGRAM = '34..34s..';
PROGRAM = '1<<<<<<<<.  9>d.>d.>d.>d.>d.';

PROGRAM = '1 7=.1 2=.  3 3=.5 5=.  7 1=.7 6=.';
PROGRAM = "1 2 3 4 5'A'B'C........";

// r stack
PROGRAM = '1 2 3 4 5 6 7RR.....r.r.';
PROGRAM = '1 2 3 4 5 6 7RRrr.......';

///PROGRAM = '19s..11111`A56789@d.1+9s!fish\n';
// PROGRAM = '9876543210..........'; test stack and print


// TODO:
// exit, hmmm, searches for ) lol
PROGRAM = ':1.]2 3 4';

// ( ) loop
PROGRAM = '1 2 3(4.(5.)9.9.9.)5 6 7';

// loop w ]
PROGRAM = '1 2 3(4.]6.6.6.)5 6 7';

// TODO: should print 1 2 3 4 5 6
// (the ')' is somewhat undefefined,
// in this case pulls z 0 from stack, lol)
PROGRAM = ':1.]6.6.6.;  2.3.4.)8.8.';

// tail recurse on last ')', lol
// (however, this has overhead of one PH,PL
//  for interpreted words :-( )
// For ALF; words start at Y=0, but then needs
//  another word for tailrecurse :-( )
PROGRAM = ':1.)2 3 4;';

// TODO: skip intermediate (count matching)
// should give 1 2 3 4 
PROGRAM = '1 2(3.](6.9.6.)0.6.0.)4.5.6.';

// 0=
PROGRAM = '0z. 1z. 2z. 3z. 4z. 5z. 6z. 7z. 8z. 9z. ';

// math

PROGRAM = '3 4+.';

PROGRAM = '0.1.2.3.7.9.';

PROGRAM = `
3 4+.9 9+.
7 3-.3 7-.9 9-.0 1-.
7 3*.3 7*.9 9*.
7 3/.3 7/.9 9/.9 3/.
1 3&.9 7&.8 4 &.
1 3|.9 7|.8 4|.
1 3^.9 7^.8 4^.
 1~. 0~. 8~.0 1-~.
`;

PROGRAM = '1 7=.1 2=.  3 3=.5 5=.  7 1=.7 6=.';


// TODO: * mul not working
PROGRAM = `
9
  1 1*.. 0 1*..  1 0*.. 2 2*.. 3 3*..
  9 9*.. 8 8*.. 7 7*.. 4 4*..

 .`;

// numbers, truncate correctly
PROGRAM = '12.34.55.123.234.345.256.257.65535. 66 . 111 .';

PROGRAM = '3 4+. 4 7+.';

PROGRAM = '0.';
PROGRAM = '12.34.5.6.7.';
PROGRAM = '1.12.123.9 0.0. 00. 000007. .'
PROGRAM = '3 4+. 1d.n.2d.n.3d.n. 0.0d.n. 00... 000. 0000. 00000. 01. 07. 0009.';

// edit
PROGRAM = 
`ABC DEF GHI  JKL
  2 SPACES LATER\tTAB
TAB\tTAB\tTAB\tTAB\tTAB
        SPACES
\tTAB
      ETC
    DEF
  GHI
END`;

PROGRAM = '1 2 3 4 5.....';
PROGRAM = '3 4+. 1d.n.2d.n.3d.n. 0.0d.n. 00... 000. 0000. 00000. 01. 07. 0009.';

// over
PROGRAM = '1d. 2d. 3d. 4d. 5d. o......';
// pick
PROGRAM = '11d. 22d. 33d. 44d. 55d. 4p......';

// multiply
PROGRAM = '0 0*. 8 0*. 0 8*. 1 8*. 8 1*. 8 8*. 255 2*. 255 255*. 128 128*. 42 33*. 17 99*. 1 255*. 255 1*.';

// new number parse
PROGRAM = '33 44+d.47.42.1025.0.  007. .';

// multiple unloop/leave

PROGRAM = '1 2(3])4 5 6 7.......';
PROGRAM = '1 2(3(4]4)5]5)6 7.......';
PROGRAM = '1 2(3(4]]4)4]4)5 6 7.......';
PROGRAM = '1 2(3(4]]4)44)5 6 7.......';

// string
PROGRAM = '8d.9d."BAR"oo..t..';
PROGRAM = '8d.9d."BAR"oo.."FOO"oo..6.tt7...';




// zzzz to find fast!

//      -*- truncate-lines: true; -*-
//
//
//
//              F8rth 8-Bit Forth
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

// DICTIONARY ENTRY (longword)
//               ____________________________ 
//              /    +------------------+    \
// offset:     /     |                  |     \
// |0     |1  /   |2 ^  |3         |4   v      \
// | link | flags | cod | name...7 | CODE... | data |
//    #2     #1      #1    #len
// bytes^^^
//
// link  : pointer to previous entry (2B)
// flags : N=immediate (lo bits data offset)
// cod   : offset of code (len = cod-2)
// name  : ascii, hi-bit terminated
// data  : as this is somewhat object
//         orienterd, data is after code
//         known by the code (?)
// 

// INTERPREATION
// 
// In general execution takes place inside
// a word.
//
// variables and registers
//
// BIP   : Base IP
//     Y : little "yp", added to IP
//         using LDAAY BIP as "next"
//         If you want to use Y, save it.
//
//         Either TYA,PHA .... PLA,TAY
//         Or     STAA('tmp') LDAA('tmp')
//
//         (BIP+ip) == token stored in X
//         ...except when function parsing
// 
//     X : general index register, free
//         initially it contains 'token'
//
//     A : general register free to use
//
// TASKS
//
// A word can be seen as a task.
//
//   - Limited to 256 bytes (1 page)
//   - Send and receive messages
//   - Reactive system ala erlang
//   - Internal storage
//   - Check status
//   - y yield
//   - Multiple types of message
//     X: message number
//     data on global stack?
//   - Provide and use services
//     (alarm, 
//   - local "recv" function (called)

// Local Storage ("User")
//
//   * static variables/data
//   * circular double-headed buffer
//     - l<     l>  (push, pop)
//     - q<     q>  (unshift, shift)
//           #      (size, 0 if empty)
//       q!     q@  (send, receive)
//       l!     l@  (1 byte addresses)
//   * or use Pub/Sub style
//     emit, subscribers, receive,
//     channels, ...
//     - can be implemented by just
//       producer calling consumers
//     - a channel can be an instance
//       of a queue word, code impl
//       just JSR to other word, no
//       setup, does not do ENTER as
//       it's calling an "abstract obj"
//   
// Stack usage
//   * has a single entry point
//   * the system will call with message

// Private Terminale Window (tty)
//   * ala Apple ][
//     (pos r,c  size w,h  cur r,c)
//   * minimize/maximize (user request)
//     (META-123... or CTRL-123...)
//   * can enter EDITOR for the command!
//     CTRL-R etc...

let utilty = require('./utility.js');
let terminal = require('./terminal-6502.js');
let jasm = require('./jasm.js');

let putc = terminal.aputc;
let putd = terminal.aputd;
let puts = terminal.aputs;
let getc = terminal.agetc;

let start = 0x501;

let trace = 0;
let tracecyc = 0;

// TODO: if not this, hang!
//process.exit(0);

// using BRK is slower, but saves bytes
// 95 bytes for 40 functions!
let brk= 1; // save space!
function next() {
  if (brk) {
    // use only 1 saves 2 bytes!
    // (little slower)
    BRK();
  } else {
    JMPA('NEXT'); // 3 bytes :-(
  }
}

console.log(
  'text', fg(GREEN), 'fish',
  bg(YELLOW), 'crap',
  off(), fg(BLUE), 'input',
  inverse(), 'output', off());

console.log(
  fg(GREEN), '34+.',
  bold()+fg(WHITE), '7777777',
  off()+inverse()+' '+off(),
)

console.log(
  fg(GREEN), '34+.',
  fg(WHITE), '7777777',
  fg(RED), '7777777',
  bold()+fg(RED), '7777777',
  off()+inverse()+' '+off(),
  italic(), "ITALICS? italics?",
)

console.log(
  bold()+fg(WHITE),
  '34+.',
  fg(GREEN),
  '7777777',
)

console.log(
  fg(GREEN), '34+.',
  amber, '7777777',
  off()+inverse()+' '+off(),
);

function ctrl(c) {
  return ord(c.toUpperCase())-64;
}

function meta(c) {
  return 0x80 + ord(c[1].toUpperCase());
}
  

let last, last_ret;

function def(a, optJmp, cmp=CPXN, ret=next) {
  let aa = typeof a==='string' && a.length==1? ord(a) : a;
  console.error("DEF", a, aa, optJmp);
  let tryother = gensym('_is_not_'+a+'_$'+cpu.hex(2,aa));
  let match = gensym('OP_'+a+'_$'+cpu.hex(2,aa));

  def.count++;

  enddef();
  last_ret = ret;

  L(gensym('_test_'+a+'_$'+cpu.hex(2,aa)));

  cmp(aa);
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
def.count = 0;


// end def, optNext:
//   default: next();
//   ''     : no next
//   'lab'  : JMAP('lab');
function enddef(optNext) {
  if (last) {
    if (typeof optNext==='undefined') {
      last_ret();
    } else if (optNext === '') {
      // none
    } else {
      JMPA(optNext);
    }

    L(last);
  }
  last= undefined;
}

// compare if A has command if so invoke
// optionally, call jmp instead
// (similar ot def)
function cmd(c, optJmp) {
  // parse cmd chars
  if (typeof c === 'string') {
    if (c.length === 1) {
      c = ord(c);
    } else if (c[0] === '^') {
      c = ctrl(c[1]);
    } else if (c[0] === '_') {
      c = meta(c1[1]);
    }
  }

  def(c, optJmp, CMPN, RTS);
}

function endcmd(foo) {
  // because we have stuff on stack?
  if (foo) throw `"%% endcmd can't JMP to '${foo}'`;
  
  enddef();
}

////////////////////////////////////////
//  TEST

var syms_defs, alfa_defs;

function test() {

ORG(0x0100); // This is ALL of our (user) memory!

// (ANS Forth specifies a minimum:
//  of 32 cells of Parameter Stack,
//  and 24 cells of Return Stack.)
const CELL= 1; // 8-bit system, LOL
const DS_SIZE= 32*CELL;
const RS_SIZE= 24*CELL;

// everything is relative the stack
// (so we can use PHA(), PLA(), lol)
// (DON'T JSR/RTS any, you hear?)
const      S= 0x0100;
const SYSTEM= 0x01f0;  

// For now user page/memory is stack!
// TODO: zp would save code bytes,
// but probably want to use indirection ptr
//const      U= S;
const      U= 0x0400; // not ZP! (no clash)

ORG(S);
L('S'); // alias to S

ORG(U);
L('U'); // U = user space (1 page)
  L('PASCAL_PROGRAM_Z'); pascalz(PROGRAM); // LOL

// 0x100-- program/editor
// 
// "top" of memory
ORG(SYSTEM-1-RS_SIZE-DS_SIZE); L('top');

// Data Stack (Params)
ORG(SYSTEM-1-RS_SIZE);         L('stack');

// Return Stack
ORG(SYSTEM-1);                 L('rstack');

//variables
ORG(SYSTEM);
L('SYSTEM');
  // I think we want the concept
  // of local data:

  // editing 
// effects initial evaulation?
//  L('edit_pos');  byte(PROGRAM.length>>1);
  L('edit_pos');  byte(0);

  L('line_pos');  byte(0); // one before?
  L('eol_pos');   byte(0); // one before?
  L('end_pos');   byte(0);
  L('last_line'); byte(0); // tmp3 ?
  L('num_pos');   byte(0);

  // make ZP global?
  L('tmp');       byte(0); // tmp?
  L('tmp2');      byte(0); // tmp?
  // these may be local page related?
  L('latest');    byte(0); // => zp?
  L('here');      byte(0); // "where"
  // "state" (or rather mode)  test with BITA!
  //   0d-- ---- : run ("interpreting") // BPL
  //   1d-- ---- : editing              // BMI
  //   -d-- ---- : display char/echo    // BVS
  const state_edit = 0x80;
  const state_display = 0x40;
  const state_run = 0;
  L('state');     byte(0); // why local?
                           // use for loop counting?
  L('sp');        byte(0); // might
  L('rp');        byte(0);
  L('LATEST');    word(0); 

L('SYSTEMS_END');
////////////////////////////////////////

if (jasm.address() > 0x0200)
  throw `%% SYSTEM area too big! ends at ${hex(4,jasm.address())}`;
////////////////////////////////////////

// separate code (ROM) & RAM
// == Harward Architecture
ORG(start);
L('FORTH_BEGIN');
  // init stack pointers
  LDXN('stack', lo); TXS();
L('quit');
  LDXN('rstack', lo); STXA('rp');

  // init
  LDAN(0xff),STAA('num_pos');;

  if (brk) {
    // modify BRK as short cut for JMPA('next'); (save 2 bytes/call)
    LDAN('BRK_NEXT', lo); STAA(cpu.consts().IRQ);
    LDAN('BRK_NEXT', hi); STAA(cpu.consts().IRQ, inc);
  } else {
    LDAN('FORTH_BEGIN', lo); STAA(cpu.consts().RESET);
    LDAN('FORTH_BEGIN', hi); STAA(cpu.consts().RESET, inc);
  }

  LDAN('FORTH_BEGIN', lo); STAA(cpu.consts().RESET);
  LDAN('FORTH_BEGIN', hi); STAA(cpu.consts().RESET, inc);

  // init other stuff
  LDAN(0); {
    STAA('tmp');
    STAA('latest');
    STAA('here');
    // init state of interpreter
    TAY();
  }

  LDAN(state_display); STAA('state');
  next();

L('FORTH_INIT_END');

L('edit2'); JMPA('edit');

// If enabled (why not always?) allow for:
// 
//   BRK();          // 1 byte "next"
//   JMPA('NEXT');   // 3 byte "next"
//
// - saves 2 bytes per next! (40 words -> 96!)
// - 16 cycles instead of 3 cycles.
//
L('BRK_NEXT');
  if (brk) { // overhead i-2, b5 c10
    TSX(),INX(),INX(),INX(),TXS();
  }

  let savcyc = 0;
L('NEXT');
  TRACE(()=>{
    if (!tracecyc) return;
    let c = cpu.state().cycles;
    princ('\t(C:'+(c-savcyc)+')\n');
    savcyc= c;
  });

// TODO: Use some tricks from Token Threaded Forth
// - http://6502org.wikidot.com/software-token-threading

  INY();
  // wrapped around?
  //BEQ('edit2');
  LDXAY(U);

  BITA('state');
  BVC('nodisplay'); {
    PHA(),TXA(); { // save TOS
      JSRA('display');
    } PLA();

    BITA('state');
    // loop if in editing: (re)display all!
    BMI('NEXT'); 
  }
 L('nodisplay');

  // TODO: replace state with JMP edit!
  BPL('_not_edit');
  JMPA('edit_next');
 L('_not_edit');

L('NEXT_END');

////////////////////////////////////////
// Interpreter

L('INTERPRET_BEGIN');
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

  // We're INTERPRETING!
  // (token in X)

  terminal.TRACE(jasm, ()=>{
    if (!trace) return;
    console.log('--interpret', {
      X: chr(cpu.reg('x')),
    });
  });

  // -- "interpretation" or running
  // LOL: we incstate by dec!
  // neg num can test with BIT!
  def(0); { 
    DEY(),LDXN(state_edit+state_display),STAA('state');
    // terminal debug help
    TRACE(()=>{
      // assumes to have printed screen first
      let used= cpu.reg('y');
      let free= SYSTEM-S-used;
      let rstack= jasm.getLabels().rstack+1;
      let stack= jasm.getLabels().stack+1;
      print();
      print();
      //for(let i=0; i<free; i++) {
      for(let i=0; i<256; i++) {
        //princ(m[SYSTEM+used+i]?'x':'.');
        princ(m[S+i]?'x':'.');
      }
      print();
      for(let i=0; i<DS_SIZE; i++) {
        princ(m[stack+i-DS_SIZE]?'D':':');
      }
      print();
      for(let i=0; i<RS_SIZE; i++) {
        princ(m[rstack+i-RS_SIZE]?'R':':');
      }

      // OMG: TODO: somuch cheating!
      princ(gotorc(1,1)+`(${used} free: ${free})`); 
      princ(ansi.cleol());
      princ(cursorRestore());
    });

    JMPA('edit');
  }

  L('INTERPRET_END');

  ////////////////////////////////////////
  // Symbol based operators

  // (and it fit in 256 bytes?)
  // (if so make an page offset jmp table for 32)

  // no TOS: // b12 c20 all stack !
  //   def('+'); TSX(),CLC(),LDAN(S+1),ADCAX(S+2),STAAX(S+2),PLA();
  //
  // zp stack using X // b11 c16 zp stack
  //   def('+'); CLC(),LDAAX(S+1),ADCAX(S+2),STAAX(S+2),DEX();
  L('SYMS_BEGIN'); syms_defs = def.count;

  // almost peano numbers!
  //def('M*'); { // b15 zp
  if (0) {
    TAX(),BEQ('NEXT');
    PLA(),STAA(0);

   L('_*');
    DEX();
    BEQ('NEXT');
    CLC();
    ADCA(0);
    JMPA('_*');
  }

  def('M'); {
    // TODO: remove
    TRACE(()=>{
      if (!tracecyc) return;
      savcyc= cpu.state().cycles;
      print();
    });

    // c144 Z1156
    STAZ(1);
    PLA(),STAZ(2);

    LDAN(0x80); // sentiel bit
    STAZ(0);
    CLC(),ROL();  // hi byte = 0 /// ASL?
    DECZ(1);
L('L1');
    LSRZ(2); // lo bit of NUM2
    BCC('L2');
    ADCZ(1); // If 1, add (NUM1-1)+1
L('L2');
    ROR(); // "Stairstep" shift (catching carry from add)
    RORZ(0);
    BCC('L1'); // When sentinel falls off into carry, we're done
    //STA RESULT+1
    LDAZ(0);

    // TODO: remove
    TRACE(()=>{
      if (!tracecyc) return;
      print('MUL.c: ', cpu.state().cycles-savcyc);
    });
  }

  def('*'); { // b19 avg c73 c26-172
    // TODO: remove
    TRACE(()=>{
      if (!tracecyc) return;
      savcyc= cpu.state().cycles;
      print();
    });

    STAZ(0);
    PLA(),STAZ(1);
    LDAN(0);

   L('_*N'); // c16
    LSRZ(0);
    BCC('_*noadd');

    CLC();
    ADCA(1);

   L('_*noadd');
    // w extra 2 bytes... => c93  Z932
    // avg c93 c22-204
    BEQ('_*done');
    CLC(),ROLZ(1); // asl?
    BNE('_*N')
  }

  L('_*done');
  // TODO: remove
  TRACE(()=>{
    if (!tracecyc) return;
    print('MUL.c: ', cpu.state().cycles-savcyc);
  });

  // TODO: JMPA('dex_txs');
  //        /get stack ptr                    /drop one
  def('+'); TSX(),CLC(),ADCAX(S+1),           DEX(),TXS(); // b7 c12 : TOS in A winner!
  def('-'); TSX(),CLC(),SBCAX(S+1),EORN(0xff),DEX(),TXS(); // haha CLC,NOT==M-A
  def('&'); TSX(),      ANDAX(S+1),           DEX(),TXS();
  def('|'); TSX(),      ORAAX(S+1),           DEX(),TXS();
  def('^'); TSX(),      EORAX(S+1),           DEX(),TXS();

  def('~'); EORN(0xff)                                     // WINNER!

  def('.'); STYA('tmp'),LDYN(0),JSRA(putd),LDYA('tmp'),PLA();

  def('<'); CLC(),ROL(); // TODO: ASL(); save 1B
  def('>'); CLC(),ROR(); // TODO: LSR()

  // TODO:
  //   # $ % , ?
  
  // TODO: this is limited/local to one page
  def('"'); {
    PHA(),
    INY(),TYA(),PHA(),
    LDXN(0),LDAN(ord('"'));
    L('_"'),CMPAY(U),BEQ('_".done'); {
      INY(),INX();
    } BNE('_"');
    L('_".done'),TXA();
  }
  def(' '); // do not interpret as number! lol
  def('@'); TAX(),LDAAX(U); // cool!
  def('!'); TAX(),PLA(),STAAX(U),PLA();

  // ?=
  // ?<
  // ?>
  // ?~=
  // ?~<
  // ?~>

  def('='); { // Unsigned <=>  ==> -1, 0, 1
    TSX(),CMPAX(S, inc);
    // Had to do some thinking about this one...
    //
    // N  Z  C               C  !Z         -2
    // --------              ===== ordered ===
    // ?  0  0      A < M    0  1   1      -1
    // 0  1  1      A = M    1  0   2       0
    // ?  0  1      A > M    1  1   3      +1
    //
    //         A := C*2 + !Z - 2;
    //
    // too difficult; asked in 6502 forum for shortest
    // - https://m.facebook.com/groups/1449255602010708?view=permalink&id=2956507981285455&notif_ref=m_beeper

    TSX(),CMPAX(S, inc);
    
    if (0) {
      // THIS IS SO WRONG, lol? but why works sometimes?
  LDAN(255);
  CMPN(1);  // for these it's wrong!
      // works  b7 c13  !!!! WTF!
      PHP();
      PLA();
      ROL();
      ANDN(1);
      SBCN(0);

    } else if (0) {  // b9 c5 or c10 (with SBC/CMP +c4)
      // jsk - CORRECT!

      SEC();
      SBCAX(S, inc); // nc
      BEQ('__next');
      LDAN(1);
      ADCN(254); // make ADC w C add 2!
      ADCN(0);
    L('__next');


    } else if (1) {  // b 9  c5 | c9 | c10
      // Daneiele Versotto NICE!

      SEC();
      SBCAX(S, inc); // nc
      BEQ('__next');
      LDAN(1);
      BCC('__next');
      LDAN(0xff);
    L('__next');

      
    } else if (1) { // b11 +1 SEC()
      // jsk variant of below

      SEC();
      SBCAX(S, inc);  // change to SBC

      BEQ('__end');   // A is already 0!
      LDAN(0);
      BCS('__p');
      ADCN(0xff);
    L('__p');
      ADCN(0);
    L('__end');

    } else if (1) { // b10

      STYA('tmp'); // not counting

      LDYN(0);
      CMPAX(S, inc); // no count

      BEQ('-z');
      BCS('-p');
      DEY();
      DEY();
     L('-p');
      INY();
     L('-z');
      TYA();
      
      L('_=end');

    LDYA('tmp');

    }
    // all variants cleanup
    TSX(),DEX(),TXS(); // pop

    next();
  }

  // TODO:color\ make a JSR "getc" that echoes?
  def("'"); PHA(),INY(),LDAAY(U),JSRA(putc); // got the char!

  if(0) { // dispatch and next for these 


//  def('#');
//  def('$');
//  def('%');
    
  }
  
  // TODO: if
//  def('?');

  // TODO: GOTO ?
  // TAY(),PLA();

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

  // loop stuff
  def('('); {
    L('do');
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

  // COLON (not ENTER) and ; (EXIT)
  def(':', 'do'); // dispatch does ENTER
  def(';'); {
    PHA(); {
      L('_;_mid');
      R_PLA();
      // do "RTS"
      R_PLA(),TAY();
    }
    PLA();
  }


  L('SYMS_END'); syms_defs = def.count - syms_defs;


  ////////////////////////////////////////
  // ALFA / letter commands

  // TODO:
  //   g v y z
  //   [ ]
  //   { } - nested strings / lambdas
  //   _longname
  //
  // TOOO: rename r R
  // TOOO (secondary ops):
  //
  //   a c r w
  //
  //  (No def: b f u m)
  //
  // 27 words... for double... :-(
  // w must: * + . < > " @ ! ( ) o s i j r R (15)
  // w op  : - & | ^ ~ = d \ o n t (12)
  L('ALFA_BEGIN'); alfa_defs = def.count;

  def('d'); PHA();
  def('\\'); PLA();
  def('o'); PHA(),TSX(),LDAAX(S+2);
  def('s'); STAA('tmp'),PLA(),TAX(),LDAA('tmp'),PHA(),TXA(); // b10 c19

  def('p'); PHA(),TSX(),TXA(),ADCAX(S+1),TAX(),PLA(),LDAAX(S+1);
  def('i'); PHA(),LDXA('rp'),LDAAX(S+1);
  def('j'); PHA(),LDXA('rp'),LDAAX(S+3);

  def('r'); L('R>'),PHA(),R_PLA(); // b10 + 7
  def('R'); L('>R'),R_PHA(),PLA(); // b10 + 7

  def('t'); TAX(),STYA('tmp'); {
    PLA(),LDYN(U, hi),JSRA(puts);
  } LDYA('tmp'),PLA();

  def('q', ''); JMPA('quit');

  // not needed unless go with Words (double)
  //def('h'); PHA(),LDAAX('here');
  //def('l'); PHA(),LDAAX('latest');

  def(']'); { // b44 (HUGE! because of interpret)
    // TODO: idea; have a "skip mode",
    // only then we need a stack of modes?
    //
    // Hmmmm STATE = 0  Immediate mode (running)
    //       STATE = 1  Skipping mode!
    //                  just reacting to editing
    //                  and maybe [ ] ?
    //                  but [] 
    // possibly    > 1  is the count of {} to skip?
    //                  do we need to match correctly?
    //                  LOL: only "..." and then
    //                  counting ({}) no count[]
    //   !!! During "skipping" / compilation mode
    //     we can use the data stack to store
    //     expected token!
    //
    // Maybe STATE = -1   Immediate
    //                0   Compiling
    //               >1   Loops that needs dec?
    //       can have separate words for ();
    //  maybe won't work when enter immediate mode?
    //  may need to have separate counter. Hmmm
    //
    // CONCLUSION: (?)
    //   it's cheaper and much more effective
    //   to "compile" the code... the traditional
    //   way. It's probably smaller even!
    //
    // OR>...
    //   We could just enter "compile mode"?
    //   That skips matching stuff?
    //   (it doesn't have to normally, but...)
    //
    //   So just name it "skip mode"?
    PHA(); {

      TXA();
      LDXN(0); // count of depth of ()

      // TODO: count the number of ]]]]
    L('_]]');
      TRACE(_=>['].count', cpu.reg('x')]);
      CMPN(ord(']'));
      BNE('_]skip');
      INX(),INY(),LDAAY(U);
      BNE('_]]');
      // never falls out (unless at 00)
      // TODO: test...
      DEY();

      // Takes an f to run at emulation time
      // if it returns an array, pass on to
      // console.log

    L('_]skip.next');
      INY();
    L('_]skip');
      LDAAY(U);
      terminal.TRACE(jasm, ()=>{
        //princ(' <skip: '+chr(cpu.reg('x'))+'> ');
      });

      // TODO: "  [  ) "
      // TODO: nesting of "{ ..{ ...  } .. }"

      CMPN(ord(';'));
      BNE('_;_nomid');
      JMPA('_;_mid');
      L('_;_nomid');

      // skip inline backtick value (could be any)
      CMPN(ord('`'));
      BNE('_not_backtick');
        INY();
      L('_not_backtick');

      CMPN(ord('('))
      BNE('_not(');
        INX();
      L('_not(');

      CMPN(ord(')'));
      BNE('_]skip.next');
      DEX();
      BNE('_]skip.next');
      // you'll fall through here when at
      // and the last matching ')'

      // foudn last matching ')'
      // similar to ';' but w/o PLA
      R_PLA(); // drop "ip"
    }
    PLA();
  }

// 0 -> 1 other +: 0
//  def('z'); CMPN(0),LDAN(0),ADCN(0);

// 0: 0  -: 255
//  def('z'); CMPN(0),LDAN(0),ADCN(255);

//  def('z'); CMPN(0),LDAN(255),ADCN(0);

// This gives correct:  b 8  (too much!) c8
//  def('z'); CMPN(0),LDAN(0),ADCN(0xff),EORN(0xff);

  // Typical: b 8 c7+1
//  def('z'); CMPN(0),LDAN(0),BCC('_z'),
//  EORN(0xff),L('_z');

  // nand?
  //def('N'); TSX(),ANDAX(S+2),EORN(0xff);

  def('n'); CLC(),SBCN(0),EORN(255);
  def('k'); PHA(),L('_K'),JSRA(getc),BEQ('_K');
  def('e'); JSRA(putc),PLA();

  // TODO:
  // xx execute
  // xe eval
  // xs jsr w regs
  // xa jmp w regs
  // xr rts
  def('x'); TAX(),PLA(),JMPA('interpret');

  def('S'); TSX(),TXA();

// 0 -> 0 other -> 255
//  def('z'); CMPN(0),LDAN(0),SBCN(0);


  // -- printers and formatters
  def(10); // do not interpret NL as number! lol
  def('`', ''); JMPA('printval');

  // ???
  def('z'); TSX(),CMPN(0),SBCAX(S);


  enddef();
  L('ALFA_END'); alfa_defs = def.count - alfa_defs;

  ////////////////////////////////////////
  // more special test, or fallbacks

//  CPXN(31),BCC('number?');
  //JMPA('printcontrol');

L('NUMBER_BEGIN');
 L('number?')

  PHA(); // save current

  // extract number from digit
  TXA(),SEC(),SBCN(ord('0'));
  CMPN(10),BCS('have_num'); {
    PLA(); // restore
    JMPA('not_number');
  } L('have_num');
  
  STAZ(1);

  DEY(),CPYA('num_pos'),BEQ('_num.cont'); {
    // It's a new number
    // TRACE(()=>princ('<LDAN0>'));
    LDAN(0);
  } SKIP1(),L('_num.cont'); {
    // TRACE(()=>princ('<PLA>'));
    PLA();
  }
  INY();

  STYA('num_pos');

  // multiply A by 10
  STAZ(0);
  CLC(),ROL();         // *4 
  CLC(),ROL();         // TODO: fix ASL
  CLC(),ADCA(0);       // A*4 + A
  CLC(),ROL();         // *2 = A*10

  // add digit
  CLC(),ADCZ(1);

  next();

L('not_number');
L('NUMBER_END');

L('FIND_BEGIN');
L('findword'); 
next();

  // -- ENTER If not a primitive, then it's "interpreted" ends with ;
  STXA('tmp');

  // save data stack
  TSX(); STXA('stack'); {
    // restore rstack
    LDXA('rstack'); TXS(); {
      TYA(),PHA(); // save "ip"
    } TSX(); STXA('rstack');
  } LDXA('stack'); TXS();

  LDXA('tmp');
  // Find word from token (TODO:' ?)
  LDYA('latest');

L('find');
  TXA(); // get token
  CMPAY(U+1); // 0: "ptr to next word", 1: "token/name", 2: "code"
  BEQ('found');
  LDAAX(U); // link
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
L('FIND_END');

//   (to much growth: implement as word?)
L('FORTH_END');

////////////////////////////////////////
// Extras (not core)

L('XTRAS_BEGIN');

L('printval');
  PHA(); {
    // TODO: make section for commands where A Y is saved

    // next byte
    INY(),LDXAY(U);

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

  // control codes, quote them!
L('printcontrol');
  PHA(),TYA(),PHA(); {
    LDAN(ord('<')),JSRA(putc);
    TXA(),LDYN(0),JSRA(putd);
    LDAN(ord('>')),JSRA(putc);
  }; PLA(),TAY(),PLA();
  next();

L('XTRAS_END');
  
////////////////////////////////////////
// Emacs

L('EDIT_BEGIN');

L('OP_BackSpace');
  // nothing to delete?
  CPYN(1),BMI('edit_next');
  //CPYN(2),BMI('edit');

  PHA(); {
    // delete on screen (BS+SPC+BS) // b12
    // (TODO: optimize with a putsi)
    LDAN(8),JSRA(putc);
    LDAN(32),JSRA(putc);
    LDAN(8),JSRA(putc);

    // null out last char
    DEY();
    PHA(); {
      LDAN(0),STAAY(U);
    } PLA();
  }
  RTS();

L('OP_Run');
  TRACE(()=>{
    princ(ansi.hide());
    princ(ansi.home());
  });

  PHA(); {
    LDAN(ord('\n')),LDYN(0),JSRA(putc);
    LDAN(ord('\n')),LDYN(0),JSRA(putc);
  } PLA();
  LDYN(0xff);
  
  // Reinterpret buffer from scratch
  // stack is lost etc, only memory remain!
  TRACE(()=>princ(ansi.hide()));
  JMPA('FORTH_BEGIN');

L('OP_List');
  TRACE(()=>princ(ansi.cursorSave()));
  TRACE(()=>princ(ansi.cls()+ansi.home()+ansi.hide()));
  TYA(),PHA(); {
    LDAN(ord('\n')),JSRA(putc);
    LDAN(ord('\n')),JSRA(putc);
    LDXN(0xff);
    LDAN(U+1, lo),LDYN(U+1, hi), JSRA(puts);
  } PLA(), TAY();
  TRACE(()=>princ(ansi.cursorRestore()+ansi.show()));
  JMPA('edit_next');
  // TODO: FALLTHROUGH!

// We're not forthing, so we can use the rstack!
// (what if we want to do editing in forth?)
L('edit');
  LDYA('edit_pos');

  TRACE(()=>princ(ansi.show()));

  PHA(); // save TOS!

  // this so can use RTS for 'edit_next'!
 L('_edit');
  JSRA('edit_next');
  BITA('state'),BMI('_edit')

  // if no longer editing
  PLA(); // restore TOS
  next();

L('edit_next');
  // save cursor position
  STYA('edit_pos');

  TRACE(()=>{
    princ(cursorSave());
    princ(gotorc(1, 30));
    princ(cpu.reg('y')+'   ');
    princ(cursorRestore());
  });

 L('edit_next_waitkey');
  NOP(); // just to display different label
 L('_edit.waitkey'),
  JSRA(getc),
  BEQ('_edit.waitkey');

  if(1)
  terminal.TRACE(jasm, ()=>{
    return;
    console.log('edit', {
      A: hex(2,cpu.reg('a')),
      c: chr(cpu.reg('a')),
      Y: hex(2,cpu.reg('y')),
      X: hex(2,cpu.reg('x')),
    });
    //cpu.dump(S, 256/8, 8, 1);
  });

  // hmmm
  //def(':'); colon(),INCA('state');

  cmd(0x7f, 'OP_BackSpace');
  cmd('^R', 'OP_Run');
  cmd('^H', 'OP_BackSpace');
  cmd('^L', 'OP_List');

  cmd('^F'); L('e+'),INY(),
    BEQ('e-');
    TRACE(()=>princ(ansi.forward())); NOP();
  cmd('^B'); L('e-'),DEY(),
    BEQ('e+');
    TRACE(()=>princ(ansi.back())); NOP();
  cmd('^P'); DEY(),BEQ('e+');
    TRACE(()=>princ(ansi.up())); NOP();
  cmd('^N'); INY();
    TRACE(()=>princ(ansi.down())); NOP();
  cmd('^A'); LDYA('line_pos');
    TRACE(()=>princ(chr(10)));
  cmd('^E'); LDYA('eol_pos');
  cmd('^G'); TYA(),CLC(),ROR(),TAY();
  endcmd();

  // non-printable
  CMPN(31),BCS('edit_next'); // ctrl-
  CMPN(128),BCC('edit_next'); // meta-

  // store character
  STAAY(U),INY();
//  next();
//  JSRA('display');
//  JMPA('edit_next');

  // TODO: can we be in vt100 insert char mode?

  // Display have two functions:
  // 1. display a trace of command character
  // 2. display an edit buffer character
  // 3. update line_pos, eol_pos, end_pos
  //    to make the editor code simple.
 L('display');
  // TODO: don't cheat!
  TRACE(()=>princ(lime));

  // tell terminal to save cursor when
  // it's at edit_pos!
  CPYA('edit_pos'),BNE('_display.nopos');
 L('display_pos');
  NOP();
  TRACE(()=>princ(ansi.cursorSave()));
  LDXA('last_line'),STXA('line_pos');
  LDXN(0),STXA('eol_pos');
  NOP();
  if(0) TRACE(()=>print("<<<HERE"+JSON.stringify({
    A: cpu.reg('a'),
    Y: cpu.reg('y'),
    edit_pos: m[jasm.getLabels().edit_pos]})));
  NOP();
  L('_display.nopos');

  // need CR NL
  CMPN(10),BNE('_display.notnl'); {
    TRACE(()=>princ(ansi.cleol()));
    PHA(),LDAN(13),JSRA(putc),PLA();

    STYA('line_pos');
  
    // if eol_pos is zero it'll be set!
    LDXA('eol_pos'),BNE('_display.notnl');
    STYA('eol_pos');
  } L('_display.notnl');

  // actually print char!
  JSRA(putc);

  // end? - turn off display
  CMPN(0),BPL('_display.noend'); {
    LDAN(state_edit); // stay edit/run
    ANDA('state');
    STAA('state');
    STYA('end_pos');
  } L('_display.noend');

  // TODO: don't cheat!
  TRACE(()=>princ(fg(WHITE)));

  RTS();
  // Do NOT put any more code here!
  // (to keep display bytes correct)
L('EDIT_END');

////////////////////////////////////////
// High-Level words go here
L('WORDS_BEGIN');

  WORD('ones', 0, '11111.....');
  WORD('twos', 0, '2222....');
  WORD('threes', 0, '333...');

L('WORDS_END');

} // test

L('resultColor'); string(amber);
L('colorOff'); string(off());
L('hide'); string(ansi.hide());
L('show'); string(ansi.show());

////////////////////////////////////////
// word functions

// define a high level word
// at "pre-process time" (macro)
// Usage:
//   CREATE('square', 0, 'd*');
// Returns start address
var latest = 0
function WORD(name, imm, prog, datas=[], qsize=0) {
  if (!!prog.match(/:/) !== !!prog.match(/;/))
      throw `%% WORD: '${word} must either use : and ; or neither`;
  let start = jasm.address();
  let l = gensym('WORD_cod_'+name);

  // link
  word(latest);
  // imm / flags
  byte(imm);
  // cod
  byte(l, a=>a-start);
  // name
  hibit(name);
  // dataset
  // (TODO: how to find it?)
  datas.forEach(x=>data(x));
  // program
 L(l);
  string(prog);
  // circular queue/buffer
  // (TODO: howto find it?)
  allot(qsize);
  
  let len = jasm.address() - start;
  if (len > 256)
    throw `%% WORD: '${name}' bigger than 256 bytes: ${len}`;

  latest = jasm.address();

  // pathc/put first in linked-list
//  ORG(jasm.getLabels().LATEST); word(latest);

  // let's continue
//  ORG(latest);
} 


// generates 6502 code for create
function create() {
  
}

////////////////////////////////////////
// Generic Library

function R_BEGIN() { // b8
  TSX(),STXA('sp'),LDXA('rp'),TXS();
}

function R_END() { // b8
  TSX(),STXA('rp'),LDXA('sp'),TXS();
}

// use these twice and you might as well...
function R_PHA() { // b9
  LDXA('rp'),STAAX('S'),DECA('rp'); // push
}
function R_PLA() { // b9
  LDXA('rp'),INCA('rp'),LDAAX('S', inc); // drop
}

// BIT trick (overlaps other instr)
// use:
//   CMP(0),BNE(3),LDAN(0)p
function SKIP1() { // BITZ()
  data(0x24);
}
function SKIP2() { // BITA()
  data(0x2c);
}

function TRACE(f) {
  terminal.TRACE(jasm, ()=>{
    let r = f();
    if (!Array.isArray(r)) return;
    print(' >>> ', ...r);
  });
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
  let lasta, last='', runtot = 0;
  Object.keys(l).forEach(x=>{
    // skip local labels
    if (x.match(/^_/)) return;
    if (x.match(/_$/)) return;

    let a = l[x];
    let len = lasta ? a - lasta : '-';
    runtot += +len;
    
    if (last) {
      print(last.padEnd(22,' '), hex(4,lasta),
            "\t", len.toString().padStart(4),
            "\t", runtot.toString().padStart(5));
    }

    if (last.match(/_BEGIN$/)) runtot = 0;
    if (last.match(/_END/)) runtot = 0;


    lasta = a;
    last = x;

  });

}

print();

function prsize(nam, len, more) {
  console.log(nam,
              len.toString().padStart(6),
              more?more:'');
}
prsize("FORTH :", l.FORTH_END-l.FORTH_BEGIN);
prsize(" INIT :", l.FORTH_INIT_END-l.FORTH_BEGIN);
prsize(" NEXT :", l.NEXT_END-l.NEXT);
prsize(" inter:", l.INTERPRET_END-l.INTERPRET_BEGIN);
prsize(" SYMS :", l.SYMS_END-l.SYMS_BEGIN);
prsize("  ( # :", syms_defs, '/ 22)');
prsize(" ALFA :", l.ALFA_END-l.ALFA_BEGIN);
prsize("  ( # :", alfa_defs, '/ 36)');
prsize(" NUMS :", l.NUMBER_END-l.NUMBER_BEGIN);
prsize(" FIND :", l.FIND_END-l.FIND_BEGIN);
prsize("XTRA  :", l.XTRAS_END-l.XTRAS_BEGIN);
prsize("EDIT_ :", l.EDIT_END-l.EDIT_BEGIN);
prsize(" displ:", l.EDIT_END-l.display);
prsize("WORDS :", l.WORDS_END-l.WORDS_BEGIN);
prsize("TOTAL :", jasm.address()-start);


print('-'.repeat(40));
print();

// crash and burn
jasm.burn(m, jasm.getChunks());
console.log({start});

// remove l.waitKey!
delete l._waitkey;
delete l['_edit.waitkey'];

cpu.setLabels(l);

cpu.setTraceLevel(1);
cpu.setTraceLevel(2);
cpu.setTraceLevel(0);

cpu.setOutput(1);
cpu.setOutput(0);

trace = 1;
trace = 0;


cpu.reg('pc', start);
cpu.run(-1);
