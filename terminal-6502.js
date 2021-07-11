const url = require('url');
const fs = require('fs');
const cpu6502 = require('./fil.js');
const readline = require('readline');
const utility = require('./utility.js');


// file I/O
// TODO: implement
let afopen = 0xffe0;
let aflush = 0xffe2;
let afread = 0xffe4;
let afwrit = 0xffe6;
let afclos = 0xffe8;
let afstat = 0xffea;
let afseek = 0xffec;
let afremo = 0xffee;

// terminal I/O

let aputc = 0xfff0;
let aputd = 0xfff2;
let aputs = 0xfff4;
let agetc = 0xfff6;

// 0xFFF8-  6502 hardwired vectors

let orig_maker = cpu6502.cpu6502;

function TRACE(jasm, f) {
  TRACE[jasm.address()] = f;
}

let output= 0;

function _putc(fd, ch) {
  //console.log(`\nJSK:<putc: ${fd}, ${ch}>\n`);
  if (fd >= 4) {
    throw "NIY:_putc";
    return -1;
  }

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
// optional max LEN chars
// stops if char = 0
// or after a hitbit char
//
// returns address of last char
// in string (not affected by len)
// (0 or hibit set) after where
// next insstruction is
function _puts(a, len=-1, m) {
  //process.stdout.write(' @'+hex(4,a)+' ');
  let saved_len = len;
  if (output) princ("OUTPUT.s: ");
  let c= 0;
  while((a <= 0xffff) && (c= m[a])) {
    if (len-- > 0)
      process.stdout.write(chr(c & 0x7f));
    if (len < -256) break; // give up

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
function _getc(fd) {
  if (fd >= 4) {
    let fo = _files[fd];
    if (!fo) return -2;
    let b = Buffer.alloc(1);
    // TODO: use async?
    let n = fs.readSync(fo.f, b);
    if (n<=0) return 0;
    //princ(`<${chr(b[0])}>`);
    return b[0];
  }

  // fd == 0: keyboard, non-blocking
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

// fd: 0 stdin, 1 stdout, 2 stderr
//     (all same, haha!)
// fd: 3 == CONTROL
// fd: 128>= (== 255) from fopen => ERROR
var _files = [];
var _fdnext = 4;
var _fnames = {};

// https://stackoverflow.com/questions/6287297/reading-content-from-url-with-node-js
{
  //let fd = _fopen('blockfile.4th');
  let fd = _fopen('index.html');
  if (fd !== 4) 
    throw `%%fopen blockfile.4th fd!=4==${fd}`;
}

function _fopen(name, mode) {
  let fo = _fnames[name];
  if (fo) {
    fo.mode = mode;
    // TODO: modify mode?
    return fo.fd;
  }

  if (_fdnext > 250) return -1;
  // mode - https://nodejs.org/api/fs.html#fs_file_system_flags
  // TODO: handle error
  let f = fs.openSync(name, 'r+'); 
  let fd = _fdnext++;
  fo = _files[fd] = {
    name, mode, fd, f,
  };
  _fnames[name] = fo;
  return fo.fd;
}

function _flush() {
}

function _fread() {
}

function _fwrit() {
}

function _fclos() {
}

function _fstat() {
}

function _fseek() {
}

function _fremo() {
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

  // terminal I/O
  aputc, _putc,
  aputd, _putd,
  aputs, _puts,
  agetc,

  // file I/O
  afopen, _fopen,
  aflush, _flush,
  afread, _fread,
  afwrit, _fwrit,
  afclos, _fclos,
  afstat, _fstat,
  afseek, _fseek,
  afremo, _fremo,

// terminal I/O

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
          //princ(lime);
          //princ(green);
          cpu.tracer(cpu, h);
          princ(white);
        }

        if (traceLevel > 2) {
          cpu.dump(h.ipc,1);
          // this.prinstack not work
          //c.printstack(); print("\n\n");
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
        case(aputc): _putc(cpu.reg('x'), cpu.reg('a')); break;
        case(aputd): _putd((cpu.reg('y')<<8)+cpu.reg('a')); break;
          // TODO: remove?
        case(aputs): {
          let end = _puts(
            (cpu.reg('y')<<8)+cpu.reg('a'),
            cpu.reg('x'), cpu.state().m);
          cpu.reg('a', end & 0xff);
          cpu.reg('y', end >> 8);
          break; }
        case(agetc): {
          let c= _getc(cpu.reg('x'));
          let consts= cpu.consts();
          if (c >= 0) {
            cpu.reg('a', c);
            cpu.reg('p', "g=sc(0)");
            cpu.setFlags(c);
          } else {
            // ERROR
            cpu.reg('a', 0);
            //process.stdout.write('['+c+']');
            cpu.reg('p', "g=sc(1)");
            cpu.setFlags(c);
          }

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
