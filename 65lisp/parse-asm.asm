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



;;; STATS:

;;; TOTAL: 1010 bytes = (+ 631 379)
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
;;; TODO:  634 bytes ... partial long names (+ 141 B)



;;; not counting: printd, mul10, end: print out

;;; C-Rules: (52 bytes is table a-z)
;;; 
;;;    71 bytes - voidmain(){return4711;}
;;;   112 bytes - ...return 8421*2; /2, +, -
;;;   124 bytes - ...return e+12305;
;;;   128 bytes -           1+2+3+4+5
;;;   262 bytes - +-&|^ %V %D == ... 
;;;   364 bytes - int,table,recurse,a=...; ...=>a; statements
;;;   379 bytes - IF(E)S;   (+ 17B)
;;; 
;;; TODO: parameterize the ops?
;;; TODO: jsr ... lol

;;;
;;; If there is an error a newline '%' letter error-code
;;; is printed.

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


;;; Long names support
;;; TODO: make functional
;LONGNAMES=1

;;; TODO: not yet done, just thinking
;BNFLONG=1

;;; Enable for debug info
;DEBUG=1

;;; wait for input on each new rule invocation
;DEBUGKEY=1

;
DEBUGRULE=1

;;; show input during parse \=backtrack
;;; Note: some chars are repeated at backtracking!
;SHOWINPUT=1

;;; print input (after compile)
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
        lda #<ruleP
        sta rule
        lda #>ruleP
        sta rule+1

        ;; end-all marker
        lda #128
        pha

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
        lda #0                  ; rule-mark
        pha

        ;; - load new rule
        lda (rule),y
.ifdef DEBUGRULE
    pha
    putc ' '
    pla
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
        lda #'I'
        pha

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
        ;; - remove (all) re-tries
        pla
        beq uprule
;;; TODO: too far
        bpl @skip
        jmp _donecompile
@skip:
        
;;; 2 - PATCH
        cmp #2
;;; TODO: assumes it's 'I''
        bne @gotretry
    DEBC '}'
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

;;; 1 - RETRY
@gotretry:
;        jsr putchar
    DEBC '.'
.ifdef DEBUGRULE
    putc '.'
.endif
        pla
        pla
        jmp @loop

;;; 0 - RULE
uprule: 
.ifdef DEBUGRULE
    putc '_'
.endif
    DEBC '_'
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
        jsr _printd
        putc 10
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
.endif
        ;; - seek next alt in rule
@loop:
        jsr _incR
        ldy #0
        lda (rule),y
        beq endrule

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
   jsr _printd
   pla
@after:
.endif
    DEBC ','

        ;; skip any inline gen
        cmp #'['
        bne @notgen
@skipgen:
    DEBC ';'
        jsr _incR
        lda (rule),y
        cmp #']'
        bne @skipgen
        
@notgen:
        cmp #'|'
        bne @loop

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
        bmi _donecompile
        beq gotrule

;;; TODO: assume it's 'I'? (how about is patch?)

;;; TODO: at failure... need to get out fast???
;;; TODO: not active!!!!
.ifnblank
;;; TODO: Why this interferes with simple ???
        cmp #'I'
        beq gotretry
;;; otherwise - error
gotpatch:       
        lda #'P'
        jmp error
.endif

gotretry:
.ifdef DEBUGRULE
    putc '!'
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
	;; END - rule
    DEBC 'E'
;.ifdef DEBUG
;    putc '.'
;.endif

;;; TODO: is this always like this?
;;;  (how about patch?)

        ;; nothing to backtrack
        ;; - get rid of retry
        pla
        pla
        pla
        ;; - get rid of current rule

        pla
        pla
        pla

        jmp uprule


_donecompile:   
        jmp aftercompile


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
halt:
        jmp halt

FUNC _var
DEBC '$'
        sta vrule
        ldy #0
        lda (inp),y

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


@global:
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

        ;; vrule='A' >>1 => C=1
        ;;       'V' >>1 => C=0
        ror vrule
        bcc @noset
        ;; set dos
        sty dos
        sta dos+1
@noset:
        ;; skip read var char
        jsr _incIspc
        jmp _next
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
        lda #2
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
        tay
        bne @noinc
        inx
@noinc:
        ;; put
        ldy #0
        sta (out),y
        txa
        pha
        jsr _incO
        jsr _incR
        pla
        iny
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
;;; TODO: this gives memory corruption?
        ;; lool space delim numbers
;        jsr _incIspc
        jsr _incI
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

;;; BEGIN CHEAT? - not count...

;PRINTHEX=1                     
PRINTDEC=1
.include "print.asm"


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

FUNC aftercompile

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

        jsr putchar

        jsr _incP
@print:
        ldy #0
        lda (pos),y
        bne @loop

        putc 10
.endif ; PRINTINPUT

        jmp failed


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

FUNC _dummy4

;;; END CHEAT?


  .res 256-(* .mod 256)
secondpage:     

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
ruleF:
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
ruleU:  
ruleV:  
ruleW:  
ruleX:  
ruleY:  
ruleZ:  
        .byte 0

;;; aggregate statements
ruleA:  
        ;; Right-recursion is "fine"
        .byte 'S'+128,'A'+128,"|",0

;;; Block
ruleB:  
;;; TODO: empty?
        .byte "{}"
        .byte "|{",'A'+128,"}"
        .byte 0

;;; "Constant"/(variable) (simple, lol)
ruleC: 

;.ifnblank
;        .byte "%v"
;n      .byte '['
;        ldy sframe
;;;; requires zero page wrap around
;        ldx '<',y              
;        dey
;        lda '<',y
;      .byte ']'
;
;        .byte "|%V"
;.else
;        .byte "%V"
;.endif

        .byte "%V"
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

;;; aDDons (::= op %d | op %V)
ruleD:

;;; TODO: %V before %D (otherwise not working)
        .byte "+%V"
      .byte '['
        clc
        adc VAL0
        tay
        txa
        adc VAL1
        tax
        tya
      .byte ']'
        .byte 'D'+128

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
        .byte 'D'+128

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
        .byte 'D'+128

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
        .byte 'D'+128

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
        .byte 'D'+128

        .byte "|&%D"
      .byte '['
        and #'<'
        tay
        txa
        and #'>'
        tax
        tya
      .byte ']'
        .byte 'D'+128

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
        .byte 'D'+128

        .byte "|\|%D"
      .byte '['
        ora #'<'
        tay
        txa
        ora #'>'
        tax
        tya
      .byte ']'
        .byte 'D'+128
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
        .byte 'D'+128

        .byte "|^%D"
      .byte '['
        eor #'<'
        tay
        txa
        eor #'>'
        tax
        tya
      .byte ']'
        .byte 'D'+128

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
        .byte 'D'+128

        .byte "|*2"
      .byte '['
        asl
        tay
        txa
        rol
        tax
        tya
      .byte ']'
        .byte 'D'+128

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
        .byte 'D'+128

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
        .byte 'D'+128


        .byte "|"
        .byte 0

;;; Exprssion:
ruleE:  
        .byte 'C'+128,'D'+128,0

;;; Program
ruleP:  

.ifdef LONGNAMES
        .byte 'T'+128,"%N()",'B'+128
.else
        .byte 'T'+128,"main()",'B'+128
.endif ; LONGNAMES
      .byte '['
        rts
        ;; TODO: HOWTO? maybe conflic with 'putchar'
      .byte ']'
        .byte 0

;;; Type
ruleT:  
        .byte "int|char|void",0

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
        'L'+128,")";"
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
;        .byte 'B'+128

        ;; RETURN
;        .byte "|return",'E'+128,";"

;        .byte "return",'E'+128,";"
        .byte "return",'E'+128,";"
      .byte '['
        rts
      .byte ']'

        ;; IF(E)S; // no else
        .byte "|if(",'E'+128,")"
      .byte '['
        stx savex
        ora savex
        bne @skipjmp
        jmp PUSHLOC
@skipjmp:
      .byte ']'
        .byte 'S'+128
        ;; Auto-patches at exit!


        ;; A=7; // simple assignement, ONLY as statement
        ;; and can't be nested or part of expression
        ;; (unless we use a stack...)
        .byte "|%A=",'E'+128,";"
      .byte "[:"                ; ':' => tos=dos
        sta VAL0
        stx VAL1
      .byte "]"

        ;; 7=>A; // Extention to C:
        ;; Forward assignemenbt 3=>a; could work! lol
        ;; TODO: make it multiple 3=>a=>b+7=>c; ...
        .byte "|",'E'+128,"=>%A;"
      .byte "[:"
        sta VAL0
        stx VAL1
      .byte "]"

        ;; empty statement is legal
        .byte "|;"

        .byte 0

;;; END rules
;;; ========================================

.include "end.asm"


;;; TODO: make it point at screen,
;;;   make a OricAtmosTurboC w fullscreen edit!
input:

;; WRONG result - should be 1, error introduced w LONGNAMES (do diff?)
        .byte "int main(){ return e; }",0
        .byte "int main(){ a=99; if(0) a=10; a=a+1; return a;}",0
;;; OK 11
        .byte "int main(){ if(1) a=10; a=a+1; return a;}",0

;;; OK 
        .byte "int main(){return 4711;}",0

;;; syntax error highlight!
;        .byte "int main(){ if(1) a=10x; a=a+1; return a;}",0


;;; ERROR
        .byte "int main(){ if(1) { return 33; } a=a+1; return a;}",0


;;; OK (w S not = B | )
        .byte "int main(){ if(0) return 33; return 22; }",0
        .byte "int main(){ if(1) return 33; return 22; }",0



;;; FAIL
        .byte "int main(){ if(1) { a=e+50; return a; } a=a+1; return a;}",0
;;; FAIL
        .byte "int main(){ if(0) { a=e+50; return a; } a=a+1; return a;}",0
;;; FAIL
        .byte "int main(){ if(1) { a=89; return a; } a=a+1; return a;}",0


        .byte "int main(){ if(1) return 99; a=a+1; return a;}",0
        .byte "int main(){ if(1) a=10; a=a+1; return a;}",0
        .byte "int main(){ if(0) a=10; a=a+1; return a;}",0



        .byte "int main(){ a=2005*2; a=a+700; return a+1; }",0

;;; WRONG
        .byte "int main(){ a=2005*2; b=84; a=a+700; a=b/2+a; return a+1; }",0

;;; OK
        .byte "int main(){ a=99; a=a+1; a=a+100; return a+1; }",0

;;; TODO: somehow this gives garbage and jumps wrong!
;;;  (stack messed up?)

;;; FAILS
        .byte "intmain(){return e==40;}",0
;;; FAILS
        .byte "intmain(){return 42==42;}",0


;;; OKAY:
        .byte "intmain(){a=42;return a+a;}",0
        .byte "intmain(){42=>a;return a+a;}",0
        .byte "intmain(){return 40==e;}",0
        .byte "intmain(){return e==e;}",0
        .byte "intmain(){return e+e;}",0
        .byte "intmain(){a=99;a=a+1;return a+1;}",0
        .byte "intmain(){a=99;return 77;}",0
        .byte "intmain(){return 4711;}",0
        .byte "intmain(){a=99;return a+1;}",0
        .byte "voidmain(){a=99;}",0
        .byte "intmain(){return 1+2+3+4+5;}",0
;        .byte "intmain(){return 42==e;}",0
        .byte "intmain(){return e+12305;}",0
        .byte "intmain(){return e;}",0
        .byte "intmain(){return 4010+701;}",0
        .byte "intmain(){return 8421*2;}",0
        .byte "intmain(){return 8421/2;}",0
        .byte "intmain(){return 4711;}",0
;;; garbage (OK)
        .byte "voidmain(){}",0

docs:   
        .byte "C-Syntax: { a=...; ... return ...; }",10
        .byte "C-Ops   : *2 /2 + - ==", 10
        .byte "C-Vars  : a= ... ; ... =>a;", 10

vars:
;        .res 2*('z'-'a'+2)
;;; TODO: remove (once have long names)
        ;;    a  b  c  d  e  f  g  h  i  j
        .word 0,10,20,30,40,50,60,70,80,90
        .word 100,110,120,130,140,150,160,170
        .word 180,190,200,210,220,230,240,250,260




defs:   

;;; test example
;;; TODO: remove?
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

output:
        ;; fill with RTS - "safer"
        _RTS=$60
        .res 8*1024, _RTS


.end
