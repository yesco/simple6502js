//      ALfabetic Forth
// 
// 2021 (>) Jonas S Karlsson
//       jsk@yesco.org
//
let cpu6502 = require('./fil.js');
let jasm = require('./jasm.js');
let aputc = 0xfff0;
let aputd = 0xfff2;
let aputs = 0xfff4;

// TODO: testing!
// use https://github.com/scotws/TaliForth2/blob/master/tests/core_a.fs ...

//let output = 1; // show 'OUTPUT: xyz'
let output = 0; // show 'OUTPUT: xyz'
let traceLevel = 0; // 1=labels, 2=instr.
let showStack = 0;
tabcod.trace = 0;
let showMem = 0;

// ALF - ALphabet  F O R T H

let start = 0x501; // TODO: get from label?

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

  ////// ========= input buffer ========= ///////
  // ORIC 79 bytes input buffer

ORG(0x35); L('INPUT_BUF'); allotTo(0x84);

// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


ORG(0x35); /* INPUT_BUF */ string(













'1234(.)9'













);

//'123456789(d..1+)"end"$99');


//'1230D.1D.?."//"$1D.1D.?."//"$2D.1D.?.456');


//'5671<2.3<4.2<1.4<3.567');
//'6543210##');

//'65432103P......');

// TODO: --- ROLL BUG 9!
//'"ROLL"P2222222226171915RL.............'); // 6 breaks in this case? where the hell the values went?
//'"ROLL"$333365432106RL.............'); // 8 works fine.... ? WTF?
//'"ROLL"$333398765432109RL.............'); - 8 works fine.... ? WTF?
//'"ROLL"$333398765432109RL.............'); - doesn't work 

// --- TODO: fill not working correctly
//'81D+D+D+D+D+D+D+D+D.4Z');
//'1D+D+D+D+D+D+D+D+D+D+D+D+D+D.1D+D+D+D+D+D+D+D+D2+.4Z'); // 512+2
//'1D+D+D+D+D+D+D+D+D+D+D+D+D+D.1D+D+D+D+D+D+D+D+2+.4Z'); // 256+ 2
//'1D+D+D+D+D+D+D+D+D+D+D+D+D+D.2D.4Z'); // 2


/////////////////////////////////////////////



  // ALForth
ORG(0x85);
  // Need save this for subroutine call?
  L('QUIT_STACK');  byte(0);
  L('NEXT_BASE');   word('INPUT_BUF');
  L('NEXT_Y');      byte(0);

  L('STATE');       data(0);
  // - FREE

  ORG(0xbf); L('DSTACK');    allotTo(0xfe); // 32*2
  ORG(0xff); L('DPTR');      byte(0xff);

  // - FREE

// program code

ORG(start); L('reset');
  // make sure
  CLD();
  // init stack
  LDXN(0xff); TXS();
  // TODO: setup vectors

  JMPA('ALF_init');
  //JSR('end');

//  LDAN('mys', lo); STAZ('NEXT_BASE');
//  LDAN('mys', hi); STAZ('NEXT_BASE',(a)=>a+1);
//  JSRA('ALF_init');

//  LDAN('foo', lo); STAZ('NEXT_BASE');
//  LDAN('foo', hi); STAZ('NEXT_BASE',(a)=>a+1);
//  JSRA('ALF_init');

  JMPA('end');

L('mys'); string('"DOUBLING:"$1D+D.D+D.D+D.D+D.D+D.#.#.');
//L('mys'); string('43DDDDDD321.....');
//L('mys'); string('123DD#.#.');

//L('mys'); string('4123...D.#.'); //endless loop

L('foo'); string('"FOO:"$1234D...');

  JMPA('end');

//////////////////////////////
 L('ALF_init');
  // save stack for QUIT
  TSX(); STXZ('QUIT_STACK');

  JMPA('ALF');

 L('ALF_reset');
  // restore stack
  LDX('QUIT_STACK'); TXS();

  // init data stack
  LDXN(0xff);

  // reset input to command line
  LDAN('INPUT_BUF', lo); STAZ('NEXT_BASE');
  LDAN('INPUT_BUF', hi); STAZ('NEXT_BASE', (a)=>a+1);
  LDYN(0);

  // make sure it's empty!
  LDAN(0); STAIY('NEXT_BASE');

  // Possibly Return to caller?

 L('ALF');
 L('interpret');
  // init index
  LDYN(0);
  // TODO: read-eval loop!
  JSRA('MAIN');

  // TODO: restore from BASE,Y fromstack?
  RTS();
  //JMPA('end');

 L('fail'); // error in A

  puts("%% FAIL ( ");

  save('y', ()=>{
    LDYN(0);
    JSRA(aputd);
  });

  puts(")\n");

  RTS();

 L('MAIN_zero');
  RTS();

 L('drop3_next'); // maybe used only once?
  drop();

 L('drop2_next');
  drop();

 L('drop_next');
  drop();

  // This is a Alphabet Forth ("byte coded")
  // maxlen of interpreted routine = 255!
  // (b c34   FIG: c39
  //
  // jsk:
  //   STXZ(tmp_x);
  //
  //   INY();
  //   LDAIY(PROG);
  //   TAX();
  //
  //   LDAX(LO_jmptabadj);
  //   STAZ(opad);
  //   LDAX(HI_jmptabadj);
  //   STAZ(opad+1);
  //
  //   LDXZ(tmp_x);
  //   JMPI(opad);
  //
  // FB post with Garth Wilson:
  // - https://m.facebook.com/groups/6502CPU/permalink/2949669985302588/
  //
  // I'm not actually sure, the FIG forth
  // 65 is updating the IP with CLC,ADC
  // for every instruction. And for some
  // reason using a JMP to a JMP in
  // zeropage instead of JMPI (indirect).
  // 
  // It comes out at 39 cycles in most
  // cases (minimal), see picture.
  // 
  // Mine (untested):
  // --(see above)--
  // which seems to come out to 38 cycles,
  //                (      NOW: 34   )
  // I think?
  //
  // That one cycle they could also saved
  // by using JMPI instead of JMP to JMP.
  //
  // In my case I limit a ALF (ALphabet
  // Forth) subroutine to 255 chars since
  // I'm using Y.
  //
  // I'll have slightly more overhead
  // when calling a non-primitive word
  // as that recurses on the interpreter
  // having to save and then restore the
  // IP and Y.
  //
  // But yes, I'll have other
  // inefficiencies as I'll not/and
  // needn't be compiling!
  // 
  // Loops are changed to the tokens
  // '(' and ')', ']' is unloop/leave
  // (and exit). '?(' is 'if'. Since I
  // use Y as "subroutine local IP", a
  // JMP is setting Y.
  //
  // ']' unloop/leave needs to skip till
  // matching ')' so that's overhead
  // (but I deem as acceptable).
  // 
  // The intention is to be simple and
  // "embedded" with inline
  // "half-readable" op-codes.
  //
  // I never saw how SWEET16 was supposed
  // to interact with the normal 6502
  // code. It seemed to separate.
  //

 L('next');
  TRACE(()=>{
    if (showStack) {
      print(); print();
      printstack();
    }
  });

  INY();

  let drop_next= ()=>JMPA('drop_next');
  let drop2_next= ()=>JMPA('drop2_next');
  let drop3_next= ()=>JMPA('drop3_next');
  let pushA_next= ()=>JMPA('pushA_next');
  let putSA_drop_next= ()=>JMPA('putSA_drop_next');
  let putSA_next= ()=>JMPA('putSA_next');
  let pushSA_next= ()=>JMPA('pushSA_next');
  let number= ()=>JMPA('number');

  tabcod('MAIN', {

    // 42 ALForth functions defined!
    // (core forth has about 133 words)
    // (core extension has 50 words)
    //
    // 42 instructions == 1105 bytes!
    //
    // TODO:
    // - $K key or ck?
    // - cw - word skip space, read next word "store" it ( == addr len ) NOT z-terminated
    // - cf find word  WROD DOUBLE FIND >CFA
    // - ca Code Address ?
    // - create ct ?
    // - ':'
    // - ';'
    // - ','  !!!! first!
    // - Quit is "reset" ? loops Interpret
    
    Quit (){
      JMPA('ALF_reset');
    },

    Pick (){
      STXZ('tmp_x'); {
        INCZX(0);
        TXA();
        CLC();
        ADCZX(0);
        ADCZX(0);  // A = X+2*Y == destination addr
        TAX();
      
        // - X now is destination address
        // store wanted value
        LDAZX(0); STAZ(0);
        LDAZX(1); STAZ(1);
      } LDXZ('tmp_x');
      LDAZ(0); STAZX(0);
      LDAZ(1); STAZX(1);
    },


    Z_Zill_Zero_Fill_Erase_Blank() { // alias for fill?
//      push_axy(()=>{
      STXZ('tmp_x'); STYZ('tmp_y'); {
        // address
        LDAZX(4); STAZ(0);
        LDAZX(5); STAZ(1);
        // lo char
        LDAZX(0); STAZ(2);
        // count
        LDYZX(2);        // bytes (lo byte)
        LDAZX(3); TAX(); // pages (hi byte)

        LDAZ(2); // char

        JSRA('fill');

      } LDYZ('tmp_y'); LDXZ('tmp_x');
      return drop3_next;
    },

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

    '"_string': function(){
      // calculate "pc"
      INY(); // Y no points at first char
      STYZ('tmp_y');
      TYA();
      CLC();
      ADCZ('NEXT_BASE');

      push(); // TODO, tailoptimize? pushSA()
      STAZX(0);
      LDAN(0);
      ADCZ('NEXT_BASE', (a)=>a+1);
      STAZX(1);
      DEY();

      LDAN(ord('"'));
     L('skip_to"');
      INY();
      CMPIY('NEXT_BASE');
      BNE('skip_to"');
      
      // now at " push(Y-Y')
      TYA();
      SEC();
      SBCZ('tmp_y');

      return pushA_next;
    },

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

//      LDAZ('STATE');
//      BNE('forceend');
      JMPA('forceend');

      // inside '[' (immediate mode)
      // TODO: [=inc ]=dec that way can have a super immediate mode (as you type??
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
      STAZ('STATE');
    },

    '@_FETCH': function(){
      LDAXI(0); STAZ('tmp_a');

      // need to inc address!
      INCZX(0);
      BNE('@_noinc');
      INCZX(1);
     L('@_noinc');

      LDAXI(1); STAZX(1);
      LDAZ('tmp_a'); STAZX(0);
      return drop_next;
    },

    '!_STORE': function(){
      LDAZX(2); STAXI(0);

      // need to inc address!
      INCZX(0);
      BNE('!_noinc');
      INCZX(1);
     L('!_noinc');

      LDAZX(3); STAXI(0);
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
      LDAZX(1); ANDZX(3); PHA();
      LDAZX(0); ANDZX(2);
     L('putSA_drop_next');
              STAZX(-2 & 0xff);
      PLA();  STAZX(-1 & 0xff);
      return drop_next;

      LDAZX(0); ANDZX(2); STAZX(2);
      LDAZX(1); ANDZX(3); STAZX(3);
      return drop_next;
    },

    '__or' : function(){ // b12  (FIG: b14)
      LDAZX(1); ORAZX(3); PHA();
      LDAZX(0); ORAZX(2);
      return putSA_drop_next;

      // b15
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

    // on the topic of 16 bits compare
    // http://forum.6502.org/viewtopic.php?f=2&t=6136
    'UCMP': function(){
      LDAZX(3); // x
      CMPZX(1); // y
      BNE('UCMP_notequal');
      LDAZX(2);
      CMPZX(0);
     L('UCMP_notequal')
//      BCC(lower);   // x < y    lower
//      BNE(higher);  // x > y    higher
//      BEQ(same);    // x == y   ame
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

    // TODO: '#?' == CMP
    '?' : function(){
      LDAZX(1); // x
      CMPZX(3); // y
      BNE('_CMP');
      LDAZX(0);
      CMPZX(2);
     L('_CMP');

      BEQ('0');   // x == y   same
      BCC('-1');  // x < y    lower
      BNE('+1');  // x > y    higher

     L('-1');   // x < y    lower
      LDAN(0xff); STAZX(2);
      LDAN(0xff); STAZX(3);
      drop_next();

     L('+1');  // x > y    higher
      LDAN(1);
     L('put_drop_next');
                STAZX(2);

      LDAN(0);  STAZX(3);
      //JMPA('put_drop_next');
      drop_next();

     L('0');    // x == y   ame
      LDAN(0);
      JMPA('put_drop_next');

      return ()=>0;
    },

    '>_greater_than' : function(){
      JSRA('Rminus');
      BEQ('false');
//      BNE('true');
    },

    // TODO: put instruction before that also need to "drop"
    '\\_drop' : function(){
      return drop_next;
    },

    Over (){ // b8
      LDAZX(3); PHA();
      LDAZX(2);
      return pushSA_next();
    },

    Dup (){ // b5
      LDAZX(1); PHA(); // hi
      LDAZX(0);
      
     L('pushSA_next');
      push();
     L('putSA_next');
             STAZX(0);
      PLA(); STAZX(1);
    },

    Swap (){ // b18 (FIG: b16 c43
      // hi
      LDAZX(3); PHA();
      LDAZX(1); STAZX(3);
      // lo
      LDAZX(2); PHA();
      LDAZX(0); STAZX(2);
      // STACK: hi, lo
      PLA();
      return putSA_next();
    },

    '$_printstring': function(){
      // TODO: rename to $.
// TODO: why STYZ not work and is slower?
//      STYZ('tmp_y'); STXZ('tmp_x');
      push_axy(()=>{
        LDAZX(0); // length
        STAZ('tmp_x');
        LDAZX(2); // lo address
        LDYZX(3); // hi address
        LDXZ('tmp_x');
        JSRA(aputs);
      });
//    LDYZ('tmp_y'); LDXZ('tmp_x');
      return drop2_next;
    },

    '._print': function(){

      CPXN(0xff);
      BNE('._0');
      THROW(13); // we're getting 5???
     L('._0');

      push_ay(()=>{
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

    '#_prefix': function(){
      INY();
      JMPA('###');
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
  // TODO: read more digits...
  pushA_next();

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

  // zero X pages and Y bytes from R0
 L('zero');
  LDAN(0);


  // fill X pages and Y bytes with A from R0
 L('fill');
  INX();
  CPYN(0);
  BNE('_fill_op');
  // Y == 0
  CPXN(0);
  BEQ('_fillRTS_op');
  DEX();
  
//  CPYN(0);
//  BEQ('_fillpage');
//  CPXN(1);
//  BNE('_fill');
//  RTS();
  //INX(); // for 0 pages: DEX() => Z
  // move blocks (of Y chars) backwards!

 L('_fill_op');
  DEY();
  STAIY(0);
  BNE('_fill_op');
  // another page?
 L('_fillpage_op');

CLC();
ADCN(1);

  INCZ(1);
  // Y is = 0 => 256 moves!
  DEX();
  BNE('_fill_op'); // yet
 L('_fillRTS_op');
  RTS();



  // move X pages and Y bytes from R0 to R1
  // OVERWRITES: if [R0, R0+n] ^ [R1, R1+n]
  // but it's FAST! lol
 L('move');
  INX(); // for 0 pages: DEX() => Z
  // move blocks (of Y chars) backwards!
 L('_move');
  DEY();
  LDAIY(0); STAIY(2);
  BNE('move');

  // another page?
  INCZ(1);
  INCZ(3);
  // Y is = 0 => 256 moves!
  DEX();
  BNE('_move'); // yet
  //RTS(); as long as CCC_zero is there!

L('CCC_zero'); // don't move (see above!)
  RTS();

tabcod('CCC', {
  '@_C@_CFETCH': function(){
    LDAXI(2);
   L('putA_next');
              STAZX(0) // only low byte
    LDAN(0);  STAZX(1); // hi = 0
  },

  '!_C!_CSTORE': function(){
    LDAXI(2); STAZX(0) // only low byte
    return drop2_next;
  },

  'M_CMOVE': function() { // (from to chars ==)
    STYZ('tmp_y'); STYZ('tmp_x'); {
      // - store in ZP at fixed address
      // 4 from
      LDAXI(4); STAZ(0);
      LDAXI(5); STAZ(1);
      // 2 to
      LDAXI(2); STAZ(2);
      LDAXI(3); STAZ(3);
      // 0 chars
      LDYZX(0); // Y = lo byte count
      LDAZX(1); TAX(); // X = hi/page count

      JSR&('move');
    } LDXZ('tmp_x'); LDYZ('tmp_y'); 
    return drop3_next;
  },

  R_CR(){
    LDAN(10);
    JSRA(aputc);
  },

  default(){ 
    // TODO: give error?
  }});
  
L('###_zero'); // don't move (see above!)
  RTS();

tabcod('###', {
  '#_##_DEPTH': function(){
    TXA();
    EORN(0xff); // 0xff-A
    LSR();
   L('pushA_next');
    push();
             STAZX(0);
    LDAN(0); STAZX(1);
  },

  '._#._.S_print_stack': function(){
    push_axy(()=>{
      if (0) {
        // call ##
        LDAN(ord('<')); JSR(aputc);
        LDAZX(0); LDYZX(1); JSRA(aputd);
        LDAN(ord('>')); JSR(aputc);
        LDAN(ord(' ')); JSR(aputc);
      }

      // want reverse order!
      L('_printstack_next');
      CPXN(0xff);
      BEQ('_printstack_done');
      LDAN(ord(' ')); JSRA(aputc);
      // "."
      LDAZX(0); LDYZX(1); JSRA(aputd);

      drop();
      JMPA('_printstack_next');

      L('_printstack_done');
    }); // axy restored
  }
});

L('RRR_zero');
  RTS();

tabcod('RRR', {
  '<_R<_>R': function(){
    LDAZX(1);  PHA();  // hi first
    LDAZX(0);  PHA();  // lo
    return drop_next;
  },

  '>_R>_R>': function(){ // b4 !
    PLA(); // lo pops first!
    return pushSA_next;
  },

  T_RoT  (){ // (4 2 0 -- 2 0  4) b24 :-(
    STYZ('tmp_y'); {
      // TODO: maybe just call Roll?
      // lo
      LDYZX(4);
      LDAZX(2); STAZX(4);
      LDAZX(0); STAZX(2);
                STYZX(0);
      // hi
      LDYZX(5);
      LDAZX(3); STAZX(5);
      LDAZX(1); STAZX(3);
                STYZX(1);
    } LDYZ('tmp_y');
  },

  L_Roll (){ // (5 4 3 2 1 0  3 -- 5 4  2 1 0  3)
    // TODO: works only for n >= 2, lol
    // 2 ROLL == ROT    mine: 3
    // 1 ROLL == SWAP   mine: 2
    // 0 ROLL === -     mine: 1
    STYZ('tmp_y'); {
      INCZX(0);
      TXA();
      CLC();
      ADCZX(0);
      ADCZX(0);  // A = X+2*Y == destination addr
      TAX();
      
      // - X now is destination address
      // store wanted value
      LDAZX(0); STAZ(0);
      LDAZX(1); STAZ(1);

      LDYZX(2); // only lo count! (-2)
      // move Y others
     L('_roll');
      BEQ('_roll_done');
      LDAZX(0xfe); STAZX(0);
      LDAZX(0xff); STAZX(1);
//      LDAZX(0); STAZX(2);
//      LDAZX(1); STAZX(3);
      DEX(); DEX();
      DEY();
//      BNE('_roll');
      JMPA('_roll');

     L('_roll_done');
      // store the rolled out value
      //LDAZ(0); STAZX(4);
      //LDAZ(1); STAZX(5);
      LDAZ(0); STAZX(2);
      LDAZ(1); STAZX(3);
      
    } LDYZ('tmp_y');
    return drop_next;
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

let end = jasm.address();
// bytes: assuming contigious
let bytes = end - start;

print("====CODELEN: ", bytes);

//print(jasm.getChunks());
//print(jasm.getHex(1,1,0));
//print(jasm.getHex(0,0,0));

let cpu = cpu6502.cpu6502(); // hmmm "call it..?"
let m = cpu.state().m;

jasm.burn(m, jasm.getChunks());

// crash?

cpu.reg('pc', start);
//print(cpu.state());

//console.log('BCC=' + BCC.toString(), BCC);
//console.log('DEX=' + DEX.toString(), DEX);
//console.log('JMPA=' + JMPA.toString(), JMPA);

//cpu6502.dump(0x501, 16); which mem?
let labels = jasm.getLabels();
let a2l = {};
Object.keys(labels).forEach(k=>a2l[labels[k]]=k);

print('\n\nCPU.run => ', cpu.run(-1, trace, patch));

if (showMem) {
  print();

  cpu.dump(0x0000, 2);
  print();
  printstack();
  print();
  
  cpu.dump(0, 65536/8, 8, 1);
  print();
  printstack();
  print();
}

//print('INCZX=' + INCZX.toString(), INCZX);
//print('BNE=' + BNE.toString(), BNE);


// --- ALForth helpers

// (called after instruction)
function trace(c, h) {
  // quit at BRK? unless it's trapped!
  if (h.op==0) {
    return 'quit';
  }

  if (!traceLevel) return;

  let l = a2l[h.ipc];
  if (l) {
    print("\n---------------> ", l);
  }

  if (traceLevel > 1)
    cpu.tracer(cpu, h);
  if (traceLevel > 2) {
    cpu.dump(h.ipc,1);
    printstack(); print("\n\n");
  }

  l = a2l[h.d];
  if (l) {
    print("                      @ ", l);
  }
}

function printstack() {
  let x = cpu.reg('x');
  princ(`  DSTACK[${(0x101-x)/2}]: `)
  x--;
  while(++x < 0xff) {
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
  case 0xfff4: _puts((cpu.reg('y')<<8)+cpu.reg('a'), cpu.reg('x')); break;
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
}

// print string from ADDRESS
// optinal max LEN chars
// stops if char=0 or char hi-bit set.
function _puts(a, len=-1) {
  if (output) princ("OUTPUT: ");
  let c = 0;
  while(len-- && (c < 128) && (c=m[a++]))
    process.stdout.write(chr(c));
  if (output) print();
}

function _putd(d) {
  if (output) princ("OUTPUT: ");
  process.stdout.write(''+d+' ');
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
function chr(c) { return String.fromCharCode(c)}
function print(...r) { return console.log(...r)}
function princ(s) { return process.stdout.write(''+s);}

// generate a "switch" from assoc list
// does order matter?
//
// you have to have a near label NAME_zero
function tabcod(name, list, nxt= next) {
  let trace = 1;
  if (tabcod.trace)
    print("--->tabcod: ", name);

 L(name);

  if (traceLevel) {
    LDAN(ord('\n')); JSRA(aputc);
    LDAN(ord('\n')); JSRA(aputc);
    LDAN(ord('>')); JSRA(aputc);
    LDAN(ord(' ')); JSRA(aputc);
  }

  LDAIY('NEXT_BASE');

  if (traceLevel) {
    PHA(); {
      JSRA(aputc);
      LDAN(ord('\n')); JSRA(aputc);
    } PLA();
  }

  BEQ(name+'_zero');

  let count = Object.keys(list).length;
  tabcod.count = (tabcod.count || 0) + count;
  tabcod.tabcods =  (tabcod.tabcods || 0) + 1;

  if (tabcod.trace) {
    print('====tabcod=========================');
    print('====TABCOD: ', name);
    print('====tabcod: ', count);
    print('====tabcod_total: ', tabcod.count);
    print('====tabcod_tabcods: ', tabcod.tabcods);
  }

  Object.keys(list).forEach(k=>{
    if (tabcod.trace) 
      print('====TABCOD_F: ', k);
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
      (cod() || nxt)();

      // skip to here
      if (k !== 'default')
        L(nexttest);
    } else {
      // take +1 penalty only if match
      BEQ( name+'_'+k );
      // TODDO after cases need generate cod
    }
  });
  if (tabcod.trace)
    print("<---tabcod: ", name);
}

// data stack manipulation
// (stack grows down)
function drop() { INX(); INX(); }
function push(v) {
  if (v)
    throw "%% push no arg: just make spacec";
  DEX(); DEX();
}

function save(regs, f) {
  regs.split('').forEach(r=>
    global['ST'+r.toUpperCase()+'Z']('tmp_' + r.toLowerCase()));

  f();

  regs.split('').forEach(r=>
    global['LD'+r.toUpperCase()+'Z']('tmp_' + r.toLowerCase()));
}

function push_a(f) {
  PHA(); {
    f();
  } PLA();
}

function push_ax(f) {
  push_a(()=>{
    TXA(); PHA(); {
      f();
    } PLA(); TAX();
  });
}

function push_ay(f) {
  push_a(()=>{
    TYA(); PHA(); {
      f();
    } PLA(); TAY();
  });
}

function push_axy(f) {
  push_ax(()=>{
    TYA(); PHA(); {
      f();
    } PLA(); TAY();
  });
}

function push_axyp(f) {
  push_axy(()=>{
    PHP(); {
      f();
    } PLP();
  });
}

// TODO: not correct (this is more ERR)
// - https://forth-standard.org/standard/exception/CATCH
function THROW(n) {
  LDAN(n);
  JMPA('fail');
}

function puts(s) {
  // TODO: put in "datasegment?"
  let l = 'STR:' + s;

  // TODO: generate "clever"
  // inline code w/o jmp
  // like JSRA(sputs); string("foo");

  JMPA('_'+l);
 L(l); string(s);
 L('_'+l);

  push_axy(()=>{
    LDAZX(0xff); // length
    LDAN(l, lo);
    LDYN(l, hi);
    JSRA(aputs);
  });
}
  
function putc(c) {
  LDAN(ord(c));
  JSRA(aputc);
}

function putd(d) {
  push_ay(()=>{
    LDAZX(0);
    LDYZX(1);
    JSRA(aputd);
  });
}
