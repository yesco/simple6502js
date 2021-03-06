// TODO: rename
// - webForth - taken :-(
// - jsForthm - taken :-( - have js
// - wwwFORTH WWWforth we-we-we-forth
// - FFForth F3rth Fooorth 444th
// - www4th
// - w3forth
// - w34th
// - www://forth
// - forth://wwww
// TODO: move to new repo

//
//              WORTH - Web fORTH 
//
//
//          (<) 2021 Jonas S Karlsson
//                jsk@yesco.org

function Worth(boot, opt={}) {
  var DS= [], RS= [], mem= [], Y= -1, toks, t, E, X, here=0x501;
  let typ= (o)=> typeof o,
      isF= (o)=> typ(o)=='function'?o:undefined,
      isU= (o)=> o===undefined,
      isA= (o)=> Array.isArray(o),
      isS= (o)=> typ(o)=='string'?o:undefined;
  let trace= opt.trace || 0;
  let iota= (n)=>[...Array(n).keys()];
  let u= (v)=>(DS.push(v),v),
      p= ()=>{
        if (!DS.length) throw "Stack Emtpy";
        return DS.pop()}; 
  let parse= (s)=> s
      .split(/(<[^>]*>|"[^"]*"|\S+)/)
      .filter(a=>!a.match(/^\s*$/))
      .map(a=>{let s=a.match(/^"(.*)"$/);
               return s?['lit', s[1]]:a})
      .map(a=>Number.isNaN(+a)?a:['lit',+a])
      .flat();
  let def= (name, words)=>
      (mem[name]= compile(words)).NAME=name;

  '+ - * / % ^ & | && || < <= > >= != !== == === << >> >>>'.split(' ').map(n=>
    def(n, eval(`(function(b=p(),a=p()){u(a ${n} b)})`)));
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

  def('.s', ()=>{PRINC('\nSTACK: ');pp(DS);PRINC('\n')});
  def('.st', ()=>{PRINC('\nSTACK: '+DS.map(a=>`${''+a+':'+typ(a)}`).join(' ')+'\n')});
  def('.rt', ()=>{PRINC('\nSTACK: '+RS.map(a=>`${''+a+':'+typ(a)}`).join(' ')+'\n')});

  def('!', (a=p(),v=p())=>mem[a]=v);
  def('@', (a=p())=>u(mem[a]));

  def('emit', ()=>princ(String.fromCharCode(p())));
  def('.', (n=p())=>{princ(n);princ(' ')});
  def('type', ()=>princ(p()));

  def('lit', ()=>u(toks[++Y]));
  def("'", ()=>mem['lit']());

  def(':', ()=>{
    ++Y;
    let end = toks.indexOf(';', Y)
    def(toks[Y], toks.splice(Y+1,end-Y-1));
    Y= end + 1;
  });
  def('interpret', ()=>{while(toks[Y+1])next()});
  def('trace', ()=> {u(trace);trace=p()});
  def('quit', ()=>{RS=[]; try{ X('interpret') } catch(e) { console.error(`\n% ${e} at:\n  ? ${t}`) }});
  def('execute', X= (e=p())=>next(e));
  def('eval', E= (s=p())=>{Y=-1; toks= [compile(s)]; X('quit')});

  def('here', ()=>u(here));
  def('allot', ()=>here+=p());
  def('words', ()=>Object.keys(mem).forEach(w=>mem['.'](w)));

  def('BRANCH', (y=p())=> Y= y);
  def('EXIT', ()=>[Y,toks] = RS.pop() || [-1, undefined]);

  def('typeof', ()=>u(typeof(p())));
  def('new', ()=>{t='new '+toks[++Y];u(eval(t))});

  def('see', (f=p())=>pp(f.CODE || f));
  def('append', append);
  def('sprint', (s=p())=>u(sprint(s)));
  def('$', (s=p())=>u(document.querySelector(s)));
  def('$', ()=>u(dom(p())));

  function compile(o) {
    if (isF(o)) return o; // primitive
    if (isS(o)) return compile(parse(o)); // word
    if (!isA(o)) throw `Compile unknown type ${typ(o)}`;
    if (trace >= 4) PRINC(`\nCOMPILE: ${o}\n`);
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
    if (trace > 2) PRINC('\n');
    if (trace > 2) mem['.s']();

    //princ('---TOK='+t+':'+typ(t)+'----\n');
    if (isS(t) && mem[t]) return next(mem[t]);

    // TODO: where the hell is the array coming from? (this is through execute!)
    if (isA(t) && t.length==1) t = t[0];

    if (isF(t)) {
      if (trace > 1) {PRINC('{');pp(t);PRINC('} ')}
      return t();
    }
    // TODO: move parse->dispatch to compilation!
    // .toUpperCase()  Math.sqrt()   state@  3 state!
    let [_, met, name, access]= t.match(/^([\.<]?)(.*?)([!@]?|\(\))$/);
    if (met=='<') return dom(t);
    let o= met?p():global,
        f= name.split(/\./).reduce((o,a)=>o[a], o);
    if (!access) throw 'No function';
    if (access=='!') return o[name]= p();
    else if (access!='()') return u(f);
    u(f.apply(o, iota(f.length).map(p)));
  }

  Function.prototype.toString = function(){return`${this.NAME?'':''}${this.NAME||this.name}`};

  return function EE(s) {
    if (trace >= 3) PRINC(`\nEVAL: ${s}`);
    return E(s);
  }

  ////////////////////////////////////////
  // library functions

  function princ(...s) {
    if (!trace) return;
    if (trace >= 4) PRINC('\nOUTPUT{');
    PRINC(...s);
    if (trace >= 4) PRINC('}');
    return s[0];
  }

  function sprint(s) { // "interpolate"
    return s.split(/(%)/).reverse().map((s,i)=>s.replace('%', p)).reverse().join('');
  }

  function append(s=p(), e=p()) {
    if (e.append) return u((e.append(s), e));
      u(e.concat('' + s));
  }

  function dom(h) {
    if (!h.match(/^</))
      return document.querySelector(h);

    let [_, tag, attr, nocont] = h.match(/^(\S+)\s*(.*)(\/?)>$/);
    h = sprint(h); // interpolate
    if (typeof document==='undefined')
      return u(`<${h}${''+p()}</${tag}>`);
    let e = document.createElement('span');
    e.innerHTML = h; // cheat: this sets attr!
    e = e.children[0]; // get named element
    if (!nocont) e.append(p());
    u(e);
  }

  function pp(f, indent=0) {
    if (isA(f)) {
      if (f.NAME) PRINC(f.NAME+'==');
      PRINC('[');
      f.forEach(x=>PRINC(
        isS(x)?JSON.stringify(x):x, ' '));
      PRINC(']');
    }
    else if (isS(f)) PRINC(JSON.stringify(f));
    else if (isF(f)) PRINC(f.NAME);
    else if (f) PRINC('??'+f);
    else PRINC('EXIT');
  }
}

trace= 1;

// princ arguments as strings, no spaces added
// returns first argument (for debugging)
function PRINC(...s) {
  if (trace < 0) return;
  process.stdout.write(s.join(''));
  return s[0];
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

const readline = require('readline');

function browser() {
}

function interactive(w, input=process.stdin) {
  const rl = readline.createInterface({
    input: input,
    output: process.stdout,
    prompt: '3forth> ',
  });

  function prompt(line) {
    if (trace >= 1) {
      if (line!=undefined && line.length)
        PRINC('\n'); // otherwise deletes!
      rl.prompt();
    }
  }

  prompt('foo');

  rl.on('line', (line) => {
    if (line.length) 
      w(line);
    prompt(line);
  }).on('close', () => {
    //process.exit(0);
  });
}

function program() {
  let fs= require('fs');

  let args= process.argv;

  let w, nw= ()=> w= Worth(boot, {trace});
  w = nw();

  let commands = {
    'Fn.Ext': ["Load fn.ext source", _=>0],
    '-e': ["Eval next string arg", ()=> w(args.shift())],
    '-n': ["New interpreter", nw],
    '-q': ["Quite, no pips!", ()=> trace= -1],
    '-t': ["Tracing level '-t n'", ()=> trace= parseInt(args.shift())],
    //'-d': ["Dump data using pp", ...],
    '--bye': ["Bye: exit w3forth here", ()=> process.exit()],
    '--test': ["Tests: run tests", test],
    // TODO: doesn't work this way
    // '-i': ["Interactive read-eval loop", ()=> interactive(w)],
    '-h': ["Help", ()=>{
      PRINC('w3forth - a www forth for nodejs and browser\n');
      PRINC('(>) 2021 Jonas S Karlsson, jsk@yesco.org\n\n');
      PRINC('Usage: w3forth ...\n');
      Object.keys(commands).forEach(k=>{
        PRINC(` ${k}\t${commands[k][0]}\n`);
      });
      PRINC(`
Trace levels:
 -1    quiet (-q), even princ is suppressed
  0    no prompts but explicit princ yes
  1    normal
  2    prints functions while running {fun}
  3    prints stack before function call
  4    prefixes princ with 'nOUTPUT{...}'
  5    trace arguments processing
'
`);
      process.exit();
    }],
  }
  
  let a;
  args.shift();
  args.shift();
  while (a= args.shift()) {
    let cmd= commands[a];
    if (cmd) {
      if (trace >= 4) PRINC(`\nARGUMENT: ${a} - ${cmd[0]}\n`);
      cmd[1]();
    } else if (a.match(/^-/)) {
      PRINC(`%% W3Forth: unrecognized command argument: ${a}\n  -h for help\n`);
      process.exit(1);
    } else {
      w(fs.fileReadSync(argv.shift()));
    }
  }

  interactive(w);
}

function included() {
}

// -> browser() / program / module
if (typeof document !== 'undefined') {
  brower();
} else if (typeof require !== 'undefined') {
  // nodejs
  if (!module.parent) {
    // invoked as program
    program();
  } else {
    // required by other code as module    
    included();
  }
}

//[  'trace 7 sq .',
//[  'trace aa',
//[  'aa',
//[  '7 sq .',
// ].forEach(s=>{Worth()(s);console.log()});

// R E F E R E N C E S :
// A web framework (ugly?)
// - https://www.1-9-9-1.com/ 

// G e n e r i c   S t u f f :
// Browsing Forth (ANSI compliant w js extention)
// - https://github.com/brendanator/jsForth
// - controls - https://github.com/brendanator/jsForth/blob/gh-pages/forth/forth.fth
// - Longs? - https://github.com/brendanator/jsForth/blob/gh-pages/kernel/numeric-operations.js
// webForth (forth in forth and good T{ -> } suite
// - https://github.com/mitra42/webForth/blob/master/index.js
// forth standard multi-tasking
// - https://forth-standard.org/proposals/multi-tasking-proposal#reply-186
// forth NAMING-CONVENTION
// - https://github.com/ForthHub/discussion/issues/73
// Forth Foundation Libary (forth written in ANSI)
// - https://github.com/uho/ffl
// Well documented test suite for forth
// - https://github.com/gerryjackson/forth2012-test-suite
// Event driven programming/impl in forth
// - https://github.com/bradn123/literateforth/blob/master/src/events_lit.fs

// TODO:
// - ( comment )
// - ms
// - branch? branch
// - for i j next
// - begin again
// - do i j loop
// - roll
// - parse, token, number?
// - [ ]
// - immediate
// - >body does>
// - defer
// - T{ ... -> ... }T

// - h< >
// - <TAG>
// - </TAG>
// - <tag style='foo'>
// - <tag style='${"foo" "bar" concat}'>

// TODO: brower inop
// - dom' foo
// - h<
// - dom@ dom!
// - dom:
// - >dom dom>
// -

function test() {
  let w= Worth(boot);

  gurka = 'mayo'; // global

  ['. 666', // stack underflow
   '1 2 3 . . .',
   '3 4 .s + . "bb"  dup . . "dd dd" .',
   '"foo" Math.sqrtt .',
   'drop',
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

   '1 2 : foo "FOO" . "BAR" . "FIEFUM" 3 ;',
   '8 7 : bar 5 6 ; 4 bar . . . .',
   '8 9 dup . foo . . . .',
   '"foo" see "+" see',
   '9 dup . bar . .',

   ': ab "AB" ;  : ba "BA" ;',
   'ab . ba .',

   '99 123 . : q "Q" ; 321 . .',
   '. . q .',

   '========================================',
   '"SQRT of 64" . 64 Math.sqrt() "=>" . .',
   '"EVAL of 3+4" . 3+4 "=>" . .',
   '"EVAL of global" . global@ "=>" . .',

   '"UPPERCASE of fOo" . "fOo" .toUpperCase() "=>" . .',
   '"ERROR UPPERCASE of STRING foo" . "foo" .toUpperCase() "=>" . .',

   'gurka@ . "MAYO" gurka! gurka@ .',

   '"Fish" <li> .',

   '"Fish" <li style="background:pink"> .',

   '1 2 "foo%bar%fie" sprint .',
   '"Fish" "green" <li style="background:%"> .',

   // Web Server
`8080 w3: WS

   ( methods )
   m: down  forget-it WS ;
   m: all   ws-log ;
   m: catch ws+error ;

   ( handler
         ( XX WS req [params] -- XX ... )
   )
   get:  /hello      "Hello W3orld!" ;
   get:  /123        1 2 3 ;
   get:  /iota%d     for . next ;
   get:  /           ws-index ;
   get:  /edit       ws-edit ;
   post: /submit     ws-update ;
   get:  /search?%d  ws-match-num ;
   get:  /search?%s  ws-match-word ;
   get:  /shutdown   "WS" @ :down ;
   :else             ws-error ;
 :class; 

`,
   
  // if { foo } else { bar } 
  ].forEach(s=>{console.log(`\n--- ${s}`);w(s);console.log()});
}
