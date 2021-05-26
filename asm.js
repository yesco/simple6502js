// A simple hex file loader/parser
// (also includes a smiple assembler)
// (C) 2021 Jonas S Karlsson jsk@yesco.org
//
// TODO: Make it work (again)!

let testing = 1;

if (0) {
  // no rom, just "screen hardare"
  let fn = process.argv[2] || PANDORIC;
  let f = fs.readFileSync(fn, 'utf8');
}

let compileOnly = 0;

if (compileOnly) {
  console.log("\nCompilation completed - no errors!!\n");
  process.exit(0);
}


// PRINCIPLES OF PARSING:
//
//   The purpose of the parsing is to generate
//   hex bytes, this is the final result, and
//   they are on the form:
//
//   HEX DATA
//     Hex data comes in two forms either 'xx'
//     which is a single byte, or 'xxxx' which
//     is interpreted as 'HiLo' which is
//     an address in big-endian (human way).
//     it becomes changed to 'Lo Hi ':
//
//     'xxxx' is 'HiLo' and becomes 'Lo Hi '
//
//       '  01 02 03      0400    '
//       '  05       0706     08 09  '
//     ===>
//       '  01 02 03      00 04    '
//       '  05       06 07     08 09  '
//
//   START ADDRESS
//     A start address can be specified on each
//     line:
//
//       '0501: 01 02 03 04'
//
//     or just
//
//       '0501  01 02 03 04  05 06 07 08'
//     
//     or
//
//       '0501'
//       '  01 02 03 04  06 07 08'
//
//     The address is always first on the line,
//     and that it's 4 characters.
//     The ':' is optional.
//
//     You may notice how this is same as
//     most monitor dump formats. Or even
//     the start of an disassemply listing's
//     output. More on that later in the section
//     of  mixed formats.
//
//   ERRORS
//
//     Any single character, as per below '7'
//     or 'a' is an error and is not accepted.
// 
//      '  01 02  7   a   '
//    
//   TODO: =xx   optional checksum operator
//
//
//
// OTHER CONSTANTS
//
//   We recognize different constants.
//   These are simply transformed to
//   single byte hex constants.
//
//   INPUT     OUTPUT OUTPUT      EXPLAIN
//   ====      =============      =======
//   #255         ff        (decimal byte)
//   ##1024       00 04         (dec word)
//   #-2          fe            (neg byte)
//   1000_0001    81                (bits)
//
//    'A'         41             (char A)
//    "ABC"       41 42 43 00   (zstring)
// (TODO:)
//    z"ABC"      41 42 43 00   (zstring)
//    a"ABC"      41 42 4         (array)
//    ~"ABC"      41 42 c3        (hibit)
//    P"ABC"   03 41 42 43       (pascal)
//    ~zP"ABC" 03 41 42 43 00       (***)
//    3"ABC"      04 xx        (Packed16)
//    $"mixed"                      (OMG)
//
//    char    = a single character
//    zstring = zero terminate c-style str
//
// (TODO: these are not implemented yet)
//    hibit   = last char has hi-bit set
//              this is a very simple but
//              efficent scheme!
//    pascal  = a pascal string stores a
//              length byte first
//    ***     = All of those above!
//    OMG     = mix 3"ABC" with "ABC"~
//    3"ABC"  = 3 chars packed in to one
//              byte! This can take any 
//              length string.
//
// (TODO:)
//    3 CHAR 2 BYTE 16 BITS PACKED STRINGS
//
//         3"ABCD"
//
//      The two bytes are encoded as:
//   
//         1aaa aaBB  BBBc cccc 
//         |     A      B     C
//         \--- continues
//
//         0ddd dd00  0000 0000
//         |    'D'   END   -
//         \--- Continuation bit
//              If set means after there
//              is another 3-2-16 pack...
//
//      Each character has 5 bits.
//      They are encoded as follows:
//
//         0 = End of string
//         1 = 'A'
//        .. =  .
//        26 = 'Z
//        27 = '_'
//        28 = '-'
//        29 = (Uppercase next char)
//        30 = (CAPS lock)
//        31 = (Next char is symbol:)
//
//           [\ -\?] (32-63)
//          ----------------
//         [ !"#$%&'()*+,-./]
//         [0123456789:;<=>?]
//
//      This encoding, if it applies
//      can save up 1/3 of space.
//      - chars assumed lowercase
//      - minimal int((n+2)/3) bytes
//      - this is good for symbol table
//
// 
// ASSEMBLY BY SIMPLE SUBSTITUTION
//
//   The assembler isn't very intelligent.
//   It basically just reads the file and
//   substitutes any given names it recognizes.
//
//   Notes how it's written 'LDA#' instead of
//   'LDA #42' and there is no '$' as everything
//   is hex. Notice how the line starts with
//   space. (This may be relaed).
//
//   ASSEMBLY INSTRUCTIONS
//     The assembly instructions are just
//     simple names macro defined as below:
//
//        = LDA# a9 ;
//        = LDAIY b1 ;
//
//     Notice how the names can be any
//     non-white space character, it just
//     need to be delimted by space.
//
//      = SAVE    PHP PHA TXA PHA TYA PHA ;
//      = RESTORE PLA TAY PLA TAX PLA PLP ;
//
//     This is how to define a macro for
//     several instructions. Macros don't
//     take any parameters.
//
//     Implementation note: The macros are
//     extracted after parenthesis comments
//     are removed. They are saved in a
//     simple dictionary. They are then
//     substituted one by one, repeatedly
//     on the whole source, until no more
//     substitutions remain. A name
//     matches ONLY if it's not part of
//     longer non-white space sequence.
//
//     'LDA#42' will give an error.
//
// ADDRESSING MODES
//
//   The macro assembly instructions,
//   are SAN (Simple Assembly Names).
//   These contain an unique mapping
//   frome name to hex bytes for
//   each mode for each instruction.
//
//       LDA (LoaD Accumulator)
//
// USE THIS     Addr Mode     (common)
// ==========   ---------     ---------
// LDA#  44     Immediate     LDA #$44
// LDAZ  44     Zero page     LDA $44
// LDAZX 44     Zero page,X   LDA $44,X
// LDAA  4400   Absolute      LDA $4400
// LDAAX 4400   Absolute,X    LDA $4400,X
// LDAAY 4400   Absolute,Y    LDA $4400,Y
// LDAXI 44     (Indirect,X)  LDA ($44,X)
// LDAIY 44     (Indirect),Y  LDA ($44),Y
//
//   Note: It doesn't check correctness;
//   for all you want this is legal
//   
//     '  LDA# NOP  (load nop)
//
//   becomes
// 
//     '  a9 ea '
//
//   Useful for code generation! LOL
//
//   So take care to get it right.
//
//   TODO: One could write a linter.
//
//
// LABELS
//   
//      LABEL:
//
//   Symbolic labels are used to say:
//   I don't know the addres of this,
//   but still remember it for me, and
//   then subsitute it everywhere.
//   Basically it's just a 'late macro'.
//
//   Notice how this conincides with
//   specifying target address
//
//   So this would be a bad label
//
//       BEEF:  NOP ( at address  0xbeef )
//
//   Here is a longer example:
//   
//             NOP
//     F42:    LDA# 42
//             TXA
//             ...
//             CPA# 42    (still 42?)
//             BNE *F42   (relative jump!)
//             ..
//             LDA# F42-1 (address of NOP!)
//             ...
//             LDX# ^F42  (hi byte of F42)
//             LDY# _F42  (lo byte)
//             ..
//             JMP F42_END
//             ...
//     F42END: RTS
//
//    Notice the forward reference,
//    Each label will be replaced by a 
//    'xxxx' 'HiLi' string later.
//    
//    Once the labels are identified.
//    Anything that isn't:
//
//      xx         (a byte)
//      xxxx       (a word)
//  
//    Must mention a label, which later
//    will be replaced. The following
//    expressions ONLY are recognized:
//
//      *F42       (* - F42 as byte)
//      F42-1      (address of NOP!)
//      F42+3      (address of TXA)
//      _F42       (low byte of F42)
//      ^F42       (hi byte)
//      
//    This is performed in a byte counting
//    routine. The output of this is a
//    list of LABELS -> address.
//
//    The labels are then substituted.
//
//    After that the expressions are
//    replaced with actual values.
//
//    Counting the bytes again should
//    give the same result.
//           
//    (The counting may not care if you
//     specify overallping addresses.
//     You have been warned!)
//       
// FUNCTIONS
//   This is an aspiring langauge compiler.
//   It therefore tries to be simple but
//   cleverly stupid. A function is defined
//   and called as follows.
//
//   (TODO:)
//       : dup (duplicate top element on stack)
//         pull
//         push
//         push
//       ;
//
//     1. Name is typically lower/CampelCase
//     2. Just use the name it'll insert JSR
//     3. No RTS needed - automatically added
//     4. To get the address use '&dup'
//        Like tail call:   'JMPA &dup'
//     5. A big surprise when assembled!
//
//   (TODO:)
//        /DICT: !DICI &dup "dup"~
//        dup:
//          JSR &pull
//          JSR &push  
//          JSR &push
//          RTS
//
// MIX DATA
//
//   In order to be flexible; to be able
//   to read various sources of input:
//   it'll be able to ignore data
//
//     '0501: ea 42   LDA# 42'
//
//     (parenthesis are nested comments
//      can be multiline and comment code:
//
//     0577: 11 22 33 44 55 66
//     = ThisIsRemoved Not use at ALL! ;
//     )
// 
// 
//     
// STAGES IN PARSING
//
//   1. Remove comments '( )'
//   3. Replace char and string constants
//   3. Extract '= ... ;' macros
//   4. Substitute macro names recursively
//   5. Byte count and find labels pos
//   6. Replace labels
//   7. Calculate label expressions
//   8. Count bytes. Should be same.
//   9. Generate [ [addr, byte, ...], ... ]
//   A. Delete local labels
//   B. Repeat and rinse with next file
//      Order matters.
//
// - All parse functions retain newlines
// - try to retain spaces
// - All stages transformation the source
// - Stages may return extra data
// - Each stage can throw specific errors
// - Errors are identified by
//   - Lines being numbered
//   - Empty lines removed
//   - The rest is printed
//   - Up to user to grok, but what remains
//     is a big clue.

function parse(f) {
  let [nocomm]     = comments(f);
  let [noconst]    = constants(nocomm);
  let [nodef, def] = macros(noconst)
  let [nomac]      = substNames(nodef);
  let [hox,on,labs]= count(nomac, byter)
  let [hax]        = substNames(labs);
  let [hcx]        = calcExpr(hax)
  let [hex,nn]     = count(hcx, error);

  if (nn != n)
    throw "Byte count changed! new=" + nn + " old=" + on;

  let chunks  = chunker(hex);
  let exports = prunedLabels();
  return [chunks, exports, macros];
}

function repeat(f, reg, fun) {
  let lastf;
  do {
    lastf = f;
    f = f.replace(reg, fun);
  } while (f != lastf);
  return f;
}

function constants(f) {
  // strings first; so they don't change!
  f = f.replace(/([\w~]*)\"(([^\"]|\\")*?)\"/g, string);

  // remove delimiters 123_436 1001_1110
  f = f.replace(/\b(([\d_]+){8,})\b/g, (a,n)=>n.replace(/_/g, ''));

  // decimals ##dec2byte #1byte (truncates)
  f = f.replace(/(?<!\S)\#\#([\d\+\-]+)/g, (a,n)=>hex(4,+n));
  f = f.replace(/(?<!\S)\#([\d\+\-]+)/g, (a,n)=>hex(2,+n));

  // binary 10011100 (8 bits)
  f = f.replace(/\b([01]{8})\b/g, (a)=>hex(2, parseInt(a ,2)));

  // illegal numbers (odd length)
  f = f.replace(/###+/g, ' ERROR(Three or more hashess)/### ');
  f = f.replace(/\b[\da-f]+\b/g, (a)=>(a.length >4 || a.length % 2 == 1) ? ' ERROR(not a valid number)/'+a+' ' : a);
  return f;
}

function hex(n,x,r=''){for(;n--;x>>=4)r='0123456789ABCDEF'[x&0xf]+r;return r};

if (testing) {
  let f =`
Hex being untouched
  35 72 xx
Decimal one byte
  #0 #1 #10 #+1 #255 #256 #-1 #65536
Decimal two bytes
  ##0 ##1 ##255 ##256 ##65535 ##65536 ##-1
Untouched
  LDA# 42   LDA#42
Binary numbers
  10000000 0100_0000 _1__1__0___1_11_00____
Chars
  'A' 'n' '#42'
Strings
  normal       "ABBA"
  zero         z"ABBA"
  pascal    P"ABBA"
  hibit        ~"ABBA"
  pas zero  Pz"ABBA"
  p z hi    zP~"ABBA"
  pack3_3      3"ABC"
  pack3_6      3"ABCDEF"
  pack3_1      3"A"
  pack3_2      3"AB"
  pack3_5      3"ABCDE"
  pack3_13     3"abcDEFGHIJMKL"
This will give errors
  Bad decimals
    ###25
    ####666
  Not one or two bytes
    12345
    dddddd
  Binary not eight digits
    101010101
  Char quote
    'Goodbye World!'
`;
  console.log(constants, f, '========>', constants(f));
}

// replace "strings" with hex bytes
// generate bytes of zero terminated string
function string(a, prefix, s) {
  console.log('string.prefix= '+prefix);
  let pascal = prefix.match(/p/i);
  let zero   = prefix.match(/z/i);
  let hibit  = prefix.match(/~/i);
  let three  = prefix.match(/3/);

  let bytes = [];
  s.replace(/([^\"]|\\")/g, (a,c,i)=>{
    console.log("STRING>>>"+s+"<<<");
    // TODO: handle other escaped characters
    if (c === '\\n"')
      c = '\n';
    else if (c === '\\t')
      c = '\t';
    else if (c === '\\"')
      c = '"';
    else if (c[0] === '\\')
      throw "%% String withou unsupported \\";

    bytes.push(c.charCodeAt(0));

    // dont'a allow newline
    // => no runaway unterminated strings
    if (c === '\n')
      throw `No newline allowed in string: please quote it using \\n >>>${s}<<<`;
    return a;
  });

  console.log("STRING.s >"+s+"<");

  if (pascal && bytes.length > 255)
    return `ERROR(Too long pascal string)/${prefix}"${s}`;
  if (three && (pascal || hibit || zero) )
    return `ERROR(Illegal three combo)/${prefix}"${s}"`;

  let len = bytes.length;
  if (pascal) bytes.unshift(len);
  if (hibit) bytes[len-1] |= 128;
  if (zero) bytes.push(0);
  if (three) console.log("THREE: ", unpack3(
    pack3(bytes).split(/\s+/).map((h)=>parseInt(h, 16)).slice(0,-1)));
  if (three) return pack3(bytes);
  console.log("STRING.bytes:", bytes);
  
  return Array.from(bytes).map((c)=>hex(2,c)).join(' ');
}

// pack 3 chars into 2 bytes pack16?
//    3 CHAR 2 BYTE 16 BITS PACKED STRINGS
//
//         3"ABCD"
//
//      The two bytes are encoded as:
//   
//         1aaa aaBB  BBBc cccc 
//         |     A      B     C
//         \--- continues
//
//         0ddd dd00  0000 0000
//         |    'D'   END   -
//         \--- Continuation bit
//              If set means after there
//              is another 3-2-16 pack...
//
//      Each character has 5 bits.
//      They are encoded as follows:
//
//         0 = End of string
//         1 = 'A'
//        .. =  .
//        26 = 'Z
//        27 = '_'
//        28 = '-'
//        29 = (Uppercase next char)
//        30 = (CAPS lock)
//        31 = (Next char is symbol:)
//
//           [\ -\?] (32-63)
//          ----------------
//         [ !"#$%&'()*+,-./]
//         [0123456789:;<=>?]
//
//      This encoding, if it applies
//      can save up 1/3 of space.
//      - chars assumed lowercase
//      - minimal int((n+2)/3) bytes
//      - this is good for symbol table
//
// Output is always multiple of 2 bytes
// (even if empty string could be [0])
// Otherwise this may not work in index lookups
// (same with illegal char - will encode EOS but will continue encoding!)
function pack3(bytes) {
  const pack3encoding = '\0ABCDEFGHIJKLMNOPQRSTUVWXYZ_-'; // 3 free
  let words = [];
  let w = 0;
  let n = 0;
  while(bytes.length) {
    if (n && (n % 3) == 0) {
      words.push(p = w | (1 << 15)); // continue
      w = 0;
    }
    n++;

    let c = String.fromCharCode(bytes.shift()).toUpperCase();
    let e = pack3encoding.indexOf(c);
    // illegal char becomes 0
    e = (e < 0) ? 0 : e;
    w = (w << 5) + e;
  }
  // push remaining
  words.push(w << (5 * (2-((n-1) % 3))));
  
  return Array.from(words).map((w)=>{
    //console.log('three: ' + w.toString(2).padStart(16, 0));
    return hex(2, w >>> 8) + ' ' + hex(2, w & 0xff) + ' ';
  }).join('')
}

// returns a string with N x 3 chars
// for "A" encoded unpack gives "A\0\0" !
function unpack3(bytes) {
  const pack3encoding = '\0ABCDEFGHIJKLMNOPQRSTUVWXYZ_-'; // 3 free
  function char(c) {
    console.log("CHAR: ", c & 31);
    return pack3encoding[c & 31];
  }
  let res = '';
  let w = 0;
  let n = 0;
  let cont = 0;
  while(bytes.length) {
    console.log("THREE: ", bytes, typeof bytes, typeof bytes[0]);
    let w = bytes.shift();
    cont = w & 128;
    w <<= 8;
    w |= bytes.shift();
    let a = char(w >> (5*2));
    let b = char(w >> (5*1));
    let c = char(w >> (5*0));
    res += a+b+c;
  }
  return res;
}

// remove comments in () nesting ok
function comments(f) {
  // repeat, remove innnermost matching first
  return replace(/\([^\(\)]*?\)/g, (a)=>{
    // keep newlines! (for error reporting....)
    return a.replace(/[^\n]/g, '');
  });
}

function macros(f) {
  // extract '=' alias
  let alias = {};
  f = f.replace(/=\s*(\S+)([\s\S]*?);/g, (a,f,l)=>{
    // call last fun defined
    alias[f] = l.trim();;

    // keep newlines! (for error reporting....)
    return a.replace(/[^\n]/g, '');
  });

  // TODO: generalize as substName!!!

  // replace now (now subst inside?)
  // (reverse to match longest first1
  // rinse and repeat until no more subst
  let lastf;
  do {
    lastf = f;
    Object.keys(alias).sort().reverse().forEach(
      n=>f=f.replace(RegExp('(?<![A-Za-z])'+n+'(?![\\w#])', 'g'), alias[n]));
  } while (f !== lastf);

  return f;
}

// extract functions (in order!)
function count(f) {
  const valids = [
    [/^[0-9a-f]{4}:/i, 0], // set address

    [/^[0-9a-f]{4}/i, 2], // hex xxxx(+...)
    [/^[0-9a-f]{2}/i, 1], // hex xxxx(+

    [/^[a-z_]\w+:$/i, 0], // label define
    [/^[a-z_]\w+$/i, 2],  // label

    [/^:[a-z_]\w+$/i, 0], // func define
    [/^[a-z_]\w+$/i, 3],  // func call

    [/^\*/, 1], // relative address
    [/^\&/, 2], // address of name func
    [/^\^/, 1], // hi 1 byte
    [/^\_/, 1], // lo 1 byte
  ];

  let nbytes = 0;
  // first format all address set to same format
  f = '\n'+f;
  f = f.replace(/\n([0-9a-f]{4}):?/g, (a,xxxx)=>xxxx+':');

  // for each space delimited value count bytes
  // NOT CHANGING IT
  f.replace(/(\S+)/g, (a, tok)=>{
    let [r, n] = valid.find((x)=>{
      return tok.match(x[0]);
    }) || [];

    console.log('Count: ', tok, r, nbytes);

    if (r) {
      nbytes += n;
    } else {
      console.log('Count.Error: no match: '+tok);
    }

    // TOOD: remove, for debug: tok/bytes
    return t + '/' + n;;
  });

  return [f, nbytes];
}

function funcs(f) {
  let nbytes = 0, nfuncs = 0;
  f = f.replace(/:\s*(\S+)([^:;]*?)\s*;/g, (a,f,l)=>{
    console.log('FUNCTION: '+f+ ' line: '+l);
    // call last fun defined
    nbytes += deffun(f, l.trim().split(/\s+/));
    nfuncs++;

    // keep newlines! (for error reporting....)
    return a.replace(/[^\n]/g, '');
  });
}

function remains(f) {  
  // any remaining stuff in f means there
  // was unmatched paren or something...
  let no = 0;
  let flno = ('\n'+f).replace(/((\n\s*)+)/g, (nlsp)=>{
    let n = nlsp.match(/\n/g).length;
    no += n; return '\n'+no+'>>> ... '; });

  f = f.replace(/\n/g, '').replace(/\s+/g, ' ');

  if (f.match(/\S/)) {
    console.log("REMAINING f================== (error)===\n", flno);
    console.log("<<<<<<<<<<<<<<<<<<<<<\n");
    console.log("NOTE: only fragment of the line remains!\n");
    console.log("NOTE: the error may be on the line before (like one too mnay ')' or ';' !\n");
    //console.error('f.length = ', f.length);
    console.error("Terminated as something remains:\n", f, "\n\n");
    process.exit(77);
  }

  return f;
}

function admin(f) {
  let HERE_INIT = deffun.HERE_INIT;
  let HERE = m[HERE_INIT+4];

  // print out for debugging
  for(let i=0; i<=5; i++) {
    let ha = (HERE_INIT+i).toString(16);
    let h = m[HERE_INIT+i].toString(16);
    console.log(ha + " HERE_INIT +"+i+" = " + h);
  }

  // if correct, then store it
  if (typeof HERE_INIT === 'number' &&
      m[HERE_INIT+0] === 0xDE &&
      m[HERE_INIT+1] === 0xAD &&
      m[HERE_INIT+2] === 0xBE &&
      m[HERE_INIT+3] === 0xEF) {
    // those locations will be overwritten
    // HERE is a zero page address where
    // to store HERE_INIT
    m[HERE+0] = HERE_INIT % 256;
    m[HERE+1] = HERE_INIT >>> 8;
  } else {
    console.log("%% ERROR: HERE_INIT not defined or not a number ("+HERE_INIT+")");
    process.exit(99);
  }
}

function dumpNames(names) {
  // dump aliases and functions/labels
  Object.keys(alias).sort().forEach(n=>{
    console.log("A: ", n.padEnd(16),
		' = ', alias[n]);
  })

  Object.keys(deffun).sort().forEach(n=>{
    if (typeof deffun[n] === 'number') {
      if (n.endsWith('_')) // local label
	n = '('+n+')';
      let len = deffun.len[n];
      len = (typeof len === 'number') ? len.toString() : '';
      console.log(
	"L: ", n.padEnd(16),
	" @ ", hex(4, deffun[n]),
	" # ", len.padStart(3));
    }
  })

  console.log('----Total bytes used: '+nbytes+ ' for '+nfuncs+' functions');
  startAddr = deffun.reset || deffun.main;
  //process.exit(33);
}
