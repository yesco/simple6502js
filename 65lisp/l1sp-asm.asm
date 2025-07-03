;;; l1sp = Lisp 1 Stack Page
;;; 
;;; Yet another start, possibly using off-vm.asm
;;; which is a simple library of 19 stack primitives
;;; implemented in 134 bytes!

;;; ========================================
;;; Initial functions requirement for
;;; template/begin.asm

.zeropage

tos:    .res 2
tmp1:   .res 2

.code

;;; set's TOS to num
;;; (change this depending on impl
.macro SETNUM num
        lda #<num
        sta tos
        lda #>num
        sta tos+1
.endmacro

.macro SUBTRACT num
        sec

        lda tos
        sbc #<num
        sta tos

        lda tos+1
        sbc #>num
        sta tos+1
.endmacro

;;; See template-asm.asm for docs on begin/end.asm
.include "begin.asm"

.zeropage

.code

;;; ========================================
;;;                  M A I N

.export _start
_start:
        putc 'L'
        putc '1'
        putc 's'
        putc 'p'
        NEWLINE




        NEWLINE
        putc 'E'
        putc 'N'
        putc 'D'

        rts

;PRINTHEX=1                     
;PRINTDEC=1
.include "print.asm"

;;;                  M A I N
;;; ========================================

.include "end.asm"

.end
