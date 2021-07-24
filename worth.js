//
//              WORTH - Web fORTH 
//
//
//          (<) 2021 Jonas S Karlsson
//                jsk@yesco.org

function Worth() {
  var DS= [], RS= [], mem= [], Y= -1, toks, t, E, X, trace, here=0x501;
  let u= (v)=>(DS.push(v),v),
      p= ()=>{
        if (!DS.length) throw "Stack Emtpy";
        return DS.pop()}; 
  let parse= (s)=> s
      .split(/([^"\S]+|"[^"]*")/)
      .filter(a=>!a.match(/^\s*$/))
      .map(a=>{let s=a.match(/^"(.*)"$/);
               return s?['lit', s[0]]:a})
      .map(a=>Number.isNaN(+a)?a:['lit',+a])
      .flat();
  let princ= (...s)=>(process.stdout.write(s.join('')),s[0]);
  let typ= (o)=> typeof o,
      isF= (o)=> typ(o)=='function'?o:undefined,
      isU= (o)=> o===undefined,
      isA= (o)=> Array.isArray(o),
      isS= (o)=> typ(o)=='string'?o:undefined;
  let def= (name, words)=>
      (mem[name]= compile(words)).NAME=name;

  '+ - * / % ^ & | && || < <= > >= != !== == === << >> >>>'.split(' ').map(n=>
    def(n, eval(`(function(a=p(),b=p()){u(a ${n} b)})`)));
  def('~', ()=>u(~p()));
  def('=', ()=>u(p()===p()));

  def('drop', ()=>p());
  def('dup', ()=>u(u(p())));
  def('swap', (a=p(), b=p())=>{u(a),u(b)});
  def('over', ()=>u(DS[DS.length-2]));
  def('rot',()=>u(DS.splice(-3, 1)));
  def('nip', ()=>DS.splice(-2, 1));
  def('tuck', ()=>DS.splice(-1, 0, DS[DS.length-1]));
  def('depth', ()=>u(DS.length));

  def('>R', ()=>RS.push(p()));
  def('R>', ()=>u(RS.pop()));

  def('.s', ()=>{princ('\nSTACK: ');pp(DS);princ('\n')});
  def('.st', ()=>{princ('\nSTACK: '+DS.map(a=>`${''+a+':'+typ(a)}`).join(' ')+'\n')});
  def('.rt', ()=>{princ('\nSTACK: '+RS.map(a=>`${''+a+':'+typ(a)}`).join(' ')+'\n')});

  def('!', (a=p(),v=p())=>mem[a]=v);
  def('@', (a=p())=>u(mem[a]));

  def('emit', ()=>princ(String.fromCharCode(p())));
  def('.', ()=>{princ(p());princ(' ')});
  def('type', ()=>princ(p()));

  def('lit', ()=>u(toks[++Y]));
  def("'", ()=>mem['lit']());

  def(':', ()=>def(toks.shift(), toks.splice(0, toks.indexOf(';')-1)));
  def('interpret', ()=>{while(toks[Y+1])next()});
  def('trace', ()=>trace=!trace);
  def('quit', ()=>{RS=[]; try{ X('interpret') } catch(e) { console.error("\n", (typeof(e)==='string')?`% ${e} at`:'',`? ${t}`) }});
  def('execute', X= (e=p())=>next(e));
  def('eval', E= (s=p())=>{Y=-1; toks= [compile(s)]; X('quit')});

  def('here', ()=>u(here));
  def('allot', ()=>here+=p());

  def('BRANCH', (y=p())=> Y= y);
  def('EXIT', ()=>[Y,toks] = RS.pop() || [-1, undefined]);

  def('typeof', ()=>u(typeof(p())));
  def('new', ()=>{t='new '+toks[++Y];u(eval(t))});

  function compile(o) {
    if (isF(o)) return o; // primitive
    if (isS(o)) return compile(parse(o)); // word
    if (!isA(o)) throw `Compile unknown type ${typ(o)}`;
    // list of tokens
    let r = o.map(t=>{
      let f = mem[t];
      return (!f && t) || (isF(f) && f) || t;
    });
    r.push(mem['EXIT']);

    let rr = function ENTER(){
      RS.push([Y,toks]);
      Y= -1; toks= r;
    };
    rr.CODE = r;
    return rr;
  }

  function next(n=toks[++Y]) {
    t = n;
    if (trace > 1) mem['.s']();

    //princ('---TOK='+t+':'+typ(t)+'----\n');
    if (isS(t) && mem[t]) return next(mem[t]);

    // TODO: where the hell is the array coming from? (this is through execute!)
    if (isA(t) && t.length==1) t = t[0];

    if (isF(t)) {
      if (trace) {princ('{');pp(t);princ('} ')}
      return t();
    }
    // T.method(args...) / Mod.fun(T) / eval(T)
    let o = DS[DS.length-1];
    let f = o && o[t];
    if (isU(f)) f = eval(t);
    if (!isF(f)) return u(f);
    o = t.indexOf('.')<0 && p();
    let args = [...Array(f.length).keys()].map(p);
    return u(f.apply(o, args));
  }

  Function.prototype.toString = function(){return`${this.NAME?'':''}${this.NAME||this.name}`};
  return E;

  function pp(f, indent=0) {
    if (isA(f)) {
      if (f.NAME) princ(f.NAME+'==');
      princ('[');
      f.forEach(x=>princ(
        isS(x)?JSON.stringify(x):x, ' '));
      princ(']');
    }
    else if (isS(f)) princ(JSON.stringify(f));
    else if (isF(f)) princ(f.NAME);
    else if (f) princ('??'+f);
    else princ('EXIT');
  }
}

let boot = [
  // non-standard implementation
  // TODO: word needs to be IMMEDIATE
  //': constant word ! ;',
  //': variable here word ! 1 allot ;',

  // standard
  ': 2dup dup dup ;',
  ': cell 1 ;',
  ': cells cell * ;',
  ': cr 10 emit ;',
  ': space 32 emit ;',
  ': spaces for space next ;',
  ': ?dup dup if dup then ;',
  ': 0= 0 = ;',
  ': 0< 0 < ;',
  ': 0> 0 > ;',
  ': 1+ 1 + ;',
  ': 1- 1 - ;',
  ': 2+ 2 + ;',
  ': 2- 2 - ;',
  ': 2* 2 * ;',
  ': 2/ 2/ ;',
  ': negate -1 * ;',
  ': abs dup 0< if negate then ;',
  ': min 2dup > if swap then drop ;',
  ': max 2dup < if swap then drop ;',
  ': +! dup @ rot + swap ! ;',
  ': !+ dup rot ! 1+ ;',
  ': @+ dup 1+ swap @ ;',
//  ': variable skip ;',
//  ': constant quote :',
  ': , here ! 1 cells allot ;',
];

let w = Worth(boot);

['. 666', // stack underflow
 '1 2 3 . . .',
 '3 4 .s + . "bb"  dup . . "dd dd" .',
 '"foo" Math.sqrtt .',
 'drop',
 '"UPPERCASE of foo" . "foo" toUpperCase "=>" . .',
 '"SQRT of 64" . 64 Math.sqrt "=>" . .',
 '"EVAL of 3+4" . 3+4 "=>" . .',
 '"EVAL of global" . global "=>" . .',
 '3 4 > . 4 3 >= . 3 3 = . 4 4 == .',
 '"TYPEOF" . 3 4 == dup typeof . .',
 '"NEW array" . new Array(50) dup dup Array.isArray . typeof . .',
 '"NEW flower" . new flower(50) dup dup Array.isArray . typeof . .',
 '"SQuare 7" . 7 sq .',

//  def('sq', 'dup *');
//  def('cc', '"c" dup . 7 sq . .');
//  def('bb', '"b" dup . cc .');
//  def('aa', '"a" dup . bb .');
//  def('qq', 'aa');

 'aa',
 '1 2 3 rot . . .',
// '9 dup . 42 "foo" ! 33 . "foo" @ . .',
 '99 dup . "FISH" @ . .',
  '99 dup . 42 "FISH" ! "FISH" @ . .',

 "9 dup . ' dup . .",
 "9 dup . ' + dup . 3 4 rot execute . . 33 44 + .",

 ': foo "foo" . "bar" . "fiefum" ;',
 '9 dup . foo . .',

 ].forEach(s=>{console.log(`\n>>> ${s}`);w(s);console.log()});

//[  'trace 7 sq .',
//[  'trace aa',
//[  'aa',
//[  '7 sq .',
// ].forEach(s=>{Worth()(s);console.log()});

// REFERENCES:
// Browsing Forth (ANSI compliant w js extention)
// - https://github.com/brendanator/jsForth
// - controls - https://github.com/brendanator/jsForth/blob/gh-pages/forth/forth.fth
// - Longs? - https://github.com/brendanator/jsForth/blob/gh-pages/kernel/numeric-operations.js
