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
        rts

;PRINTHEX=1                     
;PRINTDEC=1
.include "print.asm"

;;;                  M A I N
;;; ========================================

endfirstpage:        
secondpage:     
bytecodes:      

.include "end.asm"

.end
