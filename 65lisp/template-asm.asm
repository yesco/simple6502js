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
        rts

;PRINTHEX=1                     
;PRINTDEC=1
.include "print.asm"

;;;                  M A I N
;;; ========================================

.include "end.asm"

.end
