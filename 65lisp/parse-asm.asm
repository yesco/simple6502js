;;; (C) 2025 jsk@yesco.org (Jonas S Karlsson)
;;; 
;;; ALL RIGHTS RESERVED
;;; - Generated code/tap-files are free, of course!


;;; TITLE
;;; 
;;; A 6502 Recursive Descent Data-Driven
;;; BNF-Parser as C Program Compiler
;;; 
;;; 
;;; It interprets a BNF-description of a programming
;;; language while reading and matching it with a
;;; source text of that langauge. The BNF contains
;;; generative "templated" rules of code generation,
;;; minimal instrumentation, that generates runnable 
;;; machine code.
;;;
;;; There are "token"-matchers: as %D to parse
;;; constants; %V %A %N %U to match vars/fun names
;;; giving addresses and enabling scope management.
;;; 
;;; The generative directives allow for substitutions
;;; of bytes: < > lo and hibyte; +> for one address
;;; higher; ':' ';' '{{' for code address manipulations;
;;; D d for value juggling.
;;; 
;;; A hack %{ is available to inject and run immediate
;;; code during parsing enabling experimential 
;;; features, like matching a byte value, or enabling
;;; partial (constant) expression evaluations.
;;; 

;;; 
;;; GOALS:
;;; - an actual machine 6502 compiler running on 6502
;;; - be a "proper" subset of C (at least syntactically)
;;; - *minimal* sized BNF-engine as well as rules
;;;   keeping the whole "compiler" in about 1-2KB!
;;; - fast "enough" to run "on a screen of code"
;;;   (~ 133 "ops" compiled/s ~ 19 lines/s) - LOL
;;;   (Turbo Pascal did 2000 lines in less than 60s)
;;;   (== 33 lines/s)
;;; - provide on-screen editor
;;; - "simple" rule-driven
;;; - many languages (just change rules)
;;; - have MINIMAL subset
;;; - have OPTRULES extentions for efficient codegen
;;; - somewhat useful error messages
;;;   (difficult w recursive descent BNF style parsing)
;;; 

;;; 
;;; NON-Goals:
;;; - not be the best super-optimizing compiler
;;; - not be the fastest
;;; - no constant folding (yet)
;;; 

;;; 
;;; The MINIMAL C-language subset:
;;; - types: word (uint_16) [limited: char (uint_8) void]
;;; - casting syntax
;;; 
;;; - decimal numbers: 4711 42
;;; - char constants: 'x' ''' (lol) '\' hmmm TODO: fix
;;; - "string" constants (== number for printing)
;;; 
;;; - word main() ... - no args
;;; - { ... }
;;; 
;;; - a= b+10;
;;; - + - *2 /2 >> << & | ^ == <   (TODO: ! && || ? != > <= >=)
;;; - &v *v
;;; - since we don't have priorities, maybe require
;;;   parenthesis around each operator if nested?
;;;      n=r*40;
;;;      n=r>>2+r>>3;       // 40 Bytes
;;;      n=(((r>>2)+r)>>3); // "compatible C"
;;;      n := r>>2+r>>3;    // PASCALish
;;;      n := r.>>2.+r.>>3;    // PASCALish
;;; 
;;; - return [...];
;;; - if () statement; [else statement;]
;;; - label:
;;; - goto label;
;;; - do ... while();
;;; - while() ...
;;; 
;;; - putchar(c); getchar();
;;; - putu(42); puth(666); putz("foo"); puts("bar");
;;;   printf("%u",x); printf("%s",s); -- ONLY!
;;;   (*compliled* printf - in progres, no big printf!)
;;; 
;;; - word F() { ... } - function definitions
;;; - F() G() - function calls (no parameters)
;;; 
;;; - single letter global variables (no need declare)
;;; - limited char support: *(char*)p=   ... *(char)i;
;;; 
;;; - library to minimize gen code+rules (slow code==cc65)
;;; 

;;; 
;;; Limits:
;;; - only *unsigned* values
;;; - if supported ops/syntax should (mostly)
;;;   work the same on normal C-compiler
;;; - NO priorities on * / (OK, this deviates from C)
;;;   TODO: could force to write:
;;;       a+3<<24+3*2+r<<2;
;;;       ((((((a+3)<<2)+3)*2)+r)<<2)
;;; - mostly no error messages uneless get stuck
;;;   and can't complete compilation
;;; - "types" aren't enforced
;;; - single lower case letter variable
;;; - single upper case letter functions
;;; - NO parenthesis
;;; - NO generic / or * (unless add library)
;;; 

;;; 
;;; Extentions:
;;; - 42=>x+7=>y;     forward assignement
;;; - 35.sqr          single arg function call
;;; - 3 + $ v         byte operator (acts only on A not AX
;;; 

;;; USER MANUAL
;;; 
;;; The program "lives" in the editor. It allows
;;; for fullscreen editing (currently: ORIC ATMOS).
;;; 
;;; Arrow keys for movement, backspace, delete (forward).

;;; Emacs commands are extras:
;;; line: ^Prev ^Next ^A=sTart ^End ^O=new
;;; char: ^Back ^Forward ^Delete BackSpace
;;; 
;;; ^T - caps toggle (ORIC, lol)
;;; 
;;;   ^Help summary (navigation, lang, symbols)
;;;   ^Write screen to buffer
;;;   ^Load screen from buffer
;;;   ^Compile buffer
;;;   ^Xexecut program
;;;   ^Run
;;; 
;;; Experimental features:
;;; 
;;;   ^Zource code (reload from orig)
;;;   ^V info of compiler/program/libraries
;;;   ^Garnish program (pretty print)
;;; 
;;;   ^Q disasm program (sensitive)
;;;   ^Utilities, ahum list "files"
;;;   ^Y quit
;;;   
;;;  ESC help
;;; 
;;; Not yet: ^Search ^J ^Killine ^Machinecode(^Q)

;;; Errors
;;; 
;;; If there is an error a newline '%' letter error-code
;;; is printed, and with PRINTINPUT ERRPOS defined the
;;; source is printed, and RED text as far as parsing got.
;;; 




;;; 
;;; ORIC ATMOS API
;;; ==============
;;; Refer to the ORIC ATMOS MANUAL for parameters.
;;;
;;; GRAPHICS: x=0..239 y=0..199 c=0..2
;;;   hires()
;;;   text()
;;;   clrscr()
;;;   curset(x, y, c)
;;;   curmov(dx, dy, c)
;;;   draw(dx, dy, c)
;;;   circle(r, c)
;;;   point(x, y)
;;;   hchar(...)
;;;   fill(...) 
;;;   paper(0-7)
;;;   ink(0-7)
;;;   pattern(0-255)
;;;
;;; SOUND:
;;;   play(...)
;;;   music(...)
;;;   sound(...)
;;;   ping(), shoot(), zap(), explode(),
;;;   tick(), tock()
;;;   
;;; FILE:
;;;   ; cload(...) - TODO
;;;   ; csave(...) - TODO
;;;   cwrite(0..255)
;;;   cread()->0..255 - TODO: erh, should be function
;;;   ; cwritehdr() - TODO
;;;   ; creadsync() - TODO
;;; 

;;; 
;;; Implementation Notes
;;; 
;;; 
;;; The BNF parser is implemented as a giant statemachine,
;;; i.e., a pushdown automata. The program stack is used
;;; as a data-stack, mixed with *some* subroutine calls.
;;; The stack grows as rules are parsed, and shrinks
;;; as they are rejected or resolved. This allows for
;;; a simple backtracking parser.
;;; 
;;; One needs to be careful as you can't use subroutine
;;; to modify the "stack".
;;; 
;;; This allows one to configure the compilation as a
;;; "background" task. Ie, it performs a piecemeal work
;;; and you can then go on to other tasks. A simple
;;; continutation (address) to be called at specified
;;; opportunity. Then, later, the compilation can be
;;; called again, until finished.
;;; 
;;; Care must be taken so that there are no interleaving
;;; program calls left on the stack when the compilation
;;; process continues, it'll go bad!
;;; 


;;; 
;;; TODO:
;;; - parameters (without stack)
;;; - recursion? (requires stack)
;;;   1) use program stack (no tailrec)
;;;   2) separate stack ops/MINIMAL
;;; 


;;; 
;;; OPTIONAL:
;;; - pointers (no type checking): *p= *p+1
;;; - I/O: getchar putc putu puth
;;; - else statement;
;;; - optimized: &0xff00 &0xff >>8 <<8
;;; - optimized: ++v; --v; += -= &= |= ^= >>=1; <<=1;
;;; - optimized: ... op const   ... op var
;;; 

;;; 
;;; How-to use
;;; 
;;; 1. The BNF is inline, rule 'P' is executed
;;; 2. The source is pointed to at addr "inp"
;;; 3. The code is generated at "out"

;;; Compile with
;;; 
;;;    ./rasm parse
;;; 
;;; gives a parse.tap in ORIC folder (symlink)



;;; STATS:

;;;                          asm rules
;;; MINIMAL   :  1016 bytes = (+ 771  383) inc LIB!
;;; NORMAL    :  1134 bytes = (+ 771  501)
;;; OLDBYTERULES :  1293 bytes = (+ 771  660)
;;; OPTRULES  :  1463 bytes = (+ 771 1090)
;;; LONGNAMES :  
;;; 
;;; v= #x392 = 914 (- 914 882) = 32 (but I count 22B, hmm)
;;; v= #x372 = 882 
;;; v= #x34c = 844 bytes!
;;; v= #x363 = 867 (+52 %U TAILREC-fix)
;;; v= #x32f = 815 (+75 D d : ; # d - WHILE!) :-(
;;; v= #x2f6 = 758
;;; (- 844 27 46) = 771 (-errpos/-checkstack?) 
;;;     100 byte more? lol)
;;; 
;;;    193 bytes backtrack parse w rule
;;;    239 bytes codegen with []
;;;    349 bytes codegen <> and  (+25 +36 mul10 digits)
;;;    450 bytes codegen +> and vars! (+ 70 bytes)
;;;    424 bytes codegen : %V %A fix recurse
;;;         ( moved out bunch of stuff - "not counting" )
;;;    438 bytes skip spc (<= ' ') on input stream!
;;;        (really 404? ... )
;;;    487 bytes IF ! (no else) (+ 43B)
;;;    493 bytes ... (+ 29 B???) I think more cmp????
;;;    517 bytes highlite error in source! (+ 24 B)
;;;    550 bytes ...fixed bugs... (lost _var code...)
;;;    554 bytes =>a+3=>c
;;;    663 bytes ... ?
;;; 73 B overhead to subtract (+ 26 47)
;;;    642 no ERRPOS no CHECKSTACK
;;;    668  +26 == ERRPOS
;;;    715  +47 == CHECKSTACK
;;;    844  +... ??? wtf? lol
;;;    914  +32B 'c' small char constants
;;; 
;;;   1230 BNF Interpreter as reported from info()
;;; 

;;; TODO:  634 bytes ... partial long names (+ 141 B)
;;; 
;;; not counting: putu, mul10, end: print out
;;; 
;;; C parse() == parse.lst (- #x715 #x463) = 690




;;; C-Rules: 469 B (- 593 56 68)
;;; 
;;;   383 bytes = MINIMAL   (rules + library)
;;;   501 bytes = NORMAL
;;;   660 bytes = OLDBYTERULES (+ 159 B)
;;;   821 bytes = OPTRULES  (+ 320 B)
;;; 
;;; 
;;; 
;;;    71 bytes - voidmain(){return4711;}
;;;   112 bytes - ...return 8421*2; /2, +, -
;;;   124 bytes - ...return e+12305;
;;;   128 bytes -           1+2+3+4+5
;;;   262 bytes - +-&|^ %V %D == ... 
;;;   364 bytes - int,table,recurse,a=...; ...=>a; statements
;;;   379 bytes - IF(E)S;   (+ 17B)
;;;   392 bytes - &a
;;;   425 bytes -  =>a+3=>c; and function calls
;;;   525 bytes - &0xff00 &0xff >>8 <<8 (+ 44B) >>v <<v
;;;   593 bytes - putu puth putc getchar +68B TOOD: rem!
;;;   627 bytes - FUNS (=+21 partial) and ELSE!(=+13 B)
;;;   821 bytes - ++ -- += -= &= |= ^= >>=1 <<=1
;;;               and changed int=>word char=>byte
;;;   521 bytes
;;;   597 bytes FUNS: more %F and %f code
;;;   642 bytes +R* - not working yet
;;;   676 bytes plain rules (!OPTRULES)
;;;   715  +47 == CHECKSTACK
;;;   886 bytes ...
;;; 
;;;  1112 bytes rules? OPTRULES
;;;  1181 bytes DO...WHILE/WHILE... (+ 69 B)
;;;  1393 bytes - OPT: << >> <<= >>=
;;;  1481 bytes FUNCTIONS/TAILREC/FUNCDEF (+ 300 B)
;;;  1544 bytes FUNCTIONS+POINTERS (+ 63 B)
;;;  1582 bytes various opts for MUL (+ 38 B)
;;; 
;;;  3026 bytes BYTERULES (opt)
;;;  3434 bytes ORIC ATMOS API (+ 408 B)
;;; 

;;; w= #x62e 1582

;;; TODO: not really rules...
;;;    56 B is table ruleA-ruleZ- could remove empty
;;;    68 B library putu/puth/putc/getchar
;;;         LONGNAMES: move to init data in env! "externals"
;;; TODO: 
;;;  ~256 B parameterize ops (gen)



;;; BNF DEFINITION
;;; ==============
;;; 
;;; The BNF is very simplified and is interpreted
;;; using backtracking. It may be ambigious but first
;;; matching result/alternative is accepted.
;;; (Can this replace priorities?)
;;; 
;;; In a BNF-rule:
;;; - Most ASCII chars are matched literally, except
;;;   '%' '|' - they need to be quoted
;;; - ' ' - SPACE (or any char<=' ') cannot be matched!
;;;   because tey are removed from input parsed!
;;; - 'R'+128 - A letter with HI-BIT set is a reference
;;;   to another rule that is matched by recursion (const _E)
;;; - '|' Rules can have alternatives: E= aa | a | b that are
;;;   tried in sequence, if one fails, the next one after
;;;   '|' is tried, basically backtracking.
;;; - NO SUBRULES "(foo|bar)"
;;; - Put literal/longer matches first in rule alternatives.
;;;   input: "foobar"    ie:   R ::= foobar | foo
;;; - Right-recursion might work, but it's limited by the
;;;   6502 hardware stack (~ 256/6) ~42 deep/recursion
;;; - TAILREC constant '*"+128 jumps to match from beginning
;;;   of the same rule. This replaces KlEENE operators *+?[].
;;; 
;;; CONSTANS
;;; 
;;; - %D - tos= NUMBER; parses various constants
;;;        4711 - number
;;;        'c'  - char constant
;;; - %S - skips (parses) string till "
;;;        NOTE: you need to write "%S 
;;;        ...\n\"..." - rest of string is matched
;;;        only \n is recognized, other \ just quotes
;;;        NOTE: this doesn't copy string!
;;;        NOTE: no address is saved given in tos, dos.
;;; 
;;; NAMES (variables, functions, labels)
;;; 
;;; - %V - tos= address; match "Variable" name
;;; - %A - dos= tos= address; address of named
;;;        variable (use for assignment)
;;; 
;;; - %N - define NEW name (forward) TODO: 2x=>err!
;;; - %U - USE value of NAME (tos= *tos)
;;; 
;;; IMMEDATE (run code inline)
;;; 
;;; - %{ - immediate code, that runs NOW during parsing
;;;        This is used to do one-offs, like test that
;;;        last %D matched a byte-value (X=0), if not _fail.
;;; 
;;;        NOTE: can't rts, must use "jsr immret"
;;;        FAIL: it's ok to call "jsr _fail" !

;;; 
;;; TODO:?
;;; - %d - TODO: match 0-255 only), orr
;;; - %B - or Byte restrictor; fails if last %D (tos) > 255
;;; - %b - match word boundary! '\b' in regexp, you know
;;; 
;;; - %n - define NEW LOCAL
;;; - %v - match LOCAL USAGE of name
;;; 
;;; - %r - the branch can be relative
;;; - %P - match iff word* pointer (++ adds 2, char* add 1)


;;; 
;
IMMEDIATE=1
;;; 
;;; Code can be executed inline *while* parsing.
;;; It's prefixed like this
;;; 
;;; RuleX: ;; match foobar, prints % after match foo
;;;        .byte "foo"
;;;      .byte "%{"
;;;        putc '%'                ; print debug info!
;;;or      IMM_FAIL                ; HOW TO FAIL

;;; NOTE: IMM_FAIL will skip to next '|'
;;;       must not find any '|' or \0
;;;       in the remaining code - OK'its a HACK!

;;;        IMM_RET                 ; HOW TO RETURN!

;;; NOTE: IMM_RET must be the last of the CODE!
;;;       as it tells the interpreter where BNF continuse

;;;      .byte "["
;;;        .byte "bar"
;;;        .byte 0                 ;
;;; 
;;; This will parse foo, then print %, then parse bar


;;; 
;;; [ GENERATIVE ]
;;; 
;;; The generative part of the rule may be invoked
;;; several times. Each one will generate code from
;;; a template.
;;; 
;;; NOTE: There is no backtradking/reset of code
;;;       generated, so use with care!
;;;       Once generated, it's there!
;;;       Typically just generate at end or when sure.
;;; 
;;; Inside the generative brackets normal *relative*
;;; 6502 asm is assumed to be used.
;;; 
;;; There are directives used that doesn't match
;;; any 6502 byte-codes, these come from this set
;;; of printable bytecodes.
;;;
;;;     missed: $(,08 KLORSTWZ`hloswz{| DEL

;;;      "#$'+/2347:;<?BCDGKORSTWZ[\_bcdgkortwz{|
;;; free "#$' /2347   ?B  GKORSTWZ \_bc gkortwz
;;;             ( '|' '[' are excluded as unsafe )
;;; HI' '"#$'(+,/023478:;<?@BCDGHKLOPRSTWXZ[\_`bcdghkloprstwxz{| DEL

;;;  ( 168 freee? '8'

;;; GROK: free: (hex)
;;; 02,03, 03,83, 07,87, 08,88, 12,92, 13,93, 0f,bf
;;; 17,97, ESC: 1b,9b, 9c, 1f,9f 9e
;;;    "#'+/237;?BCGKORSW[_ bcgkorsw{ DEL
;;; hi: #'+/237;? CGKORSW[_  cgkorsw{ DEL


;;; CONFLICTS!
;;; > is ROL $nnnn,x   62(dec)
;;; ] is EOR $nnnn,x   93(dec)




;;; 
;;; NOTE: not, there is *REAL* quoting problem
;;;       if any (data) byte matches | [ ]
;;; NOTE: JSR 0x4711 is autoquoted (thus "safe")
;;;       (unless there is a 0x20, or ' ' constant!)
;;; TODO: do the same for JMP BNE, JPI etc?
;;; 
;;; SUBSTITUTIONS
;;; 
;;;   C   - $20 (JSR) non-quoted value (can't JSR "<>")
;;;   ]   - ends the generation
;;;   <   - lo byte of last %D number matched
;;;   >   - hi byte         - " -
;;;   <>  - little endian 2 bytes of %D     VAL0
;;;   +>  -       - " -           of %D+1   VAL1
;;;         (actually + and next byte will be replaced)
;;;         (can't do single '+')
;;;  
;;; DIRECTIVES (stripped from output)
;;;            (NOTE: relative jmps - don't know!)
;;; 
;;;   {{  - PUSHLOC (push and AUTO patch at accept rule)
;;;   D   - set %D(igits) value (tos) from %A(ddr) (dos)
;;;   d   - set dos from tos
;;;   #   - push tos (on to stuck)
;;;   :   - push loc (onto stack, as backpatch! - careful)
;;;   ;   - pop loc (from stack) to %D/%A?? (tos)
;;; 
;;; TODO: keep '#' ':' ';'
;;; TODO: 'z' to swap two locs? replaces 'D and 'd'
;;; TODO: make a "pickN' rule instead! '#3' '?3'
;;; 
;;; maybe not needed
;;;   \n   - TODO: drop pos n from stack (overwrite)

;;; NOTE: if any constant being used, such as
;;;       address of JMP (library?) or a
;;;       variable/#constant matches any of these
;;;       characters.
;;; 
;;;       Hey it's a hack!
;;; 
;;; TODO: detect this and give assert error?
;;;       alt: parameterize any constants?



;;; TODO: this is the PLAN... MASTER PLAN?
;;; 
;;; TODO: experiment with
;;; - https://www.cc65.org/faq.php#ORG
;;; - http://forum.6502.org/viewtopic.php?f=2&t=4247
;;; - https://retrocomputing.stackexchange.com/questions/13188/putting-code-into-two-different-memory-areas-with-cc65-ca65
;;; 
;;; I think, one can just do .org (to after C-code)
;;; then memmove it to where it should be!
;;; 
;;; TODO: read about the linker and what it does
;;; 
;;; 
;;; (ORIC) MEMORY LAYOUT - COMILER/RUNTIME/OUTPUT
;;; ============================================
;;; _tap:       ---------jmp _output------------
;;;             bios        bios       bios
;;;             lib         lib        lib
;;; _output     compiler    gen prog   gen prog
;;;             input       ...        ...
;;;             ...         *_out      END
;;;             ...         ...        ...
;;;             END
;;;             ---------cc65-heap--   MYHEAP
;;;             ---------cc65-stack-   MYAXSTACK
;;; _compiler               input
;;;                         compiler
;;;                         END
;;; FIXED:
;;; ------
;;; _hcharset:
;;; _hires:
;;; 
;;; _charset:
;;; _textscreen:
;;; _hitext:

.export _asmstart
_asmstart:      

.import _iasmstart, _iasm, _dasm, _dasmcc
.export _endfirstpage
.export _output, _out
.export _rules


;;; ORIC ADDRESSES
;;; TODO: don't assume oric, lol
SCREEN		= $bb80
SCREENSIZE	= 40*28+0
SCREENEND	= SCREEN+SCREENSIZE
ROWADDR		= $12
CURROW		= $268
CURCOL		= $269
CURCALC		= $001f      ; ? how to update?

;;; TODO: why is this not accepted?
.define SCREENRC(r,c)   SCREEN+40*r+c-2

;;; TODO: not good idea?
;;; TODO: not working, parse error?
;COMPILESCREEN=1

;;; enable ORIC ATMOS raw TTY replacement
;;; 
;;; TTY=1


;;; ORIC ATMOS
;;; 
;;; #228 ( 4244) is the address of the ‘fast’ interrupt
;;; jump. By altering the jump address at #229,A
;;; 
;;; (#245,6) you can provide your own interrupt handler.
;;; 
;;; #230 ( #24A) is the address of the ‘slow’ interrupt
;;; routine. Control is passed to here at the end
;;; of the fast interrupt routine. Although 3 bytes are
;;; eserved here, there is only the single-byte
;;; instruction RTI present normally.
;;; 
;;; #228(4247) contains the jump vector for the NMI
;;; (Non-Maskable Interrupt) routine, which on
;;; the Oric connects to the ‘Reset button’.

;;; TODO: replace NMI with _edit, lol!
;;; TODO: 


;;; TIMe events: compile/run
;;; disables interrupts and counts cycles!
;;; relatively accurately...
;;; It also seems to make the compiler NOT crash
;;; when run repeadetly... HMMM? "resetting" stack
;;; not good when interrupts running????
;;; (just enables interrupt before getchar)
;;; 
;;; TODO: BUG: i think there is some zeropage overlap
;;;   with oric timer and vars... lol
;TIM=1

;TTY=1

;;; 
;;; $0244: jmp ?
;;; points to $ee22 (ROM interrupt handler)
;ORICINTVEC=$0245
;;; doesn't matter?
;INTCOUNT=10000                  ; 100x/s
INTCOUNT=50000                  ; 100x/s

;INTERRUPT=1

TIMER_START	= $ffff
SETTIMER        = $0306
READTIMER	= $0304
CSTIMER         = $0276


.macro SKIPONE
        .byte $24               ; BITzp 2 B
.endmacro

.macro SKIPTWO
        .byte $2c               ; BITabs 3 B
.endmacro

.macro FUNC name
  .export .ident(.string(name))
  .ident(.string(name)):
.endmacro





;;; ----------------------------------------
;;;                  BIOS

;;; -------- BIOS
;;; 17 - getchar (save XY)
;;; 19 - nl plaputchar putchar (save AXY, \n)
;;;  4 - rawputc
;;;(14)- 3 clrscr, 3 forward, 3 bs, 5 spc
;;; ========
;;; (+ 17 19 4 14) = 54 ( 56 according to info() ? )



;;; enable to invers on hibit
;TTY_HIBIT=1


FUNC _biosstart

;OLDSTYLE=1
;;; TODO: remove!!!!
.ifdef OLDSTYLE
  .include "bios.asm"
  TTY_HELPERS=1
.else

.ifdef __ATMOS__
  ;.include "bios-raw-atmos.asm"
  .include "bios-atmos-rom.asm"
.else ; SIM
  .include "bios-sim.asm"
.endif ; __ATMOS__ | SIM

.endif ; OLDSTYLE

.ifndef putcraw
        putcraw= putchar
.endif

FUNC _biosend


;;; ========================================
;;;          D       A       T       A

.zeropage
;;; reserved, lol
zero:   .res 2  

;;; compilation : tos = %D, dos =%A
;;; running code: tos, dos temporary save/deref
tos:    .res 2
dos:    .res 2
;;; used as default for printing strings (putz)
pos:    .res 2
;;; used by FOLD, maybe memcpy ???
gos:    .res 2
;;; temporaries for saved register
savea:  .res 1
savex:  .res 1
savey:  .res 1
;;; used by print.asm, lol
;;; TODO: FIX!
tmp1:   .res 2
tmp2:   .res 2



.code


;;; ========================================
;;; ---------------- LIBRARY ---------------

;;; 1284707
;;; 1150630 (/ 1284707 1150630.0) == 11.6% overhead
;;; 11.6% overhead parsing STRING CTYPE

;NOLIBRARY=1

.ifndef NOLIBRARY

;;; #include <string.h> // constants and functions
;
STRING=1

;;; #include <ctype.h> // isXXX()
;
CTYPE=1

.endif ; NOLIBRARY



FUNC _librarystart

.include "tty-helpers.asm"      ; nl spc bs PUTC putc

;;; inline str after jsr; +29 bytes
;;; saves 7 B at each puts/z("...");
;;; is it worth it?
;INLINEPUTZOPT=1  
.include "lib-stdio.asm"

;include "lib-printf.asm"       ; not working

.include "lib-ctype.asm"

.include "lib-stdlib.asm"

.include "lib-string.asm"

.include "lib-math.asm"         ; mul mul10 mul16 div16


;;; Current byte count:
;;; 
;;; Bytes #functions
;;; ----- ---- 
;;; [  23(?)      BIOS: getchar putchar -- NOT part of LIBRARY]
;;;    17         nl/newline spc bs clrscr...
;;;   119(?)      #include <stdio.h>
;;;                (print.asm: putu, putchar, putz) (127 B?)
;;;    98   10    #include <ctype.h> isdigit isalnum ...
;;;   144    6    #include <srting.h> strlen strcpy ...
;;; ======
;;;   384         (+ 23 119 98 144) 


;;; ------- <time.h>
;;; - clock difftime
;;; - va_start va_arg va_copy va_end
;;; - signal (irq timer?)

;;; -------- <assert.h>
;;; - assert

;;; --------- <stddef.h

;;; TODO:
;;; - NULL
;;; - size_t
;;; - TYPE: ptrdiff_t
;;; 

;;; ---------- <limits.h>
;;;     {INT_MAX}
;;;            Maximum value for an object of type int.
;;;            Minimum Acceptable Value: 2 147 483 647
;;;     {INT_MIN}
;;;            Minimum value for an object of type int.
;;;            Maximum Acceptable Value: -2 147 483 647
;;;     {UINT_MAX}
;;;            Maximum value for an object of type unsigned.
;;;            Minimum Acceptable Value: 4 294 967 295

;;; ---------- <strings.h>
;;; 
;;; TODO:
;;; - ffs(int) -> bit set (32..1) 1== 0x01 input FFS!
;;; - strcasecmp
;;; - strncasecmp

;;; --------- <system.h>
;;; - exec?


FUNC _unistdstart
;;; ;;????
;;; ---------- <unistd.h>
;;; 
;;; - alarm
;;; - chdir
;;; - chown
;;; - close
;;; - crypt
;;; - dup/dup2
;;; - _exit
;;; - encrypt
;;; - _exit
;;; - fsync
;;; - ftruncate
;;; - getcwd
;;; - gethostname
;;; - getpid
;;; - getuid
;;; - isatty
;;; - link
;;; - lockf
;;; - lseek
;;; - nice
;;; - pause
;;; - read
;;; - rmdir
;;; - sleep
;;; - sync
;;; - truncate
;;; - ttyname
;;; - unlink
;;; - write
;;; ---- pthreads?
FUNC _unistdend



;;; TOOD: see Docs/oric-atmos-addresses.asm ?

;;; ORIC:
;;; - wait
;;; - plot scrn
;;; - plots


FUNC _graphicsstart
;;; ORIC-rom already have routines, only compiler
;;; rules are needed for those.
;;; 
;;; TODO:
;;; - faster line
;;; - faster setpixel
;;; - faster circle
;;; - paint (fill?)
;;; 
;;; Resources:
;;; - oric graphics book
;;; - dflat has nice routines
;;; - oric .. linebench.zip? has fast routines!
;;; 
;;; Ideas:
;;; - could have several new graphics-modes:
;;;   a) normal oric
;;;   b) oric but with "set color attribute"
;;;   c) 8 FULL colors (3x3 pixels)
;;;   d) 2 color/mixing (2x2 pixels)
;;;   e) lores graphics "driver"
FUNC _graphicsend



FUNC _runtimestart

;;; TODO: IRQ put here!

FUNC _runtimeend




FUNC _minimallibrarystart
 
;;; zoropage variant? together with few general rules
;;; but really small library...
;;; 
;;; (- #xdad #xd4d) = 96 B

.ifdef MINIMAL
;;; These are totally untested, just written to paly
;;; with...

;;; TODO: use a preexisting VM .include
;;;   preferable one with all stack
_SAVE:  
        sta tos
        stx tos
        rts

_AND: 
        and tos
        tay
        txa
        and tos+1
        tax
        tya
        rts
_OR:    
        ora tos
        tay
        txa
        ora tos+1
        tax
        tya
        rts
_EOR:   
        eor tos
        tay
        txa
        eor tos+1
        tax
        tya
        rts
_PLUS:  
        clc
        adc tos
        tay
        txa
        adc tos+1
        tax
        tya
        rts
_MINUS: 
        sec
        eor #$ff
        adc tos
        tay
        txa
        eor #$ff
        adc tos+1
        tax
        tya
        rts
_EQ:    
        ldy #0
        cmp tos
        bne false
        cpx tos+1
true:  
        dey
false: 
        tya
        tax
        rts
_LT:    
        ldy #0
        cpx tos+1
        bcc true
        bne false
        cmp tos
        bcc true
        bcs false
_SHL:   
        asl
        tay
        txa
        rol
        tax
        tya
        rts
_SHR:   
        tay
        txa
        lsr
        tax
        tya
        ror
        rts


.endif ; MINIMAL
FUNC _minimallibraryend






FUNC _libraryend









;;; TODO: remove this and simplify,
;;;   it's it's own project now!


;;; See template-asm.asm for docs on begin/end.asm
NOSHOWSIZE=1
.include "begin.asm"


.zeropage

.code




;;; ========================================
;;;   P A R S E R   O P T I M I Z A T I O N
;;; 
;;;   41% faster by CUT+CUT2
;;;   40% faster w  FASTSKIP in _fail (no jsr _inc)
;;;    4.53% faster w OPTSKIP (_incIspc inline in _next)
;
OPTPARSEALL=1

;;; TODO:
;;; -1) %A %V lot's of redundant variable parsing %A+= ...
;;;    maybe HACK a guard and skip if not var?
;;; -2) %D also parse several times, similar patterns?
;;;    poke(%D,%D) poke(%D,%V) poke(%V,%D) ...
;;;    "tokenization" before would "solve" this...
;;; 0) jsr _incIspc - move it to before _next
;;;    find locations where "jsr _incIspc; ... jmp _next"!
;;;    it's at least 12c per character used!
;;; 1) byte < 32 ==> skip byte (at _fail)
;;;    check avg,max,min size of rules
;;; 2) ruleS could be directly TAILREC - must save some!
;;; 3) byte rules?
;;; 4) any %D many times is costly (parse number later?)
;;; 5) match %V many times very costly, maybe just store
;;;    pointer and look up later when syntax fine?
;;; 6) group functions by first letter, and skip?
;;; 7) bitmap hash to check if var exists (no care?)

;;; CUT and CUT2

;;; -- BYTESIEVE:
;;; 
;;; 3451213 before opt! 3.5s
;;; 2640900 CUT2
;;; 2863202 CUT
;;; 2052939 CUT+CUT2 !  2.1s!
;;; 2159... now... lol

;;; CUT2: 14.14% faster(/ 2640900 3451213.0)
;;; 
;;; both CUTs: (- 1 (/ 2052939 3451213.0))
        
;;   41% faster!
; OPTPARSEALL=1
.ifdef OPTPARSEALL

;;; CUT2 is simple ruleS cut by '}'
;
CUT2=1
;;; TODO: generalize! it now only cuts ruleD
;;;       cutting expressions at ',;:)]?'
;
CUT=1

;;; OPTSKIP inlines _incIspc in _next
;
OPTSKIP=1

.endif ; OPTPARSEALL






;;; ========================================
;;;                  M A I N

FUNC _bnfinterpstart

.ifnblank
        .macro TIMER
          jsr timer
        .endmacro
.else
        .macro TIMER
        .endmacro
 .endif

;;; enable stack checking at each _next
;;; (save some bytes by turn off)

;;; TODO: if disabled maybe something wrong? - parse err! lol
;;; checking every _next gives 30% overhead? lol
;;; TODO: find better location? enterrule?
;
CHECKSTACK=1

;;; Zeropage vars should save many byes!
;
ZPVARS=1

;;; Minimal set of rules (+ LIBRARY)
;MINIMAL=1

;;; Optimizing rules (bloats but fast!)
;;; 
;;; ++a; --a; &0xff00 &0xff <<8 >>8 >>v <<v 
;
OPTRULES=1

        ;; 

ELSE=1

;;; Byte optimized rules
;;; typically used as prefix for BYTE operators
;;; (only operating on register A, no overflow etc)
;
BYTERULES=1

;;; Pointers: &v *v= *v
;;; TODO: not working
;POINTERS=1

;;; testing data a=0, b=10, ... e=40, ...
;;; doesn't take any extra code bytes, or rule bytes
;
TESTING=1

;;; Long names support
;;; TODO: make functional
;LONGNAMES=1
;;; TODO: IDEA !!!!!!!!!!!!!!!!
;;; DONt... JUST CREATE new parse rule that maps to data
;;;           can generate address!


;;; TODO: not yet done, just thinking
;BNFLONG=1

;;; used for PARAM4
;;; 
;PARAM4=1
;DEBUGFUN=1

;;; Enable for debug info
;DEBUG=1

;;; wait for input on each new rule invocation
;DEBUGKEY=1

;DEBUGRULE=1

;;; at FAIL prints [rulechar][inputchar]/iL[rule]
;;; 

;DEBUGRULE2=1

;DEB2=1

;DEBUGRULE2ADDR=1

;;; prints when skipping
;DEBUGRULESKIP=1

;;; show input during parse \=backtrack
;;; Note: some chars are repeated at backtracking!
;SHOWINPUT=1

;;; gives a little bit more context for compile err...;
;TRACERULE=1
;;; backspaces out of rules done
;;; (works best if PRINTREAD not enabled)
;TRACEDEL=1

;;; print input ON ERROR (after compile)
;;; TOOD: also, if disabled then gives stack error,
;;;   so it has become vital code, lol
;
PRINTINPUT=1

;;; for good DEBUGGING
;;; print characters while parsing (show how fast you get)
;;; It will skip numbers etc (as they call jsr _incI)
;;; TODO: seems to miss some characters "n(){++a;" ...?
;;; Requires ERRPOS (?)

;;; TODO: useless - remove! or reimlement...

;PRINTREAD=1

;;; more compact printing of source when compiling
;UPDATENOSPACE=1



;;; TODO: sim65 crashes!!!!! when PRINTASM, it happends inside
;;;    jsr asmprintsrc which loops giving ";  m222222222222"?????

;;;                                       W   T   F?


;;; TODO: make it a runtime flag, if asm is included?
;
PRINTASM=1

;;; If asm is on, you also want to see some code
.ifdef PRINTASM
  .ifndef UPDATENOSPACE
    UPDATENOSPACE=1
  .endif

  .ifndef PRINTDOTS
    PRINTDOTS=1
  .endif
.endif ; PRINTASM




;;; TODO:
;;;  capture which rule and pos
;;;  for longest match (only)



;;; print/hilight ERROR position (with PRINTINPUT)
;
ERRPOS=1

.ifdef DEBUG
  .macro DEBC c
    PUTC c
  .endmacro
.else
  .macro DEBC c
  .endmacro
.endif

.export _start
_start:


.zeropage
        
;;; if %V or %A stores 'V' or 'A'
;;; 'A' for assigment
percentchar:  .res 1

;;; not pushing all
;state:  
  rule:   .res 2
  inp:    .res 2
 _out:    .res 2
;stateend:       

erp:    .res 2
env:    .res 2
valid:  .res 1

rulename:       .res 1

;;; stackframe for parameter start
pframe: 

.code

;;; Magical references in [generate]
.macro DOJSR addr
        .byte 'C'
        .word addr
.endmacro

VAL0= '<' + 256*'>'
VAL1= '+' + 256*'>'

.ifdef ZPVARS
  VAR0= '<'
  VAR1= '+'
.else
  VAR0= VAL0
  VAR1= VAL1
.endif

PUSHLOC= '{' + 256*'{'
TAILREC= '*'+128
DONE= '$'


.zeropage
dirty:          .res 1
showbuffer:     .res 1
.code


;;; parser to compile _
FUNC _init

        ;; editor states
        lda #255                ; first time
        sta dirty
        sta showbuffer

        ;; compile from src first time


;;; compile using defaults input, output
;;; BEWARE: never returns! ends up in _OK/_edit
FUNC _compile
        ;; default output location
        lda #<_output
        ldx #>_output
        sta _out
        stx _out+1

;;; compile source from input
;;;    _out must be set to where you want output to go
;;; BEWARE: never returns! ends up in _OK/_edit
FUNC _compileInput

        ;; default input location
        lda #<input
        ldx #>input

;;; Compiles source from AX
;;; to *_out location.
;;; BEWARE: never returns! ends up in _OK/_edit
FUNC _compileAX

        ;; store what to compile
        sta inp
        stx inp+1
;;; Not worthy (used enough)
.data
originp:        .res 2
.code
        sta originp
        stx originp+1

.ifdef ERRPOS
        sta erp
        stx erp+1
.endif        

;;; INTERRUPT DEBUG TESTING
;        lda #$40                ; RTI
;        sta $0245


;;; 21 B

        sei

        ;; init/reset stack
        ldx #$ff
        txs
        cld
.ifdef CHECKSTACK
        ;; sentinel - if these not there stack bad!
        stx $100
        stx $101
.endif
        ;; X=$ff still for init!

;;; TODO: move to bios-atos-rom???

;;; Init ORIC
.ifdef __ATMOS__
;;; #26A -- Oric status byte. Each bit relates to
;;; one aspect: from high bit to low bit – unused,
;;; double-height, protected-columns, ESC pressed,
;;; keyclick, unused, screen-on, cursor-off.
;;; (description sucks!)

;;; 0,0,protected on=0!,0, 1=off,0,screen=on=1,cursor=on=1
        lda #%00001011
        sta $26a
;;; $24E (KBDLY) delay for keyboard auto repeat, def 32
        lda #8
        sta $24e
;;; $24F (KBRPT) repeat rate for keyboard repeat, def 4

;;; TODO: not working?
        lda #1
        sta $24f

.else

.macro CURSOR_ON
.endmacro

.macro CURSOR_OFF
.endmacro

.endif


.ifdef TIM
        sei
.endif ; TIM


.ifdef INTERRUPT
ORICINTVEC=$0245
        ;; 
.zeropage
centis:     .res 1              ; 1/100ths of seconds
seconds:    .res 2              ; (/ 65536 3600)= 18h
.code

initinterrupts:


        sei

XYZ=1
.ifdef XYZ
        lda ORICINTVEC-1
        sta tos
        ldx #0
        stx tos
        jsr puth
        
        ;; save old vector
        lda ORICINTVEC
        sta origint
        ldx ORICINTVEC+1
        stx origint+1

        sta tos
        stx tos+1
        jsr puth

        ;; install interrupt vector
        lda #<_interrupt
        sta ORICINTVEC
        ldx #>_interrupt
        stx ORICINTVEC+1

        lda #0
        sta centis
        sta seconds
        sta seconds+1

.ifnblank
.ifblank
        ;; set timers for 100x a second
        lda #<INTCOUNT
        sta READTIMER
        lda #>INTCOUNT
        ;; this write starts the timer
        sta READTIMER
.else
        lda #<INTCOUNT
        sta SETTIMER
        lda #>INTCOUNT
        ;; this write starts the timer
        sta SETTIMER+1
.endif
.endif ; BLANK

        ;; go!
        cli

.endif ; XYZ

.endif ; INTERRUPT



.ifdef DEBUG 
        putc 'S'
        putc 10
.endif ; DEBUG

        ;; store an rts for safety
        _RTS=$60
        lda #_RTS
        sta _output

.ifdef LONGNAMES
        lda #<vnext
        sta env
sta tos
        lda #>vnext
        sta env+1
sta tos+1
putc '#'
jsr putu
putc 10
.endif ; LONGNAMES



;;; TODO: improve using using ruleP 'P'
        lda #'P'+128
        sta rulename

        lda #<rule0
        sta rule
        lda #>rule0
        sta rule+1

        ;; end-all marker
;;; TODO: make it 0, can save many tests bytes???

        lda #DONE
        pha

.ifdef DEBUGRULE
        jsr printstack
.endif

;.ifdef PRINTASM
        jsr _iasmstart
;.endif ; PRINTASM




        
        jmp _next

;;; TODO: opt?
;;; 1137800
;;; 1132809 ~6000 savings 0.4% - not worth it!
FUNC _nextI
;;; 3 B
        jsr _incI
;;; 6 B
;        inc inp
;        bne :+
;        inc inp+1
;:       
;;; TODO: move this to "the middle" then
;;;   can reach everything (?)
        ;; - fall-through from above
FUNC _next


;;; TODO: remove, disable here, maybe check and end of rule?

;;; This is very expensive, but keep to find overflow bugs
.ifdef CHECKSTACK
;;; TODO: measure overhead
	;; check stack sentinel
        lda #$ff
        cmp $100
        bne stackerror
        cmp $101
        bne stackerror
        jmp :+
stackerror:     
        putc 10
        jsr printstack

        ;; reset stacck
        ldx #$ff
        txs

        putc 10
        putc '%'
        putc 'S'
        putc '>'

        jmp _edit
        
:       
.endif ; CHECKSTACK


.ifdef DEBUGRULE
    pha
;    lda rulename
;    jsr putchar
;    putc '.'
    ldy #0
    lda (inp),y
    jsr putchar
    putc ' '
    pla
.endif

.ifdef DEBUG
.else
  .ifdef SHOWINPUT
    pha
    ldy #0
    lda (inp),y
    jsr putchar
    pla
  .endif
.endif ; DEBUG

.ifdef DEBUG
    ;; RULE
    putc 10
    lda rulename
    jsr putchar
    putc '.'
    ldy #0
    lda (rule),y
    jsr putchar
    ;; INPUT
    putc ':'
    ldy #0
    lda (inp),y
    jsr printchar
    putc ' '
.endif ; DEBUG

;;; TODO: ;;;;;
.ifdef xDEBUGRULE
;    PUTC ' '
    PUTC 10
    ldy #0
    lda (rule),y
    jsr putchar
.endif ; DEBUG

;;; Actual code to process rule, lol

        ldy #0
        lda (rule),y

        ;; hibit - new rule?
        bpl :+
        jmp _enterrule
:       
        ;; 0 - end = accept
        bne :+
jmpaccept:      
        jmp _acceptrule
:       

;;; CHEAT!
;;; 1287500 before
;;; 1301114 after (inline inc, I extra cmp/bne costly?)
;;; 1244770 = 3.3% faster still _incI _incR
;;; 1233114 = 4.2% faster inline _inc
;;; 1232119 = 4.30% faster (no ldy)
;;; 1231955 = 4.31% cmp == skip (maybe not need?)
;;; 1230291 = 4.44% _donecompile
;;; 1247041
;;; 1229158 = 4.53% 0 => acceptrule
;;; 1252062 = 2.75% savings (PRINTDOTS add overhead...)

;;; 1278508 = 0.7% OVERHEAD from ERRPOS, acceptable...
;;;           need to insert it here.
;;; 
;;; (- 1 (/ 1252062 1287500.0))
;;; 
;;; 299 Bytes instead of 303, fail at least point?
;;; 
.ifdef OPTSKIP
        cmp (inp),y
        bne @noteq

@skipspc:
;        jsr _incI
        inc inp
        bne :+
        inc inp+1
:       

        lda (inp),y
        beq jmpaccept

        ;; no need handling # // % [ as they'll
        ;; most likely fail problem is %D or [
        ;; could give strange bugs...
        cmp #' '+1
        bcc @skipspc

;;; TODO: hi-bit makes problem...
;;;      and #$7f

.ifdef PRINTDOTS
;;; print next statement each time when
;;; there is a ';' or '{'

;;; TODO: 
        cmp #';'
        beq :+
        cmp #'}'
        bne @nosemi
:       
        putc ','
@nosemi:
.endif ; PRINTDOTS

       
;        jsr _incR
        inc rule
        bne :+
        inc rule+1
:       
        ;; comp rule?
        cmp (rule),y
        beq @skipspc
        jmp _next

;; fallback to more costly, check-all!
@noteq:
.endif ; OPTSKIP

        ;; \ - quoted
        ;; (can't quote 0, hmmm)
        cmp #'\'
        beq quoted

        ;; | - also accept
        cmp #'|'
        beq  jmpaccept

	;; - % handle special matchers
        cmp #'%'
        beq percent

        ;; - [ gen-rule
        cmp #'['
        bne testeq
        jmp _generate

        ;; literal equal test match
quoted:
        ;; - \[ for example, match special chars
        jsr _incR
        lda (rule),y

testeq: 
        ;; - lit eq?
        cmp (inp),y
;;; LOL: relocate to "middle"?
        beq eqjmp
failjmp:
        jmp _fail
eqjmp:  
        jmp _eq

        ;; percent matchers
percent:
        jsr _incR
        ldy #0
        lda (rule),y

        sta percentchar
.ifdef DEBUGFUN
putc '%'
lda percentchar
jsr putchar
.endif ; DEBUGFUN

        ;; - skip it assumes A not modified
        ; pha
        jsr _incR
        ; pla

.ifdef IMMEDIATE
;;; 26 B
        ;; immediate code! to run NOW!
        cmp #'{'
        bne noimm
        ;; - copy rule address (self-modifying)
        lda rule
        sta imm+1
        ldx rule+1
        stx imm+2
        ;; - jump to the rule inline code!
imm:    jmp $ffff
        ;; that code "returns" by jsr immret!
        ;; (this puts after the code on stack)

;;; loads address of IMM_RET (inline in rule)
;;; and sets rule to it, to jump over it!
immret:
        pla
        sta rule
        pla
        sta rule+1
        jsr _incR
        jmp _next
immfail:
;;; TODO: doesn't seem to work correwctly
;;; TODO: isn't used...
        pla
        sta rule
        pla
        sta rule+1
        jmp _fail

.macro IMM_RET
        jsr immret
.endmacro

.macro IMM_FAIL
        jmp _fail
;;; TODO: doesn't work???
;        jsr immfail
.endmacro

        
noimm:
.endif ; IMMEDIATE

        ;; Digits? (constants really)
        cmp #'D'
        bne :+

        jmp _digits
:       

.ifdef STRING
        ;; String?
        cmp #'s'                ; means skip
        beq string
        cmp #'S'                ; means Copy
        beq string
.endif ; STRING

        ;; ELSE assume it's %var..
jmpvar: 
        ;; - % anything...
        ;;   %V (or %A %N %U %...)
        jmp _var


        ;; - "constant string"
        ;; (store inline!?)
string: 
        ;; determine if to Copy (%S not %s)
        lda percentchar
        cmp #'s'                ; sets C= not copy
        bcs :+
        ;; Copy
        lda #128
        sta percentchar
        putc '!'
:       
        ;; use "bit percentchar" to test bmi if to Copy

str:    
        ;; Y=0 still
        ;; get first char
;        ldy #0
        lda (inp),y
        beq failjmp
        ;; " - at end?
        cmp #'"'                ; "
        beq @zero

        ;; - quote (next char is raw)
        cmp #'\'
        bne @plain
        ;; -- quoted
        jsr _incI
        ;; - \n => 10
        cmp #'n'
        bne :+
        lda #10
:       
        ;; - \t => 9
        cmp #'t'
        bne :+
        lda #9
:       
        ;; TODO: - \xff
@plain:
        ;; skip to next char (keeps A)
        jsr _incI

        ;; - Copy (C=1)
        ;; 7bit set if to Copy
        bit percentchar
        bpl str

        ;; TODO: call jsr _outbyte?
        ;; 7 B
        ; ldy #0 
        sta (_out),y
jsr putchar
        jsr _incO
        jmp str

@zero:
        ;; - Copy (C=1)
        ;; 7bit set if to Copy
        bit percentchar
        bpl @noout
        ;; zero-terminate if gen
        lda #0
        sta (_out),y
        jsr _incO
@noout:       
        ;; skip "
        jmp _nextI



;;; TODO: remove?
FUNC _eq    
;;; 9 B
    DEBC '='
        jsr _incR
        jmp _nextI



FUNC _enterrule
.ifdef PRINTASM
        pha
        txa
        pha
        tya
        pha

;        jsr _iasm
        pla
        tay
        pla
        tax
        pla
.endif ;PRINTASM



.ifdef TRACERULE
        pha
;;; not totally correct
.ifdef TRACEDEL
        cmp #TAILREC
        beq :+
.endif
        putc '>'
        ldy #0
        lda (rule),y
        jsr putchar
        cmp #TAILREC
        bne :+
        lda rulename
        jsr putchar
;        jsr printstack
:       
        pla
.endif ; TRACEFULE

;;; 34 B
        ;; enter rule
        ;; - save current rulepos
    DEBC '>'
.ifdef DEBUGKEY
        jsr getchar
        cmp #13
        bne :+
        ;; print state
        putc 10
        putc '~'
        jsr putchar
        lda inp
        ldx inp+1
        jsr _printz
        putc 10
:       
        ldy #0
        
.endif ; DEBUG

        ;; TAILREC?
        cmp #TAILREC
        bne @pushnewrule

.ifdef DEBUGRULE2
;        putc 'R'
.endif
        jmp _acceptrule

;;; Hi-bit set, and it's not '*'
@pushnewrule:
        lda rule+1
        pha
        lda rule
        pha
        lda rulename
        pha

        ;; save re-skipping!
;;; TODO: would like to get rid of this
;;;   but _next skips whitespace only
;;;   (I think?)
;;; This skips // comments and #define #include...
        jsr nextInp

        ;; - push inp for retries
        lda inp+1
        pha
        lda inp
        pha
        lda #'i'
        pha

        ;; - load new rule pointer
        lda (rule),y
        sta rulename

.ifdef DEB3
    PUTC ' '
    jsr printchar
    PUTC '>'
.endif

.ifdef DEBUGRULE
    PUTC ' '
    jsr putchar
    PUTC '>'
.endif

loadruleptr:
        and #31
        asl
        tay
        lda _rules,y
        sta rule
        lda _rules+1,y
        sta rule+1


.ifdef DEBUGRULE
;    jsr printstack
.endif
        jmp _next
;;; TODO: use jsr, to know when to stop pop?
;;; (maybe don't need marker on stack?)


;;; We arrive here once a rule is matched
;;; successfully. We then cleanup 'i'nput and do
;;; any needed 'p'atching, until we reach another
;;; rule to continue parsing (or end).

FUNC _acceptrule

;;; Theory:
;;;   program compile fail (unless error up-propagates)
;;;   is AFTER the last position of input that generated
;;;   code! lol

;;; seems this in _acceptrule is cheaper than _fail
.ifdef ERRPOS
        ;; update if inp>erp
        lda inp

        ldx inp+1
        cpx erp+1
        bcc @noupdate
        bne @update

        cmp erp
        bcc @noupdate
        beq @noupdate
@update:
        sta erp
        stx erp+1
@noupdate:       
.endif        

.ifdef PRINTASM
        putc 128+5              ; magnenta RULE

        lda rulename
        jsr putchar

        putc 128+2              ; green code text

;        jsr _iasm
.endif ; PRINTASM

.ifdef TRACERULE

.ifdef TRACEDEL
        jsr bs
        jsr putchar

        jsr spc
        jsr putchar

        jsr bs
        jsr putchar
.else
        putc '<'
.endif ; TRACEDEL

.endif ; TRACERULE

;;; 19 B
    DEBC '<'
.ifdef DEBUGRULE
    putc '<'
.endif

@loop:
.ifdef DEB2
PUTC '.'
.endif
        ;; remove (all) re-tries
        pla

.ifdef DEBUGRULE2
    pha
    jsr printchar
;    jsr printstack

;;; Doesn't get here....?
        tsx
        bne :++
        PUTC 'X'
:       jmp :-
:       

    pla
.endif

        bmi uprule
        ;; - done?
        cmp #DONE
;;; TODO: what to do if have data left?
        bne :+
        ;; yes, done, no error
        jmp _donecompile
:       
        
        ;; 'p' - PATCH
        cmp #'p'
        bne @dropone
    DEBC 'P'
        pla
        sta pos
        pla
        sta pos+1

        ;; patch to here!
        ldy #0
        lda _out
        sta (pos),y
        iny
        lda _out+1
        sta (pos),y

        jmp @loop

;;; typically an 'i' but could be an '&'
@dropone:
.ifdef DEB2
PUTC '='
.endif

;        jsr putchar
    DEBC '.'
.ifdef DEBUGRULE
    putc '.'
.endif

        pla
        pla
        jmp @loop

;;; hibit - RULE
uprule:
        ;; put it back
        pha

        ;; is it TAILREC?
        ldy #0
        lda (rule),y
        cmp #TAILREC
        bne yesgoup
        
        ;; - commit inp so far
        lda inp+1
        pha
        lda inp
        pha
        lda #'i'
        pha
        ;; - reset current rule to beginning
        lda rulename
        jmp loadruleptr

yesgoup:
        pla

.ifdef DEB3
PUTC '^'
jsr printchar
.endif

.ifdef DEB2
PUTC '^'
.endif

.ifdef DEB2
sta savea

tsx
stx tos
lda #0
sta tos+1
jsr putu
PUTC 10

lda savea
.endif

.ifdef DEBUGRULE
    PUTC '_'
.endif

    DEBC '_'

        ;; - restore partial parsed rule
        sta rulename
        pla
        sta rule
        pla
        sta rule+1

.ifdef DEBUGRULE
        putc '/'
        lda rule
        sta tos
        lda rule+1
        sta tos+1
        jsr puth
        putc 10
        jsr printstack
.endif

        ;; exit rule
        jsr _incR
        jmp _next



FUNC _fail
        
;;; seems this in _acceptrule is cheaper than _fail
.ifdef xERRPOS
        ;; update if inp>erp
        lda inp
        ldx inp+1

        cpx erp+1
        bcc @noupdate
        bne @update

        cmp erp
        bcc @noupdate
        beq @noupdate
@update:
        sta erp
        stx erp+1
@noupdate:       
.endif ; ERRPOS


;;; 2159605 before FASTSKIP
;;; 1287228 with FASTSKIP! - half the time almost
;;; (/ 1287228 2159605.0) == 40.4% faster!
;;; 
;;; size 78 -> 87 Bytes (+ 9)

        ;; Y= inp.lo; // faster looping!
        ldy rule
        lda #0
        sta rule
@loop:
        lda (rule),y
        beq endrule

        cmp #'|'
        beq @nextalt

        cmp #'['
        beq @skipgen

        ;; not '[' - normal char to skip!
@next:
        iny
        bne @loop
        inc rule+1
        ;; always!
        bne @loop

        ;; skip [...0...] gen
@skipgen:
        iny
        bne :+
        inc rule+1
:       
        lda (rule),y
        cmp #']'
        bne @skipgen
        beq @next
        
;;; we're done skipping! (standing at '|')
@nextalt:
        ;; finally write it back!
        sty rule

        ;; skip '|'
        jsr _incR

restoreinp:
        ;; restore inp for alt

        ;; - peek stack
        pla
        pha
        ;; TODO: correct jump? is it error?
        ;;  (means? still have input?)
        ;        bmi gotendall
        bmi unexpectedrule
        cmp #DONE
        ; lda #0 ???? if no error
        beq _donecompile

        cmp #'i'
        beq gotretry

        ;; ignore... whatever is on the stack...
        pla
        pla
        pla

        jmp restoreinp

gotretry:
.ifdef DEBUGRULE
    putc '!'
    putc 10
.endif
    DEBC '!'

        ;; copy/restore inp and leave at stack
        tsx

        pla
        pla
        sta inp
        pla
        sta inp+1
        txs
        jmp _next

;;; we come here if FAIL find no '|' alt
endrule:

.ifdef DEB3
PUTC '/'
lda rulename
jsr printchar
.endif

.ifdef DEBUGRULE
   putc 'E'
;   jsr printstack
.endif

	;; END - rule
    DEBC 'E'

        ;; TODO: is this always like this?
        ;; (how about patch?)

        ;; nothing to backtrack

        ;; - get rid of 'i' retry ????
        pla


.ifdef DEB3
PUTC '&'
jsr printchar
.endif

.ifdef DEBUGRULE2
pha
putc ' '
ldy #0
lda (rule),y
jsr printchar
lda (inp),y
jsr printchar
putc '\'

jsr printstack

putc '/'
pla
:       
jsr printchar
tsx
;;; TODO: hmmm
beq _donecompile                ; or %S TODO:
cmp #DONE
;;; TODO: hmmm
beq _donecompile                ; ???
;cmp #'i'
;beq :+

;;; not expected, try sync up...

putc '/'
pla
pla
jmp :-

:

.endif ; DEBUGRULE2

        pla
        pla

        ;; - get rid of _R current rule
        pla

.ifdef DEBUGRULE2
jsr printchar
PUTC ' '
.endif

;.endif
        pla
        pla

        ;; need to prime uprule with one value
        ;; (this was mising -> unbalanced before)
:       
        pla
        bmi :+
;;; TODO: this fixes parse issue, ^i rule lol
;;;   but it probably drops a 'P' patch???

;;; NO, that's not the case....

;;;  TODO: loop instead, but why we got here?
        ;; not rule, go up!


;;; TODOTODOTODO:TTTOOODDDOOO fixme!
;;;    or not, what does it break?

        pla
        pla
        jmp :-
:       
        jmp uprule





_donecompile:   
        lda #0
        ;; A contains error code; 0 if no error
_errcompile:

        TIMER

.ifdef TRACERULE
        putc 10
.endif
.ifdef DEBUGRULE
        jsr printstack
.endif
        ;; no errors - lol
        lda #0
        jmp _aftercompile


;;; --------------------------- ERRORS

FUNC _errors
;;; 25 B

;;; ? mismatch stack?
unexpectedrule:
.ifdef CHECKSTACK
        putc '%'
        putc 'R'
        jmp stackerror
.else
        lda #'R'
        SKIPTWO
.endif
illegalvar:     
        lda #'I'
        SKIPTWO
;; Unexpected End of input
gotendall:
        lda #'E'
        SKIPTWO
;;; ???
failrule:
        lda #'Z'
        SKIPTWO
;;; Unexpected char?
failed:
        lda #'F'
        ;; fall-through to error

;;; After error, it calls _aftercompile
;;; A register contains error
error:
        pha
        putc 10
        putc '%'
        pla
        jsr putchar

        ;; go edit to fix again!
        jmp _edit


halt:
        jmp halt



FUNC _var
;;; 42 B
DEBC '$'
        ldy #0
        lda (inp),y
.ifnblank
PUTC '%'
jsr putchar
.endif

@global:
        ;; verify/parse single letter var
;;; range can probably in this case be done
;;; with XOR #64 ; CMP #('z' & 63) - save 1 b!
        sec
        sbc #'A'
;;; TODO: enable for a-z too, now only F
        cmp #'z'-'A'+1
;;; If we limit to A-F suddenly "word main()" doesn't
;;; parse. Since we take only char (first) "ain"
;;; doesn't match so it'll backtrack up to ruleP word main
;;; 
;;; TODO: but why is that fail different from this?
;;;   this causes ruleP: "word main(){...}" to fail!

;        cmp #'Z'-'A'+1

        bcc :+
        jmp failjmp
:

;;; TODO: move a-z A-Z to zp
        ;; pick global address
        asl
        adc #<vars

;;; TODO: dos and tos??? lol
;;;    good for a+=5; maybe?
        sta tos
        tay
;;; TODO: simplify (?)
        lda #>vars
        adc #0
        sta tos+1
        ;; AY = lohi = addr

.ifdef DEBUGFUN
putc '!'
lda percentchar
jsr putchar
jsr puth
.endif ; DEBUGFUN

        ;; %N = New defining function/variable
        ;; (TODO: if used for var they are inline code)
        lda percentchar
        cmp #'N'
        bne :+

        ;; - *FUN = out // *tos= out
        lda _out
        ldy #0
        sta (tos),y
        iny
        lda _out+1
        sta (tos),y
.ifdef DEBUGFUN
putc '='
ldy #1
lda (tos),y
tax
dey
lda (tos),y
jsr axputh
.endif ; DEBUGFUN
        jmp @set
:
        ;; %U = Use value of variable
        ;; (for functions if forward, may not
        ;;  have value jmp (ind) more safe!)
        cmp #'U'
        bne @nofun
.ifdef DEBUGFUN
PUTC 'U'                       
.endif ; DEBUGFUN
        ;; - tos = *tos !
        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y

        ;; tos= *tos (get value of var/fun)
        sta tos
        stx tos+1
.ifdef DEBUGFUN
putc ':'
jsr puth
.endif ; DEBUGFUN
        jmp @noset

        ;; TODO: idea: push to auto-gen funcall?!
.ifnblank
        ;; hi
        lda (tos),1
        pha
        lda (tos),0
        pha
        lda #'f'
        jmp _next
.endif


@nofun:
        
.ifnblank
        ;; - is assignment? => set dos
        ;; percentchar='A' >>1 => C=1
        ;;             'V' >>1 => C=0
        ror percentchar
        bcc @noset
        ;; - do set dos
.else
        cmp #'A'
        beq @set
        cmp #'V'
        beq @noset
        ;; err
        jmp error
.endif
        
@set:
        lda tos
        sta dos
        lda tos+1
        sta dos+1

@noset:
        ;; skip read var char
        jmp _nextI


.ifdef LONGNAMES
    putc '$'
        jsr _parsename
        beq failjmp2
        ;; got name
        jsr _find
        ;; return address
    ldy #2
    lda (pos),y
    sta tos
    iny
    lda (pos),y
    sta tos

    jsr putu

    PRINTZ "HALT"
    jmp halt

.else ; !LONGNAMES

        sec
        sbc #'a'
        cmp #'z'-'a'+1
        bcc @skip
        jmp failjmp
@skip:

;;; LOCAL
.ifnblank
        lda percentchar
        cmp #'a'
        bcc @global
@local:
        ;; pick local address (a,b,c...)
        asl
        sta tos
;;; TODO: use JSR/RTS loop intead of _next?
        jmp _next
.endif

.endif ; !LONGNAMES



;;; TODO: can conflict w data
;;;   write .pl script look at .lst output?
FUNC _generate
;;; ??? 19 B
        jsr _incR
        ldy #0
        lda (rule),y

        ;; ']' - END GEN
        cmp #']'
        bne :+
        DEBC ']'
        ;; - done

.ifdef xERRPOS
        lda inp
        sta erp
        ldx inp+1
        stx erp+1
.endif ; ERRPOS

        jsr _incR
        jmp _next
:       
        ;; Call substitute for $20 as it gets "quoted"
        cmp #'C'
        bne :+
        
        lda #$20                ; JSR
        jmp @skipjsr
:       
        ;; ' '- JSR skip 2 bytes (QUOTE THEM!)
        cmp #$20                ; JSR xx xx 
        ; ldx #1 ; ???
        bne :+
        ;; TODO: jmp?
        ;cmp #$4c                ;JMP xx xx
        ;; out JSR (' ')
;;; 28B
        sta (_out),y
        jsr _incO

        jsr _incR
        lda (rule),y
        sta (_out),y
        jsr _incO

        jsr _incR
        lda (rule),y
        sta (_out),y
        jsr _incO

        jmp _generate

;;; TODO: hmmm
;;; 21...?
        sta (_out),y
        jsr _incO

        ;; Y stil 0
        ;; lo: read next
        jsr _incR
        lda (rule),y

        ;; hi: read next (inc in genoutAX)
        pha

        jsr _incR            
        lda (rule),y
        tax

        pla
        jmp genoutAX

@skipjsr:
:       
;;; '<' LO %d
        cmp #'<'
        bne :+
DEBC '<'
        lda tos
        jmp doout
:       
;;; '>' HI %d
        cmp #'>'
        bne :+
DEBC '>'
        lda tos+1
        jmp doout
:       
;;; 'D' SET tos=dos
        cmp #'D'
        bne :+
DEBC 'D'
        lda dos
        sta tos
        lda dos+1
        sta tos+1
        jmp _generate
:  
;;; 25B
;;; 'd' pos=tos
        cmp #'d'
        bne :+
DEBC 'd'
        lda tos
        sta dos
        ldx tos+1
        stx dos+1
        jmp _generate
:       
;;; '#' push tos
        ;; dos=tos
        cmp #'#'
        bne :+
DEBC '#'
        lda tos+1
        pha
        lda tos
        pha
        lda #'p'
        pha
        jmp _generate
:       
;;; '{{' PATCH
        cmp #'{'
        bne :+
DEBC '{'
        lda _out+1
        pha
        lda _out
        pha
        lda #'p'
        pha
        jsr _incO
        jsr _incR
        jsr _incO
        jmp _generate
:       
;;; ":" PUSH HERE
        cmp #':'
        bne :+

        lda _out+1
        pha
        lda _out
        pha
        lda #'&'
        pha
        jmp _generate
:       
;;; ";" POP -> %D (tos)
        cmp #';'
        bne :+

        pla
.ifdef SANITY
        cmp #'&'
;;; TODO: ... bne error
.endif
        pla
        sta tos
        pla
        sta tos+1
        jmp _generate
:       
;;; "+" PUT %d+1
        cmp #'+'
        bne doout               ; raw byte - no special
DEBC '+'
        ldx tos+1
        ldy tos
        iny
        tya
        bne @noinc
        inx
@noinc:

genoutAX: 
        ;; put
        ldy #0
        sta (_out),y
        ;; - is second R char '>'?
.ifblank
        iny
        lda (rule),y
        cmp #'>'
        bne gendone
        dey
.endif
        ;; output '>' hibyte
        txa
        ;; these don't touch A
        ;; X changed, but that's ok!
        jsr _incR
        jsr _incO
        ;; fall-through doout
doout:
        sta (_out),y
gendone:
        jsr _incO
        jmp _generate



FUNC _digits
DEBC '#'
;;; 55 B + 18 B char

        ;; valid initial digit or fail?
        ldy #0
        lda (inp),y

        ;; 'c' : is char?
        cmp #'''
        beq ischar
        ;; TODO: C=1 from cmp if digit
        ;; 0-9 : is digit?
        sec
        sbc #'0'
        cmp #10
        bcs failjmp2

        ;; start with 0
        lda #0
        sta tos
        sta tos+1

nextdigit:
        ldy #0
        lda (inp),y

        ;; change '0'-> 0
        sec
        sbc #'0'
        cmp #10
        bcc digit
        ;; Done
        ;; > 9 : end == OK
        jmp _next

digit:  
;;; 20 B
        pha
        jsr _mul10
        pla
        ;; add digit from A to tos
        clc
        adc tos
        sta tos
        bcc :+
        inc tos+1
:       
        jsr _incI
        jmp nextdigit

ischar: 
;;; 18 B
        ;; - get char
        jsr _incI
        ;; - y is retained by _incI
        lda (inp),y
        sta tos
        sty tos+1
;;; TODO: quoted \n \r \0 \... ? \' \\
;        cmp #'\'
        ;; - skip char
        jsr _incI
        ;; - skip '
        jsr _incI
        jmp _next



failjmp2:        
        jmp _fail



;;; TODO: cleanup!

;;; Consumes current input char, moves to next
;;; no-space character.
;;; 
;;; Any // comment is skipped till newline
;;; Same goes for #define or whatever (for now)
;;; TODO: maybe do simple macros, at least to treat
;;;       like constant INT/STRINGS






;;; TODO: cannot remove as this is the onlyi
;;;  place that skips // comments
;;;  and # defines....  lol

;.ifdef TODOREMOVE
.ifndef TODOREMOVE            

;; registers untouched
FUNC _incIspc
        jsr _incI

;;; makes sure inp is pointing at relevant char
;;; - skips any char <= ' ' (incl attributes)
;;; - skips "// comment till nl"
FUNC nextInp
.scope
;;; oops! this was actually important to save all regs!
        pha
        txa
        pha
        tya
        pha

nextc:
        ldy #0
        lda (inp),y
        bpl :+
        ;; hi-bit set => reset, lol (cursor?)
        and #$7f
        sta (inp),y
:       
        beq done

.ifdef PRINTDOTS
        ;; at each newline print a dot
        ;; cmp #10

        ;; trigger on end of statements
        ;; - foo();
        ;; - while () {
        cmp #';'
        beq :+
        cmp #'{'
        bne @nosemi
:       

;;; TODO: move to subroutine
;;; TODO: keep track of last printed src
;;;       (and don't print again, lol)

        PUTC '.'
@nosemi:
.endif ;PRINTDOTS

        ;; CTRL characters/space skip
        cmp #' '+1
        bcc skipspc

;;; <------------Add more cases here!----------->

        ;; #include <...  - just ignore all #! .. NL!
        ;; CPP macros are complicated?
        ;; - https://en.cppreference.com/w/c/language/translation_phases.html
        cmp #'#'
        beq tillNL

        ;; // comment till NL
        cmp #'/'
        bne done

        ;; look-ahead 1 is '/'?
        iny
        lda (inp),y
        ;; second /
        cmp #'/'
        bne done

        ;; - is comment, skip till NL
tillNL:
        jsr _incI
        ldy #0
        lda (inp),y
        beq done
        cmp #10
        bne tillNL

skipspc:
        jsr _incI
        jmp nextc

done:
.ifnblank
ldy #0
lda (inp),y
putc '@'
jsr printchar
.endif

.ifdef UPDATENOSPACE
.ifdef xERRPOS
;;; store max input position
;;; (indicative of error position)
        lda inp+1
        cmp erp+1
        bcc noupdate
        bne update
        ;; erp.hi == inp.hi
        lda inp
        cmp erp
        bcc noupdate
        beq noupdate
        ;; erp := inp
update:
.ifdef xPRINTREAD
        pha

        ldy #0
        lda (erp),y
        jsr putchar

.ifnblank
        sta tos
        lda #0
        sta tos+1
        putc '#'
        jsr putu
        putc ' '
.endif

        pla
.endif

        sta erp
        lda inp+1
        sta erp+1
noupdate:
.endif ; ERRPOS
.endif ; UPDATENOSPACE


        pla
        tay
        pla
        tax
        pla
.endscope
        rts

.endif ; TODOREMOVE






;;; written more to save bytes as each
;;; is only +3 B, but costs increase till 3x!
;;; 
;;; They are ordered so I is fastest, then
;;; R O P T which probably would relate to
;;; frequency of usage...

FUNC _incT
;;; 3  32c!
        ldx #tos
        SKIPTWO
FUNC _incP
;;; 3  27c! (used for print?... TODO: optimize?)
        ldx #pos
        SKIPTWO
FUNC _incO
;;; 3  22c
        ldx #_out
        SKIPTWO
FUNC _incR
;;; 3  17c
        ldx #rule
        SKIPTWO
FUNC _incI      
;;; 2  12c
        ldx #inp
FUNC _incRX
;;; 6+1  10c (+ 4c seldomly) +12c for calling it!
        inc 0,x                 ; 6c
        bne @noinc
        inc 1,x
@noinc:
        rts
        

rts



.ifdef CUT
cut:    
;;; OK this works! (but no benefit)
;        pla
;        pla
;        jmp _fail

        ;; save current char
;;; TODO: use the inpC stuff
        ldy #0
        lda (inp),y
        sta savea
;PUTC '@'
;jsr putchar
        ;; search from 
@next:
        iny
        lda breakchars-1,y
;PUTC '^'
;jsr putchar
        ;; @end FAIL - try all the rules
        ;; (ugh; NO use '|' - it cannot skip - lol)
        cmp #'|'+128
        bne :+

        pla
        pla
        jmp _fail
:       
        cmp savea
        bne @next

;;; should work, return and go to _accept?
;;; doesn't
;        rts

;;; OK, so far so good
;        pla
;        pla
;        jmp _fail


        pla
        pla

.ifnblank
        ;; should also work, but EXIT?
        lda #<nextrule-1
        sta rule
        ldx #>nextrule-1
        stx rule+1
        jmp _next
.endif
;        jmp _fail

        ;; should work... but?
        jmp _acceptrule

.endif ; CUT


.ifdef LONGNAMES

;;; --- name handling

;DEBNAME=1

;;; env pointing to new empty entry
;;;   but @0 has link to previous
;;; Result:
;;;   new entry all linked up
;;;     with newnew link and 0 value
;;;   valid byte > 0 if have name

FUNC _parsename
;;; 66 B
        ;; pos = env+4
        lda env
        clc
        adc #4
        sta pos
        lda env+1
        adc #0
        sta pos+1
        ;; parse name
        ldy #0
        sty valid

.ifdef DEBNAME
  putc '@'
  lda pos
  sta tos
  lda pos+1
  sta tos+1
  jsr putu
  putc ' '

  ldy #0
.endif ; DEBNAME
        

@copy:
        ;; - copy one char
        lda (inp),y
        sta (pos),y
        ;; - is valid char?
        sec
        sbc #'a'
        cmp #'z'-'a'+1
        bcs @notidentchar

.ifdef DEBNAME
   lda (inp),y
   jsr putchar
.endif ; DEBNAME
        ;; - valid
        inc valid
        jsr _incI
        jsr _incP
        jmp @copy
        
@notidentchar:
        ;; end of ident
        ;; - zero terminate
        tya
        sta (pos),y
        jsr _incP

.ifdef DEBNAME
  putc '@'
  lda pos
  sta tos
  lda pos+1
  sta tos+1
  jsr putu
  putc ' '
  ldy #0
.endif ; DEBNAME

        ;; prepare next new entry!
;;; TODO: copyreg?
        ;; - link to prev
        lda env
        sta (pos),y
.ifdef DEBNAME
  sta tos
.endif ; DEBNAME
        lda env+1
        iny
        sta (pos),y
.ifdef DEBNAME
  sta tos+1
  jsr putu
  PUTC ' '
  ldy #1
.endif ; DEBNAME
        ;; - zero value
        lda #0
        iny
        sta (pos),y
        iny
        sta (pos),y
        
        ;; return valid Z=0
        lda valid
        rts


;;; word to find: @env+4 (written by parser)
FUNC _find
;;; 56 B
        ldy #3

        lda env
        sta gos
        lda env+1
        sta gos+1

@nextword:
        ;; go prev
        ;; - load prev
;;; TODO: code jsr _link ?
.ifdef DEBNAME
   PUTC 10
   PUTC '>'
.endif ; DEBNAME

        ldy #0
        lda (gos),y
        tax
        iny
        lda (gos),y
        sta gos+1
        stx gos

.ifdef DEBNAME
  sta tos+1
  stx tos
  jsr putu
.endif ; DEBNAME
        ;; end?
        ora gos
        bne @matchword
@notfound:
.ifdef DEBNAME
   PUTC '%'
.endif ; DEBNAME
        ;; - create!
        ;; - commit - link it in
        lda pos
        sta env
        lda pos+1
        sta env+1
;;; TODO: give error
        rts

@matchword:
.ifdef DEBNAME
    PUTC '?'
.endif ; DEBNAME
        ;; match word
        ldy #3
@match:
        iny
        lda (gos),y
        beq @endword

.ifdef DEBNAME
    PUTC ':'
    jsr putchar 
    pha
    lda (env),y
    jsr putchar
    pla
.endif ; DEBNAME

        cmp (env),y
        beq @match

@notmatch:
.ifdef DEBNAME
    PUTC '|'
.endif ; DEBNAME
        jmp @nextword
        
@endword:
        lda (env),y
        bne @notmatch
@found:
.ifdef DEBNAME
    PUTC '!'
.endif ; DEBNAME
        ;; Z=1
        rts

.endif ; LONGNAMES

;;; dummy
_drop:  rts

FUNC _dummy

        
;;;                  M A I N
;;; ========================================

endfirstpage:        
_endfirstpage:


FUNC _dummy4

;;; END CHEAT?

FUNC _bnfinterpend

;;; NO-need align...
;  .res 256-(* .mod 256)
secondpage:     


.ifdef MEMSET
;;; tos: address
;;; AX : length
;;; Y  : byte
memset:
;;; 16B - call 3x+ save bytes... <3 inline ok
        pha
        tay
        pla
:       
        ldy #0
        sta (tos),y

        iny
        bne :+
        inc tos+1
:       
        dex
        bpl :--
       
        rts
.endif ; MEMSET

;;; TODO: still part of parse.bin
;;;    just not in screen display form firstpage/secondpage

;;; BEGIN CHEAT? - not count...



bytecodes:      

;;; ========================================
;;; START rules


.macro CHARCHECK addr,char
  .assert (<addr <> char),error,"%% XJSR addr - bad lo']'"
  .assert (>addr <> char),error,"%% XJSR addr - bad hi']'"
.endmacro

.macro CHECK addr
;;; can't give good error message...
;;        CHARCHECK(addr,']')

  .assert (<addr <> '<'),error,"%% RULE addr - bad lo'<'"
  .assert (>addr <> '<'),error,"%% RULE addr - bad hi'<'"

  .assert (<addr <> '>'),error,"%% RULE addr - bad lo'>'"
  .assert (>addr <> '>'),error,"%% RULE addr - bad hi'>'"

  .assert (<addr <> '+'),error,"%% RULE addr - bad lo'+'"
  .assert (>addr <> '+'),error,"%% RULE addr - bad hi'+'"

  .assert (<addr <> 'D'),error,"%% RULE addr - bad lo'D'"
  .assert (>addr <> 'D'),error,"%% RULE addr - bad hi'D'"

  .assert (<addr <> 'd'),error,"%% RULE addr - bad lo'd'"
  .assert (>addr <> 'd'),error,"%% RULE addr - bad hi'd'"

  .assert (<addr <> ':'),error,"%% RULE addr - bad lo':'"
  .assert (>addr <> ':'),error,"%% RULE addr - bad hi':'"

  .assert (<addr <> ';'),error,"%% RULE addr - bad lo';'"
  .assert (>addr <> ';'),error,"%% RULE addr - bad hi';'"

  .assert (<addr <> '#'),error,"%% RULE addr - bad lo'#'"
  .assert (>addr <> '#'),error,"%% RULE addr - bad hi'#'"

  .assert (<addr <> '{'),error,"%% RULE addr - bad lo'{'"
  .assert (>addr <> '{'),error,"%% RULE addr - bad hi'{'"

  .assert (<addr <> '?'),error,"%% RULE addr - bad lo'?'"
  .assert (>addr <> '?'),error,"%% RULE addr - bad hi'?'"

.endmacro

.macro XJSR addr
        CHECK(addr)
        jsr addr
.endmacro
        

;;; ------------------------------=


FUNC _rulesstart

;;; Rules 0,A-
_rules:  
        .word rule0             ; TODO: if we use &and?
        .word ruleA,ruleB,ruleC,ruleD,ruleE
        .word ruleF,ruleG,ruleH,ruleI,ruleJ
        .word ruleK,ruleL,ruleM,ruleN,ruleO
        .word ruleP,ruleQ,ruleR,ruleS,ruleT
        .word ruleU,ruleV,ruleW,ruleX,ruleY
        .word ruleZ
        .word 0                 ; TODO: needed?

;ruleF: byte rule, keeps AX, get byte expr => Y
;ruleG: calling convention "(@tos,AX) like ruleC
;ruleH: printf parsing
;ruleI:
;ruleJ:  
.ifndef BNFLONG
  ruleK:  
  ruleL:  
  ruleM:
;  ruleN:
.endif
;;ruleO:  
;;ruleP: - program
;;ruleQ: - array data
ruleR:
;;.ifndef MINIMAL
;;ruleU:  
;;.endif
;;ruleU: - BYTERULES "ruleC"
;;ruleV: - BYTERULES "ruleD"

;ruleW:  -   HW_PARMS
;ruleX:  -   cc65 parameter list
;;ruleY: -   parameters init
;;ruleZ: -   list of parameters
        .byte 0

_A='A'+128
_B='B'+128
_C='C'+128
_D='D'+128
_E='E'+128
_F='F'+128
_G='G'+128
_H='H'+128
_I='I'+128
_J='J'+128
_K='K'+128
_L='L'+128
_M='M'+128
_N='N'+128
_O='O'+128
_P='P'+128
_Q='Q'+128
_R='R'+128
_S='S'+128
_T='T'+128
_U='U'+128
_V='V'+128
_W='W'+128
_X='X'+128
_Y='Y'+128
_Z='Z'+128

;;; Zeroth-rule
;;; NOTE: can't backtrack here! do directly other rule!
rule0:  
        .byte _P,0

;;; PROBLEM is \0 in %{ code! can't skip when _fail!!
;;; 
;;; safer if done near end of of %{ area
        

;;; aggregate statements
ruleA:  


.ifdef CUT2
        ;; '}' marks end - CUT
      .byte "%{"
        ;; peek ahead
        ldy #0                  ; danger! 0 can't skip
        lda (inp),y
        cmp #'}'
        bne :+
        jmp _acceptrule
:       
        ;; put at end "past" any 0, lol
        lda #<@next
        ldx #>@next
        sta rule
        stx rule+1
;        IMM_FAIL
        jmp _fail
@next:   
        .byte '|'
.endif ; CUT2

        .byte _S,TAILREC,"|",0

;;; Block
ruleB:  
        .byte "{}"

        .byte "|{",_A
.ifdef PRINTASM
      .byte "%{"
        jsr asmprintsrc
        IMM_RET
.endif ; PRINTASM
        .byte "}"

        .byte 0

;;; stater of expression:
;;; "Constant"/(variable) (simple, lol)
ruleC: 
        
;;; TODO: these are "more" statements...
FUNC _iorulesstart
        ;; "IO-lib" hack
        .byte "putu(",_E,")"
      .byte '['
;;; TODO: change printers to use AX
        jsr axputu
      .byte ']'

        ;; compatibility

        .byte "|printf(",34,"\%u",34,",",_E,")"
      .byte '['
        jsr axputu
      .byte ']'

        ;; LOL: printf("%s", s); // safe...
        .byte "|printf(",34,"\%s",34,",",_E,")"
      .byte '['
        jsr axputz
      .byte ']'

.ifdef OPTRULES
.ifdef INLINEPUTZOPT
        .byte "|putz(",34
      .byte '['
        jsr iputz
      .byte ']'
        .byte "%S)"

        .byte "|fputs(",34
      .byte '['
        jsr iputs
      .byte ']'
        .byte "%S,stdout)"

        .byte "|puts(",34
      .byte '['
        jsr iputs
      .byte ']'
        .byte "%S)"
.endif ; INLINEPUTZOPT
.endif ; OPTRULES

        .byte "|fputs(",_E,",stdout)"
      .byte '['
        jsr axputz
      .byte ']'

.ifdef SIGNED
        .byte "|printf(",34,"\%d",34,",",_E,")"
      .byte '['
        jsr axputd
      .byte ']'

        ;; "IO-lib" hack
        .byte "|putd(",_E,")"
      .byte '['
;;; TODO: change printers to use AX
        jsr axputd
      .byte ']'
.endif ; SIGNED

        .byte "|puth(",_E,")"
      .byte '['
;;; TODO: change printers to use AX
        jsr axputh
      .byte ']'

        .byte "|putz(",_E,")"
      .byte '['
;;; TODO: fix, strings borken?
        jsr axputz
      .byte ']'

        .byte "|puts(",_E,")"
      .byte '['
.ifdef PRINTIT
        sta pos
        stx pos+1
        ldy #0
:       
        lda (pos),y
        beq :+
        jsr putchar
        iny
        bne :-
        inc pos+1
        bne :-
:       
.else
        jsr axputs
.endif
      .byte ']'

        .byte "|putcraw(",_E,")"
      .byte '['
        jsr putcraw
      .byte ']'

.ifdef OPTRULES
        ;; putchar constant - saves 2 bytes!
        .byte "|putchar(%V)"
      .byte '['
        lda VAR0
        jsr putchar
;;; TODO: about return value...
      .byte ']'

        ;; putchar variable - saves 2 bytes!
;;; TODO: parser skips space, hahahaha!
        .byte "|putchar('')"    ; LOL!!!!
      .byte '['
        jsr spc
;;; TODO: about return value...
      .byte ']'

        ;; putchar variable - saves 2 bytes!
        .byte "|putchar('\\n')" ;      double \\???
      .byte '['
        jsr nl
;;; TODO: about return value...
      .byte ']'

        ;; putchar variable - saves 2 bytes!
        .byte "|putchar(%D)"
      .byte '['
        lda #'<'
        jsr putchar
;;; TODO: about return value...
      .byte ']'
.endif ; OPTRULES

        .byte "|putchar(",_E,")"
      .byte '['
        jsr putchar
      .byte ']'



        .byte "|getchar()"
      .byte '['
        jsr getchar
        ldx #0
      .byte ']'
FUNC _iorulesend

.ifdef CTYPE
        .byte "|isxdigit(",_E,")"
      .byte '['
        jsr isxdigit
      .byte ']'

        .byte "|isdigit(",_E,")"
      .byte '['
        jsr isdigit
      .byte ']'

        .byte "|isalnum(",_E,")"
      .byte '['
        jsr isalnum
      .byte ']'

        .byte "|isalpha(",_E,")"
      .byte '['
        jsr isalpha
      .byte ']'

        .byte "|isspace(",_E,")"
      .byte '['
        jsr isspace
      .byte ']'

        .byte "|islower(",_E,")"
      .byte '['
        jsr islower
      .byte ']'

        .byte "|isupper(",_E,")"
      .byte '['
        jsr isupper
      .byte ']'

        .byte "|ispunct(",_E,")"
      .byte '['
        jsr ispunct
      .byte ']'

        .byte "|toupper(",_E,")"
      .byte '['
        jsr toupper
      .byte ']'

        .byte "|tolower(",_E,")"
      .byte '['
        jsr tolower
      .byte ']'
.else

;;; nah,it's compiletime
;FUNC _ctypestart 
;;; TODO: _byteexpr ??? X?
        .byte "|isdigit(",_E,")"
      .byte '['
;;; 11B
;;; TODO: make library? copy in on ref
        ldy #0
        sec
        sbc #'0'
        cmp #'9'-'0'+1
        bcs :+
        iny
:       
        tya
      .byte ']'

        .byte "|isalpha(",_E,")"
      .byte '['
        ldy #0
        ;; make all lower case
        ora #32
        sec
        sbc #'a'
        cmp #'z'-'a'+1
        bcs :+
        iny
:       
        tya
      .byte ']'

        ;; we take ourselves some freedom of interpreation!
        .byte "|isspace(",_E,")"
      .byte '['
        ldy #0
        cmp #' '+1
        bcs :+
        iny
:       
        tya
      .byte ']'
;FUNC _ctypeend
;;; nah,it's compiletime
.endif ; !CTYPE


FUNC _stringrulesstart
.ifdef STRING

        .byte "|strlen(",_E,")"
      .byte '['
        jsr strlen
      .byte ']'

        ;; all these takes 2 args
        ;; TODO: harmonize?
        .byte "|strchr(",_E,",",_F,")"
      .byte '['
        jsr strAXchrY
      .byte ']'

        .byte "|strcpy(",_G
      .byte '['
        jsr strTOScpy
      .byte ']'

        .byte "|strcat(",_G
      .byte '['
        jsr strTOScat
      .byte ']'

        .byte "|strcmp(",_G
      .byte '['
        jsr strTOScmp
      .byte ']'

        .byte "|strstr(",_G
      .byte '['
        jsr strTOSstr
      .byte ']'



.endif ; STRING
FUNC _stringrulesend


FUNC _memoryrulesstart

;;; ORIC peek/poke deek/doke
.ifdef OPTRULES



;;; TODO: too many |POKE( rules!!!!

;;; OK
        .byte "|poke(%D,"
      .byte "%{"
        ;; make sure %D <256
        lda tos+1
        beq :+
        IMM_FAIL
:       
        IMM_RET

        .byte "[#]",_I
      .byte "[;"
        sta '<'
      .byte "]"

;;; OK
        .byte "|poke(%D,[#]",_I
      .byte "[;"
        sta VAL0
      .byte "]"


.ifdef ZPVARS
;;; OK
        .byte "|poke(%V,0)"
      .byte "["
        ;; save 1 B
        ldy #0
        tya
        sta (VAR0),y
      .byte "]"

;;; OK
        .byte "|poke(%V,[#]",_I
      .byte "[;"
        ldy #0
        sta (VAR0),y
      .byte "]"
.endif ; ZPVARS        


;;; TOTEST
        .byte "|doke(%D[#],",_E,")"
      .byte "[;"
;;; TODO: how about zero page addresses! save 2B
        sta VAL0
        stx VAL1
      .byte "]"

.endif ; OPTRULES


;;; OK
        .byte "|poke(",_E,",",_J
;      .byte "%{"
;        putc '!'
;        IMM_RET
      .byte "["
        sta (tos),y
      .byte "]"

;;; TOTEST
        .byte "|doke(",_G
      .byte "["
        ;; AX: value to doke
        ;; tos: addrss to put it
      .byte "["
        ldy #0
        sta (tos),y

        txa
        iny
        sta (tos),y
      .byte "]"


.ifdef OPTRULES
;;; TODO: add ZPRULES opt?
;;; actually not needed if all vars are in zp...
;;;  just use indexing!!!!
;;; peek(%V) === $%V lol deek(%V) === *(word*)%A
        .byte "|peek(%D)"
      .byte '['
        lda VAL0
        ldx #0
      .byte ']'

        .byte "|deek(%D)"
      .byte '['
        lda VAL0
        ldx VAL1
      .byte ']'
.endif ; OPTRULES

        .byte "|peek(",_E,")"
      .byte '['
        sta tos
        stx tos+1
        ldy #0
        lda (tos),y
        ldx #0
      .byte ']'

        .byte "|deek(",_E,")"
      .byte '['
        sta tos
        stx tos+1
        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y 
      .byte ']'

.import _malloc
        .byte "|malloc",_X
      .byte "["
        jsr _malloc
      .byte "]"

.import _free
        .byte "|free",_X
      .byte "["
        jsr _free
      .byte "]"

.import _realloc
        .byte "|realloc",_X
      .byte "["
        jsr _realloc
      .byte "]"

.ifdef NOTDEFINEDIN_CC65 ; ???
.import _heapmemavail
        .byte "|heapmemevail",_X
      .byte "["
        jsr _heapmemavail
      .byte "]"

.import _heapmaxavail
        .byte "|heapmaxavail",_X
      .byte "["
        jsr _heapmaxavail
      .byte "]"
.endif

        ;; TODO: more like statement
        .byte "|SEI();"
      .byte '['
        sei
      .byte ']'

        .byte "|CLI();"
      .byte '['
        cli
      .byte ']'
FUNC _memoryrulesend





;;; TODO: disturbes parseing, maybe %{ ?
;JSK_CALLING=1

.ifndef JSK_CALLING

;;; TODO: REMOVE! just for test

        ;; Function call!!!
        .byte "|%U[#]()"
      .byte "[;"
        DOJSR VAL0
      .byte "]"

        ;; Function call!!!
;;; TODO: for 0 args this still pushes, lol
        .byte "|%U[#]("
        .byte _W
      .byte "[;"
        DOJSR VAL0
;;; TODO: remove, use JSK_CALLING
;;; (this is C style where caller cleanup)
tya

pla
pla

pla
pla

pla
pla

pla
pla

tya
      .byte "]"

.else

;;; ========================================
;;;          JSK CALLING CONVENTION
;;; 
;;;       Calling "foo" with parameters
;;;  
;;;              jmp callfoo
;;;     
;;;  fooparams:  
;;;              ... eval first param => AX ...
;;; 
;;;              ;; push reverse
;;;              pha
;;;              txa
;;;              pha
;;; 
;;;              ... second param ...
;;;              pha
;;;              txa
;;;              pha
;;; 
;;;              ... last param, same ...
;;;              pha
;;;              txa
;;;              pha
;;; 
;;; 
;;;              ;; finally call "foo"
;;;              JMP foo
;;; 
;;; 
;;;  callfoo:    JSR fooparams
;;;              ... foo returns here! ...
;;; 
;;; 
;;;  foo:        
;;;              ldy #8            ; 4 params = 8 bytes
;;;              jsr save_old_regs
;;;                  (+ copy_new_params_to_regs)
;;; 
;;;              ... body foo ...
;;;   
;;;              ;; drop params
;;;              ldy #8
;;;              jmp drop_and_restore
;;; 

;;; TODO:
FUN=$ffff
        ;; Function call!!!
        .byte "|fun"
      .byte "["
        ;; jump to jsr
        jmp FUN
        ;; jsr will call here!
        .byte ":"
      .byte "]"

        ;; generate evaluating
        ;; and pushing parameters
        .byte _W

      .byte "["
        ;; JUMP to the function; return after JSR!
        jmp FUN
        .byte ";d"              ; dos= pop ":"
        .byte ";"               ; tos= pop jmp
      .byte "]"

        ;; patch the jump to here
      .byte "%{"
        lda _out
        ldy #0
        sta (tos),y

        lda _out+1
        iny
        sta (tos),y
        IMM_RET
        
      .byte "[D"                ; tos= dos
        ;; JSR to generate parameters
        jsr VAL0
        ;; after FUN; it'll RTS to here!
      .byte "]"

.endif ; JSK_CALLING




;;; TODO: a&!b .. hmmmm
        ;; ! - NOT
;;; TODO: "!%V" ...?
;;; TODO: !(...) more safe?
        .byte "|!",_E
      .byte "["
;;; 12B
        ldy #0
        cmp #0
        bne @false
        txa
        bne @false
@true:  
        dey
@false:
        tya
        tax
      .byte "]"

        ;; cast to char == &0xff !
        .byte "|(char)",_C
      .byte '['
        ldx #0
      .byte ']'

        ;; casting - ignore!
        ;; (we don't care legal, just accept if correct)
;;; TODO: lol funny way of skipping name/id/type
        .byte "|(%V\*)",_C

        ;; array index
;;; TODO: simulated
;;; TODO: _E or _V ???
        .byte "|arr\[",_E,"\]"
      .byte '['
        tax
        lda arr,x
        ldx #0
      .byte ']'


        ;; function call
        .byte "|%U()"
      .byte '['
        ;; lol, we need to quote JSR haha
        DOJSR VAL0
      .byte ']'


        ;; EXTENTION
        ;; .method call! - LOL
        .byte "|.%U"
      .byte '['
        ;; parameter already in AX
        DOJSR VAL0
      .byte ']'



        ;; Surprisingly ++v and --v expression w value
        ;; arn't smalller or faster than v++ and v-- !
        .byte "|++%V"
      .byte '['
;;; 14B 17c
        inc VAR0
        bne :+
        inc VAR1
:       
        lda VAR0
       ldx VAR1
      .byte ']'

        .byte "|--%V"
      .byte '['
.ifnblank
;;; 17B 21c
        lda VAR0
        bne :+
        dec VAR1
:       
        dec VAR0
        lda VAR0
        ldx VAR1
.else
;;; 17B 19c
        ldx VAR1
        ldy VAR0
        bne :+
        dex
        stx VAR1
:       
        dey
        tya
        sta VAR0
.endif
      .byte ']'

        .byte "|%V++"
      .byte '['
;;; 14B ! 17c ! - no extra cost!
        lda VAR0
        ldx VAR1
        inc VAR0
        bne :+
        inc VAR1
:       
      .byte ']'

        .byte "|%V--"
      .byte '['
.ifblank
;;; 14B ! 17c
        ldx VAR1
        lda VAR0
        bne :+
        dec VAR1
:       
        dec VAR0
.else
;;; 17B 19c - faster
        ldx VAR1
        ldy VAR0
        dey
        tya
        bne :+
        dex
        stx VAR1
:       
        sta VAR0
.endif
      .byte ']'

;;; cc65: get parameter value from subroutine
;000055r 1  A0 01        	ldy     #$01
;000057r 1  B1 rr        	lda     (sp),y
;000059r 1  88           	dey
;00005Ar 1  11 rr        	ora     (sp),y
;;; probably have to turn it around

;;; TDOO: $ arr\[\] ... redundant?
;;; TODO: store addresss of arr in variable

        ;; variable
        .byte "|%V"
      .byte '['
        lda VAR0
        ldx VAR1
      .byte ']'

        .byte "|'\\n'"
      .byte "%{"
        putc '!'
        IMM_RET

      .byte '['
        lda #10
        ldx #0
      .byte ']'

.ifnblank
        .byte "|"

      .byte "%{"
        putc '"'                ; "
        IMM_RET

        .byte "'"
      .byte "%{"
        putc '1'
        IMM_RET

        .byte "\\"               ; "
      .byte "%{"
        putc '2'
        IMM_RET

        .byte "n"
      .byte "%{"
        putc '3'
        IMM_RET

        .byte "'"
        
      .byte "%{"
        putc '!'
        IMM_RET

      .byte '['
        lda #10
        ldx #0
      .byte ']'
.endif

.ifdef OPTRULES
        ;; load 0 saves 1 byte
        .byte "|0"
      .byte '['
        lda #0
        tax
      .byte ']'
.endif ; OPTRULES

        ;; digits
        .byte "|%D"
      .byte '['
        lda #'<'
        ldx #'>'
      .byte ']'
        


;;; TODO:       FAILS on sim65 !

;;; fine on ORIC - why?
;;; 
;;; It seems the address is 3 bytes too small,
;;; (if it was 2 it'd make sense as it's what PUSHLOC
;;;  is, but it ISN'T!)
;;; 
;;; possiblities:
;;;  a) addresses of vars are different?
;;;     (could interact w %{ but I tested
;;;      using subroutines, doesn't seem to bit it)
;;;  b) somebody is modifying DOS? (lo byte)
;;;  c) 


;;; Simpliest for now

.ifdef STRING
;;; TODO: remove routines at endrules
POS=gos

        .byte "|",34            ; " character
      .byte "["
        ;; jump over inline string
        jmp PUSHLOC
        .byte ";"
      .byte "]"               

        ;; copy string to out
        .byte "%S"

        ;; TODO: make a patch routine
      .byte "%{"
        ;; patch jump to here
        lda _out+1
        ldy #1
        sta (tos),y

        lda _out
        dey
        sta (tos),y

        ;; add 2 to tos to skip bytes
        clc
        lda tos
        adc #2
        sta tos
        bcc :+
        inc tos+1
:       
        IMM_RET

      .byte "["
        lda #'<'
        ldx #'>'
      .byte "]"
.endif ; STRING





.ifdef STRING_DIDNTWORK_ON_EITHER
;.ifdef STRING
;;; TODO: remove routines at endrules
POS=gos

        .byte "|",34            ; " character
      .byte "["
        ;; jump over inline string
        jmp PUSHLOC
        .byte ":;d;"
      .byte "]"

        ;; TODO: make a "swap" code
      .byte "%{"
        lda tos
        ldy dos
        sta dos
        sty tos

        lda tos+1
        ldy dos+1
        sta dos+1
        sty tos+1

        IMM_RET

        ;; push str addr back on stack
        .byte "[#D]"

        ;; copy string to out
        .byte "%S"

        ;; TODO: make a patch routine
      .byte "%{"
        ;; patch jump to here
        lda _out+1
        ldy #1
        sta (tos),y

        lda _out
        dey
        sta (tos),y

        IMM_RET

      .byte "[;"
        lda #'<'
        ldx #'>'
      .byte "]"
.endif ; STRING




;;; TODO: only works on ORIC, sim65 fails... wtf?

.ifdef STRING_HMM
POS=gos ;works
;POS=pos ;workd
;POS=dos ; FAILS! who messes with dos?

        .byte "|",34            ; " character
      .byte "["
        ;; jump over inline string
        jmp PUSHLOC
        .byte ";"               ; TOS= PUSHLOC
      .byte "]"

      .byte "%{"                ; POS= addr of str
        jsr TOS2POS
        IMM_RET

        ;; copy string to out
        .byte "%S"

      .byte "%{"
        jsr TOSpatch
        jsr POS2TOS             ; TOS= POS
        IMM_RET

      .byte "["
        lda #'<'
        ldx #'>'
      .byte "]"
.endif ; STRING


;;; TODO: debug why dos get's changed value? (sometimes?)

.ifdef STRING_DEBUG
;.ifdef STRING
        .byte "|",34            ; " character
      .byte "["
        jmp PUSHLOC

;;; neither works on sim65... lol

POS=gos ;works
;POS=pos ;workd
;POS=dos ; FAILS! who messes with dos?

.ifndef POS
        .byte ":;d;"
      .byte "]"
.else
        .byte ";"               ; load PUSHLOC in tos
      .byte "]"

      .byte "%{"
        lda _out
        sta POS
        ldx _out+1
        stx POS+1
        IMM_RET
.endif ; POS

        .byte "%S"

      .byte "%{"
        ;; tos = PUSHLOC
        ;; dos = string address
        
        ;; patch jmp (over string) to here
        ldy #1                  ; void inline 0 !!! LOL
        lda _out+1
        sta (tos),y
        dey
        lda _out
        sta (tos),y
        
.ifdef POS
        lda POS
        sta tos
        lda POS+1
        sta tos+1
        IMM_RET
      .byte "["
.else
        IMM_RET
      .byte "[D"
.endif ; POS

        jsr nl
;        putc 'D' ;ugh!!!!
        putc '/'
        ;; load string address
        lda #'<'
        ldx #'>'
;;; print it just to see!
        sta tos
        stx tos+1
jsr puth
        ldy #0
:       
        lda (tos),y
        beq :+
        jsr putchar
        iny
        bne :-
:       
        jsr nl

        lda #'<'
        ldx #'>'
      .byte "]"

      .byte "%{"
        jsr nl
        jsr nl
        
      lda dos
      ldx dos+1
      jsr axputh
        IMM_RET

.endif ; STRING_DEBUG

.ifdef STRING1
        ;; string
        .byte "|",34            ; really >"<
      .byte "["
        jmp PUSHLOC
;        .byte ':'               ; push address here
      .byte "]"
      
        ;; copies string inline till "
        .byte "%S"
        ;; fix so that iasm doesn't get confused
.ifdef PRINTASM
      .byte "%{"
        .import _last
        lda _out
        sta _last
        ldx _out+1
        stx _last+1
        jsr _iasm
        IMM_RET
.endif ; PRINTASM

      .byte "["
        ;; load patch address => tos
        .byte ";"
      .byte "]"
      .byte "%{"
        ;; PATCH jump NOW, to HERE!
        lda _out
        ldy #0
        sta (tos),y

        lda _out+1
        iny
        sta (tos),y

;;; I get correct code ldx, ldx but running not?
clc
lda tos
adc #2                          ; to skip jmp ADDRESS
sta tos
lda tos+1
adc #0
sta tos+1

;;; prints address of string (?)
lda tos
ldx tos+1
jsr axputh
        IMM_RET

      .byte "["
;        .byte "D"               ; tos= dos; addr of string
        lda #'<'
        ldx #'>'
;        jsr axputh
      .byte "]"

.endif ; STRING1


.ifdef POINTERS
;;; TODO: get's it wrong...?
;;;   parses and gives "and $addr"!
        .byte "|&%V"
      .byte '['
        lda #'<'
        ldx #'>'
      .byte ']'

        .byte "|\*%V"
      .byte '['
;;; TODO: test
        lda VAR0
        sta tos
        lda VAR1
        sta tos+1

        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y
      .byte ']'

.endif ; POINTERS


;;; last chance, try byte rules?
;;; TODO: is this sane?

.ifdef BYTERULES
        ;; BYTERULES
;;; TODO: if no match backtrack not propagated UP????
        .byte "|", _U
      .byte '['
;;; PRIMEBYTE: TODO: this adds 10bytes!!!! lol 313->323
;;; but sim: correct, and oric!
;        ldx #0
      .byte ']'
.endif

        .byte 0



.ifdef MINIMAL
;;; Just save (TODO:push?) AX
;;; TODO: remove!!!!
ruleU:
      .byte '['
        jsr _SAVE
      .byte ']'
        .byte 0
.endif

;;; aDDons (::= op %d | op %V)

ruleD:

;;; TODO: generealize!

.ifdef CUT
        ;; "CUT" operator
        ;; if the next character is ,:;)]?
        ;; expression is ended
;;; BYTESIEVE:
;;;   3450146 before
;;;   2862018 cut only in ruleD
;;;   (/ 2862018 3430146.0)
;;; 
;;;   16.6% faster


      .byte "%{"
        jsr cut
        jmp _acceptrule

breakchars:
        ;; '|'+128 so not conflict with '|', not 0!
        .byte ",:;)]?",'|'+128

        .byte "|"
nextrule:       
.endif ; CUT

FUNC _oprulesstart
        ;; 7=>A; // Extention to C:
        ;; Forward assignment 3=>a; could work! lol
        ;; TODO: make it multiple 3=>a=>b+7=>c; ...
        .byte "=>%A"
      .byte "[D"
        sta VAR0
        stx VAR1
      .byte "]"
        .byte TAILREC


;;; ----------------------------------------

.ifdef MINIMAL

;;; TODO: _U used elsewhere...
        .byte "|+",_U
      .byte '['
        jsr _PLUS
      .byte ']'
        .byte TAILREC

        .byte "|-",_U
      .byte '['
        jsr _MINUS
      .byte ']'
        .byte TAILREC

        .byte "|&",_U
      .byte '['
        jsr _AND
      .byte ']'
        .byte TAILREC

        .byte '|',"\|",_U
      .byte '['
        jsr _OR
      .byte ']'
        .byte TAILREC

        .byte "|^",_C
      .byte '['
        jsr _EOR
      .byte ']'
        .byte TAILREC

        .byte "|/2"
      .byte '['
        jsr _SHR
      .byte ']'
        .byte TAILREC

        .byte "|\*2"
      .byte '['
        jsr _SHL
      .byte ']'
        .byte TAILREC

;;; ==

        .byte "|==",_U
      .byte '['
        jsr _EQ
      .byte ']'
        .byte TAILREC

        ;; Empty
        .byte '|'


.else ; !MINIMAL

        .byte "|+%V"
      .byte '['
        clc
        adc VAR0
        tay
        txa
        adc VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        ;; +BYTE
        .byte "|+%D"
      .byte "%{"
        ;; TODO: this may not be easily skippable
        ;; make sure %D <256
        lda tos+1
        beq :+
        jmp _fail
:       
        IMM_RET

      .byte '['
;;; 6 B
        clc
        adc #'<'
        bcc :+
        inx
:
      .byte ']'
        .byte TAILREC
.endif ; OPTRULES

        .byte "|+%D"
      .byte '['
;;; 9 B
        clc
        adc #'<'
        tay
        txa
        adc #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC

;;; 18 *2
        .byte "|-%V"
      .byte '['
        sec
        sbc VAR0
        tay
        txa
        sbc VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        ;; -BYTE
        .byte "|-%D"
      .byte "%{"
        ;; TODO: this may not be easily skippable
        ;; make sure %D <256
        lda tos+1
        beq :+
        jmp _fail
:       
        IMM_RET
      .byte '['
;;; 6 B
        sec
        sbc #'<'
        bcs :+
        dex
:       
      .byte ']'
        .byte TAILREC
.endif ; OPTRULES

        .byte "|-%D"
      .byte '['
;;; 9 B
        sec
        sbc #'<'
        tay
        txa
        sbc #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC

;;; 17 *2
        .byte "|&%V"
      .byte '['
        and VAR0
        tay
        txa
        and VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        .byte "|&0xff00"
      .byte '['
        lda #0
      .byte ']'
        .byte TAILREC

        .byte "|&0xff"
      .byte '['
        ldx #0
      .byte ']'
        .byte TAILREC

        .byte "|&%D"
      .byte "%{"
        ;; TODO: this may not be easily skippable
        ;; make sure %D <256
        lda tos+1
        beq :+
        IMM_FAIL
:       
        IMM_RET

      .byte "["
        and #'<'
        ldx #0
      .byte "]"
        .byte TAILREC
.endif ; OPTRULES

        .byte "|&%D"
      .byte '['
        and #'<'
        tay
        txa
        and #'>'
        tax
        tya
      .byte ']'
;;; TODO: see FORDEBUG
;;;    if have this enabled then prase will loop >D>*>*>*...
;;;       why? we have and empty alt at end...
;        .byte TAILREC

.ifnblank
;;; TODO: \ quoting
;;; 17 *2
        .byte "|\|%V"
      .byte '['
        ora VAR0
        tay
        txa
        ora VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

        .byte "|\|%D"
      .byte '['
        ora #'<'
        tay
        txa
        ora #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC
.endif ; NBLANK

;;; 17 *2
        .byte "|^%V"
      .byte '['
        eor VAR0
        tay
        txa
        eor VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

        .byte "|^%D"
      .byte '['
        eor #'<'
        tay
        txa
        eor #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC

;;; 24
        
        .byte "|/2"
      .byte '['
;;; 6B 12c
        tay
        txa
        lsr
        tax
        tya
        ror
      .byte ']'
        .byte TAILREC

        .byte "|*2"
      .byte '['
;;; 6B 12c
        asl
        tay
        txa
        rol
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        .byte "|>>8"
      .byte '['
        txa
        ldx #0
      .byte ']'
        .byte TAILREC

        .byte "|<<8"
      .byte '['
        tax
        lda #0
      .byte ']'
        .byte TAILREC
        
        .byte "|<<1"
      .byte '['
.ifblank
;;; 6B 12c
        asl
        tay
        txa
        rol
        tax
        tya
.else
;;; 7B 13c
        stx tos+1
        asl
        rol tos+1
        ldx tos+1
.endif
      .byte ']'
        .byte TAILREC

        .byte "|<<2"
      .byte '['
;;; 10B
        stx tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|<<3"
      .byte '['
;;; 13B= 4+3*n    15=4+3*n => n=11/3=4-
        stx tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|<<4"
      .byte '['
;;; 16B
        stx tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>1"
      .byte '['
.ifblank
;;; 6B 12c
        tay
        txa
        lsr
        tax
        tya
        ror
.else
;;; 7B 13c
        stx tos+1
        lsr tos+1
        ror
        ldx tos+1
.endif
      .byte ']'
        .byte TAILREC

        .byte "|>>2"
      .byte '['
;;; 10B
        stx tos+1
        lsr tos+1
        ror
        lsr tos+1
        ror
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>3"
      .byte '['
;;; 13B
        stx tos+1
        lsr tos+1
        ror
        lsr tos+1
        ror
        lsr tos+1
        ror
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>4"
      .byte '['
;;; 16B
        stx tos+1
        lsr tos+1
        ror
        lsr tos+1
        ror
        lsr tos+1
        ror
        lsr tos+1
        ror
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|<<%D"
      .byte '['
;;; 15B (breakeven: D=4-)
        stx tos+1
        ldy #'<'
:       
        dey
        bmi :+
        
        asl
        rol tos+1

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC

;;; TODO: so many duplicates...
;;;   can just do _C or _E ? priorities?
        .byte "|<<%V"
      .byte '['
;;; 15B (breakeven: D=4-)
        stx tos+1
;;; TODO: this is only difference...
;;;   IDEA: emit subroutine and remember;
;;;         incremental library buildup?
        ldy VAR0
:       
        dey
        bmi :+
        
        asl
        rol tos+1

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>%D"
      .byte '['
;PUTC '/'
;;; 15B (breakeven: D=4-)
        stx tos+1
        ldy #'<'
:       
        dey
        bmi :+
        
        lsr tos
        ror

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>%V"
      .byte '['
;;; 15B (breakeven: D=4-)
        stx tos+1
        ldy VAR0
:       
        dey
        bmi :+
        
        lsr tos
        ror

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC
.endif ; OPTRULES

;;; COMPARISIONS

        .byte "|==%V"
      .byte '['
        ;; 15
        ldy #0
        cmp VAR0
        bne :+
        cpx VAR1
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        tax
      .byte ']'
        .byte TAILREC

        .byte "|==%D"
      .byte '['
        ;; 13
        ldy #0
        cmp #'<'
        bne :+
        cpx #'>'
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        tax
      .byte ']'
        .byte TAILREC

;;; TODO: signed?
;;;    v < -42      => signed comparison
;;;    v < 32767    => SIGNED!
;;;    v < 40000    => UNSIGNED !
;;; 
;;;    v > 0        ?? impllies test for negative?
;;; 
;;; How to ipmlement signed comparison on 6502
;;; - just eor #$80 hi-byte of both values?
;;; 

        .byte "|<%D"
      .byte '['
        ;; 13
        ldy #$ff
        cpx #'>'
        bne :+
        cmp #'<'
:       
        bcc :+
        ;; FAIL !< => 0
        iny
:       
        ;; TRUE < => -1
        tya
        tax
      .byte ']'
        .byte TAILREC

        .byte "|<%V"
      .byte '['
        ;; 13
        ldy #$ff
        cpx VAR1
        bne :+
        cmp VAR0
:       
        bcc :+
        ;; !< => 0
        iny
:       
        ;;  < => -1
        tya
        tax
      .byte ']'
        .byte TAILREC

.endif ; !MINIMAL

        ;; Empty
        .byte '|'

        .byte 0
FUNC _oprulesend

;;; BYTERULES variant of ruleC:
ruleU:  

.ifdef BYTERULES
.ifdef OPTRULES
        ;; arr[i]=constant;
        .byte "|$arr\[%A\]=%D;"
      .byte "[#D"
        ldx VAR0
        .byte ";"
        lda #'<'
;;; TODO: get address of array...
        sta arr,x
      .byte "]"
.endif ; OPTRULES

        ;; array index
;;; TODO: simulated
        .byte "|$arr\[",_E,"\]="
      .byte '['
        pha
      .byte ']'
        .byte _U,";"
      .byte '['
        tay
        pla
        tax
        tya
;;; TODO: get address of array...
        sta arr,x
      .byte ']'

        ;; array index
;;; TODO: simulated
;;; TODO: _E or _V ???
        .byte "$arr\[",_E,"\]"
      .byte '['
        tax
        lda arr,x
        ldx #0
      .byte ']'
        .byte _V

        ;; variable
        .byte "|$%V"
      .byte '['
        lda VAR0
        ldx #0
      .byte ']'
        .byte _V

        ;; constant
        .byte "|%D"
      .byte '['
        lda #'<'
        ldx #0
      .byte ']'
        .byte _V


        ;; byte
        .byte "|*(char*)%V"
      .byte "["
        lda VAR0
        ldx #0
      .byte "]"
        .byte _V
.endif ; BYTERULES

        .byte 0


;;; BYTERULES variant of ruleD:
FUNC _byterulesstart

ruleV:  
        ;; TODO:        // .byte "=>
        
.ifdef BYTERULES
        .byte "|+$%V"
      .byte '['
        clc
        adc VAR0
      .byte ']'
        .byte TAILREC

        .byte "|+%D"
      .byte '['
        clc
        adc #'<'
      .byte ']'
        .byte TAILREC

;;; 18 *2
        .byte "|-%D"
      .byte '['
        sec
        sbc VAR0
      .byte ']'
        .byte TAILREC

        .byte "|-%D"
      .byte '['
        sec
        sbc #'<'
      .byte ']'
        .byte TAILREC

;;; 17 *2
        .byte "|&$%V"
      .byte '['
        and VAR0
      .byte ']'
        .byte TAILREC

        .byte "|&$%D"
      .byte '['
        and #'<'
      .byte ']'
        .byte TAILREC

.ifnblank
;;; TODO: \ quoting
;;; 17 *2
        .byte "|\|$%V"
      .byte '['
        ora VAR0
      .byte ']'
        .byte TAILREC

        .byte "|\|%D"
      .byte '['
        ora #'<'
      .byte ']'
        .byte TAILREC
.endif ; NBLANK

;;; 17 *2
        .byte "|^$%V"
      .byte '['
        eor VAR0
      .byte ']'
        .byte TAILREC

        .byte "|^%D"
      .byte '['
        eor #'<'
      .byte ']'
        .byte TAILREC

;;; 24
        
        .byte "|/2"
      .byte '['
        lsr
      .byte ']'
        .byte TAILREC

        .byte "|\*2"
      .byte '['
        asl
      .byte ']'
        .byte TAILREC

;;; ==

        .byte "|==$%V"
      .byte '['
        ldy #0
        cmp VAR0
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        ldx #0
      .byte ']'
        .byte TAILREC

        .byte "|==%D"
      .byte '['
        ldy #0
        cmp #'<'
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        ldx #0
      .byte ']'
        .byte TAILREC

        .byte "|<%D"
      .byte '['
        ldy #$ff
        cmp #'<'
        bcc :+
        ;; < => 0
        iny
:       
        ;; neq => 0
        tya
        ldx #0
      .byte ']'
        .byte TAILREC

;;; TODO: fail if <<1????
;;; TODO: need a guard %b (break char) for matcher!
       .byte "<<1"
      .byte '['
        asl
      .byte ']'                  

       .byte ">>1"
      .byte '['
        lsr
      .byte ']'                  

       .byte "<<2"
      .byte '['
        asl
        asl
      .byte ']'                  

       .byte ">>2"
      .byte '['
        lsr
        lsr
      .byte ']'                  

       .byte "<<3"
      .byte '['
        asl
        asl
        asl
      .byte ']'                  

       .byte ">>3"
      .byte '['
        lsr
        lsr
        lsr
      .byte ']'                  

       .byte "<<4"
      .byte '['
        asl
        asl
        asl
        asl
      .byte ']'                  

       .byte ">>4"
      .byte '['
        lsr
        lsr
        lsr
        lsr
      .byte ']'                  

       .byte "<<5"
      .byte '['
        asl
        asl
        asl
        asl
        asl
      .byte ']'                  

       .byte ">>5"
      .byte '['
        lsr
        lsr
        lsr
        lsr
        lsr
      .byte ']'                  

       .byte "<<6"
      .byte '['
.ifblank
;;; 5B 8c
        ror
        ror
        ror
        and #128+64
.else
;;; 6B 12c
        asl
        asl
        asl
        asl
        asl
        asl
.endif
      .byte ']'                  

       .byte ">>6"
      .byte '['
.ifblank
;;; 5B 8c
        rol
        rol
        rol
        and #1+2
.else
;;; 6B 12c
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
.endif
      .byte ']'                  

       .byte "<<7"
      .byte '['
        ror
        ror
        and #128
      .byte ']'

       .byte ">>7"
      .byte '['
        rol
        rol
        and #1
      .byte ']'


        .byte ">>%V"
      .byte '['
        ldy VAR0
:       
        dey
        bmi :+
        lsr
        jmp :-
:       
        .byte ">>%D"
      .byte '['
        ldy #'<'
:       
        dey
        bmi :+
        lsr
        jmp :-
:       
      .byte ']'


.endif ; BYTERULES
        
        .byte "|"

        .byte 0
FUNC _byterulesend

;;; printf handling
ruleH:  
;;; 111 B not finished,
;;; how big is an asm printf?
.ifdef rulePRINTF
        ;; TODO: only handles fixed formats!
        .byte "printf(",34,""
      .byte "%{"
        ;; save pointer for traversal
        lda inp 
        sta pos
        lda inp+1
        sta pos+1
        ;; skip parsing till end
        ldy #0
:       
        jsr _incI
        lda (inp),y
;;; TODO: \ and "foo""bar" ?
        cmp #'"'                ; "
        bne :-
        ;; standing at "
        jsr _incI
        ;; done
        IMM_RET

        .byte TAILREC

        ;; handle each argument
        .byte "|,"
      .byte "%{"
.scope
        ;; skip "str%..." till %
        ldy #0
:       
        lda (pos),y
        cmp #'%'
        beq :+
        cmp #'"'                ; "
        beq @done
        iny
        bne :-
:       
        jsr _incI
        ;; have string to print?
        tya
        pha

        beq @nah
        ;; string - put out JSR putherez
        lda #$20
        ldy #0
        sta (_out),y
        jsr _incO
        
        lda #<putherez
        sta (_out),y
        jsr _incO
        
        lda #>putherez
        sta (_out),y
        jsr _incO
        
        ;; string - put inline
        pla
        tax
        ;; Y=0 already
:       
        lda (pos),y
        sta (_out),y
        jsr _incO

        dex
        bne :-

        ;; string - zero terminate
        tya
        sta (_out),y
        jsr _incO
@done:  
        ;; jmp _acceptrule?
@nah:
.endscope
        IMM_RET
        ;; - process argument
        .byte _E
      .byte "%{"
        ;; pos standing char after %
        ldy #0
        lda (pos),y
        ;; 

        IMMRET
        ;; done with printf
        .byte "|);"
.endif ; rulePRINTF
        .byte 0

;;; load byte expression
ruleI:  
        .byte "%D)"
      .byte '['
        lda #'<'
      .byte ']'

        .byte "|%V)"
      .byte '['
        lda VAR0
      .byte ']'

        ;; Nothing else than Expression could come now
;;; TODO: possibly _byteexpreesion???
;;; TOOD: is this dupoicate of later stuff?
        .byte "|",_E,")"

        .byte 0



;;; read byte expression, saving AX to tos, and sets Y=0!
;;; LOL: only used by poke...

;;; TODO:   can we use all these for foo[...]= ....; ????
ruleJ:  
        .byte "0)"
      .byte '['
        ;; save 1 B
        sta tos
        stx tos+1
        lda #0
        ;; used by indirection
        tay
      .byte ']'

        .byte "|%D)"
      .byte '['
        sta tos
        stx tos+1
        lda #'<'
        ;; used by indirection
        ldy #0
      .byte ']'

        .byte "|%V)"
      .byte '['
        sta tos
        stx tos+1
        lda VAR0
        ;; used by indirection
        ldy #0
      .byte ']'

        ;; Nothing else than Expression could come now
        .byte "|"
      .byte '['
        pha
        txa
        pha
      .byte ']'
        .byte _E,")"
      .byte '['
        tay
        pla
        sta tos+1
        pla
        sta tos
        tya
        ;; used by indirection
        ldy #0
      .byte ']'

        .byte 0



;;; TODO: bad routine, at least for poke(_E,byteexpr)
;;; BYTESIEVE: saved 5 bytes using ruleF!
;;; 
;;; "keepAXsetY"
ruleF:  
;;; TODO: remove? only used by strchr?
        .byte "%D"
      .byte '['
        ldy #'<'
      .byte ']'

        .byte "|%V"
      .byte '['
        ldy VAR0
      .byte ']'

        ;; Nothing else than Expression could come now
        .byte "|"
      .byte "["
        ;; reverse save A,X
        pha
        txa
        pha
      .byte "]"
        .byte _E
      .byte "["
        tay
        ;; reverse pop X,A
        pla
        txa
        pla
      .byte "]"

        .byte 0


;;; same as ruleE/rule but protects AX (leaving it in tos, in the end)
;;; "saveTOSrule"

;;; Another calling convention!
;;; 
;;; "(",_G:  two argument rule where:
;;;    - first arg is saved in TOS
;;;    - second arg is in AX
ruleG:

.ifdef OPTRULES
        .byte _E,",0)"
      .byte '['
;;; 7
        sta tos
        stx tos+1

        lda #0
        tax
      .byte ']'
.endif ; OPTRULES

        .byte "|",_E,",%D)"
      .byte '['
;;; 8
        sta tos
        stx tos+1

        lda #'<'
        ldx #'>'
      .byte ']'

        .byte "|",_E,",%V)"
      .byte '['
        sta tos
        stx tos+1

        lda VAR0
        ldx VAR1
      .byte ']'

        ;; Nothing else than Expression could come now
        .byte "|"
      .byte "["
        ;; reverse save A,X
        pha
        txa
        pha
      .byte "]"
        .byte _E
      .byte "["
        tay
        sta savex
        ;; reverse pop X,A
        pla
        sta tos+1
        pla
        sta tos
        ;; 
        ldx savex
        tya
      .byte "]"

        .byte 0

;;; Exprssion:
ruleE:  
        .byte _C,_D
        
.ifdef BYTERULES
        .byte "|"
        .byte _U,_V
.endif ; BYTERULES
        
        .byte 0


;;; TODO: remove, this old for function calls?

;;; prefix: array= {
;;;  ruleQ:  num,num,num }

;;; TODO:allow for expressions if have constant folding
ruleQ:
        ;; end
        .byte "};"

        .byte "|,",TAILREC

        .byte "|%D"
;TODO: data inline!
;      .byte "[<]"
;;; TODO: ohoh, how to skip over!!!! LOL
      .byte "%{"
        ;; TODO: this may not be easily skippable
        ;; TODO: remove as this is hack
        lda tos
        ldy #0
        sta (pos),y
        jsr _incP
        IMM_RET

        .byte TAILREC

        .byte "|"
      .byte "%{"
        ;; TODO: this may not be easily skippable
        PRINTZ "got arr end"
        IMM_RET

        .byte 0

        

;;; DEFS ::= TYPE %NAME() BLOCK TAILREC |
ruleN:

;;; TODO: make this folding work,
;;;   mostly OK, but don't know where to put result
;;;   want to have restartable programs? 
;;;   or like cc65 just put in inline in the code?
;;;   LIMIT: can only do at top-level

;FOLD=1
.ifdef FOLD
        ;; constant partial evaluation!
        ;; TODO: expand to constant folding
;        .byte "const",_T,"%A="
        .byte "const","word","%A="

      .byte "%{"
        putc '{'
        IMM_RET

      .byte "%{"
        ;; save address
        lda dos
        ldx dos+1
        jsr pushax
        ;; save current gen
        lda _out
        sta gos
        ldx _out+1
        stx gos+1
        ;; TODO: should set a flag
        PUTC '@'
        ;; cheat: artificual fail!
        IMM_FAIL
;;; ???
        IMM_RET

;;; TODO: why needed? was it for constant folding?

;        ;; cheat!
;        ;; (it will next rule next!)
;      .byte "|"

;        .byte "const",_T,"%A="
;        .byte "const","word","%A="

.ifdef FFF
      .byte "%{"
        PUTC '?'
;        jsr _iasm
        lda inp
        ldx inp+1
        jsr _printz
        jsr nl
        IMM_RET
.endif
        .byte _C,_D
        .byte ";"
      .byte "["
        ;; make sure we get back!
        rts
      .byte "]"
      .byte "%{"
        PUTC '$'
;        jsr _iasm
        IMM_RET
        ;; TODO: if flag set

      .byte "%{"
;        jsr _iasm
        PUTC '#'
        ;; print address to call
        lda gos
        sta tos
        lda gos+1
        sta tos+1
        jsr puth
        ;; JSR (gos) !
        lda #$4c                ; trampoline: jmp
        sta gos-1
        jsr gos-1
        ;; store result in variable from DSTACK
        sta dos
        stx dos+1
        jsr popax
        sta tos
        stx tos+1
        PUTC '@'
        jsr puth
        ;; store in var
        ldy #0
        lda dos
        sta (tos),y
        iny
        lda dos+1
        sta (tos),y
        ;; print for debug
        putc '='
        lda dos
        ldx dos+1
        sta tos
        stx tos+1
        jsr putu
        ;; remove code run!
        lda gos
        sta _out
        ldx gos+1
        stx _out+1
        ;; continue
        IMM_RET

      .byte "%{"
        putc '}'
        IMM_RET

        .byte TAILREC

        .byte "|"
.endif ; FOLD

;;; DUMMY: for testing/prototype

;;; LOL uppercase WORD matches literary!
        .byte "WORD","%N(a,b,c,d)"

VARa= _vars+('a'-'A')*2

        ;;  prelude
      .byte "["

.ifdef TESTDISASM
        lda $1234,x
;;; causes parse error eor = $5d
;        eor $1234,x
        and $1234,x
        ora $1234,x
        adc $1234,x
        sta $1234,x
        nop
        lda $1234,y
        eor $1234,y
        adc $1234,y
        sta $1234,y
        nop
        nop
        ldy $1234,x
        nop
        nop
;;; prints ldx $1234,x !!! lol
        ldx $1234,y
        nop
        nop
        nop
.endif ; TESTDISASM

;
REVERSE=1
.ifndef REVERSE
;;; 37 b (wayt too big!)

        ;; swap stack w registers!
        ;; (reverse byte order)
putc '%'
        tsx
        inx
        inx
        ldy #8                  ; bytes
:       
        ;; hi was pushed last
        lda VARa-1,y
        sta savea

        lda 100,x
        sta VARa-1,y
        
        lda savea
        sta 100,x
        ;; lo
        lda VARa-2,y
        sta savea

        lda $101,x
        sta VARa-2,y
        
        lda savea
        sta $101,x
        ;; 
        inx
        inx

        dey
        dey
        bne :-
.else
putc 'S'
;;; 28 B (smaller and faster!)

        ;; swap stack w registers!
        ;; (reverse byte order)
        ;; (sadly on both - not needed)
        tsx
        stx savex
        ldy #8                  ; bytes
        ;; skip JSR
;;; TODO: with jsk-calling remove these...
        pla
        pla
:       
        ;; (trying to be clever
        ;;  - rewriting the stack!)
        ;; swap byte
;;; TODO: use ,x to do zero addressing! save bytes
        ldx VARa-1,y
        pla
        sta VARa-1,y
        txa
        pha
        ;; step up
        pla                     ; s-- !
        dey
        bne :-
        ;; restore stack pointer!
        ldx savex
        txs
.endif ; !REVERSE
      .byte "]"

        .byte _B

        ;; postlude
      .byte "["
        ;; restore register bytes from stack
        ;; (doesn't care order)
.ifndef REVERSE
;;; 8 B
        ldx #8
:       
        pla
        sta VARa-1,x
        
        inx
        bne :-
.else

        sta savea
        stx savey

;;; TODO: only need restore...
;
DOSWAP=1
.ifdef DOSWAP
putc 'R'

        tsx
        stx savex
        ldy #8                  ; bytes
        pla
        pla
:       
        ;; (trying to be clever
        ;;  - rewriting the stack!)
        ;; swap byte
        ldx VARa-1,y
        pla
        sta VARa-1,y
        txa
        pha
        ;; step up
        pla                     ; s-- !
        dey
        bne :-
        ;; restore stack pointer!
        ldx savex
        txs
.else
putc 'r'
;;; 12 B
        tsx
        stx savex
        pla
        pla

        ldx #8
:       
        pla
        sta VARa-1,x
        dex
        bne :-
.endif ; DOSWAP

;;; NOBODY else can currently return
;;;   we just need to keep AX safe...
        lda savea
        ldx savey

.endif ; !REVERSE

        rts

      .byte "]"
        .byte TAILREC

        ;; Define function definition
;;; TODO: _T never fails...
;        .byte _T,"%N()",_B

        .byte "|word","%N()",_B
      .byte '['
        ;; TODO: This maybe be redundant if there is
        ;; an return just before...
        ;; 
        ;; Not easy to fix?
        ;; 
        ;; if (3) ; else return 5;
        ;; (if no return inserted after then
        ;;  will fall through to next function...)
        rts
      .byte ']'
        .byte TAILREC

        .byte "|void*","%N()",_B
      .byte '['
        rts
      .byte ']'
        .byte TAILREC

        .byte "|void","%N()",_B
      .byte '['
        rts
      .byte ']'
        .byte TAILREC

        .byte "|byte*","%N()",_B
      .byte '['
        ldx #0
        rts
      .byte ']'
        .byte TAILREC

        .byte "|byte","%N()",_B
      .byte '['
        ldx #0
        rts
      .byte ']'
        .byte TAILREC

;;; TODO: this TAILREC messes with ruleP and several F
;;;   TAILREC does something wrong!
        
        .byte "|"

        ;; TODO: Define variable


        ;; Define array
;; TODO: now is dummy
        .byte "bytearr\[256\];"
;;; for now just simulate
        .byte TAILREC

        .byte "|"


        ;; Define array
;; TODO: now is hack
        .byte "bytearr\[\]={"
      .byte "%{"
        ;; TODO: this may not be easily skippable
        ;; set pos to array
        ;; TODO: get real array addr
        lda #<arr
        sta pos
        lda #>arr
        sta pos+1
        IMM_RET

;        .byte _Q,"};"
        .byte _Q
;;; for now just simulate
        .byte TAILREC

        .byte "|"

        .byte 0

;;; This is the first rule applied on program.
;;; Generates a jmp to main(). If no functions/decl
;;; is wasting 3B. Bah.
ruleO:
      .byte '['
        jmp PUSHLOC
      .byte ']'
        .byte _N

.ifnblank
      .byte "%{"
        putc '_'
        jsr printstack
        IMM_RET
.endif
        .byte 0
        ;; Autopatches skip over definitions in N


;;; PROGRAM ::= DEFSSKIP TYPE main() BLOCK | 
ruleP:  
      .byte "%{"
;        jsr _iasmstart
        IMM_RET

        ;; this rule with jump over definitions and arrive at main
        .byte _O

        ;; TODO: works with _S
        ;; (reason is _T error doesn't propagate up
;        .byte _T,"main()",_B
        .byte "word","main()",_B
      .byte '['
        ;; if main not return, return 0
        lda #0
        tax
        rts
      .byte ']'

.ifdef PRINTASM
      .byte "%{"
        jsr asmprintsrc
        IMM_RET
.endif ; PRINTASM

        .byte "|"

        .byte _A
      .byte "["
        rts
      .byte "]"            

.ifdef PRINTASM
      .byte "%{"
        jsr asmprintsrc
        IMM_RET
.endif ; PRINTASM

;        .byte "|",_E,TAILREC
;        .byte "|;",TAILREC
;        .byte "|{",_A,"}",TAILREC
        
        .byte 0

;;; Type
ruleT:  
        ;; don't use SIGNED int/char
.ifdef FROGMOVE
        .byte "static",TAILREC
        ;; we don't care
        .byte "|word|char*|char|void*|void|int*|int",0
.else
        .byte "word|char*|char|void|void*",0
;;; TODO: change word to int... lol
.endif



FUNC _stmtrulesstart
;;; Statement
ruleS:

.ifdef PRINTASM
      .byte "%{"
        jsr asmprintsrc
        IMM_RET
.endif ; PRINTASM

        ;; empty statement is legal
        .byte ";"
        
        ;; return from void function, no checks
        .byte "|return;"
      .byte '['
        rts
      .byte ']'
        
.ifdef OPTRULES
        ;; save for no args function!
        .byte "|return%U();"
      .byte '['
        ;; TAILCALL save 1 byte
        jmp VAL0
      .byte ']'
.endif ; OPTRULES

        ;; RETURN
        .byte "|return",_E,";"
      .byte '['
        rts
      .byte ']'

        ;; BlOCK!
;;; TODO: this gives inifinte loop! >S>B>* ...
;       .byte "|",_B

;;; TODO: this however works! 
;;;   which is just inline of _B ... HMMM :-(
        .byte "|{}"
        .byte "|{",_A,"}"


;;; TODO:
;;; -
;;; Turns out that adding a "hacky" (but correctly working) ELSE wasn't that difficult!
;;; Basically, I just made sure that the THEN branch always had the flag Z=0 (value not 0 i.e. true) and then since a false value would jump to after the THEN the ELSE can be implemented by just looking at the flag (so like an opposite THEN).
;;; Of course, this isn't very optimized: An IF comes out to 9 bytes ; ELSE support adds 2 + 5 more bytes, total 16.
;;; Currently, only patching long-JMP instructions, maybe just *define* that the if branches can't be too big(?) that is less than 127 bytes... That would make an IF THEN be 6 and ELSE 4 bytes, total 10.

;;; TODO: MINIMAL can limit to 10 bytes instead of 16
;;; 
;;; LONG could do fancy patching if >127
;;; replae BNE XX with JMP to here+3, add code
;;; 
.ifnblank
;;; LNG: 16B   (+ 9 2 5)   - all long
;;; 
;;; min: 10B   (+ 6 2 2)   - all short
;;; med: 18B   (+ 6 2 8 2) - IFF too long THEN
;;; max: 24B   (+ 6 2 8 8) - IFF also ELSE long

        ;; 6B 5-9c
        tay
        bne then
        txa
        beq PUSHREL
then:   
        ...
        ;; 2B (for else)
        lda #$ff
afterTHEN:      
        ;; + 8B to do long patch
        sec
        bcs 6
testhere:       
        beq 3
        jmp then
afterIF:        
elseTEST:       
        ;; 3B 4-5c
        bne PUSHREL
        nop
else:   
        ...
afterELSE:      
.endif

        ;; label
;        .byte "|%N:",_S
        ;; set's variable/name to that address!

        ;; goto
;;; TODO: %A can be %V ???
        .byte "|goto%A;"
      .byte "["                ; get aDdress
        jmp (VAL0)
      .byte "]"

.ifdef OPTRULES

        ;; IF( var < num ) ... saves 6 B (- 63 57)
        ;; note: this is safe as if it doesn't match,
        ;;   not code has been emitted! If use subrule... no
        .byte "|if(%A<%D)"
.scope        
      .byte "["
        ;; 14
        ;; reverse cmp as <> NUM avail first
        lda #'<'
        ldx #'>'
        ;; cmp with VAR
        .byte 'D'               ; get aDdress

        cpx VAL1
        bne :+
        ;;  NUM>=VAR ... VAR<=NUM
        cmp VAR0
        beq @nah
        bcs @ok                 ; NUM>=VAR
@nah:
        ;; set value for optional else...
.ifdef ELSE
        lda #0
        tax
.endif ;ELSE
        jmp PUSHLOC
@ok:        
        ;; THEN-branch
      .byte "]"
        .byte _S
.ifdef ELSE
        ;; for ELSE, make sure value not 0!
      .byte '['
        lda #$ff
      .byte ']'
.endif ; ELSE
.endscope

        .byte "|if(%A&%D)"
      .byte "%{"
        ;; TODO: this may not be easily skippable
        ;; make sure %D <256
        lda tos+1
        beq :+
        jmp _fail
:       
        IMM_RET

.scope        
      .byte "["
        lda #'<'
        ;; cmp with VAR
        .byte 'D'               ; get aDdress

        and VAR0 ; ->  58 ?
;        and VAL0 ; -> 111 ?
        bne @ok
@nah:
        ;; set value for optional else...
.ifdef ELSE
        ;; A is 0
        tax
.endif ;ELSE
        jmp PUSHLOC
@ok:        
        ;; THEN-branch
      .byte "]"
        .byte _S
.ifdef ELSE
        ;; for ELSE, make sure value not 0!
      .byte '['
        lda #$ff
      .byte ']'
.endif ; ELSE
.endscope

.endif ; OPTRULES


        ;; IF(E)S; // no else
        .byte "|if(",_E,")"
      .byte '['
.ifnblank
        ;; 9B 9-11c
        ;; 111*111 => 859us
        stx savex
        ora savex
        bne :+
        jmp PUSHLOC
:       
.else
        ;; 9B 5-9-11c
        ;; 111*111 => 859us same????
        ;; TODO: no savings for 111*111 ???
        ;;    609c if just make jmp PUSHLOC
        tay
        bne :+
        txa
        bne :+
        jmp PUSHLOC
:       
.endif
        ;; THEN-branch
      .byte ']'
;;; TODO: move these rules out to another rule
;;;    then don't need to repeat this one!
        .byte _S
.ifdef ELSE
        ;; for ELSE, make sure value not 0!
      .byte '['
        lda #$ff
      .byte ']'
        ;; Auto-patches at exit!

        ;; ELSE as independent as is optional! hack!
        ;; 13 B
        .byte "|else"
      .byte '['
        ;; either Z is from lda #$ff z=0 => !neq
        ;; or Z is from the if expression Z=1
        beq :+
        jmp PUSHLOC
:
      .byte ']'
        .byte _S
        ;; Auto-patches at exit!
.endif ; ELSE

;;; TODO: 3 things same result, save bytes?
        ;; simple write byte to memory
        .byte "|*(char*)%A=",_E,";"
      .byte "[D"
        sta VAR0
      .byte "]"

.ifdef BYTERULES
        .byte "|$%A=",_E,";"
      .byte "[D"
        sta VAR0
      .byte "]"
.endif


.ifdef OPTRULES
        ;; arr[i]=constant;
        .byte "|arr\[%A\]=%D;"
      .byte "["
        lda #'<'
        .byte "D"
        ldx VAR0
;;; TODO: get address of array...
        sta arr,x
      .byte "]"

;;; this makes it work, but isn't correct?
;        .byte TAILREC

.endif ; OPTRULES

        ;; array index
;;; TODO: simulated
        .byte "|arr\[",_E,"\]="
      .byte '['
        ;; save index
        pha
      .byte ']'
;;; TODO: _U in other rule???
        .byte _E,";"
      .byte '['
        ;; save value to store
        tay
        ;; get index
        pla
        tax
        tya
;;; TODO: get address of array...
        sta arr,x
      .byte ']'


.ifdef OPTRULES
        .byte "|$%A=0;"
      .byte "[D"
        sta VAR0
      .byte "]"
.endif ; OPTRULES


FUNC _stmtbyterulestart

.ifdef BYTERULES
;;; TODO: is it OPTRULES???? - nah
        .byte "|++$%V;"
      .byte "["
        inc VAR0
      .byte "]"

        .byte "|--$%V;"
      .byte "["
        dec VAR0
      .byte "]"

        ;; NOTE: no need provide: v op= const;
        ;;       - it would wouldn't save any bytes!
        .byte "|$%A+=",_U,";"
      .byte "[D"
        clc
        adc VAR0
        sta VAR0
      .byte "]"

        .byte "|%A-=",_U,";"
      .byte "[D"
        sec
        eor #$ff
        adc VAR0
        sta VAR0
      .byte "]"

        .byte "|$%A&=",_U,";"
      .byte "[D"
        and VAR0
        sta VAR0
      .byte "]"

        .byte "|$%A\|=",_U,";"
      .byte "[D"
        ora VAR0
        sta VAR0
      .byte "]"

        .byte "|$%A^=",_U,";"
      .byte "[D"
        eor VAR0
        sta VAR0
      .byte "]"

        .byte "|$%A>>=1;"
      .byte "[D"
        lsr VAR0
      .byte "]"

        .byte "|$%A<<=1;"
      .byte "[D"
        asl VAR0
      .byte "]"

        .byte "|$%A>>=2;"
      .byte "[D"
        lsr VAR0
        lsr VAR0
      .byte "]"

        .byte "|$%A<<=2;"
      .byte "[D"
        asl VAR0
        asl VAR0
      .byte "]"

        .byte "|$%A>>=3;"
      .byte "[D"
        lsr VAR0
        lsr VAR0
        lsr VAR0
      .byte "]"

        .byte "|$%A<<=3;"
      .byte "[D"
;;; 6B 15c
        asl VAR0
        asl VAR0
        asl VAR0
      .byte "]"

        .byte "|$%A>>=4;"
      .byte "[D"
;;; 8B 14c
.ifblank
        lda VAR0
        lsr
        lsr
        lsr
        lsr
        sta VAR0
.else
;;; 8B 20c
        lsr VAR0
        lsr VAR0
        lsr VAR0
        lsr VAR0
.endif
      .byte "]"

        .byte "|$%A<<=4;"
      .byte "[D"
        lda VAR0
        asl
        asl
        asl
        asl
        sta VAR0
      .byte "]"

        .byte "|$%A>>=5;"
      .byte "[D"
;;; 9B 16c
        lda VAR0
        lsr
        lsr
        lsr
        lsr
        lsr
        sta VAR0
      .byte "]"

        .byte "|$%A<<=5;"
      .byte "[D"
        lda VAR0
        asl
        asl
        asl
        asl
        asl
        sta VAR0
      .byte "]"

        .byte "|$%A>>=6;"
      .byte "[D"
;;; 10B 16c
        lda VAR0
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
        sta VAR0
      .byte "]"

        .byte "|$%A<<=6;"
      .byte "[D"
        lda VAR0
        asl
        asl
        asl
        asl
        asl
        asl
        sta VAR0
      .byte "]"

        .byte "|$%A>>=7;"
      .byte "[D"
;;; 8B 12c
        lda VAR0
        rol
        rol
        and #1
        sta VAR0
      .byte "]"

        .byte "|$%A<<=7;"
      .byte "[D"
        lda VAR0
        ror
        ror
        and #128
        sta VAR0
      .byte "]"

;;; TODO:: |<<9 >>9 ???

.ifnblank
        .byte "|$%A>>=%D;"
      .byte "["
;;; 11B (tradeoff 
        ldy #'<'
        .byte "D"
:       
        dey
        bmi :+

        lsr VAR0

        sec
        bcs :-
:       
      .byte "]"
.endif

        .byte "|$%A>>=%V;"
      .byte "["
        ldy VAR0
        .byte "D"
:       
        dey
        bmi :+

        lsr VAR0

        sec
        bcs :-
:       
      .byte "]"

.ifnblank
        .byte "|$%A<<=%D;"
      .byte "["
;;; 11B
        ldy #'<'
        .byte "D"
:       
        dey
        bmi :+

        asl VAR0

        sec
        bcs :-
:       
      .byte "]"
.endif

        .byte "|$%A<<=%V;"
      .byte "["
;;; 14B
        ldy VAR0
        .byte "D"
:       
        dey
        bmi :+

        asl VAR0
        rol VAR1

        sec
        bcs :-
:       
      .byte "]"
.endif ; BYTERULES
FUNC _stmtbyteruleend



;;; TODO: are these really "OPTRULES"
;;;   a+= is "extra syntax"?
;;;   ++a; is opt, yes

.ifdef OPTRULES
;;; TODO make ruleC when %A pushes
        .byte "|"

        .byte "++%A;"
      .byte "[D"
        inc VAR0
        bne :+
        inc VAR1
:       
      .byte "]"

;;; TODO make ruleC when %A pushes
        .byte "|--%A;"
      .byte "[D"
        lda VAR0
        bne :+
        dec VAR1
:       
        dec VAR0
      .byte "]"
.endif ; OPTRULES

.ifdef POINTERS
        .byte "|*%A=",_E,";"
      .byte "[D"
        ldy VAR0
        sty tos
        ldy VAL1
        sty tos+1

        ldy #0
        sta (tos),y
        tax
        iny
        sta (tos),y
      .byte "]"
.endif ; POINTERS

.ifdef BYTERULES
        ;; TODO: this is now limited to 256 index
        ;; bytes@[%D]= ... fixed address... hmmm
        .byte "|$%A\[%D\]="
      .byte '['
        ;; prepare index
        lda '<'
        pha
      .byte ']'
        .byte _E,";"
      .byte "[D"
        ;; load index
        tax
        pla
        tay
        txa

        sta VAR0,y
      .byte "]"
.endif ; BYTERULES







.ifdef OPTRULES

;;; TODO: BYTERULES for $ i

;;; TODO: for expects empty statement to be "true"!

        .byte "|for(i=0;i<%D[d] ;++%V)"
;;; 22B (is less than while!!! 40B!)
      .byte "%{"
        ;; TODO: this may not be easily skippable
;;;  make sure %D <256
        lda tos+1
        beq :+
        jmp _fail
:              
        IMM_RET

      .byte "["
;;;  start not with 0 but with 
        lda #0
        sta VAR0
        sta VAR1
        ;; skip inc first time
.ifdef ZPVARS
        ;beq 2
        .byte $f0,2
.else
        ;beq 3
        .byte $f0,3
.endif

;;;  We moved inc here
        .byte ":"               ; note: this generates no byte
        inc VAR0

        lda VAR0
        .byte "D"
        cmp #'<'
        bcc :+
        jmp PUSHLOC
:              
      .byte "]"
        .byte _S
      .byte "["
        .byte ";d"
        .byte ";"
        ;;  jump to inc+test
        jmp VAL0
        .byte "D#"
      .byte "]"
;;;  autopatches jump to here if false (PUSHLOC)


        ;; i > 255
        ;; (saves 20B for PRIME for)
        .byte "|for(i=0;i<%D[d];++%V)"
;;; 40B (is less than while!!!
      .byte "["
        lda #0
        sta VAR0
        sta VAR1
        ;; skip inc first time
.ifdef ZPVARS
        ;beq 2+2+2
        .byte $f0,2+2+2
.else
        ;beq 3+2+3
        .byte $f0,3+2+3
.endif
        ;; We moved inc here
        .byte ":"               ; note this generates no byte
        inc VAR0
        bne :+
        inc VAR1
:       
.ifnblank
        putc 'i'
        lda VAR0
        sta tos
        lda VAR1
        sta tos+1
        jsr puth
.endif
        ;; test i<%D
        lda VAR0
        pha
        lda VAR1
        .byte "D"
        cmp #'>'
        beq @eq
        bcc @lt
        pla
@eqorgt:
        jmp PUSHLOC
@eq:       
        ;; hi equal
        pla
        cmp #'<'
        bcs @eqorgt
        bcc @ok
@lt:
        pla
@ok:
      .byte "]"
        .byte _S
      .byte "["
        .byte ";d"
        .byte ";"
        ;; jump to inc+test
        jmp VAL0
        .byte "D#"
      .byte "]"
        ;; autopatches jump to here if false (PUSHLOC)


        .byte "|while(%A<"
        ;; similar to while(%A<%D)
      .byte "["
        ;; reverse cmp as <> NUM avail first
        .byte ":"               ; loop back location
        .byte "#"               ; push var address
      .byte "]"
.scope        
        .byte _E,")"
        ;; cmp with VAR
      .byte "["
        .byte ";"               ; pop address of var
        cpx VAR1
        bne @decide
        ;;  hi = equal
        cmp VAR0
        beq @nahwhile
@decide:
;;; TODO: seems longer than needed?
        bcs @okwhile            ; NUM>=VAR
@nahwhile:
        ;; jmp to end if false
        jmp PUSHLOC
@okwhile:
.endscope
      .byte "]"
        .byte _S
      .byte "[;d;"              ; pop tos, dos=tos; pop tos
        ;; jump to beginning of loop (:)
        jmp VAL0
      .byte "D#]"               ; tos= dos, push tos (patch)
        ;; autopatches jump to here if false (PUSHLOC)


;;; OPT: WHILE(a)...
;;; TODO: while(--a) ???
        .byte "|while(%V)"
        .byte "[:]"

      .byte "["
        lda VAR0
        ora VAR1
        ;; jmp to end if false
        bne :+
        jmp PUSHLOC
:       
      .byte "]"
        .byte _S
;;; 10B
;;; A kind of "complicated swap"
;;; TODO: maybe just a generic "pickN"???
;;;   'p' get's patched like normal and other manual
      .byte "[;d"               ; pop tos, dos=tos
        .byte ";"               ; pop tos
        ;; jump to beginning of loop (:)
;;; TODO: %j
        jmp VAL0
        .byte "D"               ; tos= dos
        .byte "#"               ; push tos (to patch)
      .byte "]"
        ;; autopatches jump to here if false (PUSHLOC)
.endif ; OPTRULES



;;; FOR( ; ; )
        .byte "|for(",_S

;
FORRUN=1

      ;; CONDITION
      .byte "["
PUTC 'B'
        .byte ":"               ; -4
        ;; test can be empty, but need to be true!
        lda #$ff
      .byte "]"
        .byte _S

      ;; LOOP "INC"
      .byte "["
PUTC 'b'        
        ;; test actual condition
        tay
        bne :++
        txa
        bne :++
:       
PUTC 'F'
        jmp PUSHLOC             ; -3
:       
PUTC 'T'
        ;; skip over INC (do first!)
        jmp PUSHLOC             ; -2
PUTC 'C'
        .byte ":"               ; -1
      .byte "]"
;;; TODO: need to make distinction beteen
;;;    argument statements and _E,
;;;    latter can take a,b,c; not in args!
        .byte _E,")"
      .byte "[:]"               ;  0
.ifdef FORRUN
      .byte "%{"
        ;; TODO: get -3 => tos
        tsx
        lda $102+ 3 *3,x
        sta tos
        lda $103+ 3 *3,x
        sta tos+1
jsr nl
jsr puth
jsr nl
        IMM_RET
.endif
      .byte "["
        jmp VAL0
      .byte "]"

.ifdef FORRUN
      .byte "%{"
        ;; TODO: get -2 => tos
        tsx
        lda $102+ 2 *3,x
        sta tos
        lda $103+ 2 *3,x
        sta tos+1
jsr nl
jsr puth
jsr nl
        IMM_RET
      .byte "%{"
        ;; TODO: patch -2 PUSHLOC to skip here
        lda _out+1
        ldy #1
        sta (tos),y
        lda _out
        dey
        sta (tos),y
        IMM_RET

      ;; BODY
.endif
      .byte "["
PUTC 'S'
      .byte "]"
        .byte _S

.ifdef FORRUN
      .byte "%{"
        ;; TODO: get -4 to skip there 
        tsx
        lda $102+ 4 *3,x
        sta tos
        lda $103+ 4 *3,x
        sta tos+1
jsr nl
jsr puth
jsr nl
        IMM_RET
.endif

      .byte "["
PUTC 's'
        jmp VAL0
      .byte "]"


.ifdef FORRUN
      .byte "%{"
        ;; TODO: get ??? => tos
        tsx
        lda $102+ 3 *5,x
        sta tos
        lda $103+ 3 *5,x
        sta tos+1
jsr nl
jsr puth
jsr nl
        IMM_RET
      .byte "%{"
        ;; TODO: patch -4 PUSHLOC to skip here
        lda _out+1
        ldy #1
        sta (tos),y
        lda _out
        dey
        sta (tos),y
        IMM_RET
.endif
        ;; cleanup
        .byte "[;;;;]"



;;; WHILE()...
        .byte "|while("
        .byte "[:]"
        .byte _E,")"

      .byte "["
        stx savex
        ora savex
        ;; jmp to end if false
        bne :+
        jmp PUSHLOC
:       
      .byte "]"
        .byte _S

;;; 10B
;;; A kind of "complicated swap"
;;; TODO: maybe just a generic "pickN"???
;;;   'p' get's patched like normal and other manual
      .byte "[;d"               ; pop tos, dos=tos
        .byte ";"               ; pop tos
        ;; jump to beginning of loop (:)
;;; TODO: %j
        jmp VAL0
        .byte "D"               ; tos= dos
        .byte "#"               ; push tos (to patch)
      .byte "]"
        ;; autopatches jump to here if false (PUSHLOC)


;;; TODO: remove?
.ifnblank
        ;; - swap the two locs!
;;; 28B
      .byte "%{"
        ;; TODO: this may not be easily skippable
        pla
        pla
        sta pos
        pla
        sta pos+1
        
        pla
        pla
        sta tos
        pla
        sta tos+1
        
        lda pos+1
        pha
        lda pos
        pha
        lda #'p'                ; patch and end
        pha
        
        IMM_RET

        ;; TOS is now before condition
      .byte "["
        jmp VAL0
      .byte "]"
.endif
        
        ;; autopatch 'p' at end to go condition

        
.ifdef OPTRULES
;;; OPT: DO ... WHILE(a);
        .byte "|do"
        .byte "[:]"
        .byte _S

        .byte "while(%V);"
      .byte "["
        lda VAR0              
        ora VAR1
        .byte ";"               ; pop tos
        ;; don't loop if not true
;;; TODO: potentially "b" to generate relative jmp
        bne :+
        jmp VAL0
:        
      .byte "]"

.endif

;;; DO...WHILE
        .byte "|do"
      .byte "[:]"
        .byte _S

        .byte "while(",_E,");"
      .byte "["
        stx savex
        ora savex
        .byte ";"
        beq :+
        jmp VAL0
:       
      .byte "]"






;;; ========================================
;;; TODO: move out to oric-cmd.rules.

FUNC _oricstart

.ifdef __ATMOS__
        .include "atmos-cmd.ruleS"
.endif ; __ATMOS__

FUNC _oricend

;;; TODO: furk!
;;;   thsi worked, when it shouldn't have!
;;;   HAHA: 5555555
;;; 
;;; void gotoxy(unsigned char, unsigned char);
;;;    somehow by pure "Luck" it worked...
;;;   but datastack is messed up!

;;; todo:
;        .BYTE "|gotoxy(",_BYTEPARM,",",_BYTEPARAM,");"

;;; void gotoxy(unsigned char, unsigned char);
.import _gotoxy

        .byte "|gotoxy",_X
      .byte "["
        jsr _gotoxy
      .byte "]"

;;; memcpy len<=256
;;; Function call with 3 constants:
;;;   cost:   23 B (3x lda/ldx, 2x sta/stx, 1x jsr)
;;;   inline: 16 B !

        .byte "|memcpy(%D[d],%D,"
      .byte "["
;;; 8B
        ldy #0

        .byte ":"

        lda VAL0,y
        .byte "D"
        sta VAL1,y

      .byte "]"
;;; TODO: verify small <= 256
;;;   and/or generate one that copies pages (+7 B!)
        .byte "%D);"
      .byte "["
;;; 8B
        iny
        cpy #'<'
        .byte ";"
        bcs :+
        jmp VAL0
:       
      .byte "]"
        
        .byte "|memcpy("
;;; (8+) 15B =(23B params+) copy
        .byte _E,","
      .byte "["
        sta dos
        stx dos+1
      .byte "]"

        .byte _E,","
      .byte "["
        sta tos
        stx tos+1
      .byte "]"
        
        .byte _E,");"
      .byte "["
;;; 8
        tay
:       
        lda (tos),y
        sta (dos),y
        iny
        bne :-

;;; TODO: not generate this part if X=0!!!
        ;; next page
;;; 7B
        inc tos+1
        inc dos+1
        dex
        bpl :-
      .byte "]"

endcmdrules:    

;;; END: hardcoded differnt "cmd("
;;; ========================================







;;; ========================================
;;; START: optimize parsing of   "|%V..."

;;; TODO: not working, seems to loop!

;;; TODO: maybe can optimize if %V name
;;;   isn't a defined variable?

;;; Moving them just here made parsing 1.27s=>1.53s
;;; 

;STARTVAROPT=1

.ifdef STARTVAROPT
        .byte "|"

        ;; store current parsing location
      .byte "%{"
        lda inp 
        sta pos
        lda inp+1
        sta pos+1
        IMM_RET

        ;; check that we have a VAR
        .byte "%V"
        ;; OK - we got it!
      .byte "%{"
        ;; reset parsing and go do the rules
        lda pos
        sta inp
        lda pos+1
        sta inp+1
putc '!'        
        clc
;;; TODO: potential zero or | ? (safer)
        bcc startparsevarfirst

        ;; we didn't match, skip all!
        .byte "|"
      .byte "%{"
putc '%'
;;; TODO: potential zero or | ?
        jmp endparsevarfirst

;;; --- after here are ONLY rules that start with %A!
        .byte "%{"
startparsevarfirst:
putc '<'
        IMM_RET

.endif ; STARTVAROPT


.ifdef OPTRULES
        ;; "|%A=%V;" (or even %A=%V _E)
        ;; TODO: if keep track of AX= var/value
        ;;   (and reset whenver we have : PUSHLOC etc)
        ;;   we may be able to save 4 bytes!

        .byte "|%A=0;"
      .byte "[D"
        lda #0
        sta VAR0
        sta VAR1
      .byte "]"
.endif ; OPTRULES

        ;; A=7; // simple assignement, ONLY as statement
        ;; and can't be nested or part of expression
        ;; (unless we use a stack...)
        .byte "|%A=",_E,";"
      .byte "[D"                ; 'D' => tos=dos
        sta VAR0
        stx VAR1
      .byte "]"

.ifdef OPTRULES
;;; NOTE: ops are done last, is that ok (except for -)?

        ;; NOTE: no need provide: v op= const;
        ;;       - it would wouldn't save any bytes!
        .byte "|%A+=",_E,";"
      .byte "[D"
        clc
        adc VAR0
        sta VAR0
        txa
        adc VAR1
        sta VAR1
      .byte "]"

        .byte "|%A-=",_E,";"
      .byte "[D"
        sec
        eor #$ff
        adc VAR0
        sta VAR0
        txa
        eor #$ff
        adc VAR1
        sta VAR1
      .byte "]"

        .byte "|%A&=",_E,";"
      .byte "[D"
        and VAR0
        sta VAR0
        txa
        and VAR1
        sta VAR1
      .byte "]"

        .byte "|%A\|=",_E,";"
      .byte "[D"
        ora VAR0
        sta VAR0
        txa
        ora VAR1
        sta VAR1
      .byte "]"

        .byte "|%A^=",_E,";"
      .byte "[D"
        eor VAR0
        sta VAR0
        txa
        eor VAR1
        sta VAR1
      .byte "]"

        .byte "|%A>>=1;"
      .byte "[D"
;;; 6B
        lsr VAR1
        ror VAR0
      .byte "]"

        .byte "|%A<<=1;"
      .byte "[D"
;;; 6B
        asl VAR0
        rol VAR1
      .byte "]"

        .byte "|%A>>=2;"
      .byte "[D"
;;; 12B
        lsr VAR1
        ror VAR0
        lsr VAR1
        ror VAR0
      .byte "]"

        .byte "|%A<<=2;"
      .byte "[D"
;;; 12B (zp: 8B)
        asl VAR0
        rol VAR1
        asl VAR0
        rol VAR1
      .byte "]"

.ifdef ZPVARS
        .byte "|%A>>=3;"
      .byte "[D"
;;; 8B
        lsr VAR1
        ror VAR0
        lsr VAR1
        ror VAR0
        lsr VAR1
        ror VAR0
      .byte "]"

        .byte "|%A<<=3;"
      .byte "[D"
;;; 8B
        asl VAR0
        rol VAR1
        asl VAR0
        rol VAR1
        asl VAR0
        rol VAR1
      .byte "]"
.endif ; ZPVARS

.endif ; OPTRULES


        .byte "|%A>>=%D;"
      .byte "["
;;; 14B (tradeoff 14=6*d => d=2+)
;;; (zp: 12B)
        ldy #'<'
        .byte "D"
:       
        dey
        bmi :+

        lsr VAR1
        ror VAR0

        sec
        bcs :-
:       
      .byte "]"

        .byte "|%A>>=%V;"
      .byte "["
;;; 14B (tradeoff 14=6*d => d=2+)
        ldy VAR0
        .byte "D"
:       
        dey
        bmi :+

        lsr VAR1
        ror VAR0

        sec
        bcs :-
:       
      .byte "]"

        .byte "|%A<<=%D;"
      .byte "["
;;; 14B
        ldy #'<'
        .byte "D"
:       
        dey
        bmi :+

        asl VAR0
        rol VAR1

        sec
        bcs :-
:       
      .byte "]"

        .byte "|%A<<=%V;"
      .byte "["
;;; 14B
        ldy VAR0
        .byte "D"
:       
        dey
        bmi :+

        asl VAR0
        rol VAR1

        sec
        bcs :-
:       
      .byte "]"

        ;; TODO: this is now limited to 128 index
        ;; word[%D]= ... fixed address... hmmm
        .byte "|%A\[%D\]="
;;; TODO: similar to poke?
      .byte '['
        ;; prepare index (*2)
        lda '<'
        asl
        pha
      .byte ']'
        .byte _E,";"
      .byte "[D"
        ;; load index
        sta savea
        pla
        tay
        lda savea

        sta VAR0,y
        txa
        sta VAL1,y
      .byte "]"

.ifdef STARTVAROPT
        .byte "%{"
putc '.'
clc
bcc parsevarcont
putc '>'
endparsevarfirst:
;;; TODO: ?
        jmp _fail
;;; TODO: or??
        ;; this moves rule parsing to here!
parsevarcont:
        IMM_RET
.endif ; STARTVAROPT

;;; END: optimize parsing of   "|%V..."
;;; ========================================


        ;; Expression; // throw away result
        .byte "|",_E,";"

        .byte 0

FUNC _stmtrulesend




FUNC _parametersstart
;;; - oric paramters
ruleY:  
        .byte "("
;;; Don't care?
.ifnblank
      .byte "["
        ;; store 0 for no error
        lda #0
        sta $02e0
      .byte "]"
.endif
      .byte "%{"
;PUTC 'C'        
        ;; oric parameters start
        lda #$02
        sta pos+1
        lda #$e1
        sta pos
        IMM_RET

        .byte _Z
        .byte 0

ruleZ:  
        .byte ",",TAILREC

        ;; end
        .byte "|)"
;        .byte "%{"
;PUTC 'F'
;        IMM_RET

        ;; parse next paramter
        .byte "|",_E
      .byte "%{"
;PUTC 'D'        
        lda pos
        sta tos
        lda pos+1
        sta tos+1
        IMM_RET
      .byte "["
        sta VAL0
        stx VAL1
      .byte "]"
      .byte "%{"
;PUTC 'E'        
        ;; move to next paramter addr
        jsr _incP
        jsr _incP
        IMM_RET
        ;; get next param
        .byte TAILREC
        
        .byte 0




;;; ----------------------------------------
;;             C   C   6   5

;;; cc65 AX _fastcall_ calling convention
.import pushax, popax, pusha0, pusha, popa

.ifnblank ;.ifdef __CC65__
ruleX:
        .byte 0
.else
;;; TODO: think hard, does it handle nesting correctly?
ruleX:  
        .byte "("
;      .byte "%{"
;        PUTC 'B'
;        IMM_RET
        .byte TAILREC

        .byte "|)"
;      .byte "%{"
;        PUTC 'E'
;        IMM_RET

        .byte "|,"
      .byte "["
        jsr pushax
;;; problem here, depend on address???
      .byte "]"
;      .byte "%{"
;        PUTC 'P'
;        IMM_RET
        .byte TAILREC

        ;; one byte constant paramter 0-255
        .byte "|%D,"
      .byte "%{"
        ;; TODO: this may not be easily skippable
;;;  make sure %D <256
        lda tos+1
        beq :+
        jmp _fail
:              
        jsr immret
      .byte "["
        ;; saves 2 bytes!
        lda  #'<'
        jsr pusha0
      .byte "]"
        .byte TAILREC

        .byte "|",_E
        ;; TODO: can we optimize if same constant twice? (10,10)??
 ;      .byte "%{"
;        PUTC 'E'
;        IMM_RET
        .byte TAILREC
        
        .byte 0



;;; TODO: fails on foo(42,(93),35) ???
        .byte "("
       .byte "%{"
PUTC 'B'
        ;; counter for args
        lda #0
        jsr pusha
        IMM_RET

        .byte TAILREC


        .byte "|,"
      .byte "%{"
PUTC 'P'
        putc '?'
        IMM_RET

      .byte "["
        jsr pushax
      .byte "]"
        .byte TAILREC
        
        .byte "|)"
      .byte "%{"
PUTC 'E'
        jsr popa
        sta tos
        IMM_RET
      .byte "["
        ;; vararg always generated, lol
        ;; (however vararg f needs call jsr pushax
        ;;  for the last argument before jsr FUN)
        ldy #'<'
      .byte "]"


        .byte "|",_E
        ;; parse E leaves value in AX
.ifnblank
      .byte "%{"
PUTC 'A'
        ;; +2 for each arg
        jsr popa
        clc
        adc #02
        jsr pusha
        putc 'B'
        IMM_RET
.endif
        .byte TAILREC


        .byte 0
.endif ; __CC65__






;;; ========================================
;;;         P H A  /  T X A  /  P H A 

;;; Use the hardward stack for parameters
;;; 
;;; TODO: cleanup!!! LOL (or just function copy)
;;; (see Play/calling-conventions.asm )



;;; (mostly copied from cc65 ruleX)

HW_PARAMS=1
.ifndef HW_PARAMS

ruleW:

        .byte 0

.else

;;; TODO: think hard, does it handle nesting correctly?


ruleW:  

        ;; End
        .byte ")"
        ;; TODO: for now all parameters are put
        ;;   on stack!
      .byte "["
        pha
        txa
        pha
      .byte "]"


        ;; Comma pushes!
        .byte "|,"
      .byte "["
        pha
        txa
        pha
      .byte "]"
        .byte TAILREC


        ;; 0 value argument 
        ;; TODO: handle 0,0,0.... ?
        .byte "|0,"
      .byte "["
        lda #0
        pha
        pha
      .byte "]"
        .byte TAILREC

        ;; one byte constant paramter 0-255
        .byte "|%D,"
      .byte "%{"
        ;;  make sure %D <256
        lda tos+1
        beq :+
        jmp _fail
:              
        IMM_RET
      .byte "["
        ;; saves 1 byte, hmmm
        lda #'<'
        pha
        lda #0
        pha
      .byte "]"
        .byte TAILREC


        ;; Generic expression 2 B value
        .byte "|",_E
        ;; TODO: can we optimize if same constant twice? (10,10)??
        .byte TAILREC
        

        .byte 0

.endif ; HW_PARAMS

FUNC _parametersend

;;; TODO: remove
.ifnblank

;;; TODO: find better place...
TOS2POS:
        lda _out
        sta POS
        ldx _out+1
        stx POS+1
        rts

POS2TOS:        
        lda POS
        sta tos
        lda POS+1
        sta tos+1
        rts

TOSpatch:       
        ldy #1                  ; void inline 0 !!! LOL
        lda _out+1
        sta (tos),y
        dey
        lda _out
        sta (tos),y
        rts
.endif

endrules:       
        .byte "|",$ff

;;; END rules
;;; ========================================

FUNC _rulesend

.include "end.asm"


FUNC _idestart

FUNC _aftercompile
;;; TODO: reset S stackpointer! (editaction C-C goes here)

;;; doesn't set A!=0 if no match/fail just errors!
;        sta err

;;; TODO: print earlier before first compile?
.ifdef __ATMOS__
        .data
status: 
        .word $bb80-2
        ;;     ////////////////////////////////////////
        ;;     MeteoriC `25 jsk@yesco.orgY^Help*acWCAPS
        .byte "MeteoriC `25 jsk@yesco.org"
        .byte                 127&YELLOW,"^Help",127&WHITE
        .byte 0
.code

        ;; - from
        lda #<status
        ldx #>status        
        jsr memcpyz         
.endif ; __ATMOS__

        ;; failed?
        ;; (not stand at end of source \0)
        ldy #0
        lda (inp),y
        and #127
        bne :+
        jmp _OK
:       
;;; ------------ ERROR ----------

FUNC _ERROR

.ifdef __ATMOS__
        lda #(RED+BG)&127
        sta SCREEN+35
.endif ; __ATMOS__

        ;; - save RTS in output to not crash
        ;; replace "jmp main" with "jmp hell"
        lda #_RTS
        lda #<hell
        ldx #>hell
        sta _output+1
        stx _output+2
        

.ifdef ERRPOS
        ;; hibit string near error!
        ;; (approximated by as far as we read)
        ;; TOOD: or as far as we _fail (or _acccept?)
        ldy #0
        lda (erp),y
        ora #128
        sta (erp),y

.endif ; ERRPOS

.scope
.ifdef PRINTINPUT
        ;; print it
        PRINTZ {10,YELLOW+BG,BLACK,"ERROR",10,10}

        lda originp
        sta pos
        lda originp+1
        sta pos+1

        ;; jumps into middle of loop!
        jmp print

loop:
.ifdef ERRPOS
        ;; hi bit on char is indicator of how far it
        ;; is ok; next char, it's assumed to be near
        ;; near the error; thus hilite red background
        ;; and white text.
        bpl nohi

        pha
        putc BG+RED
        putc WHITE
        pla

        ;; - remove hibit from src
        and #127
        sta (pos),y

        ;; - print MORE chars after HILITE for context
        ldy #1
        ldx #0
printmore:
        jsr putchar
        lda (pos),y
        ;; limit lines printed to 7
        cmp #10
        bne :+
        inx
        cpx #8
        bcs done
:       
        ;; limit chars printed
        iny
        cpy #128
        bcc printmore
done:   
        PRINTZ {10,"...",10}
        jmp _edit
        
nohi:
.endif ; ERRPOS

        ;; print source char
        jsr putchar

        jsr _incP
print:
        ldy #0
        lda (pos),y
        bne loop

        putc 10
.endif ; PRINTINPUT
.endscope

        ;; printed program error
        jmp _edit



FUNC _OK

 .ifdef __ATMOS__
        lda #(GREEN+BG)&127
        sta SCREEN+35
.endif ; __ATMOS__


        jsr _eosnormal

        PRINTZ {10,10,"OK "}

        ;; print size in bytes
        ;; (save in gos, too)
;;; TODO: gos gets overwritten by dasm(?)
        sec
        lda _out
        sbc #<_output
        sta tos
        sta gos
        lda _out+1
        sbc #>_output
        sta tos+1
        sta gos+1
        
        jsr putu
        
        putc ' '
        PRINTZ {" Bytes",10,10}

.ifblank
        GOTOXY 20,27
        ;;     
        ;; /////////////12345678901234567890
        PRINTZ {YELLOW,"^Run ESC=src ^Help",10}
.endif

        jmp _edit


_run:   

        ;; set ink for new rows
        lda #BLACK+16           ; paper
        ldx #WHITE&127          ; ink

        jsr _eoscolors

.zeropage
runs:   .res 1
.code

        ;; RUN PROGRAM n TIMES
;RUNTIMES=100
RUNTIMES=1
;RUNTIMES=10
.assert (RUNTIMES<256),error,"%% RUNTIMES too large"

        lda #RUNTIMES
        sta runs

.ifdef TIM
        ;; initiate CYCLE EXACT MEASUREMENT!
        lda #$ff
        sta READTIMER
        sta READTIMER+1
.endif ; TIM

again:
        jsr _output

        dec runs
        bne again

        ;; save result
        pha
        txa
        pha

        jsr _eosnormal

.ifdef TIM
        ;; 13617
        lda READTIMER
        ldx READTIMER+1

        ;; adjust, one time overhead 10c, each loop 8
        ;; (may depend on code-location/page boundary?)
TIMONCE=10
TIMPER=8
        TIMCOST=$ffff - TIMONCE - TIMPER*RUNTIMES
        ;; saved lo, hi
        sec
        eor #$ff
        adc #<TIMCOST
        pha
        txa
        eor #$ff
        adc #>TIMCOST
        pha

        ;; print "[47B 100x: 4711us]"
        jsr nl
        putc WHITE
        putc '['

        ;; print "47B "
;;; TODO: gos gets overwritten by dasm(?)
        lda gos
        sta tos
        ldx gos+1
        stx tos+1
        jsr putu
        jsr spc
        putc 'B'
        jsr spc

        ;; print "100x: "
        lda #<RUNTIMES
        sta tos
        ldx #>RUNTIMES
        stx tos+1
        jsr putu
        putc 'x'
        putc ':'
        jsr spc

        ;; restore timing
        pla
        sta tos+1
        pla
        sta tos

        jsr putu

        jsr spc
        putc 'u'
        putc 's'
        putc ']'
        jsr nl
.endif ; TIM

        ;; prints return code
        putc 10
        putc '='
        putc '>'
        jsr spc

        pla
        sta tos+1
        pla
        sta tos
        jsr putu

        jsr nl
        

;;; full screen editor on ORIC ATMOS
;;; - CTRL-C : compile program & run
;;; - CTRL-R : run
;;; - CTRL-L : display source for editing
;;; 
;;; - CTRL-Q : disasm compiled code
;;; - CTRL-Z : disasm mucc

;;; - just use BASIC terminal!
;;; - add "save" (to tape? load from tape?)
;;; - limit walk out and intercept ctrl-L
;;; - add features
;;;   + ^O insert newline
;;;   + ^K remove line
;;;   + ^A ^E navigation ^F ^B

;;; ORIC terminal magical chars
;;; -(CTRL-A : copy char under cursor)
;;; -(CTRL-C : break)
;;; - CTRL-D : auto double height
;;; - CTRL-F : toggle keyclick
;;; - CTRL-G : BELL
;;; - CTRL-H : backspace
;;; - CTRL-I : forward
;;; - CTRL-J : line feed
;;; - CTRL-K : up
;;; - CTRL-L : clear screen
;;; - CTRL-M : carriage return
;;; - CTRL-N : clear row
;;; - CTRL-O : toggle screen (disable)
;;; - CTRL-P : toggle printer
;;; - CTRL-Q : toggle cursor
;;; - CTRL-S : toggle screen on/off
;;; - CTRL-T : toggle CAPS
;;; -(CTRL-X : cancel line)

;;; - CTRL- toggle protected column ORIC-1 only? (say ^I)

FUNC _editorstart


;;; Issues:
;;; - return doesn't break line into two
;;;   need to scroll down part of screen 
;;;   & move some text to next line, indented...
;;; - ctrl-O insert newline
;;; 
;;; ! can cheat: insert actual 10, "extract text",
;;;   clear screen, print text!
;;; 
;;; - kill line, similar
;;; 
;;; - need ^C to break!
;;; - or at least NMI! (simpliest)
;;; 
;;; - no way to save? LPRINT? 
;;; 
;;; - seems CSAVE and CLOAD works like "random access"
;;;   Not sure if last file wins if you down load .tap
;;;   that has been saved in oriutron.
;;; 
;;; - 





FUNC _edit
        CURSOR_OFF
        
.ifdef INTERRUPT
.ifnblank
        ;; print time
        putc 'M'-'@'
        lda seconds
        sta tos
        lda seconds+1
        sta tos+1
        jsr putu
        jsr spc

        jmp _edit
.endif
.endif ; INTERRUPT

.ifdef __ATMOS__
;;; update display of state
        ;; - dirty
        lda dirty
        beq :+
        lda #'*'
        SKIPTWO
:       
        lda #' '
        sta SCREEN+33

        ;; - showbuffer
        lda showbuffer
        beq :+
        lda #'a'
        SKIPTWO
:       
        lda #' '
        sta SCREEN+34
.endif ; __ATMOS__


        ;; "EDITLOOP"

        jsr getchar

        jsr editaction
        jmp _edit


editaction:     

;;; - ESC - toggle "editor" and "cmd"
        cmp #27
        bne :+

        lda showbuffer
        bmi load                ; firsttime
        beq load                ; no buffer shown => show!
docmd:  
        jsr _savescreen

        lda #0
        sta showbuffer
        jsr _eosnormal
        jsr nl
        jmp nl
:       
;;; - ctrl-Load/edit
        cmp #CTRL('L')
        bne  :+

load:   
        ;; first time?
        lda showbuffer
        bpl @notfirst

        lda 0
        sta showbuffer
        sta dirty

        jsr _eosnormal
        jsr _printsrc
        jmp write
@notfirst:       
        ;; not first
        jsr _eosnormal
        jmp _loadscreen
:       
;;; - CTRL-H (only on oric)
        cmp #CTRL('H')
        bne :+
        ;; CTRL-KEY?
        ldx $0209
        cpx #162
        bne :+
dohelp: 
        jsr _savescreen
        jsr _eosnormal
        jsr _help
        jmp _loadscreen
:
;;; - ctrl-V - info
        cmp #CTRL('V')
        bne :+

        jsr _savescreen
        jsr _eosnormal
        .import _info
        jmp _info
:       
;;; - ctrl-C - compile
        cmp #CTRL('C')
        bne :+

        jsr _savescreen

        lda #0
        sta showbuffer

        jsr nl
        lda #(BLACK+BG)&127
        ldx #WHITE&127
        jsr _eoscolors
        PRINTZ {10,YELLOW,"compiling...",10,10}
        ;; This basically restarts program, lol
	; TIMER
        
        ;; CTRL-KEY?
;        ldx $0209
;        cpx #162
;        beq @default

        ;; shift + ctrl ? lol
        ;; TODO: better combo


        ;; save 10 newline at last pos in every line!
        ;; lol
        ;; TODO: maybe have other way to detect this
        ;;   during compilation?

;;; TODO: make one sub? (also in FUNC _compile
;;;  TODO: maybe have one func set all defaults,
;;;   then you can override, and call "cont"?
        lda #<_output
        ldx #>_output
        sta _out
        stx _out+1
        ;; set input = screen
        lda #<(savedscreen+40)
        ldx #>(savedscreen+40)
        ;; set one byte 0 *after* screen!
        ;; (I guess we could just last pos..)
        ;; 0 -- it's also BLACK TEXT...
        ldy #0 
        sty savedscreen+SCREENSIZE
        ;; alright, all done?
        jmp _compileAX
        
@default:
        jmp _init


:       
;;; - DEL - delete backwards
        cmp #127                ; DEL-key
        bne :+
        
        inc dirty
        ;; back one, delete forward!
        jsr bs
        lda #CTRL('D')
:       
;;; - ctrl-D - delete char forward
        cmp #CTRL('D')
        bne :+
@bs:
        inc dirty
        ;; move chars back til end of line
        ldy CURCOL
@copyback:
        cpy #39
        bcs @deldone
        ;; copy one char
        iny
        lda (ROWADDR),y
        dey
        sta (ROWADDR),y
        iny
        jmp @copyback

@deldone:
        ;; erase last char
        lda #' '
        sta (ROWADDR),y

ret:
        ;; if at last pos in row
        lda CURCOL
        cmp #39
        beq @notlast
        rts
@notlast:       
        ;; - then go to end of line (last nonspace)
        lda #CTRL('E')
:       
;;; - ctrl-A - beginning of text in line
        cmp #CTRL('A')
        bne :+

        putc CTRL('M')

        ;; move to first nonspace
        
        ;; (cursor must be on for this to work!!!)
        putc CTRL('Q')

ctrla:  
        ;; end of screen - don't!
        lda CURROW
        cmp #27
        beq ret                 
        ;; stand on (white)space?
        ldy CURCOL
        lda (ROWADDR),y
        cmp #' '+1
        bmi ret
        ;; move forward
        jsr forward
        jmp ctrla

        ;; off
        putc CTRL('Q')
:       
;;; - ctrl-E - end of text in line
        cmp #CTRL('E')
        bne :+

        ;; (cursor must be on for this to work!!!)
        putc CTRL('Q')

        ;; move to end of line, lol
        putc CTRL('M')          ; beginning of line
        jsr nl

        ;; move to first nonspace
ctrle:  
        ;; beginning of screen - don't!
        lda CURROW
        cmp #1
        beq ret                 
        ;; move back
        jsr bs
        ;; stand on space?
        ldy CURCOL
        lda (ROWADDR),y
        cmp #' '+1
        bmi doneCE
        jmp ctrle
doneCE: 
        ;; forward one (after last char)
        jsr forward

        ;; off
        putc CTRL('Q')

        rts
:
;;; - ctrl-R - run/display error
        cmp #CTRL('R')
        bne :+

.scope
        jsr _savescreen
        jsr _eosnormal
        jmp _run
.endscope
        ;; just shows compilation errors again
        ;; jmp _aftercompile
:       
;;; - ctrl-Qasm - disasm => ^M machine code? lol
        cmp #CTRL('Q')
        bne :+

        jsr _savescreen
        jmp _dasm
:       
;;; - ctrl-Zource (as print source)
        cmp #CTRL('Z')
        bne :+

        jsr _savescreen
        jsr _eosnormal
        jmp _printsrc
:       
;;; - ctrl-Garnish source - pretty print
        cmp #CTRL('G')
        bne :+

        jsr _savescreen
        jsr _eosnormal
        jsr clrscr
        lda #<input
        ldx #>input
        .import _prettyprint
        jmp _prettyprint
:       
;;; - ctrl-U repeat N times ... command
        cmp #CTRL('U')
        bne :+

        rts
:       
;;; - ctrl-W - save
        cmp #CTRL('W')
        bne :+
        
write:  
        ;; over-ride, you can write, silly one!
        inc showbuffer
        inc dirty

        jsr _savescreen

        ;; yeah, it's still there
        inc showbuffer
        rts
:       
;;; - ctrl-Youit (just for sim65, can't catch ^C)
        cmp #CTRL('Y')
        bne  :+

        jsr _savescreen
        jsr nl
.ifdef __ATMOS__

        ;; NOP
        rts
.else

.import _exit
        lda #0
        tax
        jsr _exit
.endif

:       

;;; === MAPPING EMACS commands to ORIC control codes

;;; - RETURN goes next line indented as prev!
        cmp #CTRL('M')
        bne :+

        inc dirty

.ifdef DOO
        ;; remember here
        ldx CURCOL
        stx savex
        ;; save current row ptr
        lda ROWADDR
        sta sos
        lda ROWADDR+1
        sta sos+1
        ;; indent like this line
        lda #CTRL('A')
        jsr editaction
        ldy CURCOL
        sty savey
        ;; - move down
        lda #CTRL('N')
        ;; - scroll these lines down
        ;;   = from 
        lda #<SCREENEND-40
        sta tos
        lda #>SCREENEND-40
        sta tos+1
        ;;   = to
        lda #<SCREENEND
        sta dos
        lda #>SCREENEND
        sta dos+1
        ;;; copy line down
        ldy #39
:       
        lda (tos),y
        sta (dos),y
        dey
        bpl :-
        ;; dec lines
        
.endif ; DOO
        

:       
;;; - ctrl-Forward (emacs)
        cmp #CTRL('F')
        bne :+

        jmp forward
:       
;;; - ctrl-Backwards (emacs)
        cmp #CTRL('B')
        bne :+

        inc dirty
        jmp bs
:       
;;; - ctrl-Next line (emacs)
        cmp #CTRL('N')
        bne :+

        lda #CTRL('J')
:       
;;; - ctrl-Previous line (emacs)
        cmp #CTRL('P')
        bne :+

        lda #CTRL('K')
:       
;;; - ctrl-Xended commands
        cmp #CTRL('X')
        ;; locked up?
;        beq extend

;;; - control char - just print it
        cmp #' '
        bcc editprint

;;; - INSERT CHAR (shift line + putchar)
        inc dirty
        pha
        ;; insert - push line right left of cursor
        ldy #38
:       
        lda (ROWADDR),y
        iny
        sta (ROWADDR),y
        dey
        dey
        cpy CURCOL
        bcs :-

        pla
editprint:
        ;; print it
        jmp rawputc

        ;; locked up?
extend:
        jsr _savescreen
        jsr _eosnormal
        
        lda #<_extendinfo
        ldx #>_extendinfo
        jsr _printz

        jmp _listfiles

        ;; get command character
        jsr getchar
        
        cmp #'b'
        bne :+
        jmp bytesieve
:       
        cmp #CTRL('F')
        bne :+
        ; jmp fileopen
:       
        cmp #CTRL('S')
        bne :+
        ; jmp savefile
:       
        cmp #CTRL('W')
        bne :+
        ; jmp writefile
:       
        cmp #CTRL('C')
        bne :+
        ; jmp crashexit
:       
        cmp #CTRL('Z')
        bne :+
        ; jmp zleep (10s?)
        ; PING
:       
        rts

FUNC _editorend


FUNC hell
        lda #<666
        ldx #>666
        rts



FUNC asmprintsrc
        ;; print next statement fully
        ;; from inp,y
        ;; 
        ;; (limit 256 chars)
        jsr _iasm
        
        putc ';'
        putc WHITE
        jsr spc

        ldy #0
;        iny
@nextc:       
        lda (inp),y
        beq @end
        cmp #10
        beq :+
        cmp #' '
        beq :+
        jsr putchar
:       
        cmp #';'
        beq @end
        cmp #'{'
        beq @end
        cmp #'}'
        beq @end

        iny
        bne @nextc
@end:
        putc GREEN

        rts




;.include "Play/byte-sieve-gen.asm"
.include "Play/byte-sieve-gen-opt.asm"



;;; TODO: move somewhere else?

origint:        .res 2
        
.ifdef INTERRUPT
FUNC _interrupt
; nah
;        rti
; nah
;        jmp (origint)

; better - LOL - WTF? how is this not equivalent?
;;; getting %R means somethingon stack messed up!!!
;        jmp $ee22

;;; doesn't get back to main code...

;;; copy of $ee22 routine...
        pha
        lda $0300
        and #$40
        beq :+
        sta $0300
        jsr $ee34
:       

;;; doesn't help much more
;        pla
;        rti

;;; gets called but no normal work done
;        PUTC '*'
        pla
        ;; basically jump to an changable rti!
        jmp $024a

;;
        
        pha
        txa
        pha
        tya
        pha

        PUTC '*'

        pla
        tay
        pla
        tax
        pla

        rti

        jmp (origint)
;        rti

        pha
        txa
        pha
        tya
        pha

;;; even this doesn't work...
        pha

        ;; count till hundred
        inc centis
;;; 85s if nothing
;;; (/ 85 34.45) = 2.46 ... 

;;; 34.4s
;        lda centis              ; if reversecount save 2c
;        cmp #100
        bne @done
        ;; update seconds
        inc seconds
        bne @next
        bne :+
        inc seconds+1
:       
PUTC '*'
.ifdef DOIT
        ;; print
        lda tos
        pha
        lda tos+1
        pha

        putc 'M'-'@'
        lda seconds
        sta tos
        lda seconds+1
        sta tos+1
        jsr putu
        jsr spc

        pla
        sta tos+1
        pla
        sta tos

.endif ; DOIT
@next:
        ;; reset centis
        lda #0
        sta centis

@done:
        pla
        tay
        pla
        tax
        pla
;;; lol?
;        rts

;;; no effect?
;        cli

        rti

.endif ; INTERRUPT


FUNC _eosnormal
        ;; reset to normal/default
        lda #BLACK&127+16       ; paper
        ldx #GREEN&127          ; ink
FUNC _eoscolors
;;; TODO:     make this save screen? save many calls


;;; TODO: oric const
        sta $026b               ; paper
        stx $026c               ; ink
        
        GOTOXY 2,27
        jmp nl



FUNC _printsrc
        jsr clrscr
        lda #<input
        ldx #>input
        jmp _printz

FUNC _listfiles
        ;; init
        lda #<input
        ldx #>input
        sta tos
        stx tos+1

        lda #'a'
        sta savea
@nextfile:       
        ;; last file?
        ldy #0 
        lda (tos),y
        beq @done

        pha
        ;; print 'letter'
        putc WHITE
        lda savea
        jsr putchar
        putc GREEN
        jsr spc

        pla
        ;; print first line
:       
        jsr putchar
        jsr _incT
        lda (tos),y
        beq @endfile
        cmp #10
        bne :-

        ;; skip till end of file
:       
        jsr _incT
        ldy #0 
        lda (tos),y
        bne :-

        ;; go next pos
@endfile:
        jsr _incT
        jsr nl
        inc savea
        jmp @nextfile

@done:
        rts


FUNC _help
        lda #<_helptext
        ldx #>_helptext
        jsr _printz

        jsr waitesc

FUNC _listsymbols
        ;; display names from ruleS
        PRINTZ {12,10, DOUBLE,YELLOW,"Symbols found",10, DOUBLE,YELLOW,"Symbols found",10, 10}
        
        lda #<_rules
        sta pos
        lda #>_rules
        sta pos+1
@nextbar:
        ldy #0
        lda (pos),y
        jsr _incP
        cmp #'|'
        bne @nextbar
        ;; next char
        lda (pos),y
        ;; end of rules ( endrules!)
        cmp #$ff
        beq @donelist
        ;; standing at name (maybe)
        ;; - print space if no have
        pha
        ldy CURCOL
        dey
        lda (ROWADDR),y
        cmp #' '+1
        bcc :+
        jsr spc
:       
        pla
@nextchar:       
        cmp #'a'
        bcc @nextbar
        cmp #'z'+1
        bcs @nextbar
        jsr putchar
        jsr _incP
        ldy #0
        lda (pos),y
        jmp @nextchar
        
@donelist:
        jsr waitesc
        jmp _loadscreen
waitesc:
        PRINTZ {CYAN,"    ESC>"}
        jsr getchar
        jmp _eosnormal
FUNC _helpend

FUNC _helptext

;;; 10. If a print line starts with control characters
;;;     – e.g., ESC N, etc. – then the protected columns
;;;     0 and 1 are used, overwriting any PAPER and INK
;;;     attributes. Always start the line with a
;;;     non-attribute character, such as space.

MEAN=WHITE
KEY=GREEN
CODE=GREEN
GROUP=YELLOW

.byte 'A'
.byte 12,10
;.byte 12,128+'A',128+'B',128+'C',10
.byte DOUBLE,"ORIC",YELLOW,"CC02",NORMAL,MEAN,"alpha",GREEN,DOUBLE,"minimal C-compiler",10
.byte DOUBLE,"ORIC",YELLOW,"CC02",NORMAL,' ',"     ",' ',DOUBLE,"minimal C-compiler",10
;.byte 128+'D',128+'E'
.byte "",10
.byte KEY,"ESC",MEAN,"Help  ",KEY," ^V",MEAN,"info",10
.byte KEY," ^C",MEAN,"ompile",KEY," ^X",MEAN,"ecute",10
.byte KEY," ^R",MEAN,"un    ",KEY," ^U",MEAN,"list",10
.byte KEY," ^Q",MEAN,"asm    - shows compiled code",10
.byte KEY," ^W",MEAN,"rite   - save screen/source",10
.byte KEY," ^L",MEAN,"oad    - load screen/source",10
.byte KEY," ^G",MEAN,"arnish - pretty print source",10
.byte MEAN,"// You are in the EDITOR (comment!)",10
.byte KEY,"arrow DEL",MEAN,"bs",KEY,"^D",MEAN,"del",KEY,"^A",MEAN,"<<",KEY,"^E",MEAN,">>",10
.byte MEAN,"line:)",KEY,"^P",MEAN,"rev",KEY,"^N",MEAN,"ext",KEY,"RET",MEAN,"next indent",10
.byte "",10
.byte MEAN,"C-Language globals",CODE,"a..z",MEAN,"type",CODE,"word",10
.byte GROUP,"V :",CODE,"a arr[..] *(char*)a",WHITE,"same",GREEN,"$ a",10
.byte GROUP,"= :",GROUP,"V",CODE,"=",GROUP,"V",MEAN,"[",GROUP,"OP S",MEAN,"]..",CODE,";",MEAN,"or",CODE,"a",GROUP,"OP",CODE,"=",GROUP,"S",CODE,";",10
.byte GROUP,"OP:",CODE,"+ - *2 /2 & | ^ << >> == < !",10
.byte GROUP,"S :",CODE,"v 4711 25 'c'",MEAN,"simple values",10
.byte GROUP,"FN:",CODE,"word A() {... return ...; }",10
.byte "    ",CODE,"if (...) ...;    else {...}",10
.byte "    ",CODE,"while(...) ...",10
.byte "    ",CODE,"do ... while(...);",MEAN,"most efficient!",10
.byte "    ",CODE,"for(i=0; i<NUM; ++i)...",MEAN,"ONLY i!",10
.byte "    ",CODE,"L: ... goto L;"
.byte 0

FUNC _extendinfo
.byte 10
.byte "TODO:",10
.byte "^Files to load from tape/disk",10
.byte "^Save current file",10
.byte "^Write as new file",10
.byte "^Crash/exit",10
.byte "^Zleep",10

.byte 0

FUNC _helptextend




;;; Copies memory from AX address (+2) to 
;;; destination address (first two bytes).
;;; String is zero-terminated.
memcpyz:
        sta tos
        stx tos+1

        ldy #0
        lda (tos),y
        sta dos
        iny
        lda (tos),y
        sta dos+1

        iny
;;; if call here set Y=0
;;; TOS= text from (lol)
;;; DOS= destination
copyz:  
        lda (tos),y
        beq @done
        sta (dos),y
        iny
        bne copyz
        ;; y overflow
        inc tos+1
        inc dos+1
        bne copyz
@done:       
        rts

FUNC _savescreen
.ifndef __ATMOS__
        rts
.endif

        ;;; update editing state

        ;; - exit if not buffer
        lda showbuffer
        beq @ret

        ;; - exit if not dirty
        lda dirty
        beq @ret

        lda #0
        sta dirty
        sta showbuffer

        ;; TODO: alt: save as sanitized "string"
        ;;       use this for comilation/saving etc...
        ;;       can have many "buffers" a-z...

        ;; "sneakily" put 10 (newline) at last pos
        ;; of each line (otherwise one long line)
        ;; 
        ;; 10 is DOUBLE NORMAL, on oric screen
        ;; but in last column it's harmless!
        lda #<(SCREEN+40)
        ldx #>(SCREEN+40)
        sta pos
        stx pos+1

        ldx #27
        ldy #39
@nextrow:
        lda #10                 ; \n newline
        sta (pos),y
        ;; move down one line
        clc
        lda pos
        adc #40
        sta pos
        bcc :+
        inc pos+1
:       
        dex
        bne @nextrow

        ;; Now save the damn screen!

;;; 23 B
        ;; from
        lda #<SCREEN
        ldx #>SCREEN
        sta tos
        stx tos+1
        ;; to
        lda #<savedscreen
        ldx #>savedscreen
        sta dos
        stx dos+1
        ;; copy
        lda #<SCREENSIZE
        ldx #>SCREENSIZE
        
        jsr _memcpy
@ret:
        rts



FUNC _loadscreen
.ifndef __ATMOS__
        rts
.endif

        ;; update state
        ldx #0
        stx dirty
        inx
        stx showbuffer


;;; TODO: fixed param calling (copy N bytes to tos++)
;;;   20+3B params+call
        ;; from
;;; TODO: implement blockcalling convention!
        lda #<(savedscreen+40)
        ldx #>(savedscreen+40)
        sta tos
        stx tos+1
        ;; to
        lda #<(SCREEN+40)
        ldx #>(SCREEN+40)
        sta dos
        stx dos+1
        ;; copy
        lda #<(SCREENSIZE-40)
        ldx #>(SCREENSIZE-40)

        jmp memcpy


;;; CHEAT - not counted in parse.bin

;;; (+ 8 21 9) = 38 
;;; now: a generic multiplication is ... 32 .. 38 bytes...

;;; Isn't it just that AX means more code than
;;; separate tos?



.ifdef FASTERMULX
;;; AX => AX

;;; (+ 8 3 21) = 32 B (+2 B on each call MUL10,MUL5)
;;; (+ 17 7 37) = 61c
;;; mul5: +2B 59c  mul10: +2B 52c  mul40: 73c     32 B

;;; tradeoff not clear ... this doesn't have routines...

.macro MUL10
;;; 5 15c (+ 15 44) = 59c
        stx savex
        jsr _xmul10
.endmacro

.macro MULT5
;;; 5 15c (+ 15 37) = 52c
        stx savex
        jsr _xmul5

FUNC MUL40
;;; 8 17c (+ 17 44) = 61c +12= 73c
        stx savex
_xmul40:        
        ;; double
        asl
        rol savex
        ;; double
        asl
        rol savex

FUNC _xmul10
;;; 3 7c (+ 7 37) = 44c (24 B (+ 3 21))
        ;; double
        asl
        rol savex

FUNC _mul5
;;; 21 37c 
        sta tos
        stx tos+1
        ;; double
        asl
        rol savex
        ;; double
        asl
        rol savex
        
        ;; add 1+4
        clc
        adc tos
        tay
        lda savex
        adc tos+1
        tax
        tya

        rts

.else ; !FASTERMULX
;;; TOS => TOS

;;; (+ 8 4 23) = 35 B
;;; (+ 20 10 42) = 72c

;;;(mul5: +2B 59c  mul10: +2B 52c  mul40: 73c     32 B )
;;; mul5:     54c  mul10:     64c  mul40: 84c     35 B

;;; (/ 1000000 100)

FUNC _mul40
;;; 8 20c (+ 20 52) = 72  +12= 84c
        ;; double
        asl tos
        rol tos+1
        ;; double
        asl tos
        rol tos+1

FUNC _mul10                     
;;; 4 10c (+ 42 10) = 52c   +12= 64c   27 B
        ;; double
        asl tos
        rol tos+1

FUNC _mul5
;;; 23 42c   +12= 54c
        lda tos
        ldx tos+1
        ;; double
        asl tos
        rol tos+1
        ;; double
        asl tos
        rol tos+1

        clc
        adc tos
        sta tos
        txa
        adc tos+1
        sta tos+1
        rts

.endif ; !FASTERMULX






.ifdef MEM1
FUNC _memcpy

;;; WORKS!

;;; memcopy smallest?
;;;   tos: FROM
;;;   dos: TO
;;;   AX:  0 <= LENGTH < 32K
;;; 
;;; Copies backwards - fast, but not good for overlap
;;; of FROM TO ranges...
;;; 
;;; - http://6502.org/source/general/memory_move.html
;;;   smallest is 33 B ?
;;; - cc65/libsrc/common/memcpy.s
;;;   ~31 B copies all in forward direction
;;; 
;;; jsk: 27 B
memcpy1: 
;;; 27 B  (+ 10 17)
        ;; copy X full pages first
        pha
        ldy #0
        jsr :+
        ;; copy A remaining bytes
        pla
        beq @done
        tay
;;; 17 B
:       
        dey
        lda (tos),y
        sta (dos),y
        tya
        bne :-
        ;; move to next page
        dex
        bmi @done
        inc tos+1
        inc dos+1
        bne :-
@done:
        rts
.endif ; MEM1
        
.ifdef MEM2
FUNC _memcpy

;;; jsk2: copy forwards
memcpy2: 
;;; 32 (+ 19 13)
;;; 19
        pha
        ;; copy X pages first
        ldy #0
@nextpage:
        dex
        bmi @pagesdone
@copypage:
        lda (tos),y
        sta (dos),y
        iny
        bne @copypage
        ;; move to next page
        inc tos+1
        inc dos+1
        bne @nextpage
@pagesdone:
;;; 13
        ;; assert: Y=0
        ;; copy A remaining bytes
        pla
        beq @done
        tax
@copyrest:
        lda (tos),y
        sta (dos),y
        iny
        dex
        bne @copyrest
@done:
        rts
.endif ; MEM2        

.ifdef MEM3
FUNC _memcpy

;;; jsk3: copies forward
;;; 26
memcpy3: 
        ldy #0
        ldx gos                 ; lo size
        inx ; ugly
@next:
        dex
        bne :+
        ;; more pages?
        dec gos+1
        bmi @done
:
        lda (tos),y
        sta (dos),y
        iny
        ;; page wrap after 256 bytes
        bne @next
        inc tos+1
        inc dos+1
        bne @next

@done:
        rts

.endif ; MEM3

.ifdef MEM4
FUNC _memcpy

;;; jsk4:
memcpy4: 
;;; 21 B - slow
        ldy #0
:       
        jsr _decG
        bmi @done
        lda (tos),y
        sta (dos),y
        jsr _incT
        jsr _incD
        jmp :-

@done:
        rts
.endif ; MEM4


MEM5=1

.ifdef MEM5
FUNC _memcpy

;;; CURRENT choosen one
memcpy: 
        sta gos
        stx gos+1

;;; jsk5: copies forward CLEAN!
;;; assumes all parameters copied to
;;;   tos,dos,gos
memcpy5: 
;;; 26 B
        ldy #0
        ldx gos                 ; lo size
@next:
        bne :+
        ;; more pages?
        dec gos+1
        bmi @done
:
        lda (tos),y
        sta (dos),y
        iny
        ;; page wrap after 256 bytes
        bne :+
        inc tos+1
        inc dos+1
:       
        dex
        jmp @next

@done:
        rts
.endif ; MEM5


.ifdef MEM6
FUNC _memcpy

;;; jsk6: copies forwards
;;;   tos: from
;;;   dos: dest
;;;   gos: size > 0 (otherwise copy at least 1 byte)
;;; 
;;; 23 B
memcpy6:
;;; 23 (26) B
        ldy #0
        ldx gos                 ; lo size
;;; TODO: optional if SIZE > 0
;;;   otherwise copy at least one byte
;        jmp @test
@next:
        lda (tos),y
        sta (dos),y
        iny
        bne :+
        ;; page wrap after 256 bytes
        inc tos+1
        inc dos+1
:       
        dex
@test:
        bne @next
        ;; more pages?
        dec gos+1
        bpl @next

@done:
        rts
.endif ; MEM6

.ifdef MEMMAD
;;; - https://forums.atariage.com/topic/175905-fast-memory-copy/
;;; MADS (pascal?) example from D.W. Howerton?
;;; A= lo length, @length= hi length
;;; 26 B copies forwards
;;; 
;;; jsk BUG? always copies 1 byte at least
FUNC _memcpy
memcpyMAD:
.scope
        tax

.ifdef jsk ; 24 B
        beq nextpage
.else      ; 26 B
        bne start
        dec gos+1               ; it's needed?
.endif

start:
        ldy #0
move:   
        lda (tos),y             
        sta (dos),y
        iny
        bne next
        ;; wrap Y (inc page address)
        inc tos+1
        inc dos+1
next:   
        dex
        bne move
nextpage:       
        dec gos+1
        bpl move

        rts        ; done
.endscope

.endif ; MEMMAD



.zeropage
  lastcs:  .res 2
.code

FUNC timer
.ifdef TIM
        lda READTIMER
        ;; TODO: could just see a flip!
        ldx READTIMER+1
        
        ;; $ffff-AX
        eor #$ff
        tay
        txa
        eor #$ff
        tax
        tya

        ;; print it
        jsr nl
        putc 128+7
        putc '['
;        putc 'T'
        sta tos
        stx tos+1
        jsr putu

        putc 'u'
        putc 's'
;        jsr nl
        
        ;; CLEAR TIMER
        lda #$ff
;        sta READTIMER
        ;; this write triggers reset
;        sta READTIMER+1
.else

        ;; software interrupt ORIC timer
        ;; 100 ticks/s
        lda CSTIMER
        ldx CSTIMER+1
        
        ;; $ffff-AX
CSRESET=1

.ifdef CSRESET
        eor #$ff
        tay
        txa
        eor #$ff
        tax
        tya
.else
.ifnblank
        sec
        eor #$ff
        adc lastcs
        tay
        txa
        eor #$ff
        adc lastcs+1
        tax
        tya
.endif ; BLANK
.endif ; CSRESET

.endif ; TIM

        ;; print it
.ifdef TIM
;        jsr spc
.else
        jsr nl
        sta tos
        stx tos+1

        jsr putu
        putc 'c'
        putc 's'

.endif
        putc ']'
        putc 128+2
        jsr nl

.ifdef CSRESET
        lda #$ff
        sta CSTIMER
        sta CSTIMER+1
.else
        sta lastcs
        stx lastcs+1
.endif

.ifdef TIM
        lda #$ff
        ;; writing hibyte triggers
        sta READTIMER
        sta READTIMER+1
.endif
        rts

FUNC printvar
        sta tos
        stx tos+1
        putc '@'
        jsr puth
        putc '='
        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y
        sta tos
        stx tos+1
        jsr putu
        jsr spc
        rts     

;;; prints readable otherwise deccode
.zeropage
pchar:     .res 1
ptossave:  .res 2
.code
FUNC printchar
        sta pchar
        pha
        tya
        pha
        txa
        pha
        
        lda pchar
        cmp #10
        bne :+
        jsr putchar
        lda #13
        jmp @printplain
:       
        bpl :+
        ;; hi-bit set '
        and #127
        sta pchar
        lda #'_'
        jsr putchar
        lda pchar
:       
        cmp #' '
        bcs @printplain
@printcode:
        cmp #0
        bne :+
        ;; zero
        lda #'$'
        jsr putchar
        jmp @done
:       
        lda tos+1
        pha
        lda tos
        pha

        lda pchar
        sta tos
        lda #0
        sta tos+1
        
        putc '['
        jsr putu
        putc ']'

        pla
        sta tos
        pla
        sta tos+1

        jmp @done
@printplain:
        jsr putchar
@done:

        pla
        tax
        pla
        tay
        pla
        rts

FUNC printaxh
        sta tos
        stx tos+1
        jmp puth

FUNC printstack
        pha
        tya
        pha
        txa
        pha

        tsx
        inx
        inx
        inx                     
        inx                    
        inx

        lda tos+1
        pha
        lda tos
        pha
        ;; we can use the stack for print

        jsr nl
        putc '#'
        lda rulename
        jsr printchar
        jsr spc
        putc 's'

        ;; print s
        stx tos
        lda #0
        sta tos+1
        jsr putu

@loop:
        jsr spc
        ;; print first byte

        lda $101,x

        jsr printchar
        inx
        beq @err

        ;; end marker?
.ifnblank
        lda tos
        cmp #DONE
        beq @done
.endif        

.ifdef DEBUGRULE2ADDR
        putc '-'
        ;; print 1 word
        lda $101,x
        sta tos
        inx
        beq @err

        lda $101,x
        inx
        beq @err
        sta tos+1
        jsr puth
.else
        inx
        beq @err
        inx
        beq @err
.endif ; DEBUGRULE2ADDR

        jmp @loop

@err:
        jsr spc
        jsr spc
        putc 'o'
        putc 'o'
        
@done:
        putc '>'
;;; TODO: 
.ifndef TIM
        jsr getchar
.endif
        sta savea
        jsr nl

        pla
        sta tos
        pla
        sta tos+1

        pla
        tax
        pla
        tay
        pla

        lda savea
        cmp #';'
        bne @ret
        ;; drop one - for debug when messed up
        pla
        sta savex
        pla
        sta savey

        ;; drop one
        pla

        lda savey
        pha
        lda savex
        pha

        jmp printstack
@ret:
        rts
        
FUNC _ideend



BLACK    =128+0
RED      =128+1
GREEN    =128+2
YELLOW   =128+3
BLUE     =128+4
MAGNENTA =128+5
CYAN     =128+6
WHITE    =128+7
BG       =16                    ; BG+WHITE
NORMAL   =128+8
DOUBLE   =128+10



;;; TODO: make it point at screen,
;;;   make a OricAtmosTurboC w fullscreen edit!

;;; Pretend to be prefixed by:
;;; 
;;;   typedef unsigned uint16_t word;
;;; 

;;; TODO: remove "word" and make "int" default.
;;;   all ops except < don't care! (2 complement)


;;; OK, not fully true, but try not put 
;;; any code after here!

FUNC _asmend

;;; TODO: move to beginning of _init/_compiler
;;;   we want to able to NUKE it from memory!

FUNC _inputstart

;;; TODO: remove
;;; This is just to keep input safe, lol
;;; _incIspc may mark prev as read, and or 
;;; it could be used by memcpyz that need prefix?
.byte 0,0

input:


        ;; MINIMAL PROGRAM
        ;; 7B 19c
;        .byte "word main(){}",0


;;; Experiments in estimating and prototyping
;;; function calls, using JSRK_CALLING !

;
PARAM4=1
.ifdef PARAM4

;
CANT=1
.ifndef CANT
        .byte "word F(word a, word b, word c, word d) {",10
        .byte "  if (a) return a+b+c+d;",10
        .byte "  return F(a-1, b+1, d*2, c/2);",10
        .byte "}",10
        .byte "",10
        .byte "word main() {",10
        .byte "}",10
        .byte 0
.else ; CANT
;;; cc02 cannot handle arguments just yet
;        .byte "word F(word a, word b, word c, word d) {",10
;;; TDOO:
.ifdef MINISUB
        .byte "word P(){",10
        .byte "  putchar(' '); puth(a);",10
        .byte "}",10
        .byte "word main() {",10
        .byte "  a=4660; P();",10
        .byte "}",10
        .byte 0
.endif ; MINISUB

        .byte "word P(){",10
        .byte "  putchar(' '); puth(a);",10
        .byte "  putchar(' '); puth(b);",10
        .byte "  putchar(' '); puth(c);",10
        .byte "  putchar(' '); puth(d);",10
        .byte "  putchar(' '); puth(e);",10
        .byte "  putchar(' '); puth(r);",10
        .byte "  putchar('\n');",10
        .byte "}",10
        .byte "WORD F(a,b,c,d) {",10
        .byte "  putchar('>'); P();",10
        .byte "  if (!a) r= a+b+c+d;",10
        .byte "  else r= F(a-1, b+1, d*2, c/2);",10
        .byte "  putchar('<'); P();",10

;;; need to run postlude...
;        .byte "  return r;",10
;;; set AX
        .byte "  r;",10

        .byte "}",10
        .byte "word main() {",10
        .byte "//#x1234  #x5678   #x1122 #x3344",10
        .byte "  a=4660;b=22136;c=4386;d=13124;e=0;",10
        .byte "  putchar('+'); P();",10
;        .byte "  return 4711;",10

        .byte "  r= F(3, 0, 1, 65535);",10
;        .byte "  r= F(0, 9, 1, 65535);",10
        .byte "  putchar('-'); P();",10
        .byte "  return r;",10
        .byte "}",10
        .byte 0
.endif ; CANT

.endif ; PARAM4


;STRBYTES=1
;;; 28 bytes (inline str, jmp over, lda/x)
;;; 21 bytes (inline after jsr inlinePuts)
.ifdef STRBYTES
        .byte "word main(){",1
;        .byte "  fputs(",34,"0123456789",34,",stdout);",10
        .byte " puts(",34,"0123456789",34,");",10
        ;; make sure newline for puts...
;        .byte " putchar('<');",10
        .byte "}",10
        .byte 0
.endif ; STRBYTES

;BIGSCROLL=1
;;; TOOD: not working...
.ifdef BIGSCROLL
        .incbin "Input/bigscroll.c"
        .byte 0
.endif ; BIGSCROLL

;FOR=1
.ifdef FOR
        .byte "word main(){",10
        .byte "  for(n=10;n;--n) {",10
        .byte "    putu(n); putchar(' ');",10
        .byte "  }",10
        .byte "}",10
        .byte 0
.endif ; FOR

;WHILECOUNT=1
.ifdef WHILECOUNT
        .byte "word main(){",10
        .byte "  s= 0; e= 8000;",10
        .byte "  while(s<e) {",10
        .byte "    putu(s); putchar(' ');",10
        .byte "    s+= 40;",10
        .byte "  }",10
        .byte "}",10
        .byte 0
.endif ; WHILECOUNT

;TEMPLATE=1
.ifdef TEMPLATE
        .byte "word main(){",10
        .byte "  putu(6502);",10
        .byte "  return 42;",10
        .res 23,10
        .byte "}"
        .byte 0
.endif ; TEMPLATE

;;; return without argument, lol (AX)
;        .byte "word main(){ 666; return; }",0


;POKEGEN=1
.ifdef POKEGEN
;;; Used to debug codegen for POKE
;;; TODO: add way to do regression testsing on
;;;       code gen sizes etc...
        .byte "word main() {",10
        .byte "  poke(7, 0);",10 ; 4 B
        .byte "  poke(4711, 0);",10 ; 5 B
        .byte "  poke(a, 0);",10 ; 5 B
        .byte "  poke(a, 3);",10 ; 6 B
        .byte "  poke(7, 17+4);",10
        .byte "  poke(a, 17+4);",10
        .byte "  poke(a, b);",10

        .byte "  poke(3+4, 0);",10 ; 9 B
        .byte "  poke(4711+4, 0);",10 ; 9 B
        .byte "  poke(4711+4, 9);",10 ; 10 B
        .byte "  poke(3+4, a);",10 ; 10 B
        .byte "  poke(3+4, 17+4);",10
        .byte "}",10
        .byte 0
.endif ; POKEGEN


;COLORCHART=1
.ifdef COLORCHART
        .incbin "Input/color-chart.c"
        .byte 0
.endif ; COLORCHART


;RAINBOW=1
.ifdef RAINBOW
        .incbin "Input/rainbow-drop.c"
        .byte 0
.endif ; RAINBOW        


;STR=1
.ifdef STR

        .byte "word main(){",10
        .byte "  s= ",34,"foobar        fiefum",34,";",10
        .byte "  puts(s);",10
        .byte "  puts(",34,"gurka",34,");",10
        .byte "  puts(",34,"foobar        fiefum",34,");",10
        .byte "  puts(s+3);",10
        .byte "  x= ",34,"smurk pa burk smakar urk",34,";",10
        .byte "  puts(x);",10

;;; on sim65 somebody is eating up 1234!!!

        .byte "  n= ",34,"1234567890",34,";",10
        .byte "  puts(n);",10
        .byte "  puts(",34,"1234567890",34,");",10
        .byte "}",10
        .byte 0


        .byte "word main(){",10
        .byte "  puth(s);",10
        .byte "  putchar(' ');",10
        ;; TODO: fix this goes wrong
        ;.byte "  puth(&s);",10



;;; space dissapear?
        .byte "  s= ",34,"foobar        fiefum",34,";",10
;;; spaces are retained!
;        .byte "  s= ",34
 ;       .byte "foobar","     ","fiefum"
;        .byte 34,";",10

;        .byte "  s= ",34,"foobar fiefum",34,";",10
;        .byte "  s= ",34,"foobar fish-fiefum",34,";",10


;;; exists according to manual... but gives error ca64
;        .literal "  s= ",34,"foobar           fiefum",34,";",10

;;; ALSO NOT WORKING \n
;        .byte "  s= ",34,"foobar\nfiefum",34,";",10
;        .byte "  s= ",34,"foobar\\nfiefum",34,";",10

;;; foobar works with +3 on oric but this gives nothing!
;;; doesn't work on sim, lol
;;; garbage on oric
;        .byte "  s= ",34,"0123456789",34,";",10
;        .byte "  putz(s+3);",10

       .byte "  putchar('\n');",10
;;; works now, but with extra hibit char first? hmmm
;;; must e some memory corruption...
;        .byte "  putz(s-2);",10
;        .byte "  putchar('\n');",10

;        .byte "  putchar('\n');",10

.ifnblank                       
;;; d=0 doesn't give same result...
        .byte "  d=0;",10
        .byte "  putu(strlen(s-d));",10
        .byte "  putchar('>');",10
        .byte "  putz(strlen(s-d));",10
        .byte "  putchar('<');",10
        .byte "  putchar('\n');",10

        .byte "  putu(strlen(s));",10
        .byte "  putchar('>');",10
        .byte "  putz(s);",10
        .byte "  putchar('<');",10
        .byte "  putchar('\n');",10
.endif
        .byte "  putu(s);",10
        .byte "  putchar(':');",10
        .byte "  putu(strlen(s));",10
        .byte "  putchar('\n');",10
        .byte "  putchar('>');",10

;;; correct on SIM! (sometimes...)
        .byte "  putz(s);",10
        .byte "  putchar('<');",10
        .byte "  putchar('\n');",10

.ifdef __ATMOS__
;        .byte "putz(20278);",10
        .byte "putz(20310);",10
        .byte "putchar('\n');",10
        .byte "putz(20310);",10
;        .byte "putz(20278);",10
.else
;;; 7 chars missing, lol
        .byte "putz(19524);",10
        .byte "putchar('\n');",10
        .byte "putz(19642+3);",10
.endif
;;; Add these two lines and SIM no longer happyy
        .byte "putchar('\n');",10
        .byte "  putu(s);",10   ; should be same?

;        .byte "  puth(s);",10
        .byte "}",10
        .byte 0
.endif ; STR


;ISCHAR=1
.ifdef ISCHAR
        .incbin "Input/test-ctype.c"
        .byte 0
.endif ; ISCHAR

;BUGS=1
.ifdef BUGS
        .byte "word main() {",10

        .byte "  putu(0);",10
;        .byte "  return 1<<10;",10

        .byte "}",10
        .byte 0
.endif


.ifdef PRINTF
        .byte "word main(){printf(",34,"%u",34,",6502);}"
        .byte 0
        .byte 0
.endif ; PRINTF


;WHILEVLTV=1
.ifdef WHILEVLTV

.ifdef OPUTD
        .byte "word main(){",10
        .byte "  x=0; y=300;",10 ; a screenful
        .byte "  while(x<y) {",10

;;; ORIC, totally crap!
;;;   clash of vars?
        .byte "    oputd(x);",10

        .byte "    ++x;",10
        .byte "  }",10
        .byte "}",10
        .byte 0
.endif

        .byte "word main(){",10
;        .byte "  i=0; m=10;",10
        .byte "  i=0; m=300;",10 ; a screenful
        .byte "  while(i<m) {",10
        .byte "    putu(i); putchar(' ');",10
        .byte "    ++i;",10
        .byte "  }",10
        .byte "}",10
        .byte 0
.endif

.ifdef CHARNL
        .byte "word main(){",10
        .byte "putchar('a');",10
        .byte "a=10;",10
        .byte "b='q';",10
        .byte "a='\n';",10
        .byte "putchar(a);putchar(b);putchar('\n');putchar('b');",10
        .byte "}",10
        .byte 0
.endif ; CHARNL

.ifdef FOLDx
        .byte "// Folding constants",10
;;; Parse problem need %b word boundary check!!!
;        .byte |<<1%b"

;        .byte "1<<10;",0

        .byte "const word a=40+2;",10
        .byte "word main(){",10
        .byte "  putu(a);",10
        .byte "}",10
        .byte 0



;;; WOW! (108)
;        .byte "3+4+100+1;",0

;; fail
;        .byte "3+4+100+1<<3>>1>>1>>1;",0
; ok
;        .byte "3+4+100+1<<1>>1;",0;

; 300?
;        .byte "return 3+4+100+1<<2>>1>>1;",0
;;; wrong?
;        .byte "3+4+100+1<<2>>1>>1;",0 
        .byte "putu(3+4+100+1<<1<<1>>1);",0 

        .byte "putu(3+4+100+1<<1<<1);",0 
        .byte "putu(3+4+100+1<<1<<1>>1>>1);",0 

;;; loops forever! lol
        .byte "r=17;"
;        .byte "n=r<<2+r<<3;"
        .byte 0
.endif ;FOLD

        ;; single expression!
;        .byte "4+3;",0
;        .byte "a=4+3;putu(a);putchar('0'+a);",0

;        .byte "word main(){a=r;}",0

;        .byte "word main(){ for(i=0; i<26; ++i) { gotoxy(i/2,i); putchar('A'+i); } }",0
;        .byte "word main(){ putchar('a'); }",0

;        .byte "word main(){ ;;; }",0
;        .byte "word main(){ gotoxy(4711,666); putchar('a'); putchar('b'); }",0
;        .byte "word main(){ gotoxy(10,10); putchar('a'); putchar('b'); }",0

;        .byte "word main(){ gotoxy(10,10); putu(4711); }",0


;;; x3  =  n=r*2+r;
;;; x5  =  n=r<<2+r;
;;; x7  =  n=r<<3-r;
;;; x9  =  n=r*2+r;n=r*2+r;   or n=r<<2+r*2-r;
;;; x10 =  n=r<<2+r*2;     n=((r<<2)+r)*2;


;;; Conclusion 44B 106c to x40
;;; optimal is 33B (grok managed eventually, store tmp in A and Y)
;FOURTY=1
;;; 62B 119c (program 16B overhead)
.ifdef FOURTY
        .byte "// MUL40",10
        .byte "word main(){",10
;        .byte "  r=17;",10
;        .byte "  while(r<28) {",10

;;; 49B => 42 B   84c
;        .byte "    n=r; n<<=2; n+=r; n<<=3;",10

;;; 47B => 40 B   75c
;;;  8B extra for << to store and retrieve x
        .byte "    n=r<<2+r<<3;",10

;;; 
;        .byte "    n= PIPE r<<2+r<<3;",01
;        .byte "    n= WITH r SHL 2 PLUS r SHL 3 END;",01

;        .byte "    putu(n); putchar(' ');",10
;        .byte "    ++r;",10 
;        .byte "  }",10
;        .byte "  return n;",10
        .byte "}",10
        .byte 0
.endif ; FOURTY

;LINEBENCH=1
.ifdef LINEBENCH
        .byte "// LINEBENCH",10
        .byte "word main(){",10
        .byte "  hires();",10
        .byte "  for(i=0; i<239; ++i) {",10
        .byte "    curset(239-i, 199, 3);",10
        .byte "    draw(i*2-239, 0-199, 2);",10
        .byte "  }",10
        .byte "  for(i=0; i<199; ++i) {",10
        .byte "    curset(0, i, 3);",10
        .byte "    draw(239, 199-i-i, 2);",10
        .byte "  }",10
        .byte "  curset(120, 100, 3);",10
        .byte "  for(i=0; i<99; ++i) {",10
        .byte "    circle(i, 0);",10
        .byte "  }",10
        .byte "  getchar();",10
        .byte "  text();",10
        .byte "}",10
        .byte 0
.endif ; LINEBENCH

;CIRCLE=1
.ifdef CIRCLE
        .byte "// CIRCLE",10
        .byte "word main(){",10
        .byte "  hires();",10
        .byte "  curset(120,100,0);",10
        .byte "  circle(75,2);",10
        .byte "  text();",10
        .byte "}",10
        .byte 0
.endif ; CIRCLE

;        .byte "word main(){z=0; ++i; ++i; z=arr[i]; ++j; ++j; }",0
;        .byte "word main(){arr[i]=42; ++i;}",0


;        .byte "word main(){",10
;        .byte "  i=0; while(i<256) { arr[i]=255; ++i; }",10
;        .byte "}",0



;        .byte "word main(){ i=0;while(i<8){putchar(i+65);++i;}}",0
;;; TODO: can optimized more as we know %D != 0 (check)
;        .byte "word main(){ for(i=0; i<8; ++i) putchar(i+65);}",0


;FROGMOVE=1
.ifdef FROGMOVE
        .byte "// frogmove-simple.c",10
        .incbin "Play/frogmove-simple.c"
        .byte 0
.endif

;FUN=1
.ifdef FUN
        .byte "// Functions",10
        .byte "word F() { return 4700; }",10
        .byte "word G() { return F()+11; }",10
        .byte "word main(){ return G(); }",0
.endif



;        .byte "word main(){a=b+c;return a;}",0

;        .byte "word main(){b=1; if (b&1) putchar(65); }",0

;;; 101B      80B: cc65 -Oirs
;;;           83B: oscar64 no opt
;;;           64B: oscal64 -Oz -Os main+M in one! (62?)
;;;          118B: oscar64 -O3 haha or -Os
;;;        
;;;  63B         : asm simple expected
;;;  47B         : asm optimal zp

;;;           33B: 16x16->16 MUL (plain algo)

;;;           57B: cc65 Mul(a,b) recursive 11 calls
;;;          126B: oscar64 Mul(a,b)  no opt

;;; .tap M()  M.size
;;; 133B 849c 99B: naive, c=0+a+c;
;;; 131B 849c 86B: opt: 0 -1B
;;; 120B 603c 85B: c+= a; works (+ etc) again
;;; 119B         : c=0; // optimized (-1B)
;;; 118B         : return M(); // tail calls -1B
;;; 117B         : removed extra rts after main -1B
;;; 113B         : 111=>a=>b; // lol, -5B
;;; 109B 603c 82B: &byte; // %{ made it possible! -5B!
;;; 101B 603c 74B: if(%A & byte) - 8B!
;;;  80B 603c 58B: ZPVARS=1 -16B!

;;; TODO: ZPVARS saves bytes but no CYCLES ??? WTF?


;;;    TODO:   b&1 oscar64: lsr+bcc cheaper! (-1B)

;;; 80B

;MUL=1
.ifdef MUL
        .byte "// MJL",10
        .byte "word M() {",10
        .byte "  c= 0;",10
        .byte "  while(b) {",10
        .byte "    if (b&1) c+= a;",10
;        .byte "    putu(a); putchar(32) ; putu(b); putchar(32); putu(c); putchar(10);",10
        .byte "    a<<= 1;",10
        .byte "    b>>= 1;",10
        .byte "  }",10
        .byte "  return c;",10
        .byte "}",10
        .byte "",10
        .byte "word main(){",10
.ifdef FFFF
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
.endif
;;; TODO: somehow this here crashes? LOL
;        .byte "  a= 111; b= 111; M();",10
;        .byte "  a= 111; b= 111;",10

;        .byte "  a= 111; b= 111;",10
;;; TODO:
;       .byte "  a=b=111;",10 ;; save 4 bytes
        .byte "  111=>a=>b;",10 ; 603us
;        .byte "  1=>a=>b;",10   ;  91us
;        .byte "  200=>a=>b;",10   ; 347us (603us !zp)

        .byte "  return M();",10
        .byte "}",10
        .byte 0
.endif ; MUL





;        .byte "word main(){ }",0

;;; TAILREC
;        .byte "word main(){ return 4700+11; }",0


;;; TODO: not working because TAILREC ruleD?
;        .byte "word main(){a=1;return a<<1;}",0
;        .byte "word main(){a=65535;a>>=8;return a;}",0

;;; MINIMAL
;        .byte "word main(){}",0

        ;; cc65:  36B !
        ;; parse: 40B 33108c          30x faster than basic
        ;; OPT:   36B 26964c 27c loop 37x faster ...
;;; OPTRULES works, --a not in other and TAILREC bug
;        .byte "word main() { a=1000; while(a) { --a; } }",0

        ;; cc65:  a=100; => 23B !!!
        ;; cc65 : 33B        25c loop
        ;; parse: 37B 32804c 30c loop (while end 15B)
        ;; OPT:   33B 15956  26c 
;;; OPTRULES works
;        .byte "word main() { a=1000; do { --a; } while(a); }",0

;        .byte "word main() { }",0

;;; TAILREC broken for ruleD ????? (loops forever)
;        .byte "word main() { a= 4700; a= a+11; return a; }",0
;;; WORKS
;        .byte "word main() { a= 4700; a+= 11; return a; }",0


;        .byte "word main() { if (a&1) ++b; }",0

;;; WORKS (w inline _B)
;        .byte "word main() { if(a&1) {--a;;--a;--a;} else {++a;++a;++a;++a;++a;} return a;}",0

;;; TODO: can't handle TAILREC, parser goes there but loops forefer!
;        .byte "word main() { if (a&1&2) ; }",0
;        .byte "word main() { if (a&1) ; }",0

; fails with TAILREC
;        .byte "word main(){ return b+1+2+3+4+5+6; }",0

;        .byte "word main() { if (a&1&2) putchar(65); else putchar(66); }",0

;        .byte "word main() { if (a&1) putchar(65); else putchar(66); }",0


;;; Fine, loops
;FOUR=1

.ifdef FOUR
        .byte "// FOUR",10
        .byte "word main() {",10
        .byte "  a= 470; b= 11;",10
        .byte "A:",10
        .byte "  if (a&1) { ++b;++b;++b;++b;b+=6; }",10
        .byte "  else { b+=8; ++b; ++b; }",10
        .byte "  --a;",10
        .byte "  if (a) goto A;",10
        .byte "  putu(b);",10
        .byte "}",10
        .byte 0
.endif ; FOUR

;;; prints A-Z.
;;; 
;ATOZ=1

.ifdef ATOZ
        .byte "// A-Z.",10
        .byte "word main() {",10
        .byte "  a='A';",10
        .byte "A:",10
        .byte "  putchar(a);",10
.ifdef OPTRULES
        .byte "  ++a;",10
.else
;;; TODO: 
        .byte "  a=a+1;",10
.endif
        .byte "  if (a<'[') goto A;",10
        .byte "  putchar('.');",10
;    .byte "  ++a;",10
        .byte "  return 42;",10
        .byte "}",10
        .byte 0
.endif ; ATOZ

;        .byte "word main(){++a;++a;return a;}",0
;        .byte "word main(){return 4711;}",0

;;; IF sanity
;        .byte "word main(){a=42;if(a==3)a+=4;putu(a);}",0

.ifdef BB
;;; ???
;;; TODO: it would seem that inp points wrong here!
;;;   then that causes error
        .byte "{}{}{}",0
        .byte "{}{b=7;}",0


;;; error from (7;)}{}
        .byte "{}{b=7;}{}",0
;;; crash (not gen end rule)
        .byte "{}{b=7;}",0
;;; ok

        .byte "{}{}{}",0
        .byte "{}{}",0
        .byte "{}",0
;;; error
        .byte "{a=3;}{b=7;}",0
        .byte "{a=3;}{}",0

;;; ok need space before putu? lol
;        .byte "{a=4;a+=3; putu(a);}",0

;;; FAIL - no space?   "putu" fails if first rule!
;;; ... and now it works....?
        .byte "{a=4;a+=3;putu(a);}{b=7;}",0
        .byte "{a=4;a+=3;putu(a);}",0
.endif ; BB

.ifdef ALTTEST
        .byte "bbb"
        .byte "aaa"
        .byte "aaa"
        .byte "aaa"
        .byte "bbb"
        .byte "aaa"
;;; ok, gives error %E - end of input...
;        .byte "b"
;        .byte "bb"
;;; ok, stop compile
;        .byte "bbx"
;;; stop compile and detect as error
;        .byte "xlxkjflksjdflkasdjf"
        .byte 0
        .byte 0
        ;; TODO: BUG: if not here get's corruption1
        ;; and getting next bytes and "word main"!
;        .byte 0

        .byte "ccc"
        .byte "ccc"
.endif ; ALTTEST


.ifdef FFF
        .byte "word main(){return 4711;}",0

;;; FAIL - both as input, in any order...
        .byte "word F(){return 4711;}"
        .byte "word main(){return 4711;}"
        .byte 0

;;; ok - either as input, but not both
        .byte "word main(){return 4711;}",0
        .byte "word F(){return 4711;}",0



;;; WTF, a space after '}' makes stack explode?
;;; TODO: could it be that empty match "...|" gives
;;;    too much recursion?
        .byte "word main(){return 4711     ;        } "
        .byte 0
.endif ; FFF

;FUNTEST=1
.ifdef FUNTEST

;;; TODO:  doesn't like 10 newline!!! lol (or space...)
        .byte "word F(){ putchar(65); return 4711; }",32
;        .byte "word F(){ putchar(65); return 4711; }"
;        .byte "word main(){ putchar(65); return 4711; }"

        .byte 0
.endif


.ifdef GOTOtest
;;; MINIMAL SANITY CHECK
;;        .byte "word main(){return 4711;}",0
;;; minimal error
;        .byte "word main(){return 47x11;}",0

;;; TODO: not found name need better error...
;;;      .byte "void main(){xyz(65);}",0

        ;; Speed of Turbo Pascal on z80 (4 MHz)
        ;; 2000 lines/less than 60s
        ;; (/ 2000 55) = 36 lines/s

        ;; GOTO !
        ;; 
        ;;      (/ 7 0.052) = 134 op compiles/s
        ;; 
        ;;                             7 "ops"/gen
        ;;                        no PRINTREAD vvv
        ;; = CC02: 57 bytes 10580c compile: 51796c=0.052s
        ;; = CC02: 57 bytes 10580c compile:  9044c
        ;; = CC02: 57 bytes 2.79cs compile:   24cs
        ;;            100x / 100
        ;; 
        ;;     putchar(%D|%V) => 63 (- 5 B)
        ;;     if(%V<%D)      => 57 (- 6 B)
        ;; 
        ;;     TODO: byte            -17 B
        ;;     TODO: zp vars          -7 B
        ;;     jsr .. ; rts           -1 B
        ;;     if no ELSE support     -5 B
        ;; 
        ;; = cc65: 50 bytes 12613c compile: 112ms
        ;;          (-20 using byte) = 30 B
        ;;        
        ;; = asm:  15 bytes! (using register only)

;;; ok - AAAAAA
;        .byte "void main(){A:putchar(65);goto A;}",0
;;;; ok
;        .byte "void main(){A:putchar(65);goto A;putchar(66);}",0
;        .byte "void main(){putchar(64);A:putchar(65);goto A;putchar(66);}",0

;        .byte "void main(){ putchar(65); putchar(66); putchar(67); }",0

;;; ok
        .byte "// GOTO test A-Z.",10
        .byte "void main()",10
        .byte "  a=65;",10
        .byte "A:putchar(a);",10
        .byte "  ++a;",10
        .byte "  if (a<91) goto A;",10
        .byte "  putchar(46);",10
        .byte "}",10
        .byte 0
;;; TODO: remove spaces crash in parse!!!!
;        .byte "void main(){ a=65; A: putchar(a); ++a; if (a<91) goto A; putchar(46); }",0
.endif ; GOOTTEST


;;; Byte Sieve Benchmark! (OLD)
;;; ===========================
;;; Normalized: 1MHz onthe6502.pdf (1M cycles/s)
;;; 
;;;   202 B     1.16s asm  onthe6502.pdf
;;;   819 B     5.82s CC65 onthe6502.pdf
;;; 
;;;   326 B     4.17s CC65 -O Play/byte-sieve-prime.c
;;;                   (-Cl static locaL) (-Or 5.37s)
;;; (1045 B     -"- in the byte-sieve-prime.out sim65)

;;;      (normalixed)
;;;             1.8s  action (see below)
;;;           228s    BASIC (according to action)
;;;             3.6s  Tigger C
;;;            16.s   "BASIC" says Tigger C video
;;; 
;;;      10 X
;;;             
;;;            10s asm (according to Action! doing 10x!)
;;;            18s Action! (algo/src from there)
;;;            38m BASIC - 126 times slower
;;; 
;;;   ????      36s   Tigger C, 4.5s 8 MHz (* 4.5 8)
;;;           "160s"  "BASIC" according to Tigger C
;;; 
;;; BN16 (use dec mode, no print? store only odd)
;;;   150ms asm (2023: super opt years later) - 1K ram

;;; Byte sieve from Byte magaxine:
;;; ==============================
;;; char prime[8192]={0}; // simplier code: no bitshift


;;;    bytes
;;; FILE   MAIN seconds  WHAT
;;; ----   ---- ----.--  ------------------------

;;; === Byte magazine ===
;;;   287                UCSD PASCAL, APPLE II, 6502

;;; === BCPL (bytecode) === ( https:projects.drogon.net/retro-basic-and-bcpl-benchmarks/ )
;;; 
;;;     NOTE: this is size=4095 (half of BYTE BENCHMARK!)
;;;     NOTE: this is 1x run!!
;;; 
;;;               96.96  BBC BASIC 1-3 (6.06s on 16Mhz)
;;;               81.12  BBC BASIC 4   (5.07s)
;;;              134.4   CBM2 (* 8.40 16)
;;;              135.86  EhBASIC (* 8.48 16)
;;;               10.352 BCPL (INT) (* 0.647 16)
;;; 
;;; === jsk: 1x = 4096 = (don't compare with 8192...) BYTESIEVE
;;;         363    2.104s CC02    my compiler
;;;         336    1.630s CC02    my compiler better WHILE
;;;         336    1.551s CC02    1000x loop
;;;            (/ 10.352 1.551) = 6.67
;;;         319    1.327s CC02    poke optimized
;;;            (/ 10.352 1.327) = 7.80

;;; === jsk tests === (1x run, 8192)
;;; FILE,  MAIN bytes 
;;;   2627  322    5.196  CC65   ./r Play/byte-sieve-prime
;;;         287    9.510  CC65   -DPROGSIZE
;;;         322    2.8323 CC65   -Cl
;;; === my compiler === ("no library!")
;;;         363    3.63   sim65  ./rrasm parse BYTESIEVE
;;;         363    4.8s   CC02   ./rasm parse  BYTESIEVE
;;;         336    3.185s CC02   ./rrams WHILE(a<_E)
;;;             12% faster than before
;;;             12% slower than cc65 -Cl
;;;         319    2.665s CC02   ./rrasm 100x (- 17B!)
;;;              6% FASTER than cc65 -Cl
;;;              1% BEAT cc65 default! SMALLER! (- 3 bytes!)
;;;             11% bigger than smallest (slowest) cc65 (287)
;;;         315    2.665s  CC02   axputu

;;; https://thred.github.io/c-bench-64/
;;;         240j means jsk extracted main from .asm
;;; 
;;;  4.3K          2.12s  Calpyso (21.4s size opt, 4.3K)
;;;  3.2K          2.05s  cc65 (2.10s, 3.2K))
;;;  7.1K          1.90s  LLVM-mos (21.8s, 6.4K))
;;;  2.5K   240j   0.94s  Oscar64 (10.3s, 1.6K)
;;;  2.4K          2.13s  SDCC (21.3s, 2.4K)
;;;  5.8K          1.33s  VBCC (15.9s, 3.4K)
;;; 
;;;         315    2.60s  CC02 10K runs ^X * 100
;;;         307    2.53s  CC02 while-speed,++i(;),+BYTE
;;;         302    2.43s  CC02 rule _F byte rule for poke!
;;;         304    +2 B ??? investigate, poke changed, wrong?
;;;                - 1a45336b30cc787f668c83dd4e4c7dff4baa7a99
;;;         303    -1 B !!! better poke


;;; TODO: at some point it got to 361 bytes
;;;    now increased to 365... INVESTIGATE
;;;    
;;; From https://github.com/yesco/simple6502js
;;;    4b6bac9..4e41cbd  main       -> origin/main
;;;; Updating 4b6bac9..4e41cbd
;;; Fast-forward

;
BYTESIEVE=1
;
NOPRINT=1

; https://thechipletter.substack.com/p/once-again-through-eratosthenes-sieve
;;; = 10x == 10x == 10x == 10x == 10x == 10x == 10x =
;;; 1899 primes:
;;;   cy,cles      bytes
;;;  -----------   -----
;;;   51,962,632    2627    - cc65    ./r Play/byte-sieve-prime
;;;   95,097,713     287           -DPROGSIZE
;;;   28,322,714     322           -Cl

;;; === my compiler ===
;;;   36.3           363    - sim65   ./rrasm parse  
;;;   43s            363    - ORIC    ./rasm parse   

;;;  #x142 322 
;;;  #x11f 287

.ifdef BYTESIEVE
;;; BC: (+ 11 9 3 16 9 6 7 3 14 5 5 1 2 1 2 1 2 2 1 2 2) = 104
;;; so 104 bytecodes is substantially lower than MC: 365...
;;; TODO: error is on "word main", lol
;.byte "x"
        .byte "// BYTE SIEVE PRIME benchmark",10
        .byte "#include <stdio.h>",10
        .byte "word main(){",10
       ;; BYTE MAGAZINE 8192 => 1899
        .byte "  m=8192;",10
        ;; used by Bench/Byte Sieve - BCPL/BBC
;        .byte "  m=4096;",10
        .byte "  a=malloc(m);",10
;.byte "x"
        .byte "  n=0; while(n<10) {",10
;        .byte "  n=0; while(47n<10) {",10

;        .byte " xwhile(47n<10) {",10

        .byte "    c=0;",10
        .byte "    i=0; while(i<m) {",10
        .byte "      poke(a+i, 1); ++i;",10
        .byte "    }",10
;;; NOPE
;        .byte "    i=0; do { poke(a+i, 1); ++i; } while(i<m);",10
        .byte "    i=0; while(i<m) {",10
        .byte "      if (peek(a+i)) {",10
        .byte "        p= i*2+3;",10
.ifndef NOPRINT
        .byte "        putu(p);",10
        .byte "        putchar(32);",10
.endif
        .byte "        k=i+p; while(k<m) {",10
        .byte "          poke(a+k, 0);",10
        .byte "          k+=p;",10
        .byte "        }",10
        .byte "        ++c;",10
        .byte "      }",10
        .byte "      ++i;",10
        .byte "    }",10
        .byte "    printf(",34,"%u",34,", c);",10
        .byte "    ++n;",10
        .byte "  }",10
        .byte "  free(a);",10
        .byte "  return c;",10
        .byte "}"
        .byte 0
.endif ; BYTESIEVE
;


;;; sim65: 40020 bytes allocatable
;;;  oric: 12704 bytes allocatable

;;; SIM65: (- 65536 (* 2 256) 17348 4096)
;;;           64K   0-1 pages .sim  output
;;;        (- 43580 40020) = 3560 bytes "cc65 stack"?

;;; ORIC:
;;; (- 65536 (* 5 256) 16384 17421 4096   8000  2000)
;;;    64KB  0-4 page  ROM   .tap  output hires charset
;;; (- 16355 12704) = 3651 bytes "cc65 stack"?
;;; 
;;; TEXT:  (- 37631 (* 5 256) 17421 2000 1000) = 15930
;;; HIRES: (- 37631 (* 5 256) 17421 8000 2000) =  8930
;;; -- cc65 

MALLOC=1
.ifdef MALLOC
        .byte "// malloc() test",10
        .byte "word main() {",10
;        .byte "  putu(heapmemavail()); putchar(10);",10
;       .byte "  putu(heapmaxavail()); putchar(10);",10
        .byte "  z= 32768;",10
        .byte "  a= 0;",10

;;        .byte "  do {",10
        .byte "X:",10

        .byte "    p= malloc(z);",10
        .byte "    if (p) {",10
        .byte "      a+= z;",10
        .byte "      putu(a); putchar(' '); puth(p); putchar(' '); putu(z); putchar(10);",10
        .byte "      // try same size again till fail!",10
        .byte "    } else {",10
        .byte "      z>>=1;",10
        .byte "    }",10
;        .byte "    if (z==0) return a;",10
        .byte "    if (!z) return a;",10

;;; crash! errror "1" lol
;        .byte "  } while(1);",10
;;; NOT TRUE????
        .byte "  goto X;",10
;        .byte "  } while(z);",10

        .byte "}",10
        .byte 0
.endif

;
PRIME=1
;;; TODO: this crashes in ORIC ????
;PRIMBYTE=1

;NOPRINT=1

;;; From: onthe6502.pdf - by 
;;;  jsk: modified for single letter var, putchar

;;; also in Play/prime.c

.ifdef PRIME
;;;   313B      3.337s BYTERULES PRIMBYTE
;;;               2.5% smaller
;;;              20% faster than cc65 
;;;  (305B)     1.9s NOPRINT! (putu(),putchar())
;;;   321B      3.426 moved i=n;
;;;               SMALLER! than cc65!!!
;;;   329B            while not long-for (256) init arr
;;;               close to 326B cc65
;;;   335B      3.432 ^65535 (-5B)
;;;   340B      3.461 j=i>>3; (-10B)
;;;               17% faster than cc65
;;;                4% faster than Tigger C
;;;   350B      3.543 while(%A<%D) (- 14B)
;;;               15% FASTER than cc65!
;;;                1.6% faster than Tigger C
;;;   364B      4.445 measure wrong? ( arr[i]=const; )
;;;   377B      4.414s PRIME (for, init, save bytes)
;;;                5.9% slower than cc65
;;;   397B      4.477s PRIME (correct result)
;;;                7% slower than cc65

;;; (+ 397 33 10)=440 B ; estimate: main + putu + putchar
;;;  (/ 4.477 4.17) 7%

;;; TODO: need more features:
;;;   x label A:
;;;   x goto A;
;;;   x do while
;;;   - array declaration
;;;   - array access/set
;;;   - parenthesis
;;; 
;;;  (- hex numbers)
;;;  (- char constants 'c')
;;;  (- t++)
;;;  (- --t)
;;;  (- // comments)
;;;  (- variable declaration)
;;;  (- %10 hmmm???)
;;;  (- for)
;;;  (- to ~ reverse bits)

;;; TODO: there might be hi-bit chars here???
        .byte "// PRIME test; char arr+bitshift",10
        .byte "char arr[256];",10
;        .byte "char b[4];",10
;        .byte 10
        .byte "word main(){",10
;       .byte "  word n,i;",10
;       .byte "  char t;",10
;       .byte "  arr[0]=0xff;",10
;;; TODO: for!
;        .byte "  arr[0]=255;",10
;       .byte "  for(t=1; t; ++t) arr[t]=0xff;",10

;
;;; 335B for loop has overhead >255
;        .byte "  for(i=0; i<256; ++i) arr[i]=255;",10
;;; 329B !!! closer to cc65... (326B)

;.ifndef PRIMEBYTE
        .byte "  i=0; while(i<256) { arr[i]=255; ++i; }",10
;.else
;        .byte "  i=0; while(i<256) { $ arr[i]=255; ++i; }",10
;.endif

;;; 338B ???
;        .byte "  i=0; while(i<256) { arr[i++]=255; }",10

;        .byte "  for(n=2; n<2048; ++n) {",10
        .byte "  n=2; while(n<2048) {",10
;        .byte "  n=1; while(++n<2048) {",10 ; worse!

;;; TODO: no paren
;        .byte "    if (arr[n>>3] & (1<<(n&7))) {",10
.ifndef PRIMBYTE
        .byte "    z=n&7; z=1<<z;",10
        .byte "    if (arr[n>>3] & z) {",10
.else
        .byte "    $ z= n&7; $ z=1<<z;",10 ;
        .byte "    if (arr[n>>3] & z) {",10
;        .byte "    if ($ arr[n>>3] & $ z) {",10
.endif

        ;;           // simulates putu?
.ifndef NOPRINT
.ifblank
        .byte "      putu(n);",10
.else
        .byte "      i=n;",10
        .byte "      t=0;",10
        .byte "      do {",10
        .byte "        b[t++]= (i%10)+'0';",10
        .byte "        i/=10;",10
        .byte "      } while(i);",10
        .byte "      do {",10
        .byte "        putchar(b[--t]);",10
        .byte "      } while(t);",10
.endif
;; TODO: LOL loops forever, WTF!
;        .byte "      putchar(' ');",10
        .byte "      putchar(32);",10
.endif
;        .byte "      for(i=n+n; i<2048; i+= n) {",10
        .byte "      i=n*2; while(i<2048) {",10

;       .byte "        a[i>>3]&= ~(1<<(i&7));",10

.ifndef PRIMBYTE
        .byte "        z=i&7; z=1<<z ^65535;",10
        .byte "        j=i>>3;",10
        .byte "        arr[j]= arr[j] & z;",10
.else
        .byte "        $ z= i&7; $ z=1<<z ^255;",10
        .byte "        j=i>>3;",10
;        .byte "        $ arr[j]= $ arr[j] & $ z;",10
        .byte "        arr[j]= arr[j] & z;",10
.endif
        ;; for the while
        .byte "        i+=n;",10

        .byte "      }",10
        .byte "    }",10
        ;; for the while
        .byte "    ++n;",10
        .byte "  }",10
        .byte "}"
        .byte 0

.endif ; PRIME


.ifdef TESTARRAY
        ;; char arrays
        .byte "// char array",10
        .byte "char a[42];",10
        .byte "word main(){ a@[3]=20; a@[7]=22;",10
        .byte "  return a@[3]+a@[3];",10
        .byte "}",0
.endif

.ifdef TWEN
        .byte "// many ++a;",10
        .byte "word main(){"
        .byte "++a;++a;++a;++a;++a;"
        .byte "++a;++a;++a;++a;++a;"
        .byte "++a;++a;++a;++a;++a;"
        .byte "++a;++a;++a;++a;++a;"
        .byte "return a;}",0
.byte "word main(){a=4700;return a+11;}",0
.byte "word main(){return 4711;}",0
.endif ; TWEN

;;; HOW is this NOT the SAME?
;        .byte "word main(){++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;return a;}",0

.ifdef REP
        .byte "// MANY statements test: repeat ++a",10
        .byte "word main(){"
        ;; 48 => 15s lol - error
        ;; 40 =>  8s LOL
;        .repeat 32+8

        ;; 25 statements takes ~2.5s to compile
        ;; 526 bytes!
        ;; 
        ;; 25 is ok: (* 25 6) = 150 recursions (inp,rule)
        ;; I think two rules deep... not helping...
        ;; (/ 256 6 2) = 21 ...
;;; TODO: need *S clenex operator for repeats!
;        .repeat 16+8+1

        ;; OPTRULES:
        ;;   a=a+1; // 16 => 3s  337 bytes (/ 337 16) = 21
        ;;   ++a;   // 16 => 1s  136 bytes 
        ;;   ++a;   // 32 => 1s  264 bytes (/ 264 32) =  8
;        .byte "a=0;"

;;; TOO high value triggers CHECKSTACK error!
        ;; run: T340 compile: T6484
;        .repeat 25           
        ;; run: T 84          T26964
        ;.repeat 12

        ;; run: T 84          T55892
        ;.repeat 0               ;  6cs
        ;.repeat 10              ; 15cs
;        .repeat 20              ; 27cs
;.byte "++a;return a;}",0

;        .repeat 20              ; 27cs
;        .repeat 2000 ; MAX!

        .repeat 20
        ;; ~~~~~~~~~~~~~~~~~~~~ 1cs/op == 100ops/s
        ;; (* 60 100)= 6000 ops ~ 2000 lines? lol?
        ;; w print  24s (/ 2000 24) =  83 ops/s
        ;; NO print 15s (/ 2000 15) = 133 ops/s
        ;; "an if is maybe 7 ops => (/ 133 7) = 19l/s
        ;; (* 60 19) = 1140 lines/60s nonoptimized!

;          .byte "a=a+1;"
;          .byte "++a;"
           .byte "++a;"
        .endrep
        .byte "return a;}",0
.endif ; REP

.ifdef FOO
;;; OOO, what comes after here matter???? LOL

;        .byte 0,0,0,0
        .byte "return a;"
        .byte "}",0


        ;; quoted test
        .byte "[]",0

        .byte "word main(){ return 3<3; }",0
        .byte "word main(){ if(1) a=42; return a;}",0

        .byte "word main(){ if(1) a=42; else a=4711; return a;}",0

        ;; tests for self-modifying v op= const;
        .byte "word main(){ a=4141; ++a; return a; }",0
        .byte "word main(){ a=4343; --a; return a; }",0
        .byte "word main(){ a=512+42+1; a&=42; return a; }",0
        .byte "word main(){ a=84; a>>=1; return a; }",0
        .byte "word main(){ a=21; a<<=1; return a; }",0
        .byte "word main(){ e-=10*2+6; return e; }",0
        .byte "word main(){ e+=2; return e; }",0

        ;; ELSE 101 or 11
        ;; BUG: TODO: if else because MINIMAL and have LONGNAME
        ;; elsea=10; might be assigned, lol
        .byte "word main(){ if(0) a=100; else a=10; return a+1; }",0


;;; 101/1
        .byte "word main(){if(1)a=100;return a+1;}",0
;;; 40
        .byte "word main(){return e;}",0


        .byte "void A(){putchar(102);}",0

        .byte "word main(){putchar(102);}",0

        .byte "word main(){putu(4711);return getchar();}",0

        .byte "word main(){return 65535>>3;}",0
;;; => 2???
        .byte "word main(){return 1<<2;}",0

        .byte "word main(){return 517&0xff+42;}",0

        .byte "word main(){3+4=>a+3=>b;return a+b;}",0


;;; TODO: LOOP shit - same issue on "MINIMAL - lol"
        .byte "word main(){return a;}",0

;;; works 1477
        .byte "word main(){if(1){a=77;a=1400+a;}return a;}",0
;;; works 0 or "magix"
        .byte "word main(){if(0){a=77;a=1400+a;}return a;}",0

;;; WORKS (but can't do three as limited {SS} ...
        .byte "word main(){a=10;if(1){a=a*2;a=a*2;} a=a+1; return a;}",0

;;; FAIL
;        .byte "word main(){ if(1) { a=e+50; return a; } a=a+1; return a;}",0

;        .byte "word main(){a=10; if(1){a=a*2;} a=a+1; return a;}",0
;;; WRONG
        .byte "word main(){ return a; if(0){a=10;} a=a+1; return a;}",0

;;; OK, fixed var.... lol
        .byte "word main(){ if(1) a=10; a=a+1; return a;}",0

.ifdef INCTESTS
        .byte "word main(){ return 4711 ; }",0
        .byte "word main(){ return e ; }",0
        .byte "word main(){ return &e ; }",0
        .byte "word main(){ return a ; }",0
        .byte "word main(){ return e; }",0
        .byte "word main(){ if(0) a=10; a=a+1; return a;}",0
;;; OK 11
        .byte "word main(){ return 4710+1; }",0
        .byte "word main(){ if(1) a=10; a=a+1; return a;}",0

;;; OK 
        .byte "word main(){return 4711;}",0

;;; ERROR
        .byte "word main(){ if(1) { return 33; } a=a+1; return a;}",0

;;; syntax error highlight!
;        .byte "word main(){ if(1) a=10x; a=a+1; return a;}",0


;;; OK (w S not = B | )
        .byte "word main(){ if(0) return 33; return 22; }",0
        .byte "word main(){ if(1) return 33; return 22; }",0



;;; FAIL
        .byte "word main(){ if(0) { a=e+50; return a; } a=a+1; return a;}",0
;;; FAIL
        .byte "word main(){ if(1) { a=89; return a; } a=a+1; return a;}",0


        .byte "word main(){ if(1) return 99; a=a+1; return a;}",0
        .byte "word main(){ if(1) a=10; a=a+1; return a;}",0
        .byte "word main(){ if(0) a=10; a=a+1; return a;}",0



        .byte "word main(){ a=2005*2; a=a+700; return a+1; }",0

;;; WRONG
        .byte "word main(){ a=2005*2; b=84; a=a+700; a=b/2+a; return a+1; }",0

;;; OK
        .byte "word main(){ a=99; a=a+1; a=a+100; return a+1; }",0

;;; TODO: somehow this gives garbage and jumps wrong!
;;;  (stack messed up?)

;;; FAILS
        .byte "wordmain(){return e==40;}",0
;;; FAILS
        .byte "wordmain(){return 42==42;}",0


;;; OKAY:
        .byte "wordmain(){a=42;return a+a;}",0
        .byte "wordmain(){42=>a;return a+a;}",0
        .byte "wordmain(){return 40==e;}",0
        .byte "wordmain(){return e==e;}",0
        .byte "wordmain(){return e+e;}",0
        .byte "wordmain(){a=99;a=a+1;return a+1;}",0
        .byte "wordmain(){a=99;return 77;}",0
        .byte "wordmain(){return 4711;}",0
        .byte "wordmain(){a=99;return a+1;}",0
        .byte "voidmain(){a=99;}",0
        .byte "wordmain(){return 1+2+3+4+5;}",0
;        .byte "wordmain(){return 42==e;}",0
        .byte "wordmain(){return e+12305;}",0
        .byte "wordmain(){return e;}",0
        .byte "wordmain(){return 4010+701;}",0
        .byte "wordmain(){return 8421*2;}",0
        .byte "wordmain(){return 8421/2;}",0
        .byte "wordmain(){return 4711;}",0
;;; garbage (OK)
        .byte "voidmain(){}",0
        .byte 0
.endif ; FOO

.endif ; INCTESTS

endinput:       

FUNC _inputend

        ;; two zeroes ends input sequence of files
        .byte 0,0


FUNC _savedscreen

savedscreen:
.ifdef JUNK
  .code
        .byte "0123456789012345678901234567890123456789"
        .byte "1111111111222222222233333333334444444444"
;        .byte "2                                       "
        .byte "2 --------------------------------------"
        .byte "3 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        .byte "4 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        .byte "5 cccccccccccccccccccccccccccccccccccccc"
        .byte "6 dddddddddddddddddddddddddddddddddddddd"
        .byte "7 eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        .byte "8 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        .byte "9 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        .byte "10 ccccccccccccccccccccccccccccccccccccc"
        .byte "11 ddddddddddddddddddddddddddddddddddddd"
        .byte "12 eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        .byte "13 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        .byte "14 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        .byte "15 ccccccccccccccccccccccccccccccccccccc"
        .byte "16 ddddddddddddddddddddddddddddddddddddd"
        .byte "17 eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        .byte "18 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        .byte "19 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        .byte "20 ccccccccccccccccccccccccccccccccccccc"
        .byte "21 ddddddddddddddddddddddddddddddddddddd"
        .byte "22 eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        .byte "23 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        .byte "24 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        .byte "25 ccccccccccccccccccccccccccccccccccccc"
        .byte "26 ddddddddddddddddddddddddddddddddddddd"
        .byte "27 eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",0
        ;; not on sceen!
        .byte "28 ####################################"

.else
.bss
        ;; ORIC SCREEN SIZE
        ;; (save program/screen before compile to "input")
        .res SCREENSIZE+1       ; +1 for \0

.endif ; JUNK

;;; END INPUT
;;; ----------------------------------------
;;; GLOBAL DATA


;;; TODO: move to earlier, or beginning of compiler?

;;; TODO: simulated arr, only one! lol
.ifdef FROGMOVE
arr:    .res 1200
.else
;PRIME
arr:    .res 256
.endif

.ifdef ZPVARS
;;; TODO: don't initialize zp variables...
  .zeropage
.endif

.export _vars
_vars:
vars:
;        .res 2*('z'-'a'+2)
;;; TODO: remove (once have long names)
.ifndef TESTING
        ;; @A-Z:.. GLOBAL FUNCS
        .res 32*2
        ;; `a-z: GLOBAL VARS
        .res 28*2
.else
;;; Can't init zeropage, so nobody should rely on
;;; these values.
;;; TODO: memset in program before run/compile

;;; FUNS A-Z / 32
        .word 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        .word 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
;;; VARS a-z / 26
        ;;    a  b  c  d  e  f  g  h  i  j
        .word 0,10,20,30,40,50,60,70,80,90
        .word 100,110,120,130,140,150,160,170
        .word 180,190,200,210,220,230,240,250,260
.endif

.ifdef ZPVARS
  .code
.endif


;;; variable defs
;;; TODO: rework to generate BNF parse rules!
FUNC _defs

defs:

;;; test example
;;; TODO: remove?
.ifdef TESTING
.ifdef LONGNAMES
vfoo:   
        .word 0                 ; linked-list end
        .word 4711
        .byte "foo",0
.ifnblank
vmain:  
        .word vfoo
        .word 0
        .byte "main",0
vbar:
        .word vmain
.else
vbar:
        .word vfoo
.endif
imain:  .word 42
        .byte "bar",0
vnext:  
        .word vbar
        .word 0
        .byte 0

.endif ; LONGNAMES
.endif ; TESTING


;;; ORIC MEMORY free
;;; - retro8bitcomputers.co.uk/Content/downloads/manuals/oric-graphics-and-machine-code-techniques.pdf

;;; From #400 to #4FF, 256 bytes are available.
;;; Be warned, however, that the Oric disk system
;;; makes use of this area.
;;; 
;;; 3. The first 256 bytes of each character set
;;; are unused, so programs can be put at
;;; #B400 to #B4FF and #B800 to #B8FF
;;; (or in HIRES mode at #9800 to #98FF
;;; and #9C00 to #9CFF).
;;; 
;;; Although the Reset button on the Oric causes
;;; the character set to be regenerated these
;;; areas are not affected.
;;;
;;; 4. Since the alternate character set is rarely
;;; used the entire area between #B800 and #BB7F
;;; is available for a machine code program.
;;; This area of RAM is ideal for facilities like
;;; Renumber.
;;; 
;;; 5. Another ‘hidden’ area lies between
;;; #BFEO and #BFFF. This area will only be overwritten
;;; if HIMEM is incorrectly set, and survives the
;;; commands ‘HIRES’, ‘TEXT’, and the Reset button.


.bss
;;; Generated program memory layout:
;;; 
;;;   _start:  jmp _output              TODO:
;;;            ...bios...               TODO:
;;;            ...library...            TODO:
;;;   _output: jmp main               GEN CODE
;;;            ...gen machine code... GEN CODE
;;;            rts
;;;    out->
;;; 
;;;            ...free...
;;;
;;;            TODO:concstants/vars ???
;;;   _outend: 

FUNC _outputstart
;;; ideally this should be *overlapping* the
;;; compiler, and memmove compiler to end of mem
;;; Probably can do by explicit .org (and then memmove)

_output:
.bss
;;; not physicaly allocated in binary
;;; ++a; x 2000
;;;  free tap inp output
;;; (- 37 11    8   16  ) = 2K left

.ifndef FROGMOVE
        ;; basically 2000x ++a; lol
        ;.res 16*1000+50
        .res 4*1024
.else
        .res 8*1000+50
.endif

FUNC _outputend

;;; Some variants save on codegen by using a library

;;; LIBRARY

.code


.end

