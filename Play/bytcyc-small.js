function bytcyc(op) {
  if (op & 0x05) return modebc(op);
  if (!op) return [1, 7]
  if (op == 0x20) return [3, 6];
  if (op == 0x40 || op == 0x60) return [1,6];
  if ((op & 0x1f) == 0x12) return modebc(op);
  if ((op & 0x9f) == 0x80) return [2, 3];
  if ((op & 0x1f) == 0x08)
    return [1, 3 + ((op & 0x20) ? 1 : 0)];
  if ((op & 0x1f) == 0x10)
    return [2, 3 + ((op & 0x20) ? 1 : 0)];
  return [1, 2];
}

function modebc(op) {
  const byts = [2,2, 2,2, 1,2, 3,3,  2,2, 2,2, 3,3, 3,3];
  const cycs = [2,6, 3,3, 2,2, 4,4,  5,5, 4,4, 4,4, 4,4];
  let i = (((op >> 1) & 0xe) | (op & 1)) & 0xf;
  return [ byts[i], cycs[i] ];
}

function mbytescycles(op, mnc, m, c) {
//  if (xxx) return [1,2];
  if ((op & 0x10) == 0x10) return [2,2];
  if ((op & 0x9f) == 0) {
    let i = op>>5;
    return [i==1 ? 3 : 1,
	    i==0 ? 7 : 6];
  }
  if ((op & 0x9f) == 0x08) 
    return [1, op&1 ? 4 : 3];
  let o= (m<<1) | (c&1);
  let b= bytes[o], cyc=cycs[o];
  if (op==0x4c){ cyc--; return [b,cyc] }
  if (op==0x6c){ cyc=5; return [b,cyc] }
  if ((op & 0xf7)== 0x91){ cyc++; return [b,cyc]}
//  if (op== 1xx xxx 10) {
//    if (op== 10x) return [b,cyc];
    if (!m && !(c&1)) return [b,cyc];
    if (m==1 || m==2 || m==4) return [b,cyc];
    cyc+=2 
    if ((m&6)===6) cyc++;
    return [b,cyc];
//  }
  // dynamic at runtime
  // cyc++ if page cross && m==100, m==111
  // cyc++ if B.. && true
  // cyc+=2 if B.. && page cross
}
  
// ASL missing?

const valids = [0x55,0xDF,0x5D,0x5D,0x7E,0xFF,0x5F,0x5F,0xFF,0xFF,0xFF,0xFF,0xFB,0xFF,0xFF,0xFF,0xAA,0xAE,0xAE,0xAE,0x6E,0xEF,0xAE,0xAE];

function valid(op) {
  let cc = op & 3;
  if (cc == 3) return; // not valid
  let i = (cc << 6) | (op >> 2);
  return valids[i>>3] & (1<< (i&7));
}


let c='';
for(let i=0; i<256; i++) {
  let [byt,cyc] = bytcyc(i);
  c+= valid(i)?cyc:0;
}

console.log(c);

