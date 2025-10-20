;;;               DON'T 

;;;      TOUCH, CHANGE, MESS WITH


;;;              instead:


;;; TODO: this file is quite a mess,
;;; only to be used by old "begin.asm"/"end.asm"

;;; Please use one of these instead!

;;;     .include "bios-atmos-rom.asm"
;;;     .include "bios-raw-atmos.asm"
;;;     .include "bios-sim.asm"

;;; Eeeek! Why they don't have common naming scheme?
;;; A: that's on purpose so that you don't mix them up.
;;;    (ROM / RAW sounds looks/sounds too simlar)


;;; ----------------------------------------
;;;               " B I O S "

;;; Sectorlisp minimal requirement:

;;; A BIOS with these functions:
;;; - jsr getchar
;;; - jsr putchar
;;; 
;;; Assumption:
;;; 
;;; Neither routine modifies X or Y register
;;; (they ar saved and restored)
;;; 
;;; A after putchar is assumed to be A before.

;;; enable to invers on hibit
;HIBIT=1


BIOSINCLUDED=1



.define CTRL(c) c-'@'


.zeropage

saveaputchar:   .res 1
savexputchar:   .res 1
saveyputchar:   .res 1

.code

.ifdef __ATMOS__

biostart:

;;; input char from keyboard
;;;
;;; 17B

getchar:        
;.ifdef TIM
        cli
;.endif ; TIM
        stx savexputchar
        sty saveyputchar

:       
        jsr $023B               ; ORIC ATMOS only
        bpl :-                  ; hibit set when ready
        tax

        ;; TODO: optional?
;        jsr $0238               ; echo char

        ldy saveyputchar
        ldx savexputchar

;.ifdef TIM
        sei
;.endif ; TIM

        rts


;.zeropage                     
;sos:    .word SCREEN
;.code

;sos:    .byte 0

;SCR=$bb80
;SCREND=SCR+40*28


;;; putchar(c) print char from A
;;;   10= cr/lf unix-style \n
;;;   A,X,Y retains values
;;; 
;;; 19 B
.export putchar

newline:        
nl:     
        lda #10
        SKIPONE
;;; platputchar used to delay print A
;;; (search usage in printd)
plaputchar:    
        pla
putchar:        
;;; Test if really called? lol
;       jsr self
;self:                          

        stx savexputchar
        ;; '\n' -> '\n\r' = CRLF
        cmp #$0A                ; '\n'
        bne notnl
        pha
        ldx #$0D                ; '\r'
        jsr $0238
        pla
notnl:  
rawputc:        
        tax
        jsr $0238

        ldx savexputchar
        rts


.macro GOTOXY xx,yy
        ;; CURROW ATMOS
        ldx #xx
        stx $0269
        ldy #yy
        sty $0268
        ;; ROWADDR
        lda #<($bb80 + yy*40)
        ldx #>($bb80 + yy*40)
;;; TODO: overlap w CC02 variables!!
        sta $12
        stx $13
.endmacro





.else ; so it's sim(ulator)



.macro GOTOXY xx,yy
;;; TODO: generate string with ANSI terminal code
.endmacro

newline:        
nl:     
        lda #10
        jmp putchar

;;; Generic IO names with cc65 (conio.h)
        .import _getchar
        .import _putchar

getchar=_getchar
rawputc=_putchar

plaputchar:
        pla

putchar:                
        sty saveyputchar
        stx savexputchar
        pha
        jsr _putchar
        pla
        ldx savexputchar
        ldy saveyputchar
        rts

.endif



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



.ifndef TTY

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
spc:
        lda #' '
        jmp putchar

.endif ; !TTY


