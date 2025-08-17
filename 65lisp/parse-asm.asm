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
;;; - %D - matches a sequence of digits (number: /\d+/ )
;;; - %I - matches an "ident" (name: /[A-Z_][a-z_\d]*/ )

;;; Warning: The recursive rule matching is limited by
;;;   the hardware stack. (~ 256/6)




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


;;; Enable for debug info
;DEBUG=1

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
        

state:  
  rule:   .res 2
  inp:    .res 2
stateend:       


.code
;;; TOTOAL
;;;    161 Bytes


;;; parser
FUNC _init
;;; 19 B

.ifdef DEBUG 
       putc 'S'
        NEWLINE
.endif ; DEBUG
        lda #<input
        sta inp
        lda #>input
        sta inp+1
        
        ;; end-all marker
        lda #128
        pha

        lda #<ruleA
        sta rule
        lda #>ruleA
        sta rule+1

FUNC _next
;;; 16 B
        ldy #0
.ifdef DEBUG
    PUTC ' '
    lda (rule),y
    jsr putchar
    PUTC ':'
    lda (inp),y
    jsr putchar
.endif ; DEBUG
        lda (rule),y
        beq _endrule
        bmi _enterrule
        ;; also end-rule
        cmp #'|'
        beq _endrule

        ;; lit eq?
        cmp (inp),y
        bne _fail
FUNC _eq    
;;; 9 B
    DEBC '='
        jsr _incI
        jsr _incR
        jmp _next

FUNC _enterrule
;;; 34 B
        ;; enter rule
        ;; - save (0, rule)
    DEBC '>'
        lda rule+1
        pha
        lda rule
        pha
        lda #0                  ; rule-mark
        pha

        ;; - load new rule
        lda (rule),y
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
        lda #1
        pha

        jmp _next
;;; TODO: use jsr, to know when to stop pop?
;;; (maybe don't need marker on stack?)

FUNC _endrule
;;; 19 B
    DEBC '<'
        ;; accept as match
        ;; - remove (all) re-tries
        pla
        beq @gotrule
        bmi _endall
@gotretry:
    DEBC '.'
        pla
        pla
        jmp endrule

@gotrule:
    DEBC '_'
        pla
        sta rule
        pla
        sta rule+1

        jmp _next

FUNC _endall
        rts


FUNC _fail
;;; TODO: test special matchers
;;;   %D - digits
;;;   %I - ident

;;; 25 B

    DEBC '%'
        ;; - seek next alt in rule
@loop:
        jsr _incR
        beq _endrule
        cmp #'|'
        bne @loop
        ;; - standing at '|' alternative
        jsr _incR
        ;; - restore inp
    DEBC '|'
        pla
        bmi gotendall   
        beq gotrule

gotretry:
    DEBC '!'
        ;; copy from stack
        tsx
        pla
        sta inp
        pla
        sta inp+1
        txs



;;; ERRORS

FUNC _errors
;;; 25

gotendall:
        lda #'E'
        SKIPTWO

endrule:
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
        
FUNC _dummy

        
;;;                  M A I N
;;; ========================================

endfirstpage:        
  .res 256-(* .mod 256)
secondpage:     

bytecodes:      

rules:  
        .word ruleA
        .word ruleB
        .word 0

ruleA:  
        .byte "aaa",0

ruleB:  
        .byte "bbb",0

.include "end.asm"

input:  
        .byte "aaaa",0

;PRINTHEX=1                     
;PRINTDEC=1
;.include "print.asm"

.end
