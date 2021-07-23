//
//              WORTH - Web fORTH 
//
//
//          (<) 2021 Jonas S Karlsson
//                jsk@yesco.org

function Worth() {
  var DS= [], RS= [], mem= [], toks= [], t, E, X, trace;
  let u= (v)=>(DS.push(v),v), p= ()=>{if(!DS.length)throw "Stack Emtpy";else return DS.pop()}; 
  let parse= (s)=>toks=s.split(/([^"\S]+|"[^"]*")/).filter(a=>!a.match(/^\s*$/)).map(a=>a.match(/^"/)?['lit',a.replace(/^"(.*)"$/, (_,s)=>s)]:a).map(a=>Number.isNaN(+a)?a:['lit',+a]).flat();
  let princ= (s)=> process.stdout.write(''+s);
  let def= (name, words)=>mem[name]=compile(words);
  let compile = (words)=>words;
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
  def('lit', ()=>u(toks.shift()));
  def(':', ()=>def(toks.shift(), toks.splice(0, toks.indexOf(';')-1)));
  def('interpret', ()=>{while(toks.length)next()});
  def('trace', ()=>trace=!trace);
  def('execute', X= (e=pop())=>next(e));
  def('eval', E= (s=pop())=>{parse(s);X('quit')});
  def('quit', ()=>{RS=[]; try{ X('interpret') } catch(e) { console.error("\n", (typeof(e)==='string')?`% ${e} at`:'',`? ${t}`) }});
//  def('.s', ()=>{process.stdout.write('\n'+DS.map(a=>`${''+a+t}`).join(' ')));
//  def('.s', ()=>process.stdout.write('\n'+DS.join(', ')+' '));
  def('.s', ()=>process.stdout.write('\nS:'+JSON.stringify(DS) + ' R:' + JSON.stringify(RS)+' >> '));

  def('typeof', ()=>u(typeof(p())));
  def('new', (tt=t)=>{X('lit');t=tt+' '+p();u(eval(t))});

  function next(n=toks.shift()) {
    t = n;
    if (trace > 2) X('.s');
    if (trace) process.stdout.write(` [ ${t} ] `);
    let f = mem[t];
    if (typeof f === 'function') return mem[t]();

    // try o.method or function()
    let o = DS[DS.length-1];
    if (typeof o !== 'undefined') f = o[t];
    if (typeof f === 'undefined') f = eval(t);
    if (typeof f === 'function') try {
        // fixed func or oo
        let o = t.indexOf('.')<0 ? p() : null;
        let args = [...Array(f.length).keys()].map(p);
        return u(f.apply(o, args));
    } catch(e) {
      throw e;
    }
    // we did eval it. What did we get?
    if (typeof f !== 'undefined') return u(f);
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
 ].forEach(s=>{Worth()(s);console.log()});
