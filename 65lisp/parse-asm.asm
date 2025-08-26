;;; 6502 parser of BNF that generates machinecode
;;; 
;;; (c) 2025 jsk@yesco.org (Jonas S Karlsson)
;;; 
;;; Essentially this is a dynamic compiler.
;;; 
;;; It interprets a BNF-description of a programming
;;; language while reading a source text in that
;;; langauge. The BNF contains generative instructions
;;; that directly generates machine code. This code can
;;; then be executed.
;;;
;;; Goals
;;; - be a "proper" subset of C
;;; - on actual machine 6502 compiler running on 6502
;;; - *minimal* size assembly code for BNF engine
;;; - fast "enough" to run "on a screen of code"
;;; - provide on-screen editor
;;; - "simple" rule-driven
;;; - many languages (just change rules)
;;; - have MINIMAL subset
;;; - have RULEOPT extentions for efficient codegen
;;; 
;;; NON-Goals:
;;; - not be the best super-optimizing compiler
;;; - not be the fastest
;;; 
;;; The MINIMAL C-language subset:
;;; - only support void, word (uint), byte (uchar)
;;; - word main() { ... }
;;; - return ...;
;;; - if () statement;
;;; - single letter global variables (no need declare)
;;; - decimal numbers: 4711 42
;;; - bin operators: + - *2 /2 & | ^ << >>
;;; - library to minimize gen code+rules (slowe code)
;;; 
;;; OPTIONAL:
;;; - I/O: getchar putc printd printh
;;; - else statement;
;;; - optimized: &0xff00 &0xff >>8 <<8
;;; - optimized: ++v; --v; += -= &= |= ^= >>=1; <<=1;
;;; - optimized: ... op const   ... op var
;;;   
;;; TODO:
;;; - { } blocks (BUGS: something lol)
;;; - hex numbers (alt to decimal?)
;;; - T F() { ... }
;;; - F() - function calls
;;; - parameters
;;; - recursion?
;;; 
;;; Extentions:
;;; - 42=>x+7=>y;     forward assignement
;;; - 35.sqr          single arg function call
;;; 
;;; Limits
;;; - only *unsigned* values
;;; - if supported ops/syntax should (mostly)
;;;   work the same on normal C-compiler
;;; - types aren't enforced
;;; - not using any extensions: same result
;;; - single lower case letter variable (TODO: fix)
;;; - single upper case letter functions (TODO: fix)
;;; - modifying ops cannot be used in expressions
;;; - NO parenthesis
;;; - NO priorities on * / (OK, deviates from C)
;;; - NO generic / or * (unless add library)




;;; STATS:

;;;                          asm rules
;;; MINIMAL   :   980 bytes = (+ 597  383) inc LIB!
;;; NORMAL    :  1098 bytes = (+ 597  501)
;;; OPTRULES  :  1418 bytes = (+ 597  821)
;;; LONGNAMES : 
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
;;;    554 bytes =>a+3=>c;
;;;    597 bytes FUNS: more %F and %f code

;;; TODO:  634 bytes ... partial long names (+ 141 B)

;;; not counting: printd, mul10, end: print out

;;; C-Rules: 469 B (- 593 56 68)
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

;;;   821 bytes = OPTRULES
;;;   501 bytes = NORMAL
;;;   383 bytes = MINIMAL (rules + library)


;;; TODO: not really rules...
;;;    56 B is table ruleA-ruleZ- could remove empty
;;;    68 B library printd/printh/putc/getchar
;;;         LONGNAMES: move to init data in env! "externals"
;;; TODO: 
;;;  ~256 B parameterize ops (gen)


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

;;; BNF capabilities
;;; 
;;; The BNF is very simplified and is interpreted
;;; using backtracking. It may be ambigious but first
;;; matching result is accepted. Can be seen as priorities.
;;; 
;;; In a BNF-rule
;;; - lower case letter is matched literally
;;; - a letter with hi-bit set ('R'+128) references
;;;   another rule that is matched by recursion
;;; - Rules can have alternatives: E= aa | a | b that are
;;;   tried in sequence.
;;; - %D - match sequence of digits (number: /\d+/ )
;;; 
;;; - %N - define NEW name (forward) TODO: 2x=>err!
;;; - %V - match "variable"
;;; - %A - (for assignment)
;;;        same as %V but stored in "dos" (and "tos")
;;;        (generative rule ':' will set tos=dos)
;;; 
;;; - %n - define NEW LOCAL
;;; - %v - match LOCAL USAGE of name


;;; Warning: The recursive rule matching is limited by
;;;   the hardware stack. (~ 256/6)


;;; [ GENERATIVE ]
;;; 
;;; The generative part of the rule may be invoked
;;; several times. Each one will generate code.
;;; 
;;; Note: There is no backtradking/reset of code
;;;       generated, so use with care!

;;; Inside the generative brackets normal *relative*
;;; 6502 asm is assumed to be used.
;;; 
;;; There are directives used that doesn't match
;;; any 6502 byte-codes, these come from this set
;;; of printable bytecodes.
;;;
;;;      "#'+2347:;<>?BCDGKOZ[\\]_bcdgkortwz{|
;;; 
;;; The following are used:
;;; 
;;;   ]   - ends the generation
;;;   <   - lo byte of last %D number matched
;;;   >   - hi byte         - " -
;;;   <>  - little endian 2 bytes of %D
;;;   +>  -       - " -           of %D+1
;;;         (actually + and next byte will be replaced)
;;;   :   - set %D value from %A(ssign)
;;; 
;;; NOTE: if any constant being used, such as
;;;       address of JSR/JMP (library?) or a
;;;       variable/#constant matches any of these
;;;       characters
;;; 
;;; NOTE2: This hasn't (?) happened yet, but we don't
;;;        test for it so we don't know.
;;; 
;;;        Hey it's a hack!
;;; 
;;; TODO: detect this and give assert error?
;;;       alt: parameterize any constants?


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


;;; Minimal set of rules (+ LIBRARY)
;MINIMAL=1

;;; Optimizing rules (bloats but fast!)
;;; 
;;; &0xff00 &0xff <<8 >>8 >>v <<v
;OPTRULES=1

;;; Pointers: &v *v= *v
;POINTERS=1

;;; testing data a=0, b=10, ... e=40, ...
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

;;; show input during parse \=backtrack
;;; Note: some chars are repeated at backtracking!
;SHOWINPUT=1

;;; print input ON ERROR (after compile)
;
PRINTINPUT=1

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
  out:    .res 2
;stateend:       

erp:    .res 2
env:    .res 2
valid:  .res 1

rulename:       .res 1

;;; stackframe for parameter start
pframe: 

.code

;;; parser
FUNC _init
;;; 21 B

        ldx #$ff
        txs

.ifdef DEBUG 
        putc 'S'
        putc 10
.endif ; DEBUG

        lda #<input
        sta inp
.ifdef ERRPOS
        sta erp
.endif
        lda #>input
        sta inp+1
.ifdef ERRPOS
        sta erp+1
.endif        
        lda #<output
        sta out
        lda #>output
        sta out+1

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

        lda #<ruleP
        sta rule
        lda #>ruleP
        sta rule+1

        ;; end-all marker
        lda #42
        pha

.ifdef DEBUGRULE
        jsr printstack
        jsr printstack
.endif

;;; TODO: but this doesn't work.... lol

.ifnblank
        lda #42
        sta rulename

        lda #'P'+128
        jmp _enterrule
.endif

;;; pause before as DEBUG scroll info away, lol
.ifdef DEBUGKEY
        jsr getchar
.endif ; NDEBUG

;;; TODO: move this to "the middle" then
;;;   can reach everything (?)
FUNC _next
;;; 16 B
        ldy #0
.ifdef DEBUG
;    PUTC ' '
    PUTC 10
    lda (rule),y
    jsr putchar
.endif ; DEBUG

;;; TODO: ;;;;;
.ifdef xDEBUGRULE
;    PUTC ' '
    PUTC 10
    lda (rule),y
    jsr putchar
.endif ; DEBUG
        lda (rule),y
        beq _acceptrule
        bmi _enterrule

;;; TODO: reorder
        ;; also end-rule
        cmp #'|'
        beq _acceptrule
        ;; gen-rule
        cmp #'['
;beq _generate
        bne testeq
        jmp _generate

testeq: 

.ifdef DEBUGRULE
    pha
    lda rulename
    jsr putchar
;    putc '.'
    lda (inp),y
    jsr putchar
    pla
.endif

.ifdef DEBUG
    pha
    PUTC ':'
    lda (inp),y
    jsr putchar
    pla
.else
  .ifdef SHOWINPUT
    pha
    lda (inp),y
    jsr putchar
    pla
  .endif
.endif ; DEBUG

        ;; lit eq?
        cmp (inp),y
;;; TODO:
;        bne _fail
        beq _eq

;;; %. handle special matchers
        cmp #'%'
        bne failjmp

        ;; special %?
        jsr _incR
        ldy #0
        lda (rule),y
        ;; assumes A not modified
        jsr _incR
;;; %D - digits
        cmp #'D'
        beq isdigits
isvar:    
        ;; % anything...
        ;; %V (or %W)
        jmp _var

failjmp:        
        jmp _fail

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
;;; 34 B
        ;; enter rule
        ;; - save current rulepos
    DEBC '>'
.ifdef DEBUGKEY
        jsr getchar
.endif ; DEBUG
        lda rule+1
        pha
        lda rule
        pha
        lda rulename
        pha

        ;; - load new rule
        lda (rule),y
        sta rulename
.ifdef DEBUGRULE
    PUTC ' '
    jsr putchar
    PUTC '>'
.endif
        and #31
        asl
        tay
        lda rules,y
        sta rule
        lda rules+1,y
        sta rule+1

        ;; - push inp for retries
        lda inp+1
        pha
        lda inp
        pha
        lda #'i'
        pha

.ifdef DEBUGRULE
    jsr printstack
.endif
        jmp _next
;;; TODO: use jsr, to know when to stop pop?
;;; (maybe don't need marker on stack?)


FUNC _acceptrule
;;; 19 B
    DEBC '<'
.ifdef DEBUGRULE
    putc '<'
.endif
@loop:
        ;; remove (all) re-tries
        pla
.ifdef DEBUGRULE
    pha
    jsr putchar
    jsr printstack
    pla
.endif
        bmi uprule
        ;; - done?
        cmp #42
        bne @skip
        jmp _donecompile
@skip:
        
        ;; 'p' - PATCH
        cmp #'p'
;;; TODO: now assumes it's 'i'
        bne @gotretry
    DEBC 'P'
        pla
        sta pos
        pla
        sta pos+1

        ;; patch to here!
        ldy #0
        lda out
        sta (pos),y
        iny
        lda out+1
        sta (pos),y

        jmp @loop

;;; 'i' - input restore and RETRY
@gotretry:
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
.ifdef DEBUGRULE
    PUTC '_'
.endif
    DEBC '_'
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
;;; TODO: test special matchers
;;;   %D - digits
;;;   %I - ident

;;; 25 B

.ifdef SHOWINPUT
        putc '\'
;        putc 10
.endif ; SHOWINPUT

    DEBC '|'
.ifdef DEBUGRULE
  putc 10
  putc '|'
  lda rule
  sta tos
  lda rule+1
  sta tos+1
  jsr printh
  putc ' '
.endif
        ;; - seek next alt in rule
@loop:
;        jsr _incR
        ldy #0
        lda (rule),y
        beq endrule

;;; TODO: remove! this only catches
;;;    bad memory location!!!! lol
;;;    shows address for "bad" byte
.ifdef DEBUGRULE
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
    DEBC ','

        ;; skip any inline gen
        cmp #'|'
        beq @nextalt
        cmp #'['
        bne @notgen
@skipgen:
    DEBC ';'
        jsr _incR
        lda (rule),y
        cmp #']'
        bne @skipgen
        jmp @loop

@notgen:
        jsr _incR
        bne @loop

@nextalt:
        ;; try next alterantive
        ;; - move after '|'
        jsr _incR

restoreinp:
        ;; - restore inp
        pla
        pha
;;; TODO: correct jump? is it error?
;;;  (means? still have input?)
;        bmi gotendall
        bmi gotrule
        cmp #42
        beq _donecompile

;;; TODO: assume it's 'I'? (how about is patch?)

;;; TODO: at failure... need to get out fast???
;;; TODO: not active!!!!
.ifnblank
;;; TODO: Why this interferes with simple ???
        cmp #'i'
        beq gotretry
;;; otherwise - error
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
        ;; copy/restore inp from stack
        tsx
        pla
        pla
        sta inp
        pla
        sta inp+1
        txs
        jmp _next


endrule:
.ifdef DEBUGRULE
   putc 'E'
   jsr printstack
.endif

	;; END - rule
    DEBC 'E'
;.ifdef DEBUG
;    putc '.'
;.endif

;;; TODO: is this always like this?
;;;  (how about patch?)

;;; TODO: lol wtf?
     pla

        ;; nothing to backtrack
        ;; - get rid of retry
        pla
.ifdef DEBUGRULE
putc '/'
jsr putchar
.endif
        pla
        pla

        ;; - get rid of current rule
        pla
.ifdef DEBUGRULE
putc '/'
jsr putchar
.endif
        pla
        pla

        jmp uprule


_donecompile:   
.ifdef DEBUGRULE
        jsr printstack
.endif
        jmp _aftercompile


;;; ERRORS

FUNC _errors
;;; 25 B

illegalvar:     
        lda #'I'
        SKIPTWO
gotendall:
        lda #'E'
        SKIPTWO
failrule:
        lda #'Z'
        SKIPTWO
failed:   
        lda #'F'
        SKIPTWO
gotrule:
        lda #'X'
        ;; fall-through to error
error:
        pha
        putc 10
        putc '%'
        pla
        jsr putchar

        jmp _aftercompile
halt:
        jmp halt

FUNC _var
;;; 42 B
DEBC '$'
        sta vrule
        ldy #0
        lda (inp),y
.ifnblank
PUTC ':'
jsr putchar
.endif

@global:
        ;; verify/parse single letter var
        sec
        sbc #'A'
        cmp #'z'-'A'+1
        bcc @skip2
        jmp failjmp
@skip2:

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

        ;; defining function/variable
        ;; (TODO: if used for var they are inline code)
        lda vrule
        cmp #'F'
        bne @nodef
        ;; - *FUN = out // *tos= out
        ldy #0
        lda out
        sta (tos),y
        iny
        lda out+1
        sta (tos),y

        jmp @set
@nodef:
        ;; if call function
        cmp #'C'
        bne @nofun
        ;; - tos = *tos
        ldy #1
        lda (tos),y
        tax
        dex
        lda (tos),y

        ;; TODO: push to auto-gen funcall?!
.ifnblank
        ;; hi
        lda (tos),1
        pha
        lda (tos),0
        pha
        lda #'f'
        jmp _next
.endif

        ;; for now just dos= tos= *tos
;;; TODO: means inline assignment will f-up!
        sta tos
        stx tos+1
        jmp @set
@nofun:
        
        ;; - is assignment? => set dos
        ;; vrule='A' >>1 => C=1
        ;;       'V' >>1 => C=0
        ror vrule
        bcc @noset
        ;; - do set dos
@set:
        lda tos
        sta dos
        lda tos+1
        sta dos+1
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



FUNC _generate
;;; ??? 19 B

;;; TODO: can conflict w data

        jsr _incR
        ldy #0
        lda (rule),y

;;; '] - END GEN
        cmp #']'
        bne @skip
DEBC ']'
        jsr _incR
        jmp _next
@skip:   
;;; '<' LO %d
        cmp #'<'
        bne @skip2
DEBC '<'
        lda tos
        jmp @doout
@skip2: 
;;; '>' HI %d
        cmp #'>'
        bne @skip3
DEBC '>'
        lda tos+1
        jmp @doout

@skip3:
;;; ':' SET tos=dos
        cmp #':'
        bne @skip4
DEBC ':'
        lda dos
        sta tos
        lda dos+1
        sta tos+1
        jmp _generate

@skip4:  
;;; '{{' PATCH
        cmp #'{'
        bne @skip5
DEBC '{'
        lda out+1
        pha
        lda out
        pha
        lda #'p'
        pha
        jsr _incO
        jsr _incR
        jsr _incO
        jmp _generate

@skip5: 
        cmp #'+'
        bne @skip6
;;; "=" PUT %d+1
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
        sta (out),y
        txa
        jsr _incO
        jsr _incR
@skip6:

@doout:
        sta (out),y
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




FUNC _incIspc
;;; 14 B
        pha
@skipspc:
        jsr _incI
        lda (0,x)
        beq @done
        cmp #' '+1
        bcc @skipspc
@done:

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
        ;; erp := inp
@update:
        sta erp
        lda inp+1
        sta erp+1
@noupdate:
.endif

        pla
        rts

FUNC _incP
;;; 3
        ldx #pos
        SKIPTWO
FUNC _incO
;;; 3
        ldx #out
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
        ;; - zero out value
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

PRINTDEC=1
PRINTHEX=1
.include "print.asm"

bytecodes:      

;;; ========================================
;;; START rules


;;; Rules 0,A-
rules:  
        .word rule0             ; TODO: if we use &and?
        .word ruleA,ruleB,ruleC,ruleD,ruleE
        .word ruleF,ruleG,ruleH,ruleI,ruleJ
        .word ruleK,ruleL,ruleM,ruleN,ruleO
        .word ruleP,ruleQ,ruleR,ruleS,ruleT
        .word ruleU,ruleV,ruleW,ruleX,ruleY
        .word ruleZ
        .word 0                 ; TODO: needed?

;;; How to access value of variable!
VAL0= '<' + 256*'>'
VAL1= '+' + 256*'>'

PUSHLOC= '{' + 256*'{'

rule0:
ruleG:
ruleH:  
ruleI:
ruleJ:  
.ifndef BNFLONG
  ruleK:  
  ruleL:  
ruleM:  
ruleN:  
.endif 
ruleO:  

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

;;; aggregate statements
ruleA:  
        ;; Right-recursion is "fine"
        .byte _S,_A,"|",0

;;; Block
ruleB:  
;;; TODO: empty?
        .byte "{}"
        .byte "|{",_A,"}"

        .byte 0
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

        .byte "|putc(",_E,")"
      .byte '['
        jsr putchar
      .byte ']'

        .byte "|getchar()"
      .byte '['
        jsr getchar
        ldx #0
      .byte ']'


.ifdef FUNS
        ;; function call
        .byte "|%F()"
      .byte '['
        jsr VAL0
        ;; result in AX
      .byte ']'

        ;; EXTENTION
        ;; .method call! - LOL
        .byte "|.%F"
      .byte '['
        ;; parameter already in AX
        jsr VAL0
        ;; result in AX
      .byte ']'
.endif ; FUNS

;.ifndef MINIMAL
.ifnblank
;;; TODO: need to have a PUSH ':' and a POP ';' ???
;;; reverse meaning from now   ^   REVERSE   ^  !!!
        .byte "|++%A"
      .byte "[:"
        .byte "|--%A"

.endif ; !MINIMAL

.ifdef POINTERS
        .byte "|&%V"
      .byte '['
        lda #'<'
        ldx #'>'
      .byte ']'

        .byte "|*%V"
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

.endif ; MINIMAL

        ;; variable
        .byte "|%V"
      .byte '['
        lda VAL0
        ldx VAL1
      .byte ']'

        .byte "|%D"
      .byte '['
        lda #'<'
        ldx #'>'
      .byte ']'

        .byte 0

.ifdef MINIMAL
;;; Just save (TODO:push?) AX
ruleU:
      .byte '['
        jsr _SAVE
      .byte ']'
        .byte _C
        .byte 0
.endif

;;; aDDons (::= op %d | op %V)

ruleD:

        ;; 7=>A; // Extention to C:
        ;; Forward assignment 3=>a; could work! lol
        ;; TODO: make it multiple 3=>a=>b+7=>c; ...
        .byte "=>%A"
      .byte "[:"
        sta VAL0
        stx VAL1
      .byte "]"
        .byte _D

.ifdef MINIMAL

        .byte '|','+',_U
      .byte '['
        jsr _PLUS
      .byte ']'
        .byte _D

        .byte '|','+',_U
      .byte '['
        jsr _MINUS
      .byte ']'
        .byte _D

        .byte '|','&',_U
      .byte '['
        jsr _AND
      .byte ']'
        .byte _D

        .byte '|',"\|",_U
      .byte '['
        jsr _OR
      .byte ']'
        .byte _D

        .byte '|','^',_C
      .byte '['
        jsr _EOR
      .byte ']'
        .byte _D

        .byte "|/2"
      .byte '['
        jsr _SHR
      .byte ']'
        .byte _D

        .byte "|*2"
      .byte '['
        jsr _SHL
      .byte ']'
        .byte _D

;;; ==

        .byte "|==",_U
      .byte '['
        jsr _EQ
      .byte ']'
        .byte _D

        ;; Empty
        .byte '|'


.else ; !MINIMAL

        .byte "|+%V"
      .byte '['
        clc
        adc VAL0
        tay
        txa
        adc VAL1
        tax
        tya
      .byte ']'
        .byte _D

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
        .byte _D

;;; 18 *2
        .byte "|-%D"
      .byte '['
        sec
        sbc VAL0
        tay
        txa
        sbc VAL1
        tax
        tya
      .byte ']'
        .byte _D

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
        .byte _D

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
        .byte _D

.ifdef OPTRULES
        .byte "|&0xff00"
      .byte '['
        lda #0
      .byte ']'
        .byte _D

        .byte "|&0xff"
      .byte '['
        ldx #0
      .byte ']'
        .byte _D
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
        .byte _D

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
        .byte _D

        .byte "|\|%D"
      .byte '['
        ora #'<'
        tay
        txa
        ora #'>'
        tax
        tya
      .byte ']'
        .byte _D
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
        .byte _D

        .byte "|^%D"
      .byte '['
        eor #'<'
        tay
        txa
        eor #'>'
        tax
        tya
      .byte ']'
        .byte _D

;;; 24
        
        .byte "|/2"
      .byte '['
        tay
        txa
        lsr
        tax
        tya
        ror
      .byte ']'
        .byte _D

        .byte "|*2"
      .byte '['
        asl
        tay
        txa
        rol
        tax
        tya
      .byte ']'
        .byte _D

.ifdef OPTRULES
        .byte "|>>8"
      .byte '['
        txa
        ldx #0
      .byte ']'
        .byte _D

        .byte "|<<8"
      .byte '['
        tax
        lda #0
      .byte ']'
        .byte _D
        
        .byte "|<<%D"
      .byte '['
        sta tos
        stx tos+1
        ldy #'<'
:       
        dey
        bmi :+
        
        asl tos
        rol tos+1

        sec
        bcs :-
:       
        lda tos
        ldx tos+1
      .byte ']'
        .byte _D

        .byte "|>>%D"
      .byte '['
        sta tos
        stx tos+1
        ldy #'<'
:       
        dey
        bmi :+
        
        lsr tos+1
        ror tos

        sec
        bcs :-
:       
        lda tos
        ldx tos+1
      .byte ']'
        .byte _D
.endif ; OPTRULES

;;; ==

        .byte "|==%V"
      .byte '['
        ;; 15
        ldy #0
        cmp VAL0
        bne @neqv
        cpx VAL1
        bne @neqv
        ;; eq => -1
        dey
        ;; neq => 0
@neqv:
        tya
        tax
      .byte ']'
        .byte _D

        .byte "|==%D"
      .byte '['
        ;; 13
        ldy #0
        cmp #'<'
        bne @neqd
        cpx #'>'
        bne @neqd
        ;; eq => -1
        dey
        ;; neq => 0
@neqd:
        tya
        tax
      .byte ']'
        .byte _D

        ;; Empty
        .byte '|'

.endif ; MINIMAL

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


;;; Program
ruleP:  

.ifndef FUNS

.ifdef LONGNAMES
        .byte _T,"%N()",_B
.else
        .byte _T,"main()",_B
.endif ; LONGNAMES
      .byte '['
        rts
      .byte ']'

;      .byte '|'

.else ; FUNS

        .byte _F
      .byte '['
        PUTC 'M'

        ;; TODO: put in main B()
;        jsr output+10-3         ; MMMM
        ;; prints F but not 'f'
;;; TODO: install disasm function...
        jsr output+17

        PUTC 'E'
        rts
      .byte ']'
.endif ; FUNS

        .byte 0
        ;; patches jmp to ehere!

;;; Type
ruleT:  
;;; TODO: don't use int/char as they can be SIGNED!
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
        .byte ':'
        jsr VAL0
;;; TODO: assuming there is no other assignement \%A
;;;       in parsing List of parameters... LOL (push/pop?)
;;; TODO: if we add push operator we can do reordering?
      .byte ']'
        .byte 0

.endif ; BNFLONG


;;; Statement
ruleS:
        ;; BlOCK!
;        .byte _B

        ;; RETURN
;        .byte "|return",_E,";"
        .byte "return",_E,";"

      .byte '['
        rts
      .byte ']'

;;; FAILS - forever!
;        .byte '|',_B
;;; works
        .byte "|{}"
;;; FAILS - forever!
;        .byte "|{",_A,"}"
;;; works
        .byte "|{",_S,"}"
;;; FAILS - forever!
        .byte "|{",_S,_S,"}"


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

        ;; IF(E)S; // no else
        .byte "|if(",_E,")"
      .byte '['
        ;; 9B 9-11c
        stx savex
        ora savex
        bne :+
        jmp PUSHLOC
:       
        ;; THEN-branch
      .byte ']'
;;; TODO: move these rules out to another rule
;;;    then don't need to repeat this one!
        .byte _S
.ifdef OPTRULES
        ;; for ELSE, make sure value not 0!
      .byte '['
        lda #$ff
      .byte ']'
.endif ; OPTRULES
        ;; Auto-patches at exit!

.ifdef OPTRULES
        ;; ELSE
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
.endif ; OPTRULE

.ifdef OPTRULES
;;; TODO make ruleC when %A pushes
        .byte "|++%A;"
      .byte "[:"
        inc VAL0
        bne :+
        inc VAL1
:       
      .byte "]"

;;; TODO make ruleC when %A pushes
        .byte "|--%A;"
      .byte "[:"
        lda VAL0
        bne :+
        dec VAL1
:       
        dec VAL0
      .byte "]"

        ;; NOTE: no need provide: v op= const;
        ;;       - it would wouldn't save any bytes!
        .byte "|%A+=",_E,";"
      .byte "[:"
        clc
        adc VAL0
        sta VAL0
        txa
        adc VAL1
        sta VAL1
      .byte "]"

        .byte "|%A-=",_E,";"
      .byte "[:"
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
      .byte "[:"
        and VAL0
        sta VAL0
        txa
        and VAL1
        sta VAL1
      .byte "]"

        .byte "|%A\|=",_E,";"
      .byte "[:"
        ora VAL0
        sta VAL0
        txa
        ora VAL1
        sta VAL1
      .byte "]"

        .byte "|%A^=",_E,";"
      .byte "[:"
        eor VAL0
        sta VAL0
        txa
        eor VAL1
        sta VAL1
      .byte "]"

        .byte "|%A>>=1;"
      .byte "[:"
        lsr VAL1
        ror VAL0
      .byte "]"

        .byte "|%A<<=1;"
      .byte "[:"
        asl VAL0
        ror VAL1
      .byte "]"

.endif ; OPTRULES

        ;; A=7; // simple assignement, ONLY as statement
        ;; and can't be nested or part of expression
        ;; (unless we use a stack...)
        .byte "|%A=",_E,";"
      .byte "[:"                ; ':' => tos=dos
        sta VAL0
        stx VAL1
      .byte "]"

.ifdef POINTERS
        .byte "|*%A=",_E,";"
      .byte "[:"
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

        .byte "|",_E,";"

        ;; empty statement is legal
        .byte "|;"

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

;;; TODO: printz
        putc 10
        putc '6'
        putc '5'
        putc 'm'
        putc 'u'
        putc 'c'
        putc 'c'
        putc '0'
        putc '2'
        putc 10

        ;; failed?
        ;; (not stand at end of source)
        ldy #0
        lda (inp),y
        beq @OK

.ifdef ERRPOS
        ;; hibit string near error!
        ;; (approximated by 
        ldy #0
        lda (erp),y
        ora #128
        sta (erp),y
.endif ; ERRPOS
        ;; print it
       
.ifdef PRINTINPUT
;;; TODO: printz? printR?
        putc 10

        lda #<input
        sta pos
        lda #>input
        sta pos+1
        jmp @print
@loop:
.ifdef ERRPOS
        ;; hi-bit set indicate error position
        bpl @nohi
        pha
        lda #1+128              ; red text
        jsr putchar
        pla
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

        jmp halt
;        jmp failed
;;; LOOPS: lol


@OK:
        putc 10
        putc 'O'
        putc 'K'
        putc ' '

        ;; print size in bytes
        sec
        lda out
        sbc #<output
        sta tos
        lda out+1
        sbc #>output
        sta tos+1
        
        jsr printd
        putc 'B'
        putc 10
        putc 10

        jsr output
        sta tos
        stx tos+1
        putc 10
        putc '='
        putc '>'
        putc ' '

        ;; prints tos
        jsr printd
        putc 10
        
        jmp halt


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
        jsr putchar
        putc ' '
        putc 's'

        ;; print S
        stx tos
        lda #0
        sta tos+1
        jsr printd

@loop:
        putc ' '
        ;; print first byte

        lda $101,x

        and #127
        cmp #' '
        bcs @noctrl
        ;; ctrl
        sta tos
        lda #0
        sta tos+1
        jsr printd
        lda #':'
@noctrl:

        jsr putchar
        inx
        beq @err

        ;; end marker?
.ifnblank
        lda tos
        cmp #42
        beq @done
.endif        
        putc ' '
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

        jmp @loop

@err:
        putc ' '
        putc ' '
        putc 'o'
        putc 'o'
        
@done:
        putc '>'
        jsr getchar
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
;;;   typedef unsigned int  word;
;;;   typedef unsigned char byte;
;;; 
input:
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


        .byte "void A(){putc(102);}",0

        .byte "word main(){putc(102);}",0

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

docs:   
        .byte "C-Syntax: { a=...; ... return ...; }",10
        .byte "C-Ops   : *2 /2 + - ==", 10
        .byte "C-Vars  : a= ... ; ... =>a;", 10

.endif ; INCTESTS


vars:
;        .res 2*('z'-'a'+2)
;;; TODO: remove (once have long names)
.ifdef TESTING
;;; FUNS A-Z
        .word 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        .word 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
;;; VARS a-z
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


output:
        ;; fill with RTS - "safer"
;        _RTS=$60
;        .res 8*1024, _RTS

;;; Some variants save on codegen by using a library

;;; LIBRARY

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
