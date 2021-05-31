var ds= [], rs= [];
var here= 0x0501, gere=0xb400; // ORIC ATMOS

let u= (v)=>ds.push(v),
    p=  ()=>ds.pop(),
 tuck=  ()=>ds.splice(-2, 0, ds[ds.length-1]),
  dup=  (_)=>(_=p(), u(_), u(_));
  // 'O' 'P'  

var op;

function nextop(allowed) {
  if (pc >= s.length) return;
  if (allowed && !allowed.includes(s[pc]))
    return 0;

  op = s[pc++];
  return 1;
}

function expect(allowed) {
  if (!nextop())
    throw `%% ALF.expect on of '${allowed}'\n`;
  return 1;
}

function ALF(s) {
  var pc = 0, op;
  while (nextop()) {
    switch(op) {
case ' ': longname(); break;
case '!': m[p()]= p(); break;
case '"': string(); break;
case '#': hash(); break;
case '$': dollar(); break;
case '%': t=p(); u(p() % t); break;
case '&': u(p() & p()); break;
case '\'': tick(); break;
case '(': lparen(); break;
case ')': rparen(); break;
case '*': u(p() * p()); break;
case '+': u(p() + p()); break;
case ',': t=p(); m[here++]= t&0xff; m[here++]= t>>8; break;
case '-': t=p(); u(p() - t); break;
case '.': print(p()); break;
case '/': t=p(); u(p() / t); break;
case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9': number(op); break;
case ':': colon(); break;
case ';': semicolon(); break;
case '<': u(p() >= p()); break;
case '=': u(p() == p()); break;
case '>': u(p() <= p()); break;
case '?': question(); break;
case '@': u(m[p()]);  break;
case 'A': alloc(); break;
case 'B': ni(); break;
case 'C': char(); break;
case 'D': dup(); break;
case 'E': print(String.fromCharCode(p())); break;
case 'F': t=p(); s=p(); fill(p(), s, t); break;
case 'G': u(gere); break;
case 'H': u(here); break;
case 'I': i(); break;
case 'J': j(); break;
case 'K': key(); break;
case 'L': literal(); break;
case 'M': t=p();s=p();u(t>s ? t: s); break;
case 'N': u(~p()); break;
case 'O': u(ds[ds.length-1-2]);
case 'P': u(ds[ds.length-1-p()]); break;
case 'Q': return quit(); break;
case 'R': rrr(); break;
case 'S': t=p();s=p();u(t);u(s); break;
case 'T': tuck(); break;
case 'U': uuu(); break;
case 'V': variable(); break;
case 'W': www(); break;
case 'X': ALF(p()); break;
case 'Y': yyy(); break;
case 'Z': t=p(); fill(p(),t, 0); break;
case '[': break;
case '\\': drop();  break;
case ']': break;
case '^': u(p() ^ p()); break;
case '_': u(p() | p()); break;
    }
  }
}

function longname() {
  while(nextop() && op===' ');
  return;

  // TODO: how to handle long names?
  ni();
}

function string() {
  ni();
}

function hash() {
  if (number()) return;
  // TODO: many things
  nih();
}

function dollar() {
  // hex
  let s = '';
  while (nextop('0123456789ABCDEFG'))
    s += op;
  if (s !== '')
    return u(parseInt(s, 16));

  // TODO: other string functions
  ni();
}

function tick() {
  ni();
}

function lparen() {
  ni();
}

function rparen() {
  ni();
}

function number() {
  let s = op;
  while (nextop('0123456789') !== -1) {
    s += op;
  }
  u(parseInt(s, 10));
  return 1;
}

function colon() {
  ni();
}

function semicolon() {
  ni();
}

function question() {
  ni();
}

function alloc() {
  ni();
}

function char() {
  ni();
}

function print(s) {
  // TODO: only works in nodejs
  // (document.write in browser is evil)
  process.stdout.write(s);
}

function i() {
  ni();
}

function j() {
  ni();
}

// TODO: to implement using callbacks if none?
// have ALF return a continuation?
function key() {
  ni();
}

function literal() {
}

// http://lars.nocrew.org/forth2012/core/QUIT.html
function quit() { // abort
  r= [];
  //if (nextop == '"') print string
  print("QUIT!\n");
  return;
}

function rrr() {
  if (!nextop()) return;
}

function uuu() {
  ni();
}

function variable() {
  ni();
}

function www() {
}

function yyy() {
}

function lbracket() {
}

function rbracket() {
}

function ni() {
  throw `%% ALF: No such opcode: '${op}'`;
}
 
function fill(a, len, v) {
  for(let len =p(), start=p(); len > 0;len--)
    m[a++] = v;
}


