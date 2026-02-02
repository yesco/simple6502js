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

;;; TODO: export _ ???
.export spaces, putnc, spc, _tab, clrscr
.export forward, bs, newline, nl, spc

;;; count in Y
spaces:
        lda #32
;;; put A char Y times
putnc:  
        sty savey
:       
        beq :+
        jsr putchar
        dey
        bpl :-
:       
        rts

;;; Good to haves!
_tab:   
tab:    
.ifdef __ATMOS__
        ;; Atmos doesn't have TAB
        ;; at least one space
:       
        jsr spc
        lda CURCOL
        and #7                  ; "mod 8"
        beq :+
        jmp :-
:       
        rts
.else
        lda #9
        SKIPTWO
.endif

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
