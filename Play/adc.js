function adc(v) {
  // TODO: set overflow?
  let oa= a;
  a= n(z(c(a + v + (p & C))));
  if ((a & N) != (oa & N)) p |= V; else p &= ~V;
  if (~p & D) return; else c(0);
  if ((a & 0x0f) > 0x09) a+= 0x06;
  if ((a & 0xf0) <= 0x90) return;
  a+= 0x60;
  sc(1);
}

function sbc(v) {
  // TODO: set overflow?
  let oa= a;
  a= a - v - (1-(p & C))
  sc( a>= 0 );
  a= z(n(a & 0xff));
  if ((a & N) != (oa & N)) p |= V; else p &= ~V;
  //if ((oa^a) & (v^a)) ...
  if (~p & D) return; else sc(0);
  if ((a & 0x0f) > 0x09) a+= 0x06;
  if ((a & 0xf0) <= 0x90) return;
  a+= 0x60;
  sc(1);
}

// function adc(v) {
//   v&= 0xff;
//   // TODO: set overflow?
//   let oa= a;
//   console.log('\n\n\t=A=', a, v, p&C);
//   a= z(n(c(a + v + (p & C))));
//   console.log('_\tA=', a, p&Z);
//   if ((a & N) != (oa & N)) p |= V; else p &= ~V;
//   //if ((oa^a) & (v^a)) ...
//   if (~p & D) return; else sc(0);
//   if ((a & 0x0f) > 0x09) a+= 0x06;
//   if ((a & 0xf0) <= 0x90) return;
//   a+= 0x60;
//   sc(1);
// }

// function sbc(v) {
//   v= ~v;
//   v&= 0xff;
//   // TODO: set overflow?
//   let oa= a;
//   console.log('\n\n\t=A=', a, v, p&C);
//   a= a - v - (p & C)
//   sc( a>= 0 );
//   a= z(n(a & 0xff));
//   console.log('_\tA=', a, p&Z);
//   if ((a & N) != (oa & N)) p |= V; else p &= ~V;
//   //if ((oa^a) & (v^a)) ...
//   if (~p & D) return; else sc(0);
//   if ((a & 0x0f) > 0x09) a+= 0x06;
//   if ((a & 0xf0) <= 0x90) return;
//   a+= 0x60;
//   sc(1);
// }

var a= 0, x= 0, y= 0, p= 0, s= 0, pc= 0, m= new Uint8Array(0xffff + 1);

let C= 0x01, Z= 0x02, I= 0x04, D= 0x08, B= 0x10, Q= 0x20, V= 0x40, N= 0x80;

function ps(i=7,v=128,r=''){for(;r+=p&v?'CZIDBQVN'[i]:' ',i--;v/=2);return r};

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



for(i=-128; i<128; i+=16) {
  for(j=-128; j<128; j+=16) {
//for(i=0; i<256; i+=16) {
//  for(j=0; j<256; j+=16) {
    let rr = i-j;
    let er = (i-j) & 0xff;
    let ev = rr != er;
    let ec = rr > 255;
    p = 0; // CLC
    a = i;
    sc(1); sbc(j); // SBC/CMP
    aa = a;
    ppss = ps();
    _n = p&N;
    console.log('\t\t\t\t', ps());
    a = p; // PHP,PLA
    a = c(n(z((a<<1) + p&C))); // ROL
    aps = ps();
    //console.log(p);
    a &= 1; // AND #1
    //sc( !! (c&p) );
//    sc(0);
//      sc ( !!(p&C) );
    sbc(0); // SBC #0
//    console.log(`${rr}=\t${i}\t${j}\t=>${aa}\tS:${aa&128?-(((~aa)+1)&0xff):aa}\t${ppss}`);
    console.log(`${rr}=\t${i}\t<=>\t${j}\t=> ${a}\t${ppss} (${aps})`);
  }
}

let foo=`
    jadc(j);
    let r = a; 
    if (er != r) {
      console.log(i, j, er, r, ev, ec, ps(), 'FAIL');
    } else {
      console.log(i, j, er, r, ev, ec, ps(), 'OK');
    }
  }
`;

function jadc(v) {
  let r = a + v;
//  a = c(n(z(r)));
  a = r & 0xff;
  if ((r & N) != (v & N))
    p |= V;
  else
    p &= ~V;
}


// relative clear description
// - https://github.com/docmarionum1/py65emu/blob/master/py65emu/cpu.py

let python =`
def ADC(self, v2):
        v1 = self.r.a

        if self.r.getFlag('D'):  # decimal mode
            d1 = self.fromBCD(v1)
            d2 = self.fromBCD(v2)
            r = d1 + d2 + self.r.getFlag('C')
            self.r.a = self.toBCD(r % 100)

            self.r.setFlag('C', r > 99)
        else:
            r = v1 + v2 + self.r.getFlag('C')
            self.r.a = r & 0xff

            self.r.setFlag('C', r > 0xff)

        self.r.ZN(self.r.a)
        self.r.setFlag('V', ((~(v1 ^ v2)) & (v1 ^ r) & 0x80))

def SBC(self, v2):
        v1 = self.r.a
        if self.r.getFlag('D'):
            d1 = self.fromBCD(v1)
            d2 = self.fromBCD(v2)
            r = d1 - d2 - (not self.r.getFlag('C'))
            self.r.a = self.toBCD(r % 100)
        else:
            r = v1 - v2 - (not self.r.getFlag('C'))
            self.r.a = r & 0xff

        self.r.setFlag('C', r >= 0)
        self.r.setFlag('V', ((v1 ^ v2) & (v1 ^ r) & 0x80))
        self.r.ZN(self.r.a)

`;
