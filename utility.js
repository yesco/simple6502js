//                 Utility
//                    -
//         make JS not being COBOL!
//               (Type less)
//
//          (>) Jonas S Karlsson
//              jsk@yesco.org
//

function ord(c) {
  return c.charCodeAt(0);
}

function chr(c) {
  return String.fromCharCode(c);
}

function print(...r) {
  return console.log(...r);
}

function princ(s) {
  return process.stdout.write(''+s);
}

function nl() {
  console.log();
}

function hex(n, x) {
  let r='';
  for(;n--;x>>=4)
    r='0123456789ABCDEF'[x&0xf] + r;
  return r;
};


////////////////////////////////////////
// ANSI

// - https://github.com/TooTallNate/ansi.js/blob/master/lib/ansi.js
// Why not use? Don't want external dependencies
// and don't want that interface. Just want the
// strings

// xterm/ansi
let BLACK= 0, RED= 1,     GREEN= 2, YELLOW= 3,
    BLUE=  4, MAGNENTA=5, CYAN=  6, WHITE=  7;

function cll() { return ereaseinline(2); }
function cleol() { return ereaseinline(0); }
function clbol() { return ereaseinline(1); }

function cls() { return ereaseinline(2); }
function cleos() { return ereaseinline(0); }
function clbos() { return ereaseinline(1); }

// 0 end 1 before 2 all
function eraseindisplay(n=0) { return'[J'; }
function eraseinline(n=0) { return'[K'; }

function home() { return gotorc(0, 0); }
function gotorc(r=0, c=0) { return '['+r+';'+c+'H'; }

function up() { return'[A'; }
function down() { return'[B'; }
function forward() { return'[C'; }
function back() { return'[D'; }
function nextline() { return'[E'; }
function prevline() { return'[F'; }
function gotoc(c=0) { return'['+c+'G'; }

function scrollup() { return'[S'; }
function scrolldown() { return'[T'; }

function getpos() { return'[6n'; }

function hide() { return '[?25h'; }
function show() { return '[?25l'; }

function cursorSave() { return '7'; }
function cursorRestore() { return '8'; }

function fg(c=WHITE) { return '[3'+c+'m'; }
function bg(c=BLACK) { return '[4'+c+'m'; }

let amber     = '[38;5;214m',
    black     = nobold()+fg(BLACK),
    darkgray  =   bold()+fg(BLACK),
    red       =   bold()+fg(RED),
    darkred   = nobold()+fg(RED),
    green     =   bold()+fg(GREEN),
    lime      = nobold()+fg(GREEN),
    yellow    =   bold()+fg(YELLOW),
    brown     = nobold()+fg(YELLOW),

    blue      =   bold()+fg(BLUE),
    darkblue  = nobold()+fg(BLUE),
    magnenta  =   bold()+fg(MAGNENTA),
    darkmagnenta = nobold()+fg(MAGNENTA),
    cyan      =   bold()+fg(CYAN),
    darkcyan  = nobold()+fg(CYAN),
    white     =   bold()+fg(WHITE),
    gray      = nobold()+fg(WHITE);

function bold() { return '[1m'; }
function italic() { return '[3m'; }
function underline() { return '[4m'; }
function inverse() { return '[7m'; }

function nobold() { return '[22m'; }
function noitalic() { return '[33m'; }
function nounderline() { return '24m'; }
function noinverse() { return '[27m'; }

function reverse() { return '\033[?5l'};
function noreverse() { return '\033[?5h'};

// you can only turn all off! :-(
function off(){ return'[m'; }

////////////////////////////////////////
////////////////////////////////////////

ansi = {
  BLACK, RED, GREEN, YELLOW,
  BLUE, MAGNENTA, CYAN, WHITE,
  fg, bg,

  amber,
  black, darkgray,
  red, darkred,
  green, lime,  
  yellow, brown,  

  blue, darkblue,
  magnenta, darkmagnenta,
  cyan, darkcyan,
  white, gray,
  
  bold, italic, underline, inverse,
  nobold, noitalic, nounderline, noinverse,
  reverse, noreverse,

  cls, home, gotorc,
  up, down, forward, back,
  nextline, prevline,
  gotoc,

  /*cls,*/ cleos, clbos,
  cll, cleol, clbol, 

  eraseindisplay, eraseinline,

  scrollup, scrolldown, getpos,

  hide, show, cursorSave, cursorRestore,
  off,
};
  
module.exports = {
  ord, chr, print, princ, nl, hex,
  ansi,
  ...ansi, // Flatten lol
};

// BAD practice!
//
// "export to global"

Object.keys(module.exports).forEach(k=>
  global[k] = module.exports[k]);

