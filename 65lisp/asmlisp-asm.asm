.export _initlisp
.export _printz, _printzptr

.zeropage

curscr: .res 2
ptr:    .res 2



.code

;;; printz: Prints an ASCIIZ zero terminated string
;;; identified by address in AX

_printz:      
        sta ptr
        stx ptr+1

;;; printzptr: Prints an ASCIIZ zero terminated string
;;; identified by address in ptr

;;; Note: can be used to print the last string printed!

_printzptr:        
        ldy #00

@next:   
        lda (ptr),y
        beq @end
        sta (curscr),y
        iny
        jmp @next
        
@end:    
        ;; advance str pointer
        tya
        clc
        adc curscr
        sta curscr
        lda curscr+1
        adc #00
        sta curscr+1

        rts



hello:  .asciiz "Hello AsmLisp!"


.proc _initlisp
        lda #$80
        sta curscr
        lda #$BB
        sta curscr+1
        ;; write a B directly
        lda #66
        sta $BB81
        ;; write a C indirectly
        lda #67
        ldy #02
        sta (curscr),y
        ;; write string x 2
        lda #<hello
        ldx #>hello
        jsr _printz
        jsr _printzptr

        rts
.endproc

        
