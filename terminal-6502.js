let cpu6502 = require('./fil.js');

let aputc = 0xfff0;
let aputd = 0xfff2;
let aputs = 0xfff4;
let agetk = 0xfff6;

let orig_maker = cpu6502.cpu6502;

function TRACE(jasm, f) {
  TRACE[jasm.address()] = f;
}

function _putc(c) {
  if (this.output) princ("OUTPUT: ");
  process.stdout.write(chr(c));
  if (this.output) print();
}

// print string from ADDRESS
// optinal max LEN chars
// stops if char=0 or char hi-bit set.
function _puts(a, len=-1, m) {
  if (this.output) princ("OUTPUT: ");
  let c = 0;
  while(len-- && (c < 128) && (c=m[a++]))
    process.stdout.write(chr(c));
  if (this.output) print();
}

function _putd(d) {
  if (this.output) princ("OUTPUT: ");
  process.stdout.write(''+d+' ');
  if (this.output) print();
}

function chr(c) { return String.fromCharCode(c) }

// extend and patch
let tcpu = {
  ...cpu6502,
  // extend
  aputc,
  aputd,
  aputs,
  agetk,

  TRACE,

  cpu6502: function(...r){
    let cpu = orig_maker(...r);
    return {
      ...cpu,

      orig_cpu: cpu,
      
      traceLevel: 0,
      setTraceLevel(n) {
        this.traceLevel = n;
      },

      output: 0,
      setOutput(n) {
        this.output = n;
      },

      // patch extend
      run(count, trace, patch) {
        return cpu.run(count, this.tracer, this.patch);
      },

      // (called after instruction)
      tracer(c, h) {
        // quit at BRK? unless it's trapped!
        if (h.op==0) {
          return 'quit';
        }

        if (!this.traceLevel) return;

        let l = a2l[h.ipc];
        if (l) {
          print("\n---------------> ", l);
        }

        if (this.traceLevel > 1)
          cpu.tracer(cpu, h);
        if (this.traceLevel > 2) {
          cpu.dump(h.ipc,1);
          printstack(); print("\n\n");
        }

        l = a2l[h.d];
        if (l) {
          print("                      @ ", l);
        }
      },

      printstack() {
        let x = cpu.reg('x');
        princ(`  DSTACK[${(0x101-x)/2}]: `)
        x--;
        while(++x < 0xff) {
          princ(hex(4, cpu.w(x++)));
          princ(' ');
        }
        print();
      },

      // install traps for putc!
      // (called before instruction)
      patch(pc, m, cpu) {
        (TRACE[pc] || (()=>0))();

        let op= m[pc], d;

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
        case 0xfff4: _puts((cpu.reg('y')<<8)+cpu.reg('a'), cpu.reg('x'), m); break;
        case 0xfff6: _getc(); break; // TODO:
          ////////////////////////////////////////
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

    };
  },
  
};

module.exports = tcpu;
