//      -*- truncate-lines: true; -*-

PROGRAM = '123 ...'; // test space
// +1 inc at 4th position
// TODO: bug? 153 wrap around (CTRL-R)
PROGRAM = '9`\0048765432102@d.1+d.2!2@...........h.';
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

///PROGRAM = '19s..11111`A56789@d.1+9s!fish\n';
// PROGRAM = '9876543210..........'; test stack and print


// TODO:
// exit, hmmm, searches for ) lol
PROGRAM = ':1.]234';

// ( ) loop
PROGRAM = '123(4.(5.)9.9.9.)567';

// loop w ]
PROGRAM = '123(4.]6.6.6.)567';

// TODO: should print 1 2 3 4 5 6
// (the ')' is somewhat undefefined,
// in this case pulls z 0 from stack, lol)
PROGRAM = ':1.]6.6.6.;  2.3.4.)8.8.';

// tail recurse on last ')', lol
// (however, this has overhead of one PH,PL
//  for interpreted words :-( )
// For ALF; words start at Y=0, but then needs
//  another word for tailrecurse :-( )
PROGRAM = ':1.)234;';

// TODO: skip intermediate (count matching)
// should give 1 2 3 4 
PROGRAM = '12(3.](6.9.6.)0.6.0.)4.5.6.';

// 0=
PROGRAM = '0z. 1z. 2z. 3z. 4z. 5z. 6z. 7z. 8z. 9z. ';

// multiple unloop/leave
PROGRAM = '12(3])456';
PROGRAM = '12(3(4]4)5]5)67';

PROGRAM = '12(3(4]]4)44)567';
PROGRAM = '12(3(4]]4)4]4)567';

PROGRAM = '34+.';

PROGRAM = '0.1.2.3.7.9.';

PROGRAM = `
34+.99+.
73-.37-.99-.01-.
73*.37*.99*.
73/.37/.99/.93/.
13&.97&.84&.
13|.97|.84|.
13^.97^.84^.
 1~. 0~. 8~.01-~.
`;

PROGRAM = '17=.12=.  33=.55=.  71=.76=.';


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

function cls() { return '[2J' + home; }
function home() { return gotorc(0, 0); }
function gotorc(r, c) { return '['+r+';'+c+'H'; }
function cursorOn() { return '[?25h'; }
function cursorOff() { return '[?25l'; }

function cursorSave() { return '7'; }
function cursorRestore() { return '8'; }

function fgcol(c) { return '[3'+c+'m'; }
function bgcol(c) { return '[4'+c+'m'; }

function inverseOn() { return '[7m'; }
function underscoreOn() { return '[4m'; }
function boldOn() { return '[1m'; }

function save(c) { return '[3'+c+'m'; }

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

  def.count++;

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
def.count = 0;


function enddef() {
  if (last) {
    next();
    L(last);
  }
  last= undefined;
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
L('S'); // alias

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
  

  // make ZP global?
  L('token');     byte(0); // tmp?
  // these may be local page related?
  L('latest');    byte(0); // => zp?
  L('here');      byte(0); // "where"
  L('state');     byte(0); // why local?
                           // use for loop counting?
  L('sp');        byte(0); // might
  L('rp');        byte(0);
  L('LATEST');    word(0); 

////////////////////////////////////////
if (jasm.address() > 0x0200)
  throw "SYSTEM area too big!";
////////////////////////////////////////

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
  TRACE(()=>princ('[H[2J[3J\n\n'));
  PHA(); {
    LDAN(ord('\n')),LDYN(0),JSRA(putc);
    LDAN(ord('\n')),LDYN(0),JSRA(putc);
  } PLA();
  LDYN(0xff);
  
 L('decstate'); 
  INCA('state');

  JMPA('FORTH_BEGIN');

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

  // hmmm
  //def(':'); colon(),INCA('state');
  //def('C'); compile();

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
  if (brk) {
    STAA('token');
    // drop BRK crap
    PLA(),PLA(),PLA();
    // TODO: brk dispatch?
    LDAA('token');
  }

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
    TRACE(()=>princ(fgcol(GREEN)));

    PHA(); TXA();
    JSRA(putc);

    // TODO: don't cheat!
    TRACE(()=>princ(fgcol(WHITE)));

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
    // terminal debug help
    TRACE(()=>{
      let used= cpu.reg('y');
      let free= SYSTEM-S-used;
      let rstack= jasm.getLabels().rstack+1;
      let stack= jasm.getLabels().stack+1;
      princ(cursorSave());
      print();
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

      princ(gotorc(1,1)+`(${used} free: ${free})`);
      princ(cursorRestore());
    });
  def(' '); // do not interpret as number! lol
  def(10); // do not interpret as number! lol

  // same "minimal" 8 as sectorforth!
  def('@'); TAX(),LDAAX(S); // cool!
  def('!'); TAX(),PLA(),STAAX(S),PLA();

  ////////////////////////////////////////
  // Symbol based operators

  L('SYMS_BEGIN'); syms_defs = def.count;
  // (and it fit in 256 bytes?)
  // (if so make an page offset jmp table for 32)

  // no TOS: // b12 c20 all stack !
  //   def('+'); TSX(),CLC(),LDAN(S+1),ADCAX(S+2),STAAX(S+2),PLA();
  //
  // zp stack using X // b11 c16 zp stack
  //   def('+'); CLC(),LDAAX(S+1),ADCAX(S+2),STAAX(S+2),DEX();

  // TODO: JMPA('dex_txs');
  //        /get stack ptr                    /drop one
  def('+'); TSX(),CLC(),ADCAX(S+1),           DEX(),TXS(); // b7 c12 : TOS in A winner!
  //TRACE(()=>[cpu.reg('a')]);
  def('-'); TSX(),CLC(),SBCAX(S+1),EORN(0xff),DEX(),TXS(); // haha CLC,NOT==M-A
  def('&'); TSX(),      ANDAX(S+1),           DEX(),TXS();
  def('|'); TSX(),      ORAAX(S+1),           DEX(),TXS();
  def('^'); TSX(),      EORAX(S+1),           DEX(),TXS();
  def('~'); EORN(0xff)                                     // WINNER!

  def('.'); STYA('token'),LDYN(0),JSRA(putd),LDYA('token'),PLA();

  // add more symbols here!

  def('<'); CLC(),ROL(); // TODO: ASL(); save 1B
  def('>'); CLC(),ROR(); // TODO: LSR()

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

      STYA('token'); // not counting

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

    LDYA('token');

    }
    // all variants cleanup
    TSX(),DEX(),TXS(); // pop

    next();
  }

  // TODO:color\ make a JSR "getc" that echoes?
  def("'"); PHA(),INY(),LDAAY(S),JSRA(putc); // got the char!

  if(0) { // dispatch and next for these 


  def('"');
  def('#');
  def('$');
  def('%');

  def('/');

  def(',');
    
  }
  
  // TODO: if
  def('?');

  // TODO: GOTO ?
  // TAY(),PLA();

  def('*'); {
    // 19 bytes only! avg 130 cycles
    // - https://www.lysator.liu.se/~nisse/misc/6502-mul.html
    // same as:
    // - https://llx.com/Neil/a2/mult.html
  L('mul');

    PHA();

    STYA('token'); {
      TSX();

      // TODO: FIX!
      // Try to fix the values
      // still not working!
      //LDAN(2); STAAX(S+1);
      //LDAN(3); STAAX(S+2);
      
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
      INX(),INY(),LDAAY(S);
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
      LDAAY(S);
      terminal.TRACE(jasm, ()=>{
        //princ(' <skip: '+chr(cpu.reg('x'))+'> ');
      });

      // TODO: "  [  ) "
      // TODO: nesting of "{ ..{ ...  } .. }"

      CMPN(ord(';'));
      BEQ('_;_mid');

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
  L('ALFA_BEGIN'); alfa_defs = def.count;


  ////////////////////////////////////////
  // ALFA / letter commands
  def('r'); L('R>'),PHA(),R_PLA(); // b10 + 7
  def('R'); L('>R'),R_PHA(),PLA(); // b10 + 7

  def('S'); TSX(),TXA();

// 0 -> 0 other -> 255
//  def('z'); CMPN(0),LDAN(0),SBCN(0);

  def('z'); TSX(),CMPN(0),SBCAX(S);

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

  // ~1+
  //def('N'); TSX(),ANDAX(S+2),EORN(0xff);
  // ... and it also defines these
  //def('B'); PHA(),LDAN('tib');
  //def('T'); PHA(),LDAA('state');
  //def('I'); PHA(),LDAN('>in');
  //def('h'); PHA(),LDAAX('here');
  def('h'); PHA(),TYA(); // if in compilation...
  def('L'); PHA(),LDAAX('latest');
  def('K'); PHA(),L('K'),JSRA(getc),BEQ('K');
  def('e'); JSRA(putc),PLA();

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
  L('ALFA_END'); alfa_defs = def.count - alfa_defs;

  ////////////////////////////////////////
  // more special test, or fallbacks

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

////////////////////////////////////////
// Extras (not core)

L('XTRAS_BEGIN');
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

L('XTRAS_END');
  
////////////////////////////////////////
// High-Level words go here
L('WORDS_BEGIN');

  WORD('ones', 0, '11111.....');
  WORD('twos', 0, '2222....');
  WORD('threes', 0, '333...');
L('WORDS_END');

} // test

L('resultColor'); string(amber());
L('colorOff'); string(off());

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
  LDXA('rp'),INCA('rp'),LDAAX('S',inc); // drop
}

// BIT trick (overlaps other instr)
// use:
//   CMP(0),BNE(3),LDAN(0)p
function SKIP1() { // BITZ()
  data(0x24);
}
function SKIP1() { // BITA()
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

function prsize(nam, len, more) {
  console.log(nam,
              len.toString().padStart(6),
              more?more:'');
}
prsize("FORTH :", l.FORTH_END-l.FORTH_BEGIN);
prsize(" SYMS :", l.SYMS_END-l.SYMS_BEGIN);
prsize("  ( # :", syms_defs, ')');
prsize(" ALFA :", l.ALFA_END-l.ALFA_BEGIN);
prsize("  ( # :", alfa_defs, ')');
prsize(" XTRA :", l.XTRAS_END-l.XTRAS_BEGIN);
prsize("WORDS :", l.WORDS_END-l.WORDS_BEGIN);
prsize("TOTAL :", jasm.address()-start);


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
