;;; TODO: Replace this with your code intro:
 


;;; TEMPLATE for minamalistic 6502 ASM projects
;;; 
;;; Why use it?
;;; 
;;; It provides these main benefits:
;;; 
;;; 1. A 6502 "BIOS" that is excluded from the bytecount.
;;; 
;;; 2. DEBUGPRINT function (hex/decimal)
;;; 
;;; 3. Before starting your code, reports the various
;;;    info, like:
;;; 
;;;        o$053E - ORG address of whole thing
;;;        s$0600 - user code START address
;;;        e$0627 - user code END address
;;;        z$0027 - SIZE in bytes of user code
;;; 
;;;    The size excludes the "loader" (PROGRAM.c)
;;;    and the "bios.asm" code. Also
;;; 
;;; 4. User code starts on a PAGE boudnary
;;;    allowing various hacky optimizations1
;;; 
;;; 5. ???
;;; 



;;; See template-asm.asm for docs on begin/end.asm
.include "begin.asm"

.zeropage

.code

;;; ========================================
;;;                  M A I N

.export _start
_start:
.ifnblank

        SETNUM $BAAD
        DEBUGPRINT
        NEWLINE

        SETNUM $F00D
;        jsr printn
        NEWLINE

        lda #'B'
        sta $bb81
        
        lda #'D'
        jsr putchar

        SETNUM $4711
        jsr printh
        NEWLINE

        SETNUM 12345
        jsr printd
        NEWLINE

        putc 'E'
        putc 'N'
        putc 'D'
.endif


.zeropage
        
inp:    .res 2

.code

;;; parser
        putc 'A'
        NEWLINE

        lda #<input
        sta inp
        lda #>input
        sta inp+1
        
        lda #<ruleA
        sta rule
        lda #>ruleA
        sta rule+1

next:   
;;; TODO: Stopping condition?
        jsr getr
        jsr nextc
        ;; literaly equal (assume it's ok)
        beq next
;;; TODO: if space match space, allow/skip any/all spaces
        
        ;; apply matchers...
        cpx #'.'
        beq next

;;; TODO: special rule... (?)
        cpx #'?'
        beq optionalnext
        cpx #'+'
        beq atleastonce
        cpx #'*'
        beq repeats

        ;; TODO: don't need push/OR/alt?
        cpx #'|'
        beq endrule
        cpx #0
        beq endrule
        
        ;; fail match -> backtrack
;;; TODO: may need pop-a-lot!
        jsr getr
        


        rts

getr:   
        ldy #rule
        jsr incRY
        ldy #0
        lda (rule),y
        ;; ref another rule?
        beq @endrule
        bpl @norule
        ;; special rules (char class)
        cmp #'d'+128
        bne notdigit 
digitchar:
        lda (inp),y
        sec
        sbc #'0'
        cmp #'9'+1
        bcs FAIL
        jmp NEXT
;;; TODO: make a: i=identifier= w*(w|d|_)
;;;     w=word= +v v=wordchar
;;;     n=number= +d d=digit
notdigit:       
        cmp #'w'+128
        bne notword
wordchar:       
        lda (inp),y
        sec
        sbc #'A'
        ;; fold case
        and #(255-32)           ; TODO:correct?
        cmp #'Z'+1
        bcs endword
        ;; keep eating chars
        iny
        jmp wordchar
endword:        
        cpy #0
        bcs FAIL
        ;; accept, Y points to end
;;; TODO: store match
        jmp NEXT

notword:
        cmp #'w'+128
        bne notword
wordchar:       

notword:        
        ;; - new rule        
        asl
        tax
        ;; push current rule
        lda rule
        pha
        lda rule+1
        pha
        ;; new rule
        lda ruletable,x
        sta rule
        lda ruletable+1,x
        sta rule+1
        jmp getr
@endrule:
        ;; pop rule state
        pla
        sta rule+1
        pla
        sta rule
        jmp getr
;;; TODO: use some other?
@norule:
        rts

;;; Gets next char in A
;;; Flags: Z= if lit equal
nextc: 
;;; 12
        ldy #inp
        jsr incRY
        ldy #0
        lda (inp),y
        cmp (rule),y
        rts
        
incrY:
;;; 9
        inc 0,y                 ; 3B
        bne @noinc
        inc 1,y                 ; 3B
noinc:  
        rts
        
        
;PRINTHEX=1                     
;PRINTDEC=1
.include "print.asm"

;;;                  M A I N
;;; ========================================

endfirstpage:        
secondpage:     
bytecodes:      

rules:  

ruleA:  
        .byte 'A'+128
        .byte "aaa",0

input:  
        .byte "aaa",0

.include "end.asm"

.end
