// A 6502 assember "hosted" in JS!
//
//    (C) 2021 Jonas S Karlsson
//          jsk@yesco.org
// 

// TODO: not working...


// Data is stored and output in chunks:
//
// [ [addr, label, byte, ...], ...]
// NOTE: backpatching will "overwrite"
// by generating overlapping chunks!
// chunks are to be loaded in sequence.
var chunks = [];

var start = 0, address = 0, current = [], curlab = '';;

function addr(a) {
  if (typeof a === 'undefind' || Number.isNaN(a))
    throw `%% jasm: use of empty label '${a}'`;
  if (current.length || curlab) {
    current.unshift(curlab);
    current.unshift(start);
    chunks.push(current);
  }
  address = start = a; current = [];
  curlab = '';
}

// force a chunk
function flush() {
  addr(address);
}

// NOTICE: output contains overlapping patching
// locations!
function getChunks() {
  flush();
  Object.keys(backpatch).map(k=>{
    let bp = backpatch[k];
    if (bp && bp.length) {
      console.error(`\n%% getChunks: label not defined: ${k}`);
      throw "%% getChunks: undefined labels!";
    }
  });
  return chunks;
}

function data(...bytes) {
  bytes.forEach((d)=>current.push(d));
  address += bytes.length;
}

let labels = {};

function clear(all=0) {
  address = start = 0; current = [];
  curlab = '';
  chunks = [];
  // TOOD: clear labels?
  if (all) {
    labels = {};
    backpatch = {};
  }
}

function label(name) {
  if (labels[name]) throw `%% Label already defined: ${name}`;

  let saved = address;
  // backpatch earlier mentions
  let bp = backpatch[name];
  if (bp) {
    flush();
    bp.forEach((f)=>f(address));
    backpatch[name] = undefined;
    flush();
  }

  addr(saved);
  labels[name] = saved;
  //console.log('LABEL: ', name);
  curlab = name;
//  flush();
}

function L(...args) { label(...args); }
function ORG(...args) { addr(...args); }

// label -> [addr]
let backpatch = {};

let lo = (w)=> w & 0xff;
let hi = (w)=> w >>> 8;

// LDAN('foo', hi);
function byte(name, fexpr) {
  word(name, fexpr, 1);
}

function word(name, fexpr, byte) {

  function maybewarn(v, addr) {
    if (byte && hi(v))
      throw Error(`%% Warning: @ ${hex(4, addr)} write of (${hex(4,v)}) truncated to byte using name='${name}'!\n`+(fexpr?'FUNCTION: '+fexpr.toString():''));
  }

  function write(v, init) {
    //console.log(`write: v=${v.toString(16)} address=${address.toString(16)}`);
    v = init ? v : fexpr ? fexpr(v) : v;
    data(lo(v));
    if (byte)
      maybewarn(v, address);
    else
      data(hi(v));
  }

  let a = typeof name==='string' ? labels[name] : name;
  if (typeof a === 'number')
    return write(a);
  if (typeof name==='undefined')
    throw new Error(`%% jasm: referred to undefined name '${name}`);

  backpatch[name] = backpatch[name] || [];
  // double closure: save address
  let x;
  backpatch[name].push( x=((address)=>(a)=>{
    let v = fexpr ? fexpr(a) : a;
    // patch at previous address
    if (byte)
      chunks.push([address, '', lo(v)]);
    else
      chunks.push([address, '', lo(v), hi(v)]);
    if (byte) maybewarn(v, address);
    })(address));
  write(byte ? 0xFF : 0xFFFF, 1); // alocate bytes!
}

function hex(n,x,r=''){for(;n--;x>>=4)r='0123456789ABCDEF'[x&0xf]+r;return r};

// lab: print 'label:' after 'addr:'
// dumplab: prints sorted label=addr @end
// pretty:  prints '  ...FOO....'
//
// NOTICE: output contains overlapping patching
// locations!
function getHex(prlab=0, dumplab=0, pretty=0) {
  let all = [...getChunks()]; // copy!
  let r = '', ch, p = '';
  while(ch = all.shift()){
    ch = [...ch]; // copy!
    let a = ch.shift();
    let lab = ch.shift();
    if (!prlab && !ch.length) continue;
    let line = hex(4, a) + ':  ';
    if (lab && prlab) {
      line += '\n'+lab+':\n       ';
      r += line;
      line = '';
    }
    line += ch.map((d)=>hex(2, d)).join(' ');
    if (pretty & ch.length) {
      let p = '$ ' + ch.map(c=>(c < 32 || c > 126) ? '.' : String.fromCharCode(c)).join('');
      let col = ((line.length + 56) / 57)*57;
      r += line.padEnd(col-line.length) + p + '\n';
    } else {
      r += line + '\n';
    }
  }
  if (dumplab) {
    r += "\n" + Object.keys(labels)
      .filter(k=>!k.endsWith('_'))
      .sort().map(k=>
	`${k}	= ${hex(4, labels[k])}\n`)
      .join('');
  }
  return r;
}

function getLabels() {
  return labels;
}

function allot(n, v= 0) {
  if (n < 0 ) throw `%% allot: negative n: ${n}`;

  while(n-->0) data(v);
  return address;
}

function allotTo(n, to, v) {
  return allot(to-n+1, v);
}

function char(c) {
  let ch = c.charCodeAt(c);
  if (ch > 255) throw `%% char: ${c} (${ch}) not single byte`;
  data(ch);
}

// TODO: PACKED16
function _string(s, pascal, hibit, zero) {
  let d = [...Buffer.from(''+s)];
  let len = d.length;
  if (pascal) d.unshift(len);
  if (hibit) d[d.length-1] |= 128;
  if (zero) d.push(0);
  data(...d);
}

function chars(s) { _string(s, 0, 0, 0)}
function string(s) { _string(s, 0, 0, 1)}
function pascal(s) { _string(s, 1, 0, 0)} 
function hibit(s) { _string(s, 0, 1, 0)}

function pascalz(s) { _string(s, 1, 0, 1)} 
function OMG(s) { _string(s, 1, 1, 1)}

function rel(name, f) {
  byte(name, ((address)=> a=>{
    a = f ? f(a) : a;
    let b = a - address - 1;
    //console.log("REL: ", address, a, b);
    if (b < -128 || b > 127) throw Error(`%% Branch to label '${name}' too far (${b})`);
    return b & 0xff;
  })(address)); // capture current addr
}

////////////////////////////////////////
//        6502 INSTRUCTIONS
//
//  xxx mmm cc = generic structure
//  ----------
//                           (v--- indirect)
//  xxx mmm 00 = --- BIT JMP JMP* STY LDY CPY CPX
//  xxx mmm 01 = ORA AND EOR ADC  STA LDA CMP SBC
//  xxx mmm 10 = ASL ROL LSR ROR  STX LDX DEC INC

// Functions needed
//   dis:
//     valid(op) -> true/false
//     bytes(op) -> 1..3, can combine 0..3
//     mnc(op) -> 'ABC' (offset) pack3
//     mod(op) -> 'XI' (offset?) pack3 (?)
//
//   asm:
//     op('ADCXI') => op (or FF ?)
//     valid(op) === see above
//     bytes(op) === see above
//     
// TABLES:
//   mnemomics         
//   valids (cc != 11) 24 bytes
//   bytes/cyc         69 bytes (machine code)
//   modes =  # Xi ... 22 bytes (zy)

// --------------------------------
// Irregular instructions... TODO?

// 20 jsr abs 	 = . jsr --- 	 JSR 	 3 6
// 6C jmpi abs 	 . = jmp abs 	 JMPA  	 3 4

// == zpx => zpy (if mnc[2]=='y'
// 96 stx zpy 	 = . stx zpx 	 STXZX 	 2 4
// B6 ldx zpy 	 = . ldx zpx 	 LDXZX 	 2 4

// === absx => absy because LDX = 'x'
// BE ldx absy 	 = . ldx absx 	 LDXAX 	 3 4

let ops = [];

// 24 bytes of bits to test if op is valid
// there are 151 opcodes valid in 6502.
//
//let valids = new Uint8Array(24);

// TODO: ASL missing?
const valids = [0x55,0xDF,0x5D,0x5D,0x7E,0xFF,0x5F,0x5F,0xFF,0xFF,0xFF,0xFF,0xFB,0xFF,0xFF,0xFF,0xAA,0xAE,0xAE,0xAE,0x6E,0xEF,0xAE,0xAE];

function valid(op) {
  let cc = op & 3;
  if (cc == 3) return; // not valid
  let i = (cc << 6) | (op >> 2);
  return valids[i>>3] & (1<< (i&7));
}

function setvalid(op) {
  let cc = op & 3;
  if (cc == 3) return; // not valid
  let i = (cc << 6) | (op >> 2);
  valids[i>>3] |= (1<< (i&7));
}

mgen('---BITJMPJMPSTYLDYCPYCPXORAANDEORADCSTALDACMPSBCASLROLLSRRORSTXLDXDECINC');
function mgen(names, valids) {
  const modes = [['imm', 'zpxi'], 'zp', ['','imm'], 'abs', 'zpiy', 'zpx', 'absy', 'absx'];
  const mds=[['N','XI'],'Z',['', 'N'],'A','IY','ZX','AY','AX'];
  // TODO: restrict gen depending on mode
  for(let c=0; c<3; c++) {
    for(let i=0; i<8; i++) {
      for(let m=0; m<8; m++) {
	let op = (i<<5) | (m<<2) | c;
	if (!valid(op)) continue;
	let io = (c << 3) | i;
	let mnc = names.substr(3*io, 3);
	//if (mnc === '---') continue;
	let mode = mds[m], mleg = modes[m];
	// use mode[2] to test for string! lol
	// it's either 'foo' or ['foo', 'bar']...
	mode = typeof mode=='string' ? mode : mode[c&1];
	mleg = typeof mleg=='string' ? mleg : mleg[c&1];

	let name = mnc + mode;
	//console.log(hex(2,op), i,m,c, mnc, 3*io, names.length, mode, mleg, name, '=');

	//if (!mnc) continue;
	//console.log(hex(2,op), mnc.toLowerCase(),modes[m], '-',  name, c, i, m);
	let [b,cyc] = modebc(op);
        genf(op, name, mnc, mleg, b, cyc);
      }
    }
  }
}

function genf(op, name, mnc, mleg, b, cyc) {

// TODO: verify instructions valid again...
// CPX  CPXA   CPXAY  CPXIY  CPXN   CPXZ

// I'm not even sure what CPX is!!!
// 
// 150:CPX (ComPare X register)
// 154:Immediate     CPX #$44      $E0  2   2
// 155:Zero Page     CPX $44       $E4  2   3
// 156:Absolute      CPX $4400     $EC  3   4
// = CPX# e0 ;
// = CPXZ e4 ;
// = CPXA ec ;
//       case 0x07: f='CPX'; sc(0 >= n(z(g= x - (m[d])))); break;




if (mnc == 'LDX') {
  console.log({op:hex(2,op),name,mnc,mleg,b,cyc});

  // INVALID!
  if (op == 0xAA) return; // no LDX ''
  
  // MODE EXCEPTION
  if (mleg == 'zpx') mleg= 'mzpy';
  if (mleg == 'absxyx') mleg= 'mzpy';

  // LDXAY but not BA but BE
  if (op == 0xBA) op= 0xBE;
}

  let f = `j6502.data(0x${hex(2,op)});`;

  if (b==1) f = Function(f);
  if (b==2) {
    //console.log('jsk: ', hex(2,op&0x1f),hex(2,op), name, mleg, mnc, b, cyc);
    if ((op & 0x1f) == 0x10) { // branch relative
      f = Function('v,f', f+`j6502.rel(v, f)`);
      //console.log('fish: ', hex(2,op), name, mnc);
    } else {
      f = Function('v,f', f+`j6502.byte(v, f)`);
    }
  }
  if (b==3) f = Function('v,f', f+`j6502.word(v, f)`);
  f.op= op; f.mnc= mnc; f.b= b; f.cyc= cyc;
  f.SAN = name; f.mode = mleg;
  ops[op] = global[name] = f;
}



//  0xx 000 00 = call&stack       BRK JSR RTI RTS
gen('BRKJSRRTIRTS', 0x00, [1,3,1,1], [7,6,6,6]);
//  0xx 010 00 = stack            PHP PLP PHA PLA
//  1xx 010 00 = v--transfers--> *DEY TAY INY INX
gen('PHPPLPPHAPLADEYTAYINYINX', 0x08, 1, [3,2,4,2,3,2,4,2]);
//  xx0 110 00 = magic flags =0   CLC CLI*TYA CLD
//  xx1 110 00 = magic flags =1   SEC SEI CLV SED
gen('CLCSECCLISEITYACLVCLDSED', 0x18);
//  1xx x10 10 = TXA TXS TAX TSX  DEX --- NOP ---
dgen(0x10,'TXATXSTAXTSXDEX---NOP---', 0x8a);
function dgen(delta, s, base) {
  if (!delta) throw "Delta can't be zero";
  let op = base;
  let i = 0;
  while (op <= 255) {
    let mnc = s.substr(i*3, 3);
    //if (!mnc) return;
    if (mnc && mnc !== '---') {
      //console.log('DGEN', '-', hex(2,op), mnc);
      let [b,cyc] = bytcyc(op);
      genf(op, mnc, mnc, '---', b, cyc);
    }
    op += delta;
    i++;
  }
}
{ // JSRA
  let op = 0x20;
  let f = `j6502.data(0x${hex(2,op)});`;
  f = Function('v','f', f+`j6502.word(v, f)`);

  // Make a function! lol
  f.op= op; f.mnc= 'JSR'; f.b= 3; f.cyc= 6;
  f.SAN = 'JSRA'; f.mode = 'abs';
  ops[0x20] = global[f.SAN] = f;
  global.JSR = undefined;
}
{ // JMPA   JMPAY  JMPIY  JMPN
  // fixing
  genf(0x6c, 'JMPI', 'JMP', 'indirect', 3, 5);
  genf(0x4c, 'JMPA', 'JMP', 'abs', 3, 3);
  genf(0x0a, 'ASL', 'ASL', '', 1, 2);

  // they didn't  override any opcodes
  delete global.JMPAY;
  delete global.JMPIY;
  delete global.JMPN;
  delete global.JMP;
  delete global.JSR;
}
function gen(s, base) {
  dgen(1 << 5, s, base);
//  ops[0x6c] = global['JMPI'] =
//  ops[0x4c] = global['JMPA'] = global['JMPA'];
}

//  ffv 100 00 = branch instructions:
//  ff0 100 00 = if flag == 0     BPL BVC BCC BNE
//  ff1 100 00 = if flag == 1     BMI BVS BCS BEQ
//  00v 100 00 = Negative flag   (BPL BMI)
//  01v 100 00 = oVerflow flag   (BVC BVS)
//  10v 100 00 = Carry flag      (BCC BCS)
//  11v 100 00 = Zero flag       (BNE BEQ)
gen('BPLBMIBVCBVSBCCBCSBNEBEQ', 0x10); // 3

//          11 = not used  / (p = page cross)
//modes summary:           | (RW = shift INC DEC)
//  xxx mmm cc             | bytes cycles
//  --- --- --              \----- ------

//   !  000  0 = #immediate     2  2
//   !  000  1 = (zero page,X)  2  6 (STA="xpy")

//      001    = zero page      2  3 +2/RW

//   !  010  0 = accumulator    1  2
//   !  010  1 = #immediate     2  2

//      011    = absolute       3  4 +2/RW JMP=3

//      100    = (zero page),Y  2  5 +1/STA +1/p

//      101    = zero page,X    2  4 +2/RW

//      110    = absolute,Y     3 \4 +3/RW +1/STA

//      111    = absolute,X     3 / +1/p
//             JMP              3  3 JMP +2/JMPI
//    branch instructions       2  2 +1/true +2/p
//      stack: PHA/PHP          1  3 +1/PLA/PLP
//             JSR RTS RTI      3  6 +1/BRK
//  other implied instructions  1  2 


// Calculate BYTES+CYCLES: (19+63 =82 bytes)
// SIMPLE: no addresing modes (63 bytes)

//(001 000 00  3 6    20jsr abs) NOT NOT NOT NOT
// 0xx 000 00  1 6,7    brk/rti/rts (BUT JSR/abs!)

// 0xx 010 00  1 3,4    PLx(3),PHx(4)
// 0xx 010 10  1 2      ROL/ROT/ on A
// xxx 010 x0  1 2      ***
// xxx x10 00  1 2      ***

// xxx 100 00  2 2,3    Bxx (imm) NOT? mmm=2bytes

function bytcyc(op) {
//
//  (A contains op)
//  TAY (backup)
	
//         x1           IS NOT SIMPLE!
//     xx1              IS NOT SIMPLE!
//
// xxx xx0 x0    maybe    SIMPLE!
  if (op & 0x05) return modebc(op);

  // maybe SIMPLE
  // after weeding out:
  // 000 000 00     00    brk 
  if (!op) // BRK
    return [1, 7]

  // 001 000 00     20    jsr abs
  // if ((001 000 00 == 0x20     JSR-MODE (jsr ABS)
  if (op == 0x20)  // JSR
    return [3, 6];

  // 010 000 00     40    rti 
  // 011 000 00     60    rts 
  if (op == 0x40 || op == 0x60) // RTI RTS
    return [1,6];

  // xxx 100 10     12    ***  zpi
  if ((op & 0x1f) == 0x12)
    return modebc(op);

  // (100 000 00     80    bra imm)
  // 101 000 00     A0    ldy imm
  // 110 000 00     C0    cpy imm
  // 111 000 00     E0    cpx imm
  // 101 000 10     A2    ldx imm
  if ((op & 0x9f) == 0x80) // ???
    return [2, 3];

  // 000 010 00     08    php 
  // 001 010 00     28    plp 
  // 010 010 00     48    pha 
  // 011 010 00     68    pla 
  if ((op & 0x1f) == 0x08)
    return [1, 3 + ((op & 0x20) ? 1 : 0)];

  // 001 010 10     2A    rol_a  1 2
  // 010 010 10     4A    lsr_a 
  // 011 010 10     6A    ror_a 
  
  // 100 010 00     88    dey 
  // 101 010 00     A8    tay 
  // 110 010 00     C8    iny 
  // 111 010 00     E8    inx 
  
  // 1xx 010 10     8A    txa    1 2
  
  // xxx 100 00     10    Bxx    2 2 (3)
  // xxx 110 x0     18    ***
  if ((op & 0x1f) == 0x10)
    return [2, 3 + ((op & 0x20) ? 1 : 0)];
  
  // in principle we have all instructions
  return [1, 2];
}

// lookup in table xx[mmm c] (16 bytes)
function modebc(op) {
  // 16 values * 2b/2pack = 16 bytes total
  const byts = [2,2, 2,2, 1,2, 3,3,  2,2, 2,2, 3,3, 3,3];
  const cycs = [2,6, 3,3, 2,2, 4,4,  5,5, 4,4, 4,4, 4,4];
  
  let i = (((op >> 1) & 0xe) | (op & 1)) & 0xf;
  return [ byts[i], cycs[i] ];
}

function burn(m, chunks) {
  chunks.forEach(c=>{
    let a = c.shift();
    let lab = c.shift();

    let b;
    while (typeof (b = c.shift()) == 'number') {
      m[a++] = b;
    }
  });
}

// Ok, let's do some sketch stuff!
//
// The Function created assembly instructions
// are global, thus they can't access any other
// functions than those in global object.
// So, we add them. Which means we don't 
// need to use the '.' notation when accessing
// them.

// used to access hi byte (next byte)
function inc(a) { return a+1 }

let gencount= 0;
function gensym(prefix) {
  return prefix + '_' + gencount++;
}

module.exports =
  global.j6502 =
  { address(){return address;}, ORG, flush, getChunks, data, label, hi, lo, byte, word, hex, getHex, getLabels, char, chars, string, pascal, pascalz, hibit, OMG, rel, burn, clear, gensym, inc };

global.ORG = ORG;
global.allot = allot;
global.allotTo = allotTo;

global.data = data;
global.byte = byte;
global.word = word;

global.char = char;
global.chars = chars;
global.string = string;
global.pascal = pascal;
global.pascalz = pascalz;
global.hibit = hibit;
global.OMG = OMG;

global.label = label; global.L = L;
global.gensym = gensym;

global.addr = addr; global.ORG = ORG;
global.inc = inc;
global.hex = hex;
global.lo = lo;
global.hi = hi;
global.burn = burn;
global.clear = clear;

////////////////////////////////////////

if (0) {
  //console.log('='.repeat(40));
  Object.keys(global).map(k=>{
    let f = global[k];
    if (!f.mnc) return;
    console.log(hex(2,f.op), '=', f.SAN, f.b, f.cyc, '(', k, ')');
  });
}

// load "REFERENCE" real (some are 6502C)
let fs = require('fs');
// Real!
let rops = "\n"+fs.readFileSync('op-mnc-mod.lst');
rops.replace(/\n(..) (\w+)( (\w+))?/g,(a,op,n,_,m)=>{
  op = parseInt(op, 16);
  let f = ops[op] = ops[op] || function MISSING(){};
  f.op = op; f.rn = n; f.rm = m;
  setvalid(op);
});

if (0){
  console.log('-'.repeat(40));
  ops.map((f,i)=>{
    //if (!f.mnc) return;
    let m;
    console.log(
      hex(2,i),
      (f.rn || '---'), m=(f.rm || '---'), '\t',
      (f.rn == (f.mnc || '').toLowerCase()) ? '=' : '.',
      (m == f.mode) ? '=' : '.',
      (f.mnc || '???').toLowerCase(), f.mode, '\t',
      f.SAN, '\t', f.b, f.cyc);
    if (i != f.op) 
      console.log(
        `   ==== OP? i=${i}, f.op=${f.op}\n`);
  });
}

//console.log([...valids].map(n=>'0x'+hex(2,n)).join(','));

// debug modebc
//console.log('modebc(LSR)=', modebc(0x4a), (((0x4a >> 1) & 14) | (0x4a&1)).toString(2));
