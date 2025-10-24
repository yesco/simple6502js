;;; tty-helpers.asm
;;; 
;;; Part of library for parse CC02 C-compiler



;;; ----------------- MACROS

.ifndef TTY_HELPERS


;;; putchar (leaves char in A)
;;; 5B
.macro putc c
        lda #(c)
        jsr putchar
.endmacro

;;; for debugging only 'no change registers A'
;;; 7B
.macro PUTC c
;        subtract .set subtract+7
        pha
        putc c
        pla
.endmacro

;;; 7B - only used for testing
.macro NEWLINE
        PUTC 10
.endmacro

;;; ----------------- UTILTITY PRINTERS

;;; Good to haves!
.export _clrscr
_clrscr:        
clrscr:        
        lda #12
        SKIPTWO
forward:        
        lda #'I'-'@'
        SKIPTWO
bs:
        lda #8
        SKIPTWO
newline:        
nl:     
        lda #10
        SKIPTWO
spc:
        lda #' '
        jmp putchar

.endif ; !TTY_HELPERS
