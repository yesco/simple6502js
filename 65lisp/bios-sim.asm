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
        pha

        ;; new line? => cr/lf
        cmp #10
        bne :+
        ;; cr
        jsr rawputc
        ;; lf
        lda #13
:       

        jsr rawputc

        pla
        rts

;;; Generic IO names with cc65 (conio.h)
        .import _getchar
        .import _putchar

getchar=_getchar
rawputc=_putchar

.macro GOTOXY xx,yy
;;; TODO: implement using ANSI codes?
.endmacro
