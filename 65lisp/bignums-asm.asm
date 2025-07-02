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

anum:   .byte 1,0
bnum:   .byte 1,$ab

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
        jsr _bigprint
        NEWLINE

halt:   jmp halt

;;; ========================================
;;;               B I G N U M S

_bigprint:        
        lda #'$'
        jsr putchar

        ldy #0
        lda (tos),y
        tay
        
next:   
        lda (tos),y
        jsr print2h
        dey
        bne next
        
        rts

_bigadd:  

        
        
