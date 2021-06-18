const cpu6502 = require('./fil.js');
const readline = require('readline');
const utility = require('./utility.js');

let aputc = 0xfff0;
let aputd = 0xfff2;
let aputs = 0xfff4;
let agetc = 0xfff6;

let orig_maker = cpu6502.cpu6502;

function TRACE(jasm, f) {
  TRACE[jasm.address()] = f;
}

let output= 0;

function _putc(ch) {
  if (typeof ch==='number')
    c = chr(ch);
  else
    ch = ord(c);

  if (output) princ("OUTPUT.c: ");
  process.stdout.write(c);
  if (output)
    print(`    (\$${hex(2,ch)})`);
}

// print string from ADDRESS
// optinal max LEN chars
// stops if char = 0
// or after a hitbit char
//
// returns address of last char
// in string (not affected by len)
// (0 or hibit set) after where
// next insstruction is
function _puts(a, len=-1, m) {
  let saved_len = len;
  if (output) princ("OUTPUT.s: ");
  let c= 0;
  while((a <= 0xffff) && (c= m[a])) {
    if (len-- > 0)
      process.stdout.write(chr(c & 0x7f));

    if (c > 127) break;
    a++;
  }

  // for OMG-strings skip (BRK) one more
  if (!m[a+1]) a++;
 
  if (output) print();

  return a;
}

function _putd(d) {
  if (output) princ("OUTPUT.d: ");
  process.stdout.write(''+d+' ');
  if (output) print();
}

// return 0 if no key
function _getc() {
  if (!keybuf.length) return 0;
  let key = keybuf.shift();
  if (!key) return 0;
  return key;
}

// on some computers a key is put in a memory
// location (ORIC ATMOS):

// array of integer char codes
var keybuf = [];

// simulate keystroke
function sendKey() {
  // key not yet consumed
  if (cpu.mem[KEYADDR] & 128)
    return;

  let key = keybuf.shift();
  if (!key) return;

  cpu.mem[KEYADDR] = 128 + key;
}	

// set up capture of key strokes
readline.emitKeypressEvents(process.stdin);
process.stdin.setRawMode(true);

function exit(key, k) {
  console.log();
  console.log();
  console.log('='.repeat(50));
  console.log("KEY=", key);
  console.log("k=", k);
  console.log("CTRL-C: Exiting...");
  process.exit();
}

process.stdin.on('keypress', (str, key) => {
  if (key.ctrl && key.name === 'c') {
    exit(key);
  } else {
    //console.log("KEY=", key, key.sequence);
    let k, seq = key.sequence;
    if (key.meta) {
      k = seq[seq.length-1].toUpperCase().charCodeAt(0);
      k |= 0x80;
    } else {
      k = seq.charCodeAt(0);
    }
    // ALT-BACKSPACE
    if (k === 255) {
      exit(key, k);
    }
    // assume get onle one key
    keybuf.push(k);
    //sendKey();
  }
});

// 100 times a second
//setInterval(sendKey, 10);

// TODO: some shit going on here with
// object scope and this???
var a2l;
var traceLevel;

// extend and patch
let tcpu = {
  ...cpu6502,
  // extend
  aputc, _putc,
  aputd, _putd,
  aputs, _puts,
  agetc,

  TRACE,

  cpu6502: function(...r){
    let cpu = orig_maker(...r);
    return {
      ...cpu,

      orig_cpu: cpu,
      
      // Doesn't seem to be this.traceLevel forall...
      setOutput(n) {
        output= n;
      },

      traceLevel: 0,
      setTraceLevel(n) {
        traceLevel = this.traceLevel = n;
      },

      output: 0,
      setOutput(n) {
        output = n;
      },

      a2l: undefined,
      setLabels(l) {
        // generate symbol information
        this.labels = l;
        this.a2l = {};
        Object.keys(l).forEach(k=>
          this.a2l[l[k]]= k);
        a2l = this.a2l;
      },

      timer: undefined,

      stop() {
        if (!timer) return;
        cancelTimout(timer);
        timer = undefined;
        return true;
      },

      // (called after instruction)
      tracer(c, h) {
        // quit at BRK? unless it's trapped!
//        if (h.op==0) {
//          return 'quit';
//        }

        //if (!this.traceLevel) return;
        if (!traceLevel) return;

        if (traceLevel > 1) {
          princ(gray);
          princ(lime);
          cpu.tracer(cpu, h);
          princ(white);
        }

        if (traceLevel > 2) {
          cpu.dump(h.ipc,1);
          // this.prinstack not work
          c.printstack(); print("\n\n");
        }

        // WTF?
        if (this.a2l && traceLevel) {
          l = this.a2l[h.d];
          if (l) {
            print("                      @ ", l);
          }
        }
        if (a2l && traceLevel) {
          l = a2l[h.d];
          if (l) {
            print("                      @ ", l);
          }
        }
      },

      // install traps for putc!
      // (called before instruction)
      patch(pc, m, cpu) {
        (TRACE[pc] || (()=>0))();

        let op= m[pc], d;

        // WTF?
        if (this.a2l && traceLevel) {
          let l = this.a2l[pc];
          if (l) {
            print("\n---------------> ", l);
          }
        }
        if (a2l &&  traceLevel) {
          let l = a2l[pc];
          if (l) {
            print("\n---------------> ", l);
          }
        }

        // get effective address
        switch(op) {
        case 0x4c: // jmpa
        case 0x20: d= cpu.w(pc+1); break; // jsra
        case 0x6c: d= cpu.w(cpu.w(pc+1)); break; // jmpi
          // case 0x40: case 0x60: // TODO: rts/rti - look on stack?
        default: return;
        }

        // traps
        switch(d) {
        case 0xfff0: _putc(cpu.reg('a')); break;
        case 0xfff2: _putd((cpu.reg('y')<<8)+cpu.reg('a')); break;
        case 0xfff4: {
          let end = _puts(
            (cpu.reg('y')<<8)+cpu.reg('a'),
            cpu.reg('x'), m);
          cpu.reg('a', end & 0xff);
          cpu.reg('y', end >> 8);
          break; }
        case 0xfff6: {
          let c= _getc();
          cpu.reg('a', c);
          let consts= cpu.consts();
          cpu.setFlags(c);
          if (c){
            //process.stdout.write('['+c+']');
          }
          break;
        }
        ///////////////////////////////////
        case 0xfff8: return; // ABORT 6502C
        case 0xfffa: return; // NMI
        case 0xfffc: return; // RESET
        case 0xfffe: return; // IRQ/BRK
        default: return;
        }

        // just go to next instruction
        cpu.reg('pc+=3'); 
        
        // for jsr - no need to rts
        if (0x20) return 1; 

        // if jmpa jmpi - simulate rts!
        d= PL()+(PL()<<8);
        cpu.reg('pc',d);
        return 1;
      },

      // patch extend
      run(count=-1, trace, patch) {
        trace = this.tracer || trace;
        patch = this.patch || patch;

        if (count < 0) { // would block

          this.timer = setInterval(function(){
            cpu.run(1000, trace, patch);
          }, 10);
          
        } else {
          return cpu.run(count, trace, patch);
        }
      },

    };
  },
  
};

module.exports = tcpu;
