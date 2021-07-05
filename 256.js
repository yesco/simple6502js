//      -*- truncate-lines: true; -*-








// TODO: make small useful 8-bit forth!










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

// multiple unloop/leave

PROGRAM = '1 2(3])4 5 6 7.......';
PROGRAM = '1 2(3(4]4)5]5)6 7.......';
PROGRAM = '1 2(3(4]]4)4]4)5 6 7.......';
PROGRAM = '1 2(3(4]]4)44)5 6 7.......';

// string
PROGRAM = '8d.9d."BAR"oo.."FOO"oo..6.tt7...';
PROGRAM = '8d.9d."BAR"... ..';
PROGRAM = '8d.9d."BAR"t ..';

// new number parse
PROGRAM = '33 44+d.47.42.1025.0.  007. .';

// double words and h ,
PROGRAM = 'h..';
PROGRAM = 'h@.';
PROGRAM = 'h..hw@.66d0s.hw!7d.hw@..';

// works fine one byte U addresses!
PROGRAM = '32@. 66 32! 44 31! 32@. 31@.';

PROGRAM = '0 128  w@..   152 118 w@..';
PROGRAM = '152 118 w@..';

// check R stack op ok
PROGRAM = '8 9 42R.17.r..';
// check i
PROGRAM = '8 9 42R.17.i..r.';
// check j
PROGRAM = '8 9 42R.99R255R17R.i.j..r.r.r.';

// tail recurse on last ')', lol
// (however, this has overhead of one PH,PL
//  for interpreted words :-( )
// For ALF; words start at Y=0, but then needs
//  another word for tailrecurse :-( )
PROGRAM = ':1.)2 3 4;';

// counted loops ()
PROGRAM = '4D.9D.0("never"t.i.8.)7. ..';
PROGRAM = '4D.9D.5("fives"t.i.8.)7. ..';
PROGRAM = '4D.9D.1("once"t.i.8.)7. ..';
PROGRAM = '55d.66d.77d.88d..10(10(i.j.))...';
PROGRAM = 'T55d.44d.33d.(1.2.3.4.)...T';

PROGRAM = 'T44.33.255(i.)..T';

PROGRAM = '9 3 4 + . .';

// test ALF inline
PROGRAM = '11d.22d.33d.D...';

// test ALF inline cycles
PROGRAM = '11d.22d.33d.Td9+T...';
PROGRAM = '11d.22d.33d.TDT...';
PROGRAM = 'TTETFT';
PROGRAM = 'TTETEEEEEEEEEET';

// Got (Rot)
PROGRAM = '1 2 3 G ...';

// Fib iterator
PROGRAM = 'T0 1 17(F)T';

PROGRAM = 'T1 2 3TGT...T';

PROGRAM = '9d.::G:Rsrs;1 2 3 ... .';

PROGRAM = `9d.
::G:Rsrs;
1 2 3 GGG... .`;

PROGRAM = `9d.
::F:o.d Rsrs +;
0 1 (F)
.`;

PROGRAM = '9d."abba"t"foo"t .';


PROGRAM = '9d.3 3-d. ?+. ..';

PROGRAM = `
9d."?0 01= "t7?0.\\ 0?0.\\.10e
9d."?1 10= "t7?1.\\ 0?1.\\.10e
9d."> 010= "t3 4?>.\\4 3?>.\\3 3?>.\\.10e
9d."< 100= "t3 4?<.\\4 3?<.\\3 3?<.\\.10e
9d."?= 001= "t3 4?=.\\4 3?=.\\3 3?=.\\.10e
9d.3 3?=('ee)\\.
9d.3 4?=('ee)\\.
9d.3 7?<('le)\\.
9d.3 2?>('ge)\\.
`;

PROGRAM = '9d. : 1.2.3. ; .';
PROGRAM = '9d. ::Q:33;  .';

PROGRAM = '9d.::P:77; ::Q:33P; 5(Q..) .';

PROGRAM = `9d.
::G:Rsrs;
::F:o.dG+;
0 1 100(F)
`;

PROGRAM = "9d.'ae'be'ce 0 100(100(i+)). .";

PROGRAM = "9d.'ae'be'ce 0 255(255(ij+.)).";

PROGRAM = '9d.3 4+..';

PROGRAM = "9d.'ae'be'ce 0 10(255(10(i+i+i+i+)d.)). .";

// TODO: not working right
PROGRAM = '9.9.9.:1.2.3.0]4.;';

// unloop+leave in one!
PROGRAM = 'A9d.3(1.4(2.3.1]4.)5.)6..';
PROGRAM = 'A9d.3(1.4(2.3.2]4.)5.)6..';

// w_
PROGRAM = '9d8dw\\..';
PROGRAM = '1 2..1 2s..';

PROGRAM = '1 2 3 4....1 2 3 4ws....';
PROGRAM = '1 2 4 8....9 9 1 2 4 8w+.. ..';
PROGRAM = '9 9 10 5 8 4w-.. ..';

// BENCH sieve primes // b77
// counter stored at 0 (zp)
// flags stored at [2] (here)
PROGRAM = `
0d! 8192 h 2!da
2@ d 1 cm
10(
  2@(
    2@i+ c@ ?1(
      0mi
      id+ id+3+ 2@(
        0 2@o+c!
      o+d#)\\ \\
    )\\
  )
)
0@.
`;

PROGRAM = '9d. 3 4 + . .';

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
//         Or     STAZ('tmp') LDAA('tmp')
//
//         (BIP+ip) == token stored in X
//         ...except when function parsing
// 
//     X : general index register, free
//         initially it contains 'token'
//
//     A : general register free to use
//

let utilty = require('./utility.js');
let terminal = require('./terminal-6502.js');
let jasm = require('./jasm.js');

let putc = terminal.aputc;
let putd = terminal.aputd;
let puts = terminal.aputs;
let getc = terminal.agetc;

let start = 0x501;





// Turn off BRK, off TOS and on table_next
// speeed: b1944
//         b1759 (+ 144 bytes + 256)
let speed = 0;
//speed = 1; // if enabled, w... not work

let tosopt = !speed;

let trace = 0;
let tracecyc = 0;
let table_next = speed;

// uncomment to see cycle counts!
//tracecyc = 1;



// TODO: if not this, hang!
//process.exit(0);

// TODO: not this easy, haha
function tos() {
  if (tosopt) {
  } else {
    PLA();
  }
}
function endtos() {
  if (tosopt) {
  } else {
    PHA();
  }
}


// using BRK is slower, but saves bytes
// 95 bytes for 40 functions!
let brk= !speed; // save space!
function next() {
  if (brk) {
    // use only 1 saves 2 bytes!
    // (little slower)
    BRK();
  } else {
    JMPA('NEXT'); // 3 bytes :-(
  }
}

function ctrl(c) {
  return ord(c.toUpperCase())-64;
}

function meta(c) {
  return 0x80 + ord(c[1].toUpperCase());
}
  
function parseKey(c) {
  // parse cmd chars
  if (typeof c === 'string') {
    if (c.length === 1) {
      return ord(c);
    } else if (c[0] === '^') {
      return ctrl(c[1]);
    } else if (c[0] === '_') {
      return meta(c1[1]);
    }
  }

  return c;
}

if (1) {
  // def('d');     .....; // def add next
  // def('d', ''); (jmp); // no next
  // def('x', 'NEXT');    // rel jmp

  let last, last_ret;
  let tab = [];

  function def(a, optJmp, cmp=CPXN, ret=next, sub) {
    let aa = parseKey(a);
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

      if (!sub && aa >= 31)
        tab[aa] = optJmp;
    } else {
      
      BNE(tryother);
      last= tryother;
      // the words def comes after
      // ... till the next def!
      L(match);

      if (!sub && aa >= 31)
        tab[aa] = match;
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

  function gentab() {
    // align on page boundary
    while(jasm.address()%256) data(0);

   L('DISPATCH');
    for(let i=0; i<0x80; i++) {
      let a = tab[i] || 'NEXT';
      word(a);
      print('  [0x'+hex(2,i)+'] = ',
            tab[i] ? tab[i] : '-');
      if (i%32==31) print();
    }
  }


} else {
// table driven DEF

  let tab = [], skip;

  function def(a, optJmp, cmp=CPXN, ret=next, sub) {
    let aa = parseKey(a);
    let lab = gensym('OP_'+a+'_$'+hex(2,aa));
    console.error("TAB.DEF", lab, optJmp);

    def.count++;

    // if ever arrive here, skip over table
    if (!skip) {
      skip = gensym('tab');
      JMPA(skip);
    }

    // label code (that comes after this call)
   L(lab);

    // store jump label
    if (tab[aa]) {
      //throw `%% DEF: '${a} already set`;
      console.error(ansi.red, `%% DEF: '${a} already set`, ansi.off);
    }

    tab[aa] = lab;
  }

  function enddef() {
    print("TABLE----------------");
    if (0) {
      Object.keys(tab).sort((a,b)=>a-b).forEach(aa=>{
        print('  TAB:', hex(2,aa), tab[aa]);
      });
    } else {
      for(let i=0; i<0x80; i++) {
        print('  [0x'+hex(2,i)+'] = ',
              tab[i] ? tab[i] : '-');
        if (i%32==31) print();
      }
    }

   L(skip);
    skip = undefined;
//    tab = [];
  }

}

// compare if A has command if so invoke
// optionally, call jmp instead
// (similar ot def)
function cmd(c, optJmp) {
  def(c, optJmp, CMPN, RTS);
}

function endcmd(foo) {
  // because we have stuff on stack?
  if (foo) throw `"%% endcmd can't JMP to '${foo}'`;
  
  enddef();
}

// used to define a sub-command
function sub(c, optJmp) {
  def(c[1], optJmp, undefined, undefined, c[0]);
}

function endsub(foo) {
  // because we have stuff on stack?
  if (foo) throw `"%% endcmd can't JMP to '${foo}'`;
  
  enddef();
}





////////////////////////////////////////
//  F8rth generation

var syms_defs, alfa_defs;

function F8rth() {

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
const SYSTEM= 0x0200;

// For now user page/memory is stack!
// TODO: zp would save code bytes,
// but probably want to use indirection ptr
// DON'T use this  var, it'll be come indirect
// USE 'U'.
//const      _U= S;
const      _U= 0x0400; // not ZP! (no clash)

ORG(S);
L('S'); // alias to S

ORG(_U);
L('U'); // U = user space (1 page)
  L('PASCAL_PROGRAM_Z'); pascalz(PROGRAM); // LOL

////////////////////////////////////////
// 0x100-- stacks

//   bottom of data stack
ORG(SYSTEM-1-RS_SIZE-DS_SIZE); L('top');

//   Data Stack (Params)
ORG(SYSTEM-1-RS_SIZE);         L('stack');

//   Return Stack
//   TODO: ? move to ZP? cheaper addressing!
ORG(SYSTEM-1);                 L('rstack');



////////////////////////////////////////
// ZERO PAGE

// 0x00--0x0f use for any

ORG(0xc0);
  // stacks
  L('rp');        byte(0);
//  L('sp');        byte(0); // TSX() ?

  L('base');      word(0); // base + Y == "IP"

  L('upbase');    word(0); // TODO: use!

  // parsing
  L('end_pos');   byte(0);
  L('num_pos');   byte(0);

  // tmps (or 0?)
  L('tmp');       byte(0); // tmp?
  L('tmp2');      byte(0); // tmp?

  // these may be local page related?
  // "state" (or rather mode)  test with BITA!
  //   0d-- ---- : run ("interpreting") // BPL
  //   1d-- ---- : editing              // BMI
  //   -d-- ---- : display char/echo    // BVS
  const state_edit = 0x80;
  const state_display = 0x40;
  const state_run = 0;
  L('state');     byte(0);

if (jasm.address() >= 0xe0)
  throw "%% ZP vars needs start earlier!";

// Temprary in zp
ORG(0xe0); L('UDF_offsets'); allot(32);




////////////////////////////////////////
// Code start
ORG(start);

L('FORTH');
  // init stack pointers
  LDXN('stack', lo),TXS();

  if (brk) {
    // modify BRK as short cut for JMPA('next'); (save 2 bytes/call)
    LDAN('BRK_NEXT', lo),STAA(cpu.consts().IRQ);
    LDAN('BRK_NEXT', hi),STAA(cpu.consts().IRQ, inc);
  }

  // TODO: needed?
//  LDAN('FORTH', lo),STAA(cpu.consts().RESET);
//  LDAN('FORTH', hi),STAA(cpu.consts().RESET, inc);

L('quit');
  // clear return stack
  LDXN('rstack', lo),STXZ('rp');

  // init = 0xff
  LDAN(0xff),STAZ('num_pos');

  // init = 00
  TAY(),INY(); // "ip" = 0
  TYA(),STAZ('state');

  // init state of interpreter
  LDAN('U', lo),STAZ('base');
  LDAN('U', hi),STAZ('base', inc);

  //LDAN(state_display); STAZ('state');
  next();
L('FORTH_INIT_END');


L('edit2');
  // TODO:needed?
  LDXN(state_edit+state_display),STAZ('state');
  JMPA('edit');

  //  9.6 cycles / enter-exit saved w noECHO
  // 55.6 cycles / enter-exit saved w ECHO
if (0) {
L('EXIT'); // c52

  // not valid anymore
  LDAN(0xff),STAZ('num_pos');;

  PLA(); // because we PHA() before read :-(

  //    TRACE(()=>print("\n<====EXIT"));
  LDXZ('rp'); {
    // empty? enter EDIT!
    CPXN('rstack',lo),BEQ('edit2');

    // load saved "ip" from "rp" stack
    LDYAX(S+1),STYZ('base'),INX(); // lo
    //TRACE(()=>princ(' (y='+hex(2,cpu.reg('y'))+') '));
    LDYAX(S+1),STYZ('base', inc),INX(); // hi
    //TRACE(()=>princ(' (y='+hex(2,cpu.reg('y'))+') '));
    LDYAX(S+1),INX(); // "ip"
    //TRACE(()=>princ(' (y='+hex(2,cpu.reg('y'))+') '));
  } STXZ('rp');
  //TRACE(()=>print());
  JMPA('NEXT'); // save 3 cycles
  L('EXIT_END');
}

  // TODO: what is this?
  DEY(),LDXN(state_edit+state_display),STAZ('state');

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




// If enabled (why not always?) allow for:
// 
//   BRK();          // 1 byte "next" // i1 c17
//   JMPA('NEXT');   // 3 byte "next" // i3 c6
//
// - saves 2 bytes per next! (40 words -> 96!)
// - 16 cycles instead of 3 cycles.
//
L('BRK_NEXT');
  if (brk) { // overhead i-2, b5 c10 + 7 for BRK
    TSX(),INX(),INX(),INX(),TXS();
  }

  let savcyc = 0;

  // TODO: make 'NEXT' more efficient.
  // Current overheads in priority:
  // 1. def() uses CMP,BNE - OH// b4 c5 * #ops/2
  //    use lookup - SAVE// b 3*#ops c5*#ops/2
  // 2. A is used for TOS - OH// b2 c7
  //    no use A TOS (lots code) - SAVE// b2 c7
  // 3. BRK costly instead of RTS OH// b1 c14
  //    a. switch to RS before RTS ==// b4 c10
  //    b. don't use stack for data ===// b1 c6
  //       (that's a lot of re-write
  //        basically a normal ALF)

  // Solutions:
  // 0. jump tables!
  // 1. not use A for TOS (what's the loss?)
  // 2. not use BRK for RTS and use real stack

L('NEXT');
  TRACE(()=>{
    if (!tracecyc) return;
    let c = cpu.state().cycles;
    princ('\t(cyc:'+(c-savcyc)+')\n');
    savcyc= c;
  });

  if (table_next) { // b16 c29
    PHA(); {
      INY(),LDAIY('base');
//      BEQ('EXIT'); // c2+1 // TODO: remove?
      TAX();
      ASL();
      STAA('jmp', a=>a+1);
    } PLA();
   L('jmp');
    // JMPI not working?
    JMPI('DISPATCH');
  } else {

    INY();
    // wrapped around?
    //BEQ('edit2');

    PHA(); { // b5 c14
      LDAIY('base'); // c5+
//      BEQ('EXIT'); // c2+1
      TAX(); // c2
    } PLA();

    BITZ('state');
    BVC('nodisplay'); {
      PHA(),TXA(); { // save TOS
        JSRA('display');
      } PLA();

      BITZ('state');
      // loop if in editing: (re)display all!
      BMI('NEXT'); 
    } L('nodisplay');

    // TODO: replace state with JMP edit!
    BPL('_not_edit');
    JMPA('edit_next');
    L('_not_edit');

  } // not table

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

  // symbols "out of place"

  def('\\'); PLA();
  def('R'); L('>R'),R_PHA(),PLA(); // b10 + 7

  // TODO: ] - exit
  def(']'); { // b37 (was 44!)
    // drop n items from rstack
    TAX(),BEQ('_].end'); // 0 == NOP

   L('_].skip.next');
    INY();
   L('_].skip');
    LDAIY('base');
    // ';' - TODO: EXIT (to local sub?)
    // TODO: not working now remove?
    CMPN(ord(';')),BNE('_;_nomid');
      // local fun 'exit'
      JMPA('_;_mid');
    L('_;_nomid');

    // skip inline backtick value (could be any)
    // TODO: remove?
    CMPN(ord('`')),BNE('_not_backtick');
      INY();
    L('_not_backtick');

    CMPN(ord('(')),BNE('_not(');
      DECZ('rp'); // "rpush"
      DECZ('rp'); // "rpush"
      INX();
    L('_not(');

    CMPN(ord(')')),BNE('_].skip.next');
      INCZ('rp'); // "rdrop"
      INCZ('rp'); // "rdrop"
      DEX();
    BNE('_].skip.next');

    // last matching ')'
   L('_].end');
    PLA(); // set TOS
  }

  // -- printers and formatters
  def(10); // do not interpret NL as number! lol
  def('`', ''); JMPA('printval');
  def(0, 'edit2');

  L('INTERPRET_END');





  ////////////////////////////////////////
  // Symbol based operators
  // 
  // TODO:
  //
  //     $abba (hex) (and more)
  //     #decimal (and math)
  //
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
    PLA(),STAZ(0);

   L('_*');
    DEX();
    BEQ('NEXT');
    CLC();
    ADCZ(0);
    JMPA('_*');
  }

  def('*'); { // b21 avg c73 c26-172
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

  def('+'); TSX(),CLC(),ADCAX(S+1),  INX(),TXS();
  def('-'); TSX(),CLC(),SBCAX(S+1),EORN(0xff),INX(),TXS();
  def('&'); TSX(),      ANDAX(S+1),  INX(),TXS();
  // actually not symbol (32-64)
  def('|'); TSX(),      ORAAX(S+1),  INX(),TXS();
  def('^'); TSX(),      EORAX(S+1),  INX(),TXS();
  def('~'); EORN(0xff);

  def('.'); STYZ('tmp'),LDYN(0),JSRA(putd),LDYZ('tmp'),PLA();

  def('<'); CLC(),ROL(); // TODO: ASL(); save 1B
  def('>'); CLC(),ROR(); // TODO: LSR()

  // TODO:
  //   # $ % , ?
  
  def('"'); {
    PHA(),
    INY(),LDAA('base',inc),PHA(),TYA(),PHA(),
    LDXN(0),LDAN(ord('"'));
    L('_"'),CMPIY('base'),BEQ('_".done'); {
      INY(),INX();
    } BNE('_"');
    L('_".done'),TXA();
  }
  def(' '); // do not interpret as number! lol
  def('?'); JMPA('QUESTION');
  def("'"); PHA(),INY(),LDAIY('base');

  def('@'); TAX(),LDAAX('U'); // cool!
  def('!'); TAX(),PLA(),STAAX('U'),PLA();

  def('='); { // Unsigned <=>  ==> -1, 0, 1
    TSX(),CMPAX(S, inc);
    { // b9  c5 | c9 | c10
      // Daneiele Versotto NICE!

      SEC();
      SBCAX(S, inc); // nc
      BEQ('__next');
      LDAN(1);
      BCC('__next');
      LDAN(0xff);
    L('__next');
    }
    // all variants cleanup
    TSX(),DEX(),TXS(); // pop

    next();
  }

  def('('); { // ( 
    LDXN(1); // means skip one ')'
    CMPN(0),BNE('_('); {
      // TODO: make it near to ']' ???
      JMPA('_].skip.next');
    } L('_(');
    // init (R: -- "ip" "counter")
    STAZ(0);

   L('do');
    LDXZ('rp'); {
      TYA(),DEX(),STAAX(S+1);
      LDAZ(0),DEX(),STAAX(S+1);
    } STXZ('rp');

    PLA();
  }
  def(')'); {
    LDXZ('rp');
    DECAX(S+1); // get count to TOS
    BNE(')_repeat');
    // end loop - ready to unroll and leave!
    INX(),INX(),STXZ('rp'); // b5 c7
    next();
    // restore "ip" to beginning of loop
  L(')_repeat');
    LDYAX(S+2);
  }

  // COLON (not ENTER) and ; (EXIT)
  def(':'); {
    PHA(); {
      INY(),LDAIY('base'),DEY(); // peek
      // if not ':' then we're running word
      CMPN(ord(':')),BNE('_:end');

      // DEFINE local word!
      INY(); // lol
      INY(),LDAIY('base'); // get name
      CLC(),SBCN(ord('A')),TAX();
      // TRACE(()=>print("\n---define.x: ",hex(2,cpu.reg('x'))));
      // TODO: boundary checks...
      // Store next ':' Y "ip" as start of function!
      INY();
      // TODO: where to store? local linked?
      // for now these are "local" functions!
      // TRACE(()=>print("\n---define.offset: ",hex(2,cpu.reg('y'))));
      STYZX('UDF_offsets');

      // skip to ;
     L('_:'),INY(),LDAIY('base');
      CMPN(ord(';')),BNE('_:');
    } L('_:end'),PLA();
  }

  def(';'); {
    INCZ('rp');
   L('_;_mid');
    LDXZ('rp'); { // b7 c12
      LDYAX(S+1);
    } INCZ('rp'); // 1b less than INX,STX
  }

  L('SYMS_END'); syms_defs = def.count - syms_defs;


  ////////////////////////////////////////
  // ALFA / letter commands
  // TODO:
  //   
  //   fill move
  //   [ ] "immediate mode" (execute while copy)
  //   { } - nested strings / lambdas
  //   _longname
  //
  // TOOO: rename r R
  // TOOO (secondary ops):
  //
  //   a c r w
  //
  //  (No def: b f g l m u v z)
  //
  L('ALFA_BEGIN'); alfa_defs = def.count;

  def('d'); PHA();
  def('o'); PHA(),TSX(),LDAAX(S+2);
  def('s'); STAZ('tmp'),PLA(),TAX(),LDAZ('tmp'),PHA(),TXA(); // b10 c19

  def('p'); PHA(),TSX(),TXA(),ADCAX(S+1),TAX(),PLA(),LDAAX(S+1);
  def('i'); PHA(),LDXZ('rp'),LDAAX(S+1),SEC(),SBCN(1);
  def('j'); PHA(),LDXZ('rp'),LDAAX(S+3),SEC(),SBCN(1);

  def('r'); L('R>'),PHA(),R_PLA(); // b10 + 7

  def('t'); TAX(),STYZ(0); {
    PLA(),STAZ(1),PLA(),TAY(),LDAZ(1),
    // TODO: change it to puts_AY_X
    // now it's puts_YA_X (save some juggle)
    JSRA(puts);
  } LDYZ(0),PLA();

  def('q', ''); JMPA('quit');
  //def('y'); PHA(),TYA();

  def('n'); CLC(),SBCN(0),EORN(255);
  def('k'); PHA(),L('_K'),JSRA(getc),BEQ('_K');
  def('e'); JSRA(putc),PLA();

  // 0=
  def('z'); TSX(),CMPN(0),CMPAX(S);

  enddef();

L('ALFA_END'); alfa_defs = def.count - alfa_defs;
  // fallthrough




  ////////////////////////////////////////
  // more special test, or fallbacks





L('NUMBER_BEGIN');
 if (table_next) {
   for(i=0; i<10; i++)
     def(chr(ord('0')+i), 'number?');
   enddef();
 }

 L('number?')
  //TRACE(()=>princ('<number?>'));

  PHA(); // save current

  // extract number from digit
  TXA(),SEC(),SBCN(ord('0'));
  CMPN(10),BCC('have_num'); {
    PLA(); // restore
    JMPA('not_number');
  } L('have_num');
  
  STAZ(1);

  DEY(),CPYZ('num_pos'),BEQ('_num.cont'); {
    // It's a new number
    //TRACE(()=>princ('<LDAN0>'));
    LDAN(0);
  } SKIP1(),L('_num.cont'); {
    //TRACE(()=>princ('<PLA>'));
    PLA();
  }
  INY();

  STYZ('num_pos');

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
  // TODO: make it more general

  // for now just lookup and ENTER word
  // "same page"
  // local 'ENTER'
 L('enter');
  PHA(); {
    // load Y of A
    // TODO: just adjust offset of UDF...
    TXA(),CLC(),SBCN(ord('A')),TAX();
    // TRACE(()=>print("\n---enter.x: ",hex(2,cpu.reg('x'))));
    LDAZX('UDF_offsets');
    // TRACE(()=>print("\n---enter.offset: ",hex(2,cpu.reg('a'))));
    PHA(); {
      // save Y
      LDXZ('rp'); {
        // TRACE(()=>print("\n---enter.save: ",hex(2,cpu.reg('y'))));
        TYA(),DEX(),STAAX(S+1);
        // ';' loads one drops one ?
        // DEX(),STAAX(S+1);
        // not valid anymore
        LDAN(0xff),STAZ('num_pos');;
      } STXZ('rp');
    } PLA();
    // set "ip" of local function
    TAY();
    //  TRACE(()=>print("\n---enter: ",hex(2,cpu.reg('y'))));
  } PLA();
  
  next();

L('FIND_END');

if (0) {

// TODO: only used by JSR('ENTER'); for inline...
L('ENTER'); // b37 c61
  // since R stack is different than callstack
  // (and we're arriving on data stack!)
  // this will be simple!
  // save address from stack
  //  TRACE(()=>print('\n====>ENTER'));
  STAZ(0); { // save TOS
    // not valid anymore
    LDAN(0xff),STAZ('num_pos');;

    // push "ip"Y, "IP"base on "rp" stack
    LDXZ('rp'); {
      // TODO: if rp-stack moves to ZP STYZX
      DEX(),TYA(),STAAX(S+1); // "ip"
      //TRACE(()=>princ(' (y='+hex(2,cpu.reg('y'))+') '));
      DEX(),LDAZ('base',inc),STAAX(S+1); // hi
      //TRACE(()=>princ(' (a='+hex(2,cpu.reg('a'))+') '));
      DEX(),LDAZ('base'),STAAX(S+1); // lo
      //TRACE(()=>princ(' (a='+hex(2,cpu.reg('a'))+') '));
    } STXZ('rp');
    // get address from source RTS
    PLA(),STAZ('base'); // lo
    PLA(),STAZ('base', inc); // hi
    LDYN(0); // 'NEXT' will skip over "current"
  } LDAZ(0); // restore TOS
  JMPA('NEXT'); // save some cycles
L('ENTER_END');
}

L('QUESTION');
  // get next // b7 c17
  PHA(); {
    INY(),LDAIY('base'),TAX();
  } PLA();

  // TODO: 256 --- remove most? keep one?
  // ? 0->0 n=>1
  // TODO: refactor PHA,CMPN(0) PHP, PLP ???
  // most of these is just test, no next // b4
  //    // b28 can be done in 14
  sub('?0', ''); PHA(),CMPN(0),JMPA('?0');
  sub('?-', ''); PHA(),CMPN(0),BMI('=>1'),BPL('=>0');
  sub('?+', ''); PHA(),CMPN(0),BEQ('=>0'),BPL('=>1'),BMI('=>0');
  sub('?1'); PHA(),CMPN(1),LDAN(0),ADCN(0); // b7
  sub('?>', ''); TSX(),CMPAX(S+1),LDAN(0),ADCN(0),JMPA('?0');
  sub('?<', ''); TSX(),CMPAX(S+1),BCC('=>0'),BEQ('=>0'),BCS('=>1');
  sub('?='); TSX(),SBCAX(S+1),L('?0'),BEQ('=>1'),L('=>0'),LDAN(0),BRK(),L('=>1'),LDAN(1);
  endsub();

  next();
L('QUESTION_END');



L('TABLESPACE');
  if (table_next) {
    gentab();
  }
L('TABLESPACE_END');




L('FORTH_END');







//   (to much growth: implement as word?)
////////////////////////////////////////
// Extras (not core)

L('XTRAS_BEGIN');

L('printval');
  PHA(); {
    // TODO: make section for commands where A Y is saved

    // next byte
    PHA(); {
      INY(),LDAIY('base');
      TAX();
    } PLA();

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
// EDITOR

L('EDIT_BEGIN');




L('OP_Run');
  TRACE(()=>{
    princ(ansi.hide());
    princ(ansi.cls());
  });

  PHA(); {
    LDAN(ord('\n')),JSRA(putc),JSRA(putc);
  } PLA();
  LDYN(0xff);
  
  // Reinterpret buffer from scratch
  // stack is lost etc, only memory remain!
  TRACE(()=>princ(ansi.hide()));
  JMPA('FORTH');




L('OP_List');
  //TRACE(()=>princ(ansi.cursorSave()));
  TRACE(()=>princ(ansi.cls()+ansi.home()+ansi.hide()));
  TYA(),PHA(); {
    LDAN(ord('\n')),JSRA(putc),JSRA(putc);
    LDXN(0xff);
    LDAZ('base'),CLC(),ADCN(1);
    LDYZ('base', inc),BCC('_List'),INY(),L('_List');
    JSRA(puts);

    TRACE(()=>{
      return;
      print("\n\n");
      let a = cpu.w(jasm.getLabels().base);
      for(let i=1;i<256;i++) {
        princ(chr(m[a+i]));
      }
    });

  } PLA(), TAY();
  //TRACE(()=>princ(ansi.cursorRestore()+ansi.show()));
  TRACE(()=>princ(ansi.show()));
  JMPA('edit_next');
  // TODO: FALLTHROUGH!


L('OP_BackSpace');
  // nothing to delete?
  CPYN(1),BMI('edit_next');
  //CPYN(2),BMI('edit');

  // delete on screen (BS+SPC+BS) // b12
  // (TODO: optimize with a putsi)
  LDAN(8),JSRA(putc);
  LDAN(32),JSRA(putc);
  LDAN(8),JSRA(putc);
  
  DECZ('end_pos');
  
  // move everything down
 L('_OP_BS');
  // copy current
  LDAIY('base');
  //TRACE(()=>princ(' @'+hex(2,cpu.reg('y'))+'='+chr(cpu.reg('a'))));
  // overwrite last
  DEY(),STAIY('base'),INY();
  INY();

  RTS();


// We're not forthing, so we can use the rstack!
// (what if we want to do editing in forth?)
L('edit');
  // TODO: last pos executed is length?
  STYZ('end_pos');

  TRACE(()=>princ(ansi.show()));

  PHA(); // save TOS!

  // this so can use RTS for 'edit_next'!
 L('_edit');
  JSRA('edit_next');
  // TODO: maybe not needed?
  BITZ('state'),BMI('_edit')
  // if no longer editing
  PLA(); // restore TOS
  next();

L('edit_redisplay');
  PHA(),JSRA('OP_List'),PLA();
  JMPA('_edit.gotkey');

L('edit_next');
  // save cursor position
  //STYZ('edit_pos');

  TRACE(()=>{
    princ(cursorSave());
    princ(gotorc(1, 1));
    princ('(EDIT) ');
    princ(cpu.reg('y')+' / ');
    princ(m[jasm.getLabels().end_pos]+'   ');
    princ(cursorRestore());
  });

 L('edit_next_waitkey');
  NOP(); // TODO: remove; it's just for label

 L('_edit.waitkey'),
  JSRA(getc),
  BEQ('_edit.waitkey');
  // jump here to simulate keystroke
 L('_edit.gotkey');

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

  cmd('^R', 'OP_Run');
  cmd('^L', 'OP_List');
  //cmd('^T', 'OP_Trace');
  //cmd('^J', 'OP_RunLine');

  cmd(0x7f, 'OP_BackSpace');
  cmd('^H', 'OP_BackSpace');
  endcmd();

L('insert');
  // non-printable
  CMPN(31),BCC('edit_next'); // ctrl-
  CMPN(128),BCS('edit_next'); // meta-

  // to insert we need to shift all
  // after one forward
  JSRA(putc);

  INCZ('end_pos'); // add one to count
  STAIY('base');
  INY();

  RTS();

  // TODO: can we be in vt100 insert char mode?

  // Display have two functions:
  // 1. display a trace of command character
  // 2. display an edit buffer character
  // 3. update line_pos, eol_pos, end_pos
  //    to make the editor code simple.
 L('display');
  // TODO: don't cheat!
  TRACE(()=>princ(lime));

 L('display_pos');
  NOP();
  TRACE(()=>princ(ansi.cursorSave()));
  if(0) TRACE(()=>print("<<<HERE"+JSON.stringify({
    A: cpu.reg('a'),
    Y: cpu.reg('y'),
  })));
  NOP();

  L('_display.nopos');

  // need CR NL
  CMPN(10),BNE('_display.notnl'); {
    TRACE(()=>princ(ansi.cleol()));
    PHA(),LDAN(13),JSRA(putc),PLA();
  } L('_display.notnl');

  // actually print char!
  JSRA(putc);

  // end? - turn off display
  CMPN(0),BPL('_display.noend'); {
    LDAN(state_edit); // stay edit/run
    ANDZ('state');
    STAZ('state');
    STYZ('end_pos');
  } L('_display.noend');

  // TODO: don't cheat!
  TRACE(()=>princ(fg(WHITE)));

  RTS();
  // Do NOT put any more code here!
  // (to keep display bytes correct)
L('EDIT_END');

L('resultColor'); string(amber);
L('colorOff'); string(off());
L('hide'); string(ansi.hide());
L('show'); string(ansi.show());

}  // F8rth




////////////////////////////////////////
// Generic Library

// TODO: 3 pushes in BEGIN END is cheaper
function R_BEGIN() { // b9 zp:b8
  TSX(),STXZ('sp'),LDXZ('rp'),TXS();
}

function R_END() { // b9 zp:b8
  TSX(),STXZ('rp'),LDXZ('sp'),TXS();
}

// use these twice and you might as well...

// TODO: move to zero page ( will be b6)

function R_PHA() { // b7 zp:b6
  LDXZ('rp'),STAAX('S'),DECZ('rp'); // push
}
// no reason can't do PLY ...
function R_PLA() { // b7 zp:b6
  LDXZ('rp'),INCZ('rp'),LDAAX('S', inc); // drop
}
// three or more R_DROP can do better
function R_DROP() { // b3 c4
  INCZ('rp'); 
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

F8rth();

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
prsize("FORTH :", l.FORTH_END-l.FORTH);
prsize(" INIT :", l.FORTH_INIT_END-l.FORTH);
prsize(" ENTR :", l.ENTER_END-l.ENTER);
prsize(" EXIT :", l.EXIT_END-l.EXIT);
prsize(" NEXT :", l.NEXT_END-l.NEXT);
prsize(" inter:", l.INTERPRET_END-l.INTERPRET_BEGIN);
prsize(" SYMS :", l.SYMS_END-l.SYMS_BEGIN);
prsize("  ( # :", syms_defs, '/ 22)');
prsize(" ALFA :", l.ALFA_END-l.ALFA_BEGIN);
prsize("  ( # :", alfa_defs, '/ 30)');
prsize(" QUEST:", l.QUESTION_END-l.QUESTION);
prsize(" NUMS :", l.NUMBER_END-l.NUMBER_BEGIN);
prsize(" FIND :", l.FIND_END-l.FIND_BEGIN);
print();
prsize(" ALIGN:", l.DISPATCH-l.TABLESPACE);
prsize(" TABLE:", l.TABLESPACE_END-l.DISPATCH);
print();
print();
prsize("XTRA  :", l.XTRAS_END-l.XTRAS_BEGIN);
prsize("EDIT_ :", l.EDIT_END-l.EDIT_BEGIN);
prsize(" displ:", l.EDIT_END-l.display);
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


cpu.setTraceLevel(2);
cpu.setTraceLevel(1);
cpu.setTraceLevel(0);

cpu.setOutput(1);
cpu.setOutput(0);

trace = 1;
trace = 0;


cpu.reg('pc', start);
cpu.run(-1);
// = 0x08 ^H backspace (0x1f)
// = 0x0d ^M return
// < 0x33 "space"
// d      dup
// \      drop
// +      minus
// n      nand
// m      -1
// $      2 digit hex
// r      r>
// p      r<
// }      rshift
// (      y>r
// )      y<r
// ]      seek nth ]
// !      store
// @      fetch
// e      emit
// k      key
// t      type
