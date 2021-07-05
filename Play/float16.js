//                FLOAT16
//
// Idea, implement a float16 using 2 bytes
//
// 1 byte (1 bit sign, 7 bits exponent)
// 1 byte (9 bits mantissa (1 implicit)
//

function add(a,b) {
  if (lt(a, b)) return add(b, a);
  // Now: a >= b 
  let [as, ae, am] = unpack(a);
  let [bs, be, bm] = unpack(b);
  while (be < ae) {
    be++;
    bm >>= 1;
    // underflow
    if (!bm) return a;
  }
  return norm(ae, am+bm);
}

// TODO: mantissa?
const nInf = pack(1, -63, 0);
const pInf = pack(0, +63, 0);
//const nan = [+/-127, 255];

function pack(s, e, m) {
  return [(s << 7) + e, m];
}

function unpack(f) {
  let [se, m] = f;
  let s = se >> 7;
  let e = se & 0x7f;
  // implicit 0 or 1
  return [s, e, m];
}

function norm(s, e, m) {
  // "sub-normal" 0. xxxx xxxx
  if (!e && (m < 256)) return pack(s, 0, m);
  // "normal" 1. xxxx xxxx
  while (m && m < 256) {
    e--;
    m <<= 1;
    console.log('norm<<', e, m);
  }
  while (m >= 512) {
    e++;
    console.log('norm>>.0', e, m);
    //m >>= 1; // only words for < 2^32
    m = Math.floor(m/2);
    console.log('norm>>.1', e, m);
  }
  // normal
  if (m >= 256) {
    e++; m = m - 256;
  }
  if (e < -128) return nInf;
  if (e > +127) return pInf;
  return pack(s, e, m);
}

function i2f(i) {
  return norm(+(i<0), 0, i);
}

function f2i(f) {
  let [s, e, m] = unpack(f);
  // normal
  if (e) {
    e--; m += 256;
  }
  while (e < 0) {
    e++;
    m >>= 1;
  }
  while (e > 0) {
    e--;
    m <<= 1;
  }
  // e == 0 so we have integer
  return s ? -m : m;
}

function print(v) {
  let f,i,ff,ii;
  if (typeof v=='number') {
    ff = i2f(i=v);
    ii = f2i(ff);
  } else { // float
    ii = f2i(f=v);
    ff = i2f(ii);
  }
  console.log(i, f, ii, ff);
  console.log();
}

print(0);
print(1);
//print(-1);
print(7);
//print(-7);
print(255);
print(256);
print(257);
print(511);
print(512);
print(513);
print(1023); // loss
print(1024);
print(1025); // loss
print(65535); // loss
print(65536);
print(65537); // loss
print(2**16);
print(2**17);

//process.exit(0);
console.log('--- below here - wrong! ---');
print(2**32);
print(2**62)
print(2**63);
print(2**64);
print(2**65);


