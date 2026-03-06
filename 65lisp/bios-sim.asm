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


;;; TOOD: vt100?

.macro CURSOR_ON
        jsr setcursoron
.endmacro

.macro CURSOR_OFF
        jsr setcursoroff
.endmacro

setcursoron:    
        pha

;        PRINTZ {27,"[?25h"}
.data
curon: .byte 27,"[?25h",0
.code
        lda #<curon
        ldx #>curon
        jsr _printz
        
        pla
        rts


setcursoroff:
        pha

;        PRINTZ {27,"[?25l"}
.data
curoff: .byte 27,"[?25l",0
.code
        lda #<curoff
        ldx #>curoff
        jsr _printz

        pla
        rts




.define CTRL(c) c-'@'

.zeropage

saveaputchar:   .res 1
savexputchar:   .res 1
saveyputchar:   .res 1

.code

KBHIT=kbhit
;;; TODO: fix, use read(1) non-blocking?
kbhit:  
        ;; dummy, just return 0
        ;; TODO: this might cause problem if waiting...
        ;;    but also may skip some updating screen
        ;;    action if say have key...
        lda #0
        rts


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
        lda #13
        jsr rawputc
        ;; lf
        lda #10
:       
        jsr rawputc

        lda saveaputchar
        ldx savexputchar
        ldy saveyputchar

        rts

;;; Generic IO names with cc65 (conio.h)
        .import _getchar
        .import _putchar

getchar:        
        stx savexputchar
        sty savexputchar
        ;; modifies Y (for sure)
        jsr _getchar
        ldx savexputchar
        ldy savexputchar
        rts

;;; NON-BLOCKING ? - how to do?

;.import _cgetc
;getchar=_cgetc
;.import _mygetc
;getchar=_mygetc


rawputc=_putchar

putcraw=_putchar

.macro GOTOXY xx,yy
.scope

.data
@foo:   .byte sprintf( {27,"[%d;%dH"}, yy, xx)

.code
        lda #<@foo
        ldx #>@foo
        jsr _printz

.endscope
.endmacro


gotoxy:
        pha
        txa
        pha

        lda #27
        jsr putchar

        lda #'['
        jsr putchar

        ;; row
        tya
        ldx #0
        jsr _printu

        lda #';'
        jsr putchar

        ;; col
        pla
        jsr _printu

        lda #'H'
        jsr putchar

        pla
        rts

