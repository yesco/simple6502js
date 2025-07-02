.zeropage

savea:  .res 1
savex:  .res 1
savey:  .res 1

tos:    .res 2

;;; ========================================
.code

.include "bios.asm"

PRINTHEX=1
.include "print.asm"

.data

anum:   .byte 1,0     
        .res 256
bnum:   .byte 1,$ab 
        .res 256

.code

.macro TOS num
        lda #<num
        sta tos
        lda #>num
        sta tos+1
.endmacro

.export _initlisp
_initlisp:

        TOS anum
        jsr _bigprint
        NEWLINE
        
        TOS bnum
double: 
;        jsr _bigprint
;        NEWLINE
        jsr _bigshl
        jmp double

        NEWLINE
        putc 'E'
        putc 'N'
        putc 'D'

halt:   jmp halt

;;; ========================================
;;;               B I G N U M S

.proc bignum 
        ldy #0
        lda (tos),y
        tay
        rts
.endproc

.proc _bigprint
        lda #'$'
        jsr putchar

        jsr bignum
next:   
        lda (tos),y
        jsr print2h
        dey
        bne next
        
        rts
.endproc

.proc _bigshl
        ldy #0
        lda (tos),y
        sta savey
        jsr print2h

        clc
next:   
        iny
        lda (tos),y
        adc (tos),y
        sta (tos),y
        dec savey
        bne next
        
        ;; extend?
        bcc ret
        iny
        lda #0
        adc #0
        sta (tos),y

        ldy #0
        lda (tos),y
        clc
        adc #1
        sta (tos),y

ret:
        rts
.endproc

        
;;; 1 byte 2 digits
; (+ (* 9 16) 9) = 153        

        
        
