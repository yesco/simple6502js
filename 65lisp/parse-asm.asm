;;; 6502 Minimal Universal Compiler - Rule Based Native Compiler
;;; 
;;; (c) 2025 jsk@yesco.org (Jonas S Karlsson)
;;; 
;;; Essentially, this is a dynamic rule-based compiler.
;;; 
;;; It interprets a BNF-description of a programming
;;; language while reading and matching it with a
;;; source text of that langauge. The BNF contains
;;; generative "templated" bytes of machine code with
;;; minimal instrumentation to generate runnable machine
;;; code.
;;;
;;; 
;;; Implementation Notes
;;; 
;;; The BNF parser is implemented as a giant statemachine,
;;; i.e., a pushdown automata. The program stack is used
;;; as a data-stack, mixed with *some* subroutine calls.
;;; However, one needs to be careful as you can't use
;;; subroutine to modify the "stack". This means, that
;;; the current rule/input char is read several times.
;;; 
;;; TODO: store them in ZP when stepping
;;; 
;;; 
;;; GOALS:
;;; - an actual machine 6502 compiler running on 6502
;;; - be a "proper" subset of C (at least syntactically)
;;; - *minimal* sized BNF-engine as well as rules
;;;   keeping the whole compiler in about 1-2KB!
;;; - fast "enough" to run "on a screen of code"
;;;   (~ 133 "ops" compiled/s ~ 19 lines/s)
;;;   (Turbo Pascal did 2000 lines in less than 60s)
;;;   (== 33 lines/s)
;;; - provide on-screen editor
;;; - "simple" rule-driven
;;; - many languages (just change rules)
;;; - have MINIMAL subset
;;; - have RULEOPT extentions for efficient codegen
;;; - somewhat useful error messages
;;;   (difficult w recursive descent BNF style parsing)
;;; 
;;; NON-Goals:
;;; - not be the best super-optimizing compiler
;;; - not be the fastest
;;; - no constant folding (yet)
;;; 
;;; The MINIMAL C-language subset:
;;; - types: word (uint_16) [limited: byte (uint_8) void]
;;; - casting syntax
;;; 
;;; - decimal numbers: 4711 42
;;; - "string" constants (== number for printing)
;;; 
;;; - word main() ... - no args
;;; - { ... }
;;; 
;;; - a= b+10;
;;; - + - *2 /2 >> << & | ^ == <   (TODO: ! && || ? != > <= >=)
;;; - &v *v
;;; 
;;; - return ...;
;;; - if () statement; [else statement;]
;;; - label:
;;; - goto label;
;;; - do ... while();
;;; - while() ...
;;; 
;;; - putchar(c); getchar();
;;; - printd(42); printh(666); printz("foo");
;;; 
;;; - word F() { ... } - function definitions
;;; - F() G() - function calls (no parameters)
;;; 
;;; - single letter global variables (no need declare)
;;; - limited char support: *(char*)p=   ... (char)i;
;;; 
;;; - library to minimize gen code+rules (slow code==cc65)


;;; TODO:
;;; - parameters (without stack)
;;; - recursion? (requires stack)
;;;   1) use program stack (no tailrec)
;;;   2) separate stack ops/MINIMAL


;;; Limits:
;;; - only *unsigned* values
;;; - if supported ops/syntax should (mostly)
;;;   work the same on normal C-compiler
;;; - NO priorities on * / (OK, this deviates from C)
;;; - mostly no error messages uneless get stuck
;;;   and can't complete compilation
;;; - "types" aren't enforced
;;; - single lower case letter variable
;;; - single upper case letter functions
;;; - NO parenthesis
;;; - NO generic / or * (unless add library)


;;; OPTIONAL:
;;; - byte datatype
;;; - pointers (no type checking): *p= *p+1
;;; - I/O: getchar putc printd printh
;;; - else statement;
;;; - optimized: &0xff00 &0xff >>8 <<8
;;; - optimized: ++v; --v; += -= &= |= ^= >>=1; <<=1;
;;; - optimized: ... op const   ... op var

  
;;; Extentions:
;;; - 42=>x+7=>y;     forward assignement
;;; - 35.sqr          single arg function call
;;; - 3 @+ v          byte operator (acts only on A not AX)

;;; If there is an error a newline '%' letter error-code
;;; is printed, and with PRINTINPUT ERRPOS defined the
;;; source is printed, and RED text as far as parsing got.

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
;;; MINIMAL   :  1016 bytes = (+ 685  383) inc LIB!
;;; NORMAL    :  1134 bytes = (+ 685  501)
;;; BYTERULES :  1293 bytes = (+ 685  660)
;;; OPTRULES  :  1463 bytes = (+ 685  1090)
;;; LONGNAMES :  
;;; 
;;; v= #x363 = 867 (+52 %U TAILREC-fix)
;;; v= #x32f = 815 (+75 D d : ; # d - WHILE!) :-(
;;; v= #x2f6 = 758
;;; (- 758 27 46) = 685 (-errpos/-checkstack?) 
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
;;; 
;;; 73 B overhead to subtract (+ 26 47)
;;;    642 no ERRPOS no CHECKSTACK
;;;    668  +26 == ERRPOS
;;;    715  +47 == CHECKSTACK
;;; 
;;; TODO:  634 bytes ... partial long names (+ 141 B)
;;; 
;;; not counting: printd, mul10, end: print out
;;; 
;;; C parse() == parse.lst (- #x715 #x463) = 690




;;; C-Rules: 469 B (- 593 56 68)
;;; 
;;;   383 bytes = MINIMAL   (rules + library)
;;;   501 bytes = NORMAL
;;;   660 bytes = BYTERULES (+ 159 B)
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
;;;   593 bytes - printd printh putc getchar +68B TOOD: rem!
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
;;;  1181 bytes DO...WHILE/WHILE... (+ 69B)
;;;  1393 bytes - OPT: << >> <<= >>=
;;;  1481 bytes FUNCTIONS/TAILREC/FUNCDEF (+ 300B)
;;;  1544 bytes FUNCTIONS+POINTERS (+ 63B)
;;; 

;;; TODO: not really rules...
;;;    56 B is table ruleA-ruleZ- could remove empty
;;;    68 B library printd/printh/putc/getchar
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
;;; In a BNF-rule
;;; - lower case letter is matched literally
;;; - spaces (or any char <= ' ') won't work!- don't use
;;; - a letter with hi-bit set ('R'+128) is a reference
;;;   to another rule that is matched by recursion
;;; - rules can have alternatives: E= aa | a | b that are
;;;   tried in sequence. Once accepted no backtracking.
;;; - Put literal/longer matches first in rule alternatives.
;;; - Right-recursion might work:
;;; - Warning: The recursive rule matching is limited by
;;;   the hardware stack: (~ 256/6) ~42 levels
;;; - No Kleene operator (*+?[]) just use:
;;; - TAILREC hibit-* = do tail-recursion on current rule!
;;; - %D - match sequence of digits (number: /\d+/ )
;;; - %S - string "...\n\r\"..."
;;; 
;;; - %V - match "VARiable"
;;; - %A - ADDRESSd of name (for assignment)
;;;        same as %V but stored in "dos" (and "tos")
;;;        (generative rule 'D' will set tos=dos)
;;; - %N - define NEW name (forward) TODO: 2x=>err!
;;; - %U - USE value of NAME (tos= *tos)
;;; 
;;; TODO:?
;;; -(%d - TODO: match 0-255 only)
;;; - %n - define NEW LOCAL
;;; - %v - match LOCAL USAGE of name
;;; - %B or %d - match iff datatype is byte
;;; - %r - the branch can be relative
;;; - %P - match iff word* pointer (++ adds 2, char* add 1)
;;; 
;;; %{ IMMEDIATE CODE (need to enable IMMEDIATE, takes 26B)
;
IMMEDIATE=1
;;; 
;;; Code can be executed inline *while* parsing.
;;; It's prefixed like this
;;; 
;;; RuleX:
;;;        .byte "foo"
;;;      .byte "%{"
;;;        putc '%'                ; print debug info!
;;;        jsr immret              ; HOW TO RETURN!
;;;      .byte ""
;;;        .byte "bar"
;;;        .byte 0                 ;
;;; 
;;; This will parse foo, then print %, then parse bar

;;; [ GENERATIVE ]
;;; 
;;; The generative part of the rule may be invoked
;;; several times. Each one will generate code.
;;; 
;;; NOTE: There is no backtradking/reset of code
;;;       generated, so use with care!
;;;       Typically just generate at end or when sure.
;;; 
;;; Inside the generative brackets normal *relative*
;;; 6502 asm is assumed to be used. See example C.
;;; 
;;; There are directives used that doesn't match
;;; any 6502 byte-codes, these come from this set
;;; of printable bytecodes.
;;;
;;;      "#'+2347:;<>?BCDGKOZ[\]_bcdgkortwz{|
;;; free "#' 2347    ?BC GKOZ \ _bc gkortwz |
;;; 
;;; TODO: consider not using | to allow for faster skip!
;;;       using less byte code (?) (quoting problem?)
;;; 
;;; The following are used:
;;; 
;;;   [   - (redundant - start generative)
;;;   ]   - ends the generation
;;;   <   - lo byte of last %D number matched
;;;   >   - hi byte         - " -
;;;   <>  - little endian 2 bytes of %D     VAL0
;;;   +>  -       - " -           of %D+1   VAL1
;;;         (actually + and next byte will be replaced)
;;; 

;;; TODO: too many ops - consider "pickN" and patch only
;;;   {?  - PUSHLOC (push and patc next loc)
;;;   D   - set %D(igits) value (tos) from %A(ddr) (pos)
;;;   :   - push loc (onto stack)
;;;   ;   - pop loc (from stack) to %D/%A?? (tos)

;;;   d   - set pos from tos
;;;   #   - TODO: push tos

;;; maybe not needed
;;;   Z   - TODO: swap 2 loc
;;;   \   - TODO: slash it, pos= pop(); tos= pop(); push(pos)

;;; 
;;; NOTE: if any constant being used, such as
;;;       address of JSR/JMP (library?) or a
;;;       variable/#constant matches any of these
;;;       characters.
;;; 
;;; NOTE2: This hasn't (?) happened yet, but we don't
;;;        test for it so we don't know.
;;; 
;;;        Hey it's a hack!
;;; 
;;; TODO: detect this and give assert error?
;;;       alt: parameterize any constants?


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


;;; See template-asm.asm for docs on begin/end.asm
.include "begin.asm"

.zeropage

.code

;;; ========================================
;;;                  M A I N

.macro SKIPONE
        .byte $24               ; BITzp 2 B
.endmacro

.macro SKIPTWO
        .byte $2c               ; BITabs 3 B
.endmacro

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
;
TIM=1

.ifblank
;.ifnblank
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
;
CHECKSTACK=1

;;; Minimal set of rules (+ LIBRARY)
;MINIMAL=1

;;; Optimizing rules (bloats but fast!)
;;; 
;;; ++a; --a; &0xff00 &0xff <<8 >>8 >>v <<v 
;
OPTRULES=1
;
ELSE=1

;;; Byte optimized rules
;;; typically used as prefix for BYTE operators
;;; (only operating on register A, no overflow etc)
;BYTERULES=1

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

;;; TODO: not yet done, just thinking
;BNFLONG=1

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
;
;;; TODO: seems to miss some characters "n(){++a;" ...?
;;; Requires ERRPOS (?)
;PRINTREAD=1
;PRINTASM=1

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
        
;;; TOS
; (defined in print.asm .lol)

;;; DOS (second value)
dos:    .res 2

;;; POS (Patch ptr)
pos:    .res 2
gos:    .res 2

;;; if %V or %A stores 'V' or 'A'
;;; 'A' for assigment
vrule:  .res 1

savea:  .res 1
savex:  .res 1
savey:  .res 1

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
VAL0= '<' + 256*'>'
VAL1= '+' + 256*'>'
PUSHLOC= '{' + 256*'{'
TAILREC= '*'+128
DONE= '$'


;;; parser
FUNC _init
;;; 21 B

        ;; init/reset stack
        ldx #$ff
        txs
        cld
.ifdef TIM
        sei
.else
        ;; let interrupts run like normal
;        cld
.endif

.ifdef CHECKSTACK
        ;; sentinel - if these not there stack bad!
        stx $100
        stx $101
.endif

.ifdef DEBUG 
        putc 'S'
        putc 10
.endif ; DEBUG

        ;; init input
.ifdef COMPILESCREEN
        jsr _printsrc

        ;; "Zero terminate the screen!" LOL
        lda #0
        sta SCREENEND+1

        COMPILESTART= SCREEN+40+1
        ;; set screen as input
.else
        COMPILESTART= input+1
.endif

        lda #<(COMPILESTART-1)
        ldx #>(COMPILESTART-1)

        sta inp
        stx inp+1

.ifdef ERRPOS
        sta erp
        stx erp+1
.endif        

        ;; init _out vector
        lda #<_output
        sta _out
        lda #>_output
        sta _out+1
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
jsr printd
putc 10
.endif ; LONGNAMES

;;; TODO: improve using 'P'
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
        jsr printstack
.endif

;;; TODO: but this doesn't work.... lol

.ifnblank
        lda #DONE
        sta rulename

        lda #'P'+128
        jmp _enterrule
.endif

;;; pause before as DEBUG scroll info away, lol
.ifdef DEBUGKEY
        jsr getchar
.endif ; NDEBUG

;;; TODO: why two?
.ifdef COMPILESCREEN
        jsr _incIspc
        jsr _incIspc
.endif
;        jsr _incIspc


.ifdef PRINTASM
        jsr _iasmstart
.endif ; PRINTASM

;;; crashes, lol
;        TIMER



;;; TODO: move this to "the middle" then
;;;   can reach everything (?)
FUNC _next

.ifdef CHECKSTACK
	;; check stack sentinel
        lda #$ff
        cmp $100
        bne stackerror
        cmp $101
        bne stackerror
        jmp :+
stackerror:     
        putc 10
        putc '%'
        putc 'S'
        putc '>'
;;; TODO: this one blocks if TIM
        jsr getchar
        jsr printstack

        ldx #$ff
        txs
        jmp _edit
        
;;; TODO: remove
        jmp halt
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
        bmi _enterrule

        ;; 0 - end = accept
        bne :+
jmpaccept:      
        jmp _acceptrule
:       
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
        beq _eq
failjmp:
        jmp _fail


        ;; percent matchers
percent:
        jsr _incR
        ldy #0
        lda (rule),y
        ;; - skip it assumes A not modified
        ; pha
        jsr _incR
        ; pla

.ifdef IMMEDIATE
;;; 26 B
        ;; - immediate code!
        cmp #'{'
        bne noimm
        ;; copy rule address
        lda rule
        sta imm+1
        ldx rule+1
        stx imm+2

        ;; jump to the rule inline code!
;        putc 'I'
imm:    jmp $ffff
        ;; that code "returns" by jsr immret!
        ;; (this puts after the code on stack)
immret: 
;        putc 'R'
        pla
        sta rule
        pla
        sta rule+1
        jsr _incR
        jmp _next
        
noimm:
.endif ; IMMEDIATE

        ;; - %D - digits
        cmp #'D'
        beq isdigits
        cmp #'S'
        beq isstring
jmpvar: 
        ;; - % anything...
        ;;   %V (or %A %N %U %...)
        jmp _var

        ;; - "constant string"
        ;; (store inline!?)
isstring:       
;STRING=1
.ifdef STRING
        ;; when arrive here %S only reads till "
        ;; (skipping \"). \n is converted.
        
str:    
        jsr _incI
        cmp #'"'                ; "
        beq _next
        cmp #'\'
        bne :+
        ;; quote (next char is raw)
        jsr _incI
        ;; \n - except => 10
        cmp #'n'
        bne :+
        lda #10
:       
;;; TODO: [just copy byte to out]
        jmp str
        ;; have complete string
;;; TODO: where to store it? haha
;;; TODO: [0-terminate]
;;; TODO: [PUSHLOC to here]
;;; TODO: ldax %D
        jmp _next
.endif ; STRING

isdigits:       
        ;; assume it's %D
        jmp _digits


FUNC _eq    
;;; 9 B
    DEBC '='
        jsr _incIspc
exitrule:
        jsr _incR
        jmp _next



FUNC _enterrule
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

.ifdef PRINTASM
        putc 128+5              ; magnenta RULE

        lda rulename
        jsr putchar

        putc 128+2              ; green code text

        jsr _iasm
.endif ; PRINTASM

.ifdef TRACERULE

.ifdef TRACEDEL
        lda #8
        jsr putchar
        jsr putchar

        lda #' '
        jsr putchar
        jsr putchar

        lda #8
        jsr putchar
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
jsr printd
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
        jsr printh
        putc 10
        jsr printstack
.endif

        jmp exitrule



FUNC _fail
.ifdef DEB3
PUTC '\'
.endif
;;; TODO: somehow this triggers more debug output???? 
;putc '\'
;putc 0
;nop

;;; 25 B

;;; TODO: can save bytes somehow???

;;; TODO: ????
.ifdef NOTRIGHTERROR
        ;; Unexpected end of file?
        ldy #0
        lda (inp),y

;;; TODO: not a problem if at end of rule too?
;;;   but then we shouldn't end up here...
;        beq gotendall

        bne :+
;;; TODO: just local rule end... no meaning?
        lda (rule),y
        beq @bothzero
@rulenotzero:
        jsr putchar
        putc 'z'
        jmp gotendall
@bothzero:
        putc '0'
        jmp gotendall
:       
.endif


.ifdef SHOWINPUT
        putc '\'
;        putc 10
.endif ; SHOWINPUT

    DEBC '|'
.ifdef DEBUGRULESKIP
  putc 10
  putc '|'
  lda rule
  sta tos
  lda rule+1
  sta tos+1
  jsr printh
  putc ' '
.endif
        ;; - seek next | alt in rule
@loop:
;        jsr _incR
        ldy #0
        lda (rule),y
        ;; or fail if at end of rule (no more alt)
        beq endrule

;;; TODO: remove! this only catches
;;;    bad memory location!!!! lol
;;;    shows address for "bad" byte
.ifdef DEBUGRULESKIP
   cmp #'U'
   beq @isU
   cmp #'U'+128
   beq @isU
   jsr putchar
   jmp @after
@isU:
   pha
   putc 13
   lda rule
   sta tos
   lda rule+1
   sta tos+1
   jsr printh
   putc ' '        
   pla
@after:
.endif
;    DEBC ','

        ;; skip any inline gen (binary data)
        cmp #'|'
        beq @nextalt
        cmp #'['
        bne @notgen
;;; TODO: much faster if instead have count and skip?
@skipgen:
;    DEBC ';'
        jsr _incR
        lda (rule),y
        cmp #']'
        bne @skipgen
        jmp @loop

@notgen:
        jsr _incR
        ;; _incRX is guaranteed not be be 0!
        bne @loop

@nextalt:
        ;; try next alterantive
        ;; - move after '|'
        jsr _incR

restoreinp:
        ;; - restore inp for alt
        pla
        pha
;;; TODO: correct jump? is it error?
;;;  (means? still have input?)
;        bmi gotendall
        bmi unexpectedrule
        cmp #DONE
;;; lda #0 ???? if no error
        beq _donecompile

;;; TODO: assume it's 'I'? (how about is patch?)

;;; TODO: at failure... need to get out fast???
;;; TODO: not active!!!!
.ifnblank
;;; TODO: Why this interferes with simple ???
        cmp #'i'
        beq gotretry
;;; otherwise - error 'P'
gotpatch:
        lda #'P'
        jmp error
.endif

gotretry:
.ifdef DEBUGRULE
    putc '!'
    putc 10
.endif
    DEBC '!'

        ;; copy/restore and leave inp at stack
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

;;; TODO: is this always like this?
;;;  (how about patch?)

        ;; nothing to backtrack

        ;; - get rid of 'i' retry
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
;;; A contains error code; 0 if no error
_errcompile:
        TIMER

.ifdef TRACERULE
        putc 10
.endif
.ifdef DEBUGRULE
        jsr printstack
.endif
        ;; no errors
        lda #0
        jmp _aftercompile


;;; ERRORS

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

        ;; TODO: could printty print stack showing what 
        ;;   was expected/failed? got "aa" expected "aaa"?
        ;;   difficult(?), except at END of input
        ;; Maybe just keep whatever rule got furtherts
        ;; and pretty print it?

        ;; go edit to fix again!
        jmp _edit

halt:
        jmp halt

FUNC _var
;;; 42 B
DEBC '$'
        sta vrule
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
;;; TODO: simplify
        lda #>vars
        adc #0
        sta tos+1
        ;; AY = lohi = addr

        ;; %N = new defining function/variable
        ;; (TODO: if used for var they are inline code)
        lda vrule
        cmp #'N'
        bne :+

        ;; - *FUN = out // *tos= out
        lda _out
        ldy #0
        sta (tos),y
        iny
        lda _out+1
        sta (tos),y

        jmp @set
:
        ;; %U = Use value of variable
        ;; (for functions if forward, may not
        ;;  have value jmp (ind) more safe!)
        cmp #'U'
        bne @nofun
        ;; - tos = *tos !
        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y

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

        ;; tos= *tos (get value of var/fun)
        sta tos
        stx tos+1
        jmp _next

@nofun:
        
.ifnblank
        ;; - is assignment? => set dos
        ;; vrule='A' >>1 => C=1
        ;;       'V' >>1 => C=0
        ror vrule
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
lda vrule
jsr printchar
        lda tos
        sta dos
        lda tos+1
        sta dos+1
jsr printh
PUTC ' '

@noset:
        ;; skip read var char
        jsr _incIspc
        jmp _next


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

    jsr printd

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
        lda vrule
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

;;; '] - END GEN
        cmp #']'
        bne :+
DEBC ']'
        jsr _incR
        jmp _next
:       
;;; '<' LO %d
        cmp #'<'
        bne :+
DEBC '<'
        lda tos
        jmp @doout
:       
;;; '>' HI %d
        cmp #'>'
        bne :+
DEBC '>'
        lda tos+1
        jmp @doout
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
        bne @doout              ; raw byte - no special
DEBC '+'
        ldx tos+1
        ldy tos
        iny
        tya
        bne @noinc
        inx
@noinc:
        ;; put
        ldy #0
        sta (_out),y
        txa
        jsr _incO
        jsr _incR
        ;; fall-through @doout
@doout:
        sta (_out),y
        jsr _incO
        jmp _generate



;;; TODO: doesn't FAIL if not digit!
FUNC _digits
DEBC '#'
;;; 36 B (+ 36 25) = 61

        ;; valid initial digit or fail?
        ldy #0
        lda (inp),y
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
.ifdef DEBUG
        jsr putchar
.endif ; DEBUG

        sec
        sbc #'0'
        cmp #10
        bcc digit
        ;; end (not 0-9)
        jmp _next
digit:  
        pha
        jsr _mul10
        pla
        clc
        adc tos
        sta tos
        bcc @noinc
        inc tos+1
@noinc:
        ;; lol space inside numbers!
        jsr _incIspc
        jmp nextdigit

failjmp2:        
        jmp _fail



;;; flags not set in any way, registers untouched
FUNC _incIspc
;;; oops! this was actually important to save all regs!
        pha
        txa
        pha
        tya
        pha

        ;; skips any char <= ' ' (incl attributes)
        ;; this requires input be 1 less when starting

        ldx #inp
@skipspc:
;;; TODO: maybe too much dupl w loop beq @done too?

;;; TODO: BUG: if enabled crashes stack lol WTF?
;;; should make it safer as we don't go past end!!!
.ifblank
        lda (0,x)
        beq @done
;;; TODO: eight bit set? if so...
.endif
        
.ifdef COMPILESCREEN
        ldy #0
        lda (inp),y
        ;; mark last read character
        ;; TODO: Seems this messes things up a bit?
        ora #128
        sta (inp),y
;;; TODO: this may get messed up when we backtrack!
.endif
        ;; TODO: or just jsr _incRX
        jsr _incI

;;; TODO: cleanup
        lda (0,x)
.ifdef COMPILESCREEN
        and #127
        sta (0,x)
.endif
        ;; TODO: redundant?
        beq @done

        cmp #' '+1
        bcc @skipspc
@done:

;;; print decimal number of char

.ifdef BAD
;;; TODO: need save tos, or print should use AX...
        ;; this changss result? lol
        sta tos                

        pha
        txa
        pha
        tya
        pha

        putc '('
        ldx #0
        stx tos+1
        jsr printd
        putc ':'
        lda tos
        jsr putchar
        putc ')'
        putc ' '

        pla
        tay
        pla
        tax
        pla
.endif
;;; TODO: only update when backtrack/_fail?

.ifdef ERRPOS
;;; store max input position
;;; (indicative of error position)
        lda inp+1
        cmp erp+1
        bcc @noupdate
        bne @update
        ;; erp.hi == inp.hi
        lda inp
        cmp erp
        bcc @noupdate
        beq @noupdate
        ;; erp := inp
@update:
.ifdef PRINTREAD
        pha

        ldy #0
        lda (erp),y
        jsr putchar

.ifnblank
        sta tos
        lda #0
        sta tos+1
        putc '#'
        jsr printd
        putc ' '
.endif

        pla
.endif

        sta erp
        lda inp+1
        sta erp+1
@noupdate:
.endif ; ERRPOS

        pla
        tay
        pla
        tax
        pla

        rts

FUNC _incP
;;; 3
        ldx #pos
        SKIPTWO
FUNC _incO
;;; 3
        ldx #_out
        SKIPTWO
FUNC _incR
;;; 3
        ldx #rule
        SKIPTWO
FUNC _incI
;;; 2
        ldx #inp
FUNC _incRX
;;; 7
        inc 0,x                 ; 3B
        bne @noinc
        inc 1,x                 ; 3B
@noinc:
        rts
        

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
  jsr printd
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
  jsr printd
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
  jsr printd
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
  jsr printd
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


;;; NO-need align...
;  .res 256-(* .mod 256)
secondpage:     

;;; TODO: still part of parse.bin
;;;    just not in screen display form firstpage/secondpage

;;; BEGIN CHEAT? - not count...

;;; TODO: somehow should be able to put BEFORE begin.asm
;;;    but not get error, just doesn't work! (hang)
;;;    or AFTER 

PRINTDEC=1
PRINTHEX=1
.include "print.asm"

bytecodes:      

;;; ========================================
;;; START rules


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

ruleG:
ruleH:  
ruleI:
ruleJ:  
.ifndef BNFLONG
  ruleK:  
  ruleL:  
ruleM:  
;;ruleN:
.endif 
;;ruleO:  

ruleQ:
ruleR:
.ifndef MINIMAL
ruleU:  
.endif
ruleV:
ruleW:
ruleX:  
ruleY:  
ruleZ:  
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

;;; aggregate statements
ruleA:  
        ;; Right-recursion is "fine"
        .byte _S,TAILREC,"|",0

;;; Block
ruleB:  
        .byte "{}"
        .byte "|{",_A,"}"

        .byte 0

;;; "Constant"/(variable) (simple, lol)
ruleC: 
        
        ;; "IO-lib" hack
        .byte "printd(",_E,")"
      .byte '['
        sta tos
        stx tos+1
        jsr printd
      .byte ']'

        .byte "|printh(",_E,")"
      .byte '['
        sta tos
        stx tos+1
        jsr printh
      .byte ']'

        .byte "|printz(",_E,")"
      .byte '['
        jmp _printz
      .byte ']'

.ifdef OPTRULES
        ;; putchar constant - saves 2 bytes!
        .byte "|putchar(%V)"
      .byte '['
        lda VAL0
        jsr putchar
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


        ;; cast to char/byte == &0xff !
        .byte "|(byte)",_C
      .byte '['
        ldx #0
      .byte ']'

        ;; casting - ignore!
        ;; (we don't care legal, just accept if correct)
        .byte "|(%V\*)",_C


.ifdef BYTERULES
;;; TODO: FUNS?

        ;; 25 B (+ 6 15 4) - byte
        ;; 29 B            - word
        .byte "|%V@\["
      .byte '['
;;; TODO: this assumes %V gives adress
;;;   but is just pointer to address, lol...
;;;   lda (tos),y ... 
        ;; 6
        lda #'>'
        pha
        lda #'<'
        pha
      .byte ']'
        .byte _E,"]"
      .byte '['
;;; TODO: use existing stack library?
        ;; 15
        ;; lo
        sta tos
        pla
        clc
        adc tos
        sta tos
        ;; hi
        stx tos+1
        pla
        adc tos+1
        sta tos+1
        ;; load
.ifdef WORD
        ;; 8
        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y
.else ; BYTE
        ;; 4
        ldy #0
        lda (tos),y
.endif
      .byte ']'
        
.ifdef POINTERS
        .byte "|@\*%V"
      .byte '['
;;; TODO: test
        lda VAL0
        sta tos
        lda VAL1
        sta tos+1

        ldy #1
        lda (tos),y
        ldx #0
      .byte ']'
.endif ; POINTERS
        
        ;; variable
        .byte "|@%V"
      .byte '['
        lda VAL0
        ldx #0
      .byte ']'

        ;; TODO: hmmm 
        .byte "|%D"
      .byte '['
        lda #'<'
        ldx #0
      .byte ']'

.endif ; BYTERULES

        ;; function call
        .byte "|%U()"
      .byte '['
        jsr VAL0
        ;; result in AX
      .byte ']'

        ;; EXTENTION
        ;; .method call! - LOL
        .byte "|.%U"
      .byte '['
        ;; parameter already in AX
        jsr VAL0
        ;; result in AX
      .byte ']'

        ;; Surprisingly ++v and --v
        ;; isn't smalller or faster than v++ and v-- !
        .byte "|++%V"
      .byte '['
;;; 14B 17c
        inc VAL0
        bne :+
        inc VAL1
:       
        lda VAL0
        ldx VAL1
      .byte ']'

        .byte "|--%V"
      .byte '['
.ifnblank
;;; 17B 21c
        lda VAL0
        bne :+
        dec VAL1
:       
        dec VAL0
        lda VAL0
        ldx VAL1
.endif
;;; 17B 19c
        ldx VAL1
        ldy VAL0
        bne :+
        dex
        stx VAL1
:       
        dey
        tya
        sta VAL0
      .byte ']'

        .byte "|%V++"
      .byte '['
;;; 14B ! 17c ! - no extra cost!
        lda VAL0
        ldx VAL1
        inc VAL0
        bne :+
        inc VAL1
:       
      .byte ']'

        .byte "|%V--"
      .byte '['
;;; 14B ! 17c
        ldx VAL1
        lda VAL0
        bne :+
        dec VAL1
:       
        dec VAL0
.ifnblank
;;; 17B 19c - faster
        ldx VAL1
        ldy VAL0
        dey
        tya
        bne :+
        dex
        stx VAL1
:       
        sta VAL0
.endif
      .byte ']'

        ;; variable
        .byte "|%V"
      .byte '['
        lda VAL0
        ldx VAL1
      .byte ']'

.ifdef RULEOPT
        ;; load 0 saves 1 byte
        .byte "|0"
      .byte '['
        lda #0
        tax
      .byte ']'
.endif ; RULEOPT

        ;; digits
        .byte "|%D"
      .byte '['
        lda #'<'
        ldx #'>'
      .byte ']'
        
        ;; string
        .byte "|",34            ; really >"<
      .byte '['
        jmp PUSHLOC
        .byte ':'               ; push here
      .byte ']'
        ;; copies string inline till "
        .byte "%S"
      .byte "["
        ;; load string from %D value
        .byte ";"               ; pop here
        lda #'<'
        ldx #'>'
      .byte ']'
        ;; autopatches jmp to here
;;; TODO: DAMN - wrong, should be to before "load string"


.ifdef POINTERS
        .byte "|&%V"
      .byte '['
        lda #'<'
        ldx #'>'
      .byte ']'

        .byte "|\*%V"
      .byte '['
;;; TODO: test
        lda VAL0
        sta tos
        lda VAL1
        sta tos+1

        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y
      .byte ']'

.endif ; POINTERS

        .byte 0

.ifdef MINIMAL
;;; Just save (TODO:push?) AX
ruleU:
      .byte '['
        jsr _SAVE
      .byte ']'
        .byte 0
.endif

;;; aDDons (::= op %d | op %V)

ruleD:

        ;; 7=>A; // Extention to C:
        ;; Forward assignment 3=>a; could work! lol
        ;; TODO: make it multiple 3=>a=>b+7=>c; ...
        .byte "=>%A"
      .byte "[D"
        sta VAL0
        stx VAL1
      .byte "]"
        .byte TAILREC


;;; ----------------------------------------
.ifdef BYTERULES
;;; TODO: How to automatically detect that a var
;;;   is byte and use rule, or does C require INT
;;;   for all calculations?

        .byte "|@+%V"
      .byte '['
        clc
        adc VAL0
      .byte ']'
        .byte TAILREC

        .byte "|@+%D"
      .byte '['
        clc
        adc #'<'
      .byte ']'
        .byte TAILREC

;;; 18 *2
        .byte "|@-%D"
      .byte '['
        sec
        sbc VAL0
      .byte ']'
        .byte TAILREC

        .byte "|@-%D"
      .byte '['
        sec
        sbc #'<'
      .byte ']'
        .byte TAILREC

;;; 17 *2
        .byte "@|&%V"
      .byte '['
        and VAL0
      .byte ']'
        .byte TAILREC

        .byte "|@&%D"
      .byte '['
        and #'<'
      .byte ']'
        .byte TAILREC

.ifnblank
;;; TODO: \ quoting
;;; 17 *2
        .byte "|@\|%V"
      .byte '['
        ora VAL0
      .byte ']'
        .byte TAILREC

        .byte "|@\|%D"
      .byte '['
        ora #'<'
      .byte ']'
        .byte TAILREC
.endif ; NBLANK

;;; 17 *2
        .byte "|@^%V"
      .byte '['
        eor VAL0
      .byte ']'
        .byte TAILREC

        .byte "|@^%D"
      .byte '['
        eor #'<'
      .byte ']'
        .byte TAILREC

;;; 24
        
        .byte "|@/2"
      .byte '['
        lsr
      .byte ']'
        .byte TAILREC

        .byte "|@\*2"
      .byte '['
        asl
      .byte ']'
        .byte TAILREC

;;; ==

        .byte "|@==%V"
      .byte '['
        ldy #0
        cmp VAL0
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
      .byte ']'
        .byte TAILREC

        .byte "|@==%D"
      .byte '['
        ldy #0
        cmp #'<'
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
      .byte ']'
        .byte TAILREC

        .byte "|@<D"
      .byte '['
        ldy #$ff
        cmp #'<'
        bcc :+
        ;; < => 0
        iny
:       
        ;; neq => 0
        tya
      .byte ']'
        .byte TAILREC

.endif ; BYTERULES
;;; ----------------------------------------

.ifdef MINIMAL

        .byte "|+",_U
      .byte '['
        jsr _PLUS
      .byte ']'
        .byte TAILREC

        .byte "|+",_U
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

      .byte "%{"
        ldy tos
        sty savea
        ldy tos+1
        sty savex

        ldy dos
        sty tos
        ldy dos+1
        sty tos+1

        pha
        txa
        pha
        jsr printh
        pla
        tax
        pla

        ldy savea
        sty tos
        ldy savex
        sty tos+1

        jsr immret

      .byte '['
        clc
        adc VAL0
        tay
        txa
        adc VAL1
        tax
        tya
      .byte ']'
        .byte TAILREC

        .byte "|+%D"
      .byte '['
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
        sbc VAL0
        tay
        txa
        sbc VAL1
        tax
        tya
      .byte ']'
        .byte TAILREC

        .byte "|-%D"
      .byte '['
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
        and VAL0
        tay
        txa
        and VAL1
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
        ora VAL0
        tay
        txa
        ora VAL1
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
        eor VAL0
        tay
        txa
        eor VAL1
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

        .byte "|>>%D"
      .byte '['
;;; 15B (breakeven: D=4-)
        stx tos+1
        ldy #'<'
:       
        dey
        bmi :+
        
        lsr
        ror tos

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
        cmp VAL0
        bne :+
        cpx VAL1
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

        .byte "|<%D"
      .byte '['
        ;; 13
        ldy #$ff
        cmp #'<'
        bcc :+
        cpx #'>'
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

;;; Exprssion:
ruleE:  
        .byte _C,_D,0


ruleF:  
;;; works
;        .byte _T,"%V(){",_S,"}"

        .byte _T,"%F()"

;;; TODO: something wrong with 'B'
;        .byte _T,"%V(){",_B,"}"
      .byte '['
        PUTC '!'
;;; TODO: remove, for now we skip over function, lol
;;;   need for compile LONGNAMES and "main" for now
        jmp PUSHLOC
      .byte ']'
        .byte "{",_S,"}"
      .byte '['
        PUTC 'F'
        rts
      .byte ']'
        
        .byte 0



        .byte "%V()"
        .byte _B
;      .byte '['
        ;; pretend it's the body
;        PUTC 'F'
;      .byte ']'


;;; DEFS ::= TYPE %NAME() BLOCK TAILREC |
ruleN:
        ;; Define function
        .byte _T,"%N()",_B
      .byte '['
        rts
      .byte ']'
;;; TODO: this TAILREC messes with ruleP and several F
;;;   TAILREC does something wrong!
        .byte TAILREC
        
        .byte "|"

        .byte 0
        
;;; DEFSSKIP ::= jmp main; DEFS <here>
ruleO:  
      .byte '['
        jmp PUSHLOC
      .byte ']'
        .byte _N
        .byte 0
        ;; Autopatches skip over definitions in N


;;; PROGRAM ::= DEFSSKIP TYPE main() BLOCK | 
ruleP:  
        .byte _O

        .byte _T,"main()",_B
      .byte '['
        ;; if main not return, return 0
        lda #0
        tax
        rts
      .byte ']'
;        .byte TAILREC

      .byte '['
        rts
      .byte ']'

        .byte 0

;;; Type
ruleT:  
        ;; don't use SIGNED int/char
        .byte "word|byte|void",0


.ifdef BNFLONG

;;; List of actual paramters
ruleL:  
;;; Problem with "E,L|E|" is that E might be generated twice!
;;; 
;;; TODO: we could push "out" and restore with "inp" when
;;;   backtrackging...

;;; instead we gobble ','
        .byte ",ML|ML|"         ; LOL
        .byte 0

;;; expression parameter push! (all!)
ruleM:  
      .byte '['
;;; 3 B  9c - program stack!
        pha
        txa
        pha
;;; 9 B 17c - zero page stack
        dec spy
        ldy spy
        sta losp,y
        stx hisp,y
;;; 9 B 22c - split stack
        dec spy
        ldy spy
        sta (losp),y
        txa
        sta (hisp),y
;;; 11 B 24c -- other stack
        ldy spy
        dey
        sta (sp),y
        dey
        txa
        sta (sp),y
        sta spy
;;; 16 B -- other stack
        ldy #1
        sta (sp),y
        txa
        dey
        sta (sp,y
        ;; stack grow down
        dec sp
        dec sp
        bne @noinc
        dec sp+1
@noinc:
      .byte ']'
        .byte 0

;;; Local variable
ruleN:
        .byte "%v"
      .byte '['
;;; 9 B 14c - program stack
        tsx
        ldy VAL0,x          ; lo
        lda VAL1,x          ; hi
        tax
        tya
;;; 8 B 16c - other stack
        ldy #'<'
        lda (sp),y
        tax
        dey 
        lda (sp),y
      .byte ']'

;;; ++a; // more efficent, no need value
        .byte "++%v;"
      .byte '['
        tsx
        inc VAL0,x
        bne @noinc
        inc VAL1,x
@noinc:
      .byte ']'

;;; --a; // more efficent, no need value
        .byte "--%v;"
      .byte '['
        tsx
        lda VAL0,x
        bne @nodec
        dec VAL1,x
@nodec:
        dec VAL0,x
      .byte ']'

;;; ++a+3
        .byte "++%v"
      .byte '['
        tsx
        inc VAL0,x
        bne @noinc
        inc VAL1,x
        ;; need to load it
        lda VAL0,x
        ldx VAL1,x
@noinc:
      .byte ']'

        .byte "%v==%D"
      .byte '['
        
      .byte ']'

        .byte "+%v"
      .byte '['
;;; 15 B 26c - program stack
        stx savex
        tsx
        ;; lo
        clc
        adc VAL0,x
        tay
        ;; hi
        lda savex
        adc VAL1,x
        tax

        tya
      .byte ']'
        .byte 0

;;; Kall function
ruleK:
        ;; Function name
        .byte "%A("
      .byte '['
;;; ? B ?c - program stack
        lda #

      .byte ']'
        ;; Parameters
        _L,")";"
      .byte '['
        ;; get %A value to tos
        .byte TAILREC
        jsr VAL0
;;; TODO: assuming there is no other assignement \%A
;;;       in parsing List of parameters... LOL (push/pop?)
;;; TODO: if we add push operator we can do reordering?
      .byte ']'
        .byte 0

.endif ; BNFLONG


;;; Statement
ruleS:
        ;; empty statement is legal
        .byte ";"
      .byte '['
        ;; for expects empty statement to be "true"
;;; TODO: move to for
        lda #42
      .byte ']'
        

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
        .byte "|%N:",_S
        ;; set's variable/name to that address!

        ;; goto
        .byte "|goto%A;"
      .byte "[D"                ; get aDdress
        jmp (VAL0)
      .byte "]"

.ifdef OPTRULES

        ;; IF( var < num ) ... saves 6 B (- 63 57)
        ;; note: this is safe as if it doesn't match,
        ;;   not code has been emitted! If use subrule... no
        .byte "|if(%A<%D)"
      .byte "["
        ;; reverse cmp as <> NUM avail first
        lda #'<'
        ldx #'>'
        ;; cmp with VAR
        .byte 'D'               ; get aDdress

        cpx VAL1
        bcc @nah                ; NUM<VAR (num.h<var.h)
        ;;  NUM>=VAR ... VAR<=NUM
        cmp VAL0
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

.endif ; OPTRULES

        ;; IF(E)S; // no else
;;; TODO: "if (a&1)" gives error before ')' ????
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



        ;; A=7; // simple assignement, ONLY as statement
        ;; and can't be nested or part of expression
        ;; (unless we use a stack...)
        .byte "|%A=",_E,";"
      .byte "[D"                ; 'D' => tos=dos
        sta VAL0
        stx VAL1
      .byte "]"



.ifdef OPTRULES
;;; TODO make ruleC when %A pushes
        .byte "|++%A;"
      .byte "[D"
        inc VAL0
        bne :+
        inc VAL1
:       
      .byte "]"

;;; TODO make ruleC when %A pushes
        .byte "|--%A;"
      .byte "[D"
        lda VAL0
        bne :+
        dec VAL1
:       
        dec VAL0
      .byte "]"

        ;; NOTE: no need provide: v op= const;
        ;;       - it would wouldn't save any bytes!
        .byte "|%A+=",_E,";"
      .byte "[D"
        clc
        adc VAL0
        sta VAL0
        txa
        adc VAL1
        sta VAL1
      .byte "]"

        .byte "|%A-=",_E,";"
      .byte "[D"
        sec
        eor #$ff
        adc VAL0
        sta VAL0
        txa
        eor #$ff
        adc VAL1
        sta VAL1
      .byte "]"

        .byte "|%A&=",_E,";"
      .byte "[D"
        and VAL0
        sta VAL0
        txa
        and VAL1
        sta VAL1
      .byte "]"

        .byte "|%A\|=",_E,";"
      .byte "[D"
        ora VAL0
        sta VAL0
        txa
        ora VAL1
        sta VAL1
      .byte "]"

        .byte "|%A^=",_E,";"
      .byte "[D"
        eor VAL0
        sta VAL0
        txa
        eor VAL1
        sta VAL1
      .byte "]"

        .byte "|%A>>=1;"
      .byte "[D"
;;; 6B
        lsr VAL1
        ror VAL0
      .byte "]"

        .byte "|%A<<=1;"
      .byte "[D"
;;; 6B
        asl VAL0
        rol VAL1
      .byte "]"

        .byte "|%A>>=2;"
      .byte "[D"
;;; 12B
        lsr VAL1
        ror VAL0
        lsr VAL1
        ror VAL0
      .byte "]"

        .byte "|%A<<=2;"
      .byte "[D"
;;; 12B
        asl VAL0
        rol VAL1
        asl VAL0
        rol VAL1
      .byte "]"

        .byte "|%A>>=%D;"
      .byte "["
;;; 14B (tradeoff 14=6*d => d=2+)
        ldy #'<'
        .byte "D"
:       
        dey
        bmi :+

        lsr VAL1
        ror VAL0

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

        asl VAL0
        rol VAL1

        sec
        bcs :-
:       
      .byte "]"

.endif ; OPTRULES

.ifdef POINTERS
        .byte "|*%A=",_E,";"
      .byte "[D"
        ldy VAL0
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
        .byte "|%A@\[%D\]="
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

        sta VAL0,y
      .byte "]"
.endif ; BYTERULES

        ;; TODO: this is now limited to 128 index
        ;; word[%D]= ... fixed address... hmmm
        .byte "|%A\[%D\]="
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

        sta VAL0,y
        txa
        sta VAL1,y
      .byte "]"

.ifdef OPTRULES
;;; OPT: WHILE(a)...
;;; TODO: while(--a) ???
        .byte "|while(%V)"
        .byte "[:]"

      .byte "["
        lda VAL0
        ora VAL1
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
.endif

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
        
        jsr immret

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
        lda VAL0
        ora VAL1
        .byte ";"               ; pop tos
        ;; don't loop if not true
;;; TODO: potentially "b" to generate relative jmp
        bne :+
        jmp VAL0
:        
      .byte "]"

.endif

;;; DO...WHILE
;ruleW:  
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

        ;; Expression; // throw away result
        .byte "|",_E,";"

        .byte 0

;;; END rules
;;; ========================================


.include "end.asm"



;;; CHEAT - not counted in parse.bin



;;; Isn't it just that AX means more code than
;;; separate tos?
FUNC _mul10
;;; 25
        lda tos
        ldx tos+1
        jsr _double
        jsr _double
        clc
        adc tos
        sta tos
        txa
        adc tos+1
        sta tos+1
        ;; double
_double:        
        asl tos
        rol tos+1
        rts

FUNC _aftercompile
;;; doesn't set A!=0 if no match/fail just errors!
;        sta err

        .data
status: 
        .word $bb80-2
        ;;     ////////////////////////////////////////
        .byte "CC02 (C) 2025 jsk@yesco.org",0
.code
        ;; - from
        lda #<status
        ldx #>status
        jsr memcpyz

;        PRINTZ {10,10,"65mucc02",10}
;        PRINTZ {"(C)2025 Jonas S Karlsson jsk@yesco.org",10}

        ;; failed?
        ;; (not stand at end of source)
        ldy #0
        lda (inp),y
        beq _OK

.ifdef ERRPOS
        ;; hibit string near error!
        ;; (approximated by as far as we read)
        ldy #0
        lda (erp),y
        ora #128
        sta (erp),y

.endif ; ERRPOS

.ifdef xCOMPILESCREEN
;;; TODO: ....
        PRINTZ "HALT2"
        jmp halt
.endif

        ;; print it
       
.ifdef PRINTINPUT

        putc '>'
;;; TOOD: put in getchar...
.ifdef TIM
        cli
        jsr getchar
        sei
.else
        jsr getchar
.endif

;;; TODO: printz? printR?

;;; TODO: ldx , ldy, jsr _copyR - 6B
;;; 8 B
        lda #<input
        sta pos
        lda #>input
        sta pos+1

        jmp @print

@loop:
.ifdef ERRPOS
        ;; hi bit on char is indicator of how var it
        ;; read, next char, or here is the error
        ;; - print red attribute
        bpl @nohi
        pha
        lda #1+128              ; red text
        jsr putchar
        ;; - remove hibit from src
        pla
        and #127
        sta (pos),y
@nohi:
.endif ; ERRPOS

        ;; print source char
        jsr putchar

        jsr _incP
@print:
        ldy #0
        lda (pos),y
        bne @loop

        putc 10
.endif ; PRINTINPUT

        jmp _edit
;        jmp failed
;;; LOOPS: lol


_OK:
        putc 10
        putc 'O'
        putc 'K'
        putc ' '

        ;; print size in bytes
        sec
        lda _out
        sbc #<_output
        sta tos
        lda _out+1
        sbc #>_output
        sta tos+1
        
        jsr printd
        putc 'B'
        putc 10
        putc 10

_run:   

;;; Enable to always show generated code
;;; TODO: make it do inline while PRINTREAD
;        jsr _dasm

        TIMER

;;; TODO: remove, or make Compile not Run?
;        jsr _dasm
;        TIMER



.zeropage
runs:   .res 1
.code

        ;; RUN PROGRAM
        lda #1
        sta runs
again:
        jsr _output

;;; 2132 - 256 empty loops
;;; (* 256 (+ 6 3)) = 2304 means (- 2304 2132)
;;; = 172c overhead ???
;;; 
;;; 1108 - 128 empty loops
;;; (* 128 (+ 6 3)) (- 1152 1108) = 45 overhead ???

        dec runs
        bne again

        pha
        txa
        pha

        TIMER

        putc 10
        putc '='
        putc '>'
        putc ' '

        ;; prints tos
        pla
        sta tos+1
        pla
        sta tos
        jsr printd

        putc 10
        

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


FUNC _edit  

        ;; TODO: getchar already echoes!!!
.ifdef TIM
        cli
        jsr getchar
        sei
.else
        jsr getchar
.endif

        ;; - ctrl-C - compile
        cmp #'C'-'@'
        bne :+


        jsr _clrscr

;;; TODO: can compile few times, something messed up?
;;; TODO: detect dirty (?) and require save?

        ;; This basically restarts program, lol
        TIMER
        jmp _init
:       
        ;; - ctrl-D - delete char forward
        cmp #'D'-'@'
        bne :+

;;; TODO: remove when getchar not echo
        jsr putchar

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

        jmp _edit
:       
        ;; - ctrl-A - beginning of text in line
        cmp #'A'-'@'
        bne :+

        lda #'M'-'@'
        jsr putchar

        ;; move to first nonspace
ctrla:  
        ldy CURCOL
        lda (ROWADDR),y
        cmp #' '+1
        bmi _edit
        ;; move forward
        lda #'I'-'@'
        jsr putchar
        jmp ctrla
:       
        ;; - ctrl-E - end of text in line
        cmp #'E'-'@'
        bne :+

        ;; move to end of line, lol
        lda #'M'-'@'
        jsr putchar
        lda #'J'-'@'
        jsr putchar
        lda #8
        jsr putchar

        ;; move to first nonspace
ctrle:  
        ldy CURCOL
        lda (ROWADDR),y
        cmp #' '+1
        bmi doneCE
        ;; move back
        lda #8                  ; BS
        jsr putchar
        jmp ctrle
doneCE: 
        ;; move one forward
        lda #'I'-'@'
        jsr putchar
:       
        ;; - ctrl-R - run/display error
        cmp #'R'-'@'
        bne :+

        jsr _clrscr
        jmp _aftercompile
:       
        ;; - ctrl-X - execute whatever
        cmp #'X'-'@'
        bne :+

;        jsr _clrscr
        jmp _run
:       
        ;; - ctrl-q - disasm
        cmp #'Q'-'@'
        bne :+

        jsr _clrscr
        jsr _dasm
        jmp _edit
:       
.ifnblank
        ;; - ctrl-z - disasmccc
        cmp #'Z'-'@'
        bne :+

        jsr _clrscr
        jsr _dasmcc
        jmp _edit
:       
.endif

        ;; ctrl-Print (as source)
;;; 10B dispatch should be 3B lol
        cmp #'P'-'@'
        bne :+
        jsr _printsrc
        jmp _edit
:       
        ;; - ctrl-W - save
        cmp #'W'-'@'
        bne :+
        
        jsr _savescreen
        jmp _edit
:       
        ;; ctrl-Load
        cmp #'L'-'@'
        bne  :+

        jsr _loadscreen
:       
        jmp _edit

        ;; TODO: getchar already echoes!!!
;        jsr putchar
        jmp _edit
        

FUNC _printsrc
        jsr _clrscr
        lda #<input
        ldx #>input
        jmp _printz

FUNC _clrscr
        lda #12
        jmp putchar

;;; TODO: ???
FUNC _dymmy5

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
;;; tos= text from (lol)
;;; dos= destination
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
        
        jmp _memcpy

FUNC _loadscreen
        ;; from
        lda #<savedscreen
        ldx #>savedscreen
        sta tos
        stx tos+1
        ;; to
        lda #<SCREEN
        ldx #>SCREEN
        sta dos
        stx dos+1
        ;; copy
        lda #<SCREENSIZE
        ldx #>SCREENSIZE

        jmp memcpy
        





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


TIMER_START	= $ffff
SETTIMER        = $0306
READTIMER	= $0304
CSTIMER         = $0276


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
        putc 10
        putc 128+7
        putc '['
;        putc 'T'
        sta tos
        stx tos+1
        jsr printd

        putc 'u'
        putc 's'
;        putc 10
        
        lda #$ff
        sta READTIMER
        ;; this write triggers reset
        sta READTIMER+1
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
;        PUTC ' '
.else
        PUTC 10
        sta tos
        stx tos+1

        jsr printd
        putc 'c'
        putc 's'

.endif
        putc ']'
        putc 128+2
        putc 10

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
        jsr printh
        putc '='
        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y
        sta tos
        stx tos+1
        jsr printd
        putc ' '
        rts     

;;; prints readable otherwise deccode
.zeropage
pchar:  .res 1
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
        jsr printd
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
        jmp printh

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

        putc 10
        putc '#'
        lda rulename
        jsr printchar
        putc ' '
        putc 's'

        ;; print s
        stx tos
        lda #0
        sta tos+1
        jsr printd

@loop:
        putc ' '
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
        jsr printh
.else
        inx
        beq @err
        inx
        beq @err
.endif ; DEBUGRULE2ADDR

        jmp @loop

@err:
        putc ' '
        putc ' '
        putc 'o'
        putc 'o'
        
@done:
        putc '>'
;;; TODO: 
.ifndef TIM
        jsr getchar
.endif
        sta savea
        putc 10

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
        





;;; TODO: make it point at screen,
;;;   make a OricAtmosTurboC w fullscreen edit!

;;; Pretend to be prefixed by:
;;; 
;;;   typedef unsigned uint16_t word;
;;;   typedef unsigned uing8_t  byte;
;;; 


;;; This is just to keep input safe, lol
;;; _incIspc may mark prev as read, and or 
;;; it could be used by memcpyz that need prefix?
.byte 0,0

input:

;        .byte "word main(){a=b+c;return a;}",0

;        .byte "word main(){b=1; if (b&1) putchar(65); }",0

;;; 133 naive, c=0+a+c;
;;; 131 opt: 0

MUL=1
.ifdef MUL
        .byte "word M() {",10
        .byte "  c= 0;",10
        .byte "  while(b) {",10
;;; TODO: some bug, lol
;        .byte "    if (b&1) c+= a;",10
;        .byte "    if (b&1) c= 1000+a;",10
        .byte "    if (b&1) c= 0+a+c;",10
;        .byte "    printd(a); putchar(32) ; printd(b); putchar(32); printd(c); putchar(10);",10
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
        .byte "  a= 111; b= 111;",10
;        .byte "  putchar(99);",10
        .byte "  return M();",10
        .byte "}",10
        .byte 0
.endif ; MUL

        .byte "word main(){ }",0

;;; TAILREC
;        .byte "word main(){ return 4700+11; }",0

;;; TODO: enable this one compiles correctly but 
;;;   give garbage rule names and %S...
;
FUN=1
.ifdef FUN
        .byte "word F() { return 4700; }",10
        .byte "word G() { return F()+11; }",10
        .byte "word main(){ printh(F); printh(&F); putchar(10); printh(G); printh(&G); putchar(10); return G(); }",0
;        .byte "word main(){ printh(F); printh(&F); putchar(10); printh(G); printh(&G); putchar(10); return F(); }",0
.endif

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
        .byte "word main() {",10
        .byte "  a= 470; b= 11;",10
        .byte "A:",10
        .byte "  if (a&1) { ++b;++b;++b;++b;b+=6; }",10
        .byte "  else { b+=8; ++b; ++b; }",10
        .byte "  --a;",10
        .byte "  if (a) goto A;",10
        .byte "  printd(b);",10
        .byte "}",10
        .byte 0
.endif ; FOUR

;
;
ATOZ=1

.ifdef ATOZ
        .byte "word main() {",10
        .byte "  a=65;",10
        .byte "A:",10
        .byte "  putchar(a);",10
.ifdef OPTRULES
        .byte "  ++a;",10
.else
;;; TODO: 
        .byte "  a=a+1;",10
.endif
        .byte "  if (a<91) goto A;",10
        .byte "  putchar(46);",10
;    .byte "  ++a;",10
        .byte "  return 42;",10
        .byte "}",10
        .byte 0
.endif ; ATOZ

;        .byte "word main(){++a;++a;return a;}",0
;        .byte "word main(){return 4711;}",0

;;; IF sanity
;        .byte "word main(){a=42;if(a==3)a+=4;printd(a);}",0

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

;;; ok need space before printd? lol
;        .byte "{a=4;a+=3; printd(a);}",0

;;; FAIL - no space?   "printd" fails if first rule!
;;; ... and now it works....?
        .byte "{a=4;a+=3;printd(a);}{b=7;}",0
        .byte "{a=4;a+=3;printd(a);}",0
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
        .byte "void main(){ a=65; A: putchar(a); ++a; if (a<91) goto A; putchar(46); }",0
;;; TODO: remove spaces crash in parse!!!!
        .byte "void main(){ a=65; A: putchar(a); ++a; if (a<91) goto A; putchar(46); }",0
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
;;;      (normalixed)
;;;             1.8s  action (see below)
;;;           228s    BASIC (according to action)
;;;             3.6s  Tigger C
;;;            16.s   "BASIC" says Tigger C video
;;; 
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


;PRIME=1

;;; From: onthe6502.pdf - by 
;;;  jsk: modified for single letter var, putchar

.ifdef PRIME
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
        .byte "byte a[256];",10
        .byte "byte b[4];",10
        .byte 10
        .byte "word main(){",10
;       .byte "  word n,i;",10
;       .byte "  byte t;",10
;       .byte "  a[0]=0xff;",10
        .byte "  a[0]=255;",10
;       .byte "  for(t=1; t; ++t) a[t]=0xff;",10
        .byte "  for(t=1; t; ++t) a[t]=255;",10
        .byte "  for(n=2; n<2048; ++n) {",10
        .byte "    if (a[n>>3] & (1<<(n&7))) {",10
        .byte "      i=n;",10
        .byte "      t=0;",10
        ;;           // simulates printd?
.ifblank
        .byte "      printd(i);",10
.else
        .byte "      do {",10
        .byte "        b[t++]= (i%10)+'0';",10
        .byte "        i/=10;",10
        .byte "      } while(i);",10
        .byte "      do {",10
        .byte "        putchar(b[--t]);",10
        .byte "      } while(t);",10
.endif
;       .byte "      putchar(' ');",10
        .byte "      putchar(32);",10
        .byte "      for(i=n+n; i<2048; i+= n) {",10
;       .byte "        a[i>>3]&= ~(1<<(i&7));",10
;       .byte "        a[i>>3]&= (1<<(i&7))^0xffff;",10
        .byte "        a[i>>3]&= (1<<(i&7))^65535;",10
        .byte "      }",10
        .byte "    }",10
        .byte "  }",10
        .byte "}"
        .byte 0

.endif ; PRIME


.ifdef TESTARRAY
        ;; byte arrays
        .byte "byte a[42];",10
        .byte "word main(){ a@[3]=20; a@[7]=22;",10
        .byte "  return a@[3]+a@[3];",10
        .byte "}",0
.endif

.ifdef TWEN
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

        .byte "word main(){printd(4711);return getchar();}",0

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
.endif ; FOO

docs:   
        .byte "C-Syntax: { a=...; ... return ...; }",10
        .byte "C-Ops   : *2 /2 + - ==", 10
        .byte "C-Vars  : a= ... ; ... =>a;", 10

.endif ; INCTESTS

savedscreen:    
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
        ;; ORIC SCREEN SIZE
        ;; (save program/screen before compile to "input")
        .res SCREENSIZE+1

;;; END INPUT
;;; ----------------------------------------


vars:
;        .res 2*('z'-'a'+2)
;;; TODO: remove (once have long names)
.ifdef TESTING
;;; FUNS A-Z / 32
        .word 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        .word 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
;;; VARS a-z / 26
        ;;    a  b  c  d  e  f  g  h  i  j
        .word 0,10,20,30,40,50,60,70,80,90
        .word 100,110,120,130,140,150,160,170
        .word 180,190,200,210,220,230,240,250,260
.endif

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


;;; 
;;; 

.bss
;;; Generated program memory layout:
;;; 
;;;   _output: jmp main
;;;            ...machine code...
;;;            rts
;;;    out->
;;; 
;;;            ...free...
;;;
;;;            TODO:concstants/vars ???
;;;   _outend: 

_output:
;;; not physicaly allocated in binary
;;; ++a; x 2000
;;;  free tap inp output
;;; (- 37 11    8   16  ) = 2K left
        .res 16*1000+50

;;; Some variants save on codegen by using a library

;;; LIBRARY

.code
library:        
;;; (- #xdad #xd4d) = 96 B

.ifdef MINIMAL

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

.end
