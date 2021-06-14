function adc(v) {
  // TODO: set overflow?
  let oa= a;
  a= c(a + v + (p & C));
  if ((a & N) != (oa & N)) p |= V; else p &= ~V;
  //if ((oa^a) & (v^a)) ...
  if (~p & D) return; else c(0);
  if ((a & 0x0f) > 0x09) a+= 0x06;
  if ((a & 0xf0) <= 0x90) return;
  a+= 0x60;
  sc(1);
}

var a= 0, x= 0, y= 0, p= 0, s= 0, pc= 0, m= new Uint8Array(0xffff + 1);

let C= 0x01, Z= 0x02, I= 0x04, D= 0x08, B= 0x10, Q= 0x20, V= 0x40, N= 0x80;

// set flag depending on value (slow?)
let z= (x)=> (p^= Z & (p^(x&0xff?0:Z)), x),
    n= (x)=> (p^= N & (p^ x)          , x),
    c= (x)=> (p^= C & (p^ !!(x & 0xff00))  , x & 0xff),
    v= (x)=> (p^= V & (p^ (x & V))    , x),
    // set carry if low bit set (=C!)
    sc=(x)=> (p^= C & (p^ x)          , x);

function hex(n,x,r=''){for(;n--;x>>=4)r='0123456789ABCDEF'[x&0xf]+r;return r};
function ps(i=7,v=128,r=''){for(;r+=p&v?'CZIDBQVN'[i]:' ',i--;v/=2);return r};
function is(v){ return typeof v!=='undefined'};



for(i=-128; i<128; i++) {
  for(j=-128; j<128; j++) {
    let rr = i+j;
    let er = (i+j) & 0xff;
    let ev = rr != er;
    let ec = rr > 255;
    p = 0;
    a = i;
    jadc(j);
    let r = a; 
    if (er != r) {
      console.log(i, j, er, r, ev, ec, ps(), 'FAIL');
    } else {
      console.log(i, j, er, r, ev, ec, ps(), 'OK');
    }
  }
}

function jadc(v) {
  let r = a + v;
//  a = c(n(z(r)));
  a = r & 0xff;
  if ((r & N) != (v & N))
    p |= V;
  else
    p &= ~V;
}
