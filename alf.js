// TODO: make it in C
// TODO: make memory model changeable
//       (6502 64K, word computer, hardward,
//        string computer)
// TODO: assumption seems to be a "long machine"
// TODO: make it 64K byte addressable
let SIZE= 32768;
var ds= [], rs= [], m= Array(32768);
var here= 0x0501, gere=0xb400; // ORIC ATMOS, lol

let u= (v)=>ds.push(v),
    p=  ()=>ds.pop(),
 tuck=  ()=>ds.splice(-2, 0, ds[ds.length-1]),
  dup=  (_)=>(_=p(), u(_), u(_)),

  toR=  (...l)=>l.forEach(v=>rs.push(v)),
fromR=  ()=>rs.pop,
    R=  (n)=>rs[rs.length-1-n];

function ALF(program) {
  var pc = 0, op, num= 0;

  print('program: ', program);

  function nextop(allowed) {
    if (pc >= program.length) return;
    if (allowed && !allowed.includes(program[pc]))
      return '';

    //  return op = s[pc++];
    op = program[pc++];
    return op;
  }

  function expect(allowed) {
    if (!nextop(allowed))
      throw `%% ALF.expect on of '${allowed}'\n`;
    return op;
  }

  while (nextop()) {
    num--;
    print('nextop: ', op, {pc, ds, rs, num});
    switch(op) {
case '': return;
case ' ': longname(); break;
case '!': m[p()]= p(); break;
case '"': t=''; u(string()); break;
case '#': hash(); break;
case '$': dollar(); break;
case '%': t=p(); u(p() % t); break;
case '&': u(p() & p()); break;
case "'": nextop(); u(op.charCodeAt(0)); break;
case '(': toR(pc, 0); break;
case ')': toR(fromR()+1, pc= fromR()); break;
case '*': u(p() * p()); break;
case '+': u(p() + p()); break;
case ',': t=p(); m[here++]= t&0xff; m[here++]= t>>8; break;
case '-': t=p(); u(p() - t); break;
case '.': princ(''+p()); break;
case '/': t=p(); u(p() / t); break;
case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
      u((num>=0?p()*10:0) +ord(op)-ord('0')); num= 1; break;
case ':': colon(); break;
case ';': semicolon(); break;
case '<': u(p() >= p()); break;
case '=': u(p() == p()); break;
case '>': u(p() <= p()); break;
case '?': t=p(); if (p()) ALF(t); break;
case '@': u(m[p()]);  break;
case 'a': alloc(); break;
case 'b': ni(); break;
case 'c': char(); break;
case 'd': dup(); break;
case 'e': princ(chr(p())); break;
case 'f': t=p(); s=p(); fill(p(), s, t); break;
case 'g': u(gere); break;
case 'h': u(here); break;
case 'i': u(R(1)); break;
case 'j': u(R(3)); break;
case 'k': key(); break;
case 'l': literal(); break;
case 'm': t=p();s=p();u(t>s ? t: s); break;
case 'n': u(-p()); break;
case 'o': u(ds[ds.length-1-2]);
case 'p': u(ds[ds.length-1-p()]); break;
case 'q': return quit(); break;
case 'r': rrr(); break;
case 's': t=p();s=p();u(t);u(s); break;
//case 't': tuck(); break;
case 'u': uuu(); break;
//case 'v': variable(); break;
case 'w': www(); break;
// TODO: make char, or if address make string?
case 'x': ALF(p()); break;
case 'y': yyy(); break;
case 'z': t=p(); fill(p(),t, 0); break;
case '[': ni(); break;
case '\\': p(); break;
case ']': fromR(); fromR(); break;
case '^': u(p() ^ p()); break;
case '|': u(p() | p()); break;
case '_': ___(); break;
case '{': u(curly()); break;
case '}': ni(); break;
case '`': ni(); break;
case '~': u(~p()); break;
    }
  }

  function ord(c) { return c.charCodeAt(0)}
  function chr(c) { return String.fromCharCode(c)}
  function print(...x){ return console.log(...x)}
  function princ(s) { process.stdout.write(''+s)}


  function longname() {
    return;

    // TODO: longname?
    while(nextop() && op===' ');
    return;

    // TODO: how to handle long names?
    ni();
  }

  // parse nested { abc { foo } ... }
  function curly() {
    let s= '';
    while(nextop()) {
      if (op==='}') return s;
      else if (op==='{') s+= '{'+curly()+'}';
      else if (op==='"') s+= '"'+string()+'"';
      else s+= op;
    }
    return op;
  }

  function string() {
    let s= '';
    while(nextop()!='"') s+= op;
    return s;
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

    switch(op) {
    case '.': princ(p().toString(16)); break;
    case 't': princ(p()); break;
    default: ni(); break;
    }
  }

  function number() {
    let s = op;
    while (nextop('0123456789'))
      s += op;
    console.log('number: ', s);
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
    here+= p();
  }

  function char() {
    ni();
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
    switch(nextop()) {
    case '<': toR(p()); break;
    case '>': u(fromR()); break;
    case '@': u(R(0)); break;
    }
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

}

// main

ALF('3 4+. 77 33 + {2*{10000+}x} x 11 1 {123*} ? 3333');

console.log();
console.log({ds, rs});
