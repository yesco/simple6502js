// [ [addr, label, byte, ...], ...]
// NOTE: backpatching will "overwrite"
// by generating overlapping chunks!
// chunks are to be loaded in sequence.
var chunks = [];

var start = 0, address = 0, current = [], curlab = '';;

function addr(a) {
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

function getChunks() {
  flush();
  return chunks;
}

function data(...bytes) {
  bytes.forEach((d)=>current.push(d));
  address += bytes.length;
}

let labels = {};

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
  console.log('LABEL: ', name);
  curlab = name;
//  flush();
}

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
      console.warn(`%% Warning: @ ${hex(4, addr)} write of (${hex(4,v)}) trunacted to byte!`);
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

  let a = typeof name=='string' ? labels[name] : name;
  if (typeof a === 'number')
    return write(a);

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

function char(c) {
  let ch = c.charCodeAt(c);
  if (ch > 255) throw `%% char: ${c} (${ch}) not single byte`;
  data(ch);
}

function string(s, pascal, hibit, zero) {
  let d = [...Buffer.from(''+s)];
  let len = d.lenght;
  if (pascal) d.unshift(len);
  if (hibit) d[d.length-1] |= 128;
  if (zero) d.push(0);
  data(...d);
}

function pascal(s) { string(s, 1, 0, 0) } 
function hibit(s) { string(s, 0, 1, 0) }
function OMG(s) { string(s, 1, 1, 1) }

function rel(name) {
  byte(name, ((address)=> a=>{
    let b = a - address - 1;
    console.log("REL: ", address, a, b);
    //if (b < -128 || b > 127) throw `%% Branch to label '${name} to far (${b})`;
    return b & 0xff;
  })(address)); // capture current addr
}

function LDAN(v, f) { data(0xA9); byte(v, f)}

function BNE(name) { data(0xd0); rel(name)};

function RTS() { data(0x60)};
////////////////////////////////////////

addr(0x0501);
	LDAN(3);
	LDAN(3, (v)=>v*v);
	LDAN(3);

label('foo');
	LDAN('foo', lo);
	LDAN('foo', hi);
	LDAN('bar', hi); // forward!
	LDAN('bar', (v)=>hi(v)*hi(v)); // delaye

label('bar');
	LDAN(0xbe);
	LDAN(0xef);

label('fish');
	LDAN(0xff);

label('string');
	string("ABC");

label('sverige');
	string("Svörigä");

label('char');
	char('j');
	char('ö');
label('copy');
	char('©');

label('here');
	BNE('here');
	LDAN(0x42);
	BNE('there');
	RTS()
label('there');
	RTS()
label('end');

console.log(current);

console.log(getChunks());
console.log(getHex(1,1,1));
console.log(getHex(0,0,0));

