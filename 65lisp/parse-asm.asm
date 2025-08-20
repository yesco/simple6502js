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

;;; TOTAL: 802 bytes = (+ 438 364)
;;; 
;;;    193 bytes backtrack parse w rule
;;;    239 bytes codegen with []
;;;    349 bytes codegen <> and  (+25 +36 mul10 digits)
;;;    450 bytes codegen +> and vars! (+ 70 bytes)
;;;    424 bytes codegen : %V %A fix recurse
;;;         ( moved out bunch of stuff - "not counting" )
;;;    438 bytes skip spc (<= ' ') on input stream!
;;;        (really 404? ... )

;;; not counting: printd, mul10, end: print out

;;; C-Rules: (52 bytes is table a-z)
;;; 
;;;    71 bytes - voidmain(){return4711;}
;;;   112 bytes - ...return 8421*2; /2, +, -
;;;   124 bytes - ...return e+12305;
;;;   128 bytes -           1+2+3+4+5
;;;   262 bytes - +-&|^ %V %D == ... 
;;;   364 bytes - int,table,recurse,a=...; ...=>a; statements
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
;;; - %V - match "variable" (name: /[A-Z_][a-z_\d]*/ )
;;; - %A - (for assignment)
;;;        same as %V but stored in "dos" (and "tos")
;;;        (generative rule ':' will set tos=dos)

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

;PRINTHEX=1                     
PRINTDEC=1
.include "print.asm"


;;; ========================================
;;;                  M A I N

.macro SKIPONE
        .byte $24               ; BITzp 2 B
.endmacro

.macro SKIPTWO
        .byte $2c               ; BITabs 3 B
.endmacro


;;; Enable for debug info
;DEBUG=1

;;; show input during parse \=backtrack
;;; Note: some chars are repeated at backtracking!
;SHOWINPUT=1

;;; print input (after compile)
;
PRINTINPUT=1

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

;;; if %V or %A stores 'V' or 'A'
;;; 'A' for assigment
vrule:  .res 1


;;; not pushing all
;state:  
  rule:   .res 2
  inp:    .res 2
  out:    .res 2
;stateend:       
        



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
        lda #>input
        sta inp+1
        
        lda #<output
        sta out
        lda #>output
        sta out+1

;;; TODO: improve using 'P'
        lda #<ruleP
        sta rule
        lda #>ruleP
        sta rule+1

        ;; end-all marker
        lda #128
        pha

;;; pause before as DEBUG scroll info away, lol
.ifdef DEBUG
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
        cmp #'%'
        bne _fail
        ;; special %?
        jsr _incR
        ldy #0
        lda (rule),y
        ;; assumes A not modified
        jsr _incR

        cmp #'D'
        beq isdigits
isvar:    
        ;; % anything...
        ;; %V (or %W)
        jmp _var
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
.ifdef DEBUG
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
@loop:
        ;; - remove (all) re-tries
        pla
        beq uprule
        bmi _endall
@gotretry:
;        jsr putchar
    DEBC '.'
        pla
        pla
        jmp @loop

uprule: 
    DEBC '_'
        pla
        sta rule
        pla
        sta rule+1

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
        ;; - seek next alt in rule
@loop:
        jsr _incR
        ldy #0
        lda (rule),y
        bne @notend
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

@notend:

        ;; skip any inline gen
        cmp #'['
        bne @notgen
@skipgen:
        jsr _incR
        lda (rule),y
        cmp #']'
        bne @skipgen
        
@notgen:
        cmp #'|'
        bne @loop

        ;; - move after '|'
        jsr _incR

@done:
        ;; - restore inp
        pla
        pha
        bmi gotendall
        beq gotrule

gotretry:
    DEBC '!'
        ;; copy from stack
        tsx
        pla
        pla
        sta inp
        pla
        sta inp+1
        txs
        jmp _next


_endall:        
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
.ifdef DEBUG
  jsr putchar        
.endif ; DEBUG
        sec
        sbc #'a'
        cmp #'z'-'a'+1
        bcs _fail

        ;; pick global address
        asl
        adc #<vars
;;; TODO: dos and tos??? lol
;;;    good for a+=5; maybe?
        sta tos
        tay
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


FUNC _generate
;;; ??? 19 B
        jsr _incR
        ldy #0
        lda (rule),y
;;; TODO: can conflict w data
        cmp #']'
        bne @skip
        ;; continue rule parse
DEBC ']'
        jsr _incR
        jmp _next
@skip:   

        cmp #'<'
        bne @skip2
DEBC '<'
        lda tos
        jmp @doout
@skip2: 

        cmp #'>'
        bne @skip3
DEBC '>'
        lda tos+1
        jmp @doout

@skip3:
        cmp #':'
        bne @skip4
DEBC ':'
        lda dos
        sta tos
        lda dos+1
        sta tos+1
        jmp _generate

@skip4:  
        cmp #'+'
        bne @skip5
;;; put word+1
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
@skip5:

@doout:
        sta (out),y
        jsr _incO
        jmp _generate

failjmp:        
        jmp _fail


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
        bcs failjmp

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
        pla
        rts

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
        

;;; dummy
_drop:  rts

FUNC _dummy

        
;;;                  M A I N
;;; ========================================

endfirstpage:        

;;; BEGIN CHEAT? - not count...

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

.ifdef PRINTINPUT
        putc 10

        lda #<input
        sta inp
        lda #>input
        sta inp+1
        jmp @print
@loop:
        jsr putchar
        jsr _incI
@print:
        ldy #0
        lda (inp),y
        bne @loop

        putc 10
.endif ; PRINTINPUT

;;; 
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

rule0:
ruleF:
ruleG:
ruleH:  
ruleI:  
ruleJ:  
ruleK:  
ruleL:  
ruleM:  
ruleN:  
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
        ;; Right-recrusion is "fine"
        .byte 'S'+128,'A'+128,"|",0

;;; Block
ruleB:  
;;; TODO: empty?
        .byte "{}"
        .byte "|{",'A'+128,"}"
        .byte 0

;;; "Constant"/(variable) (simple, lol)
ruleC:  
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
        .byte 'T'+128,"main()",'B'+128
      .byte '['
        rts
        ;; TODO: HOWTO? maybe conflic with 'putchar'
      .byte ']'
        .byte 0

;;; Type
ruleT:  
        .byte "int|char|void",0

;;; Statement
ruleS:
;;; TODO: if

        .byte "return",'E'+128,";"
      .byte '['
        rts
      .byte ']'

        ;; simple assignement, ONLY as statement
        ;; and can't be nested or part of expression
        ;; (unless we use a stack...)
        .byte "|%A=",'E'+128,";"
      .byte "[:"                ; ':' => tos=dos
        sta VAL0
        stx VAL1
      .byte "]"

;;; Extention to C:
;;; Forward assignemenbt 3=>a; could work! lol
;;; TODO: make it multiple 3=>a=>b+7=>c; ...
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
;;; TODO: remove (once have assignement?)
        ;;    a  b  c  d  e  f  g  h  i  j
        .word 0,10,20,30,40,50,60,70,80,90
        .word 100,110,120,130,140,150,160,170
        .word 180,190,200,210,220,230,240,250,260

output:
        .res 8*1024, 0


.end
