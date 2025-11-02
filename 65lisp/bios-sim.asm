;;; ----------------------------------------
;;;               " B I O S "

;;; Sectorlisp minimal requirement:

;;; A BIOS with these functions:
;;; - jsr getchar
;;; - jsr putchar
;;; 
;;; NOTE: these are different than cc65 built-in.
;;; 
;;; This file is supposed to be .included!
;;; 

;;; Assumption:
;;; 
;;; Neither routine modifies X or Y register
;;; (they ar saved and restored)
;;; 
;;; And after putchar is assumed to be A before.

;;; TODO: implement TTY_HIBIT (to inverse)


BIOSINCLUDED=1



.define CTRL(c) c-'@'

.zeropage

saveaputchar:   .res 1
savexputchar:   .res 1
saveyputchar:   .res 1

.code

.export getchar

;sos:    .byte 0

;;; putchar(c) print char from A
;;;   10= cr/lf unix-style \n
;;;   A,X,Y retains values
;;; 
;;; 19 B
.export putchar

;;; platputchar used to delay print A
;;; (search usage in printd)
plaputchar:    
        pla
putchar:        
        sta saveaputchar
        stx savexputchar
        sty saveyputchar

        ;; new line? => cr/lf
        cmp #10
        bne :+
        ;; cr
        jsr rawputc
        ;; lf
        lda #13
:       

        jsr rawputc

        lda saveaputchar
        ldx savexputchar
        ldy saveyputchar

        rts

;;; Generic IO names with cc65 (conio.h)
        .import _getchar
        .import _putchar

getchar=_getchar

;;; NON-BLOCKING ? - how to do?

;.import _cgetc
;getchar=_cgetc
;.import _mygetc
;getchar=_mygetc


rawputc=_putchar

.macro GOTOXY xx,yy
;;; ansi codes not working?
        pha
        txa
        pha
        tya
        pha

        putc 27
        putc '['

        ;; row
        lda #<yy
        ldx #>yy
        jsr _printu

        putc ';'

        ;; col
        lda #<xx
        ldx #>xx
        jsr _printu

        putc 'H'
        
        pla
        tay
        pla
        tax
        pla
.endmacro
