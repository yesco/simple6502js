//
//              WORTH - Web fORTH 
//
//
//          (<) 2021 Jonas S Karlsson
//                jsk@yesco.org

function Worth() {
  var DS= [], RS= [], mem= [], Y= -1, toks= [], t, E, X, trace;
  let u= (v)=>(DS.push(v),v), p= ()=>{if(!DS.length)throw "Stack Emtpy";else return DS.pop()}; 
  let parse= (s)=> toks= s.split(/([^"\S]+|"[^"]*")/).filter(a=>!a.match(/^\s*$/)).map(a=>a.match(/^"/)?['lit',a.replace(/^"(.*)"$/, (_,s)=>s)]:a).map(a=>Number.isNaN(+a)?a:['lit',+a]).flat();
  let princ= (s)=> process.stdout.write(''+s);
  let typ= (o)=>typeof o, isF= (o)=> typ(o)=='function'?o:undefined;
  let isU= (o)=>o===undefined, isA= (o)=> Array.isArray(o), isS= (o)=> typ(o)=='string'?o:undefined;
  let def= (name, words)=> (mem[name]= compile(words)).NAME=name;
  '+ - * / % ^ & | && || < <= > >= != !== == ==='.split(' ').map(n=>
    def(n, eval(`(function(a=p(),b=p()){u(a ${n} b)})`)));
  def('~', ()=>u(~p())); def('=', ()=>u(p()===p()));
  def('drop', ()=>p());
  def('dup', ()=>u(u(p())));
  def('swap', (a=p(), b=p())=>{u(a),u(b)});
  def('over', ()=>u(DS[DS.length-2]));
  def('nip', ()=>DS.splice(-2, 1));
  def('tuck', ()=>DS.splice(-1, 0, DS[DS.length-1]));
  def('!', (v=p(),a=p())=>mem[a]=v);
  def('@', (a=p())=>mem[a]);
  def('emit', ()=>princ(String.fromCharCode(p())));
  def('.', ()=>{princ(p());princ(' ')});
  def('type', ()=>princ(p()));
  def('lit', ()=>u(toks[++Y]));
  //def(':', ()=>def(toks.shift(), toks.splice(0, toks.indexOf(';')-1)));
  def('interpret', ()=>{while(Y<toks.length)next()});
  def('trace', ()=>trace=!trace);
  def('execute', X= (e=pop())=>next(e));
  def('eval', E= (s=pop())=>{parse(s);X('quit')});
  def('quit', ()=>{RS=[]; try{ X('interpret') } catch(e) { console.error("\n", (typeof(e)==='string')?`% ${e} at`:'',`? ${t}`) }});
//  def('.s', ()=>{process.stdout.write('\n'+DS.map(a=>`${''+a+t}`).join(' ')));
//  def('.s', ()=>process.stdout.write('\n'+DS.join(', ')+' '));
  def('.s', ()=>process.stdout.write('\nS:'+JSON.stringify(DS) + ' R:' + JSON.stringify(RS)+'\n -- '));

  def('typeof', ()=>u(typeof(p())));
  def('new', (tt=t)=>{X('lit');t=tt+' '+p();u(eval(t))});

  def('BRANCH', (y=pop())=> Y= y);
  def('ENTER', (f=p())=>{RS.push([Y,toks]);Y= -1; toks= f});
  def('EXIT', ()=>{if(RS.length) [Y, toks] = RS.pop()});

  def('sq', 'dup *');

  def('cc', '"c" dup . 7 sq . .');
  def('bb', '"b" dup . cc .');
  def('aa', '"a" dup . bb .');

  // TODO: no need to deep print?
  function pp(f, indent=0) {
    if (isA(f)) {
      princ(f.NAME); princ(' [\n');
      for(let i=0; i<f.length; i++) {
        let ff= f[i];
        princ(f.NAME, indent+1);
        if (ff != mem['lit'])
          princ(' '+f[++i]+'\n');
      }
    }
  }

  function compile(o) {
    if (isF(o)) return o; // primitive
    if (isS(o) && o.match(/ /)) { // string def
      parse(o);
      return compile(toks);
    }
    if (!isA(o)) throw `Compile unknown type ${typ(o)}`;

    let r = o.map(t=>{
      let f = mem[t];
      if (f) return f;

      // dynamic runtime dispatch
      return t;
    });
    //r.push(mem['EXIT']);
    return r;
  }

  function next(n=toks[++Y], arg) {
    if (isU(n)) n=mem['EXIT'];
    t = n;
    if (trace > 1) mem['.s']();
    if (trace) process.stdout.write(` <${isF(t)?t.NAME:t}> `);

    // dispatch
    if (isF(t)) return t(arg);
    //    console.log("\n-----------------\nF.1", pp(t));

    let f = mem[t];
    if (isF(f)) return f();

    //console.log("F.2", pp(f));

    if (isA(f)) {
      //console.log("F.3", pp(f));
      return next(mem['ENTER'], f);
    }

    // try o.method or function()
    let o = DS[DS.length-1];
    if (!isU(o)) f = o[t];
    // eval?
    if (isU(f)) f = eval(t);
    if (!isU(f)) return u(f);

    if (isF(f)) try {
        // fixed func or oo
        let o = t.indexOf('.')<0 ? p() : null;
        let args = [...Array(f.length).keys()].map(p);
        return u(f.apply(o, args));
    } catch(e) {
      throw e;
    }
    throw `Object ${o}: ${typeof o}`;
  }

  return E;
}

['. 666', // stack underflow
 '1 2 3 . . .',
 '3 4 .s + . "bb"  dup . . "dd dd" .',
 '"foo" Math.sqrtt .',
 '"UPPERCASE of foo" . "foo" toUpperCase "=>" . .',
 '"SQRT of 64" . 64 Math.sqrt "=>" . .',
 '"EVAL of 3+4" . 3+4 "=>" . .',
 '"EVAL of global" . global "=>" . .',
 '3 4 > . 4 3 >= . 3 3 = . 4 4 == .',
 '"TYPEOF" . 3 4 == dup typeof . .',
 '"NEW array" . new Array(50) dup dup Array.isArray . typeof . .',
 '"NEW flower" . new flower(50) dup dup Array.isArray . typeof . .',
 '"SQuare 7" . 7 sq .',
 'aa',
 ];//.forEach(s=>{Worth()(s);console.log()});

[  'trace 7 sq .',
   ].forEach(s=>{Worth()(s);console.log()});
