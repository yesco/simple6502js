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

.ifdef __ATMOS__

.zeropage

saveaputchar:   .res 1
savexputchar:   .res 1
saveyputchar:   .res 1

.code

biostart:       

;;; USEFUL ROM ADDRESSES
;;; 
;;; When fast key action is not required, a machine
;;; code program can quickly get the ASCII code
;;; of the last keypress with one of two calls:
;;; 
;;; 1. To read a key without waiting, returning
;;; the ASCII code in the accumulator, call
;;; subroutine #E905 (version 1.0) or
;;; #EB78 (version 1.1).
;;; This is identical to using KEY$ in BASIC.
;;;
;;; 2. To wait for a key to be pressed (i.e., like GET
;;; in BASIC), call either #C5F8 (version 1.0)
;;; or #C5E8 (version 1.1).

.ifnblank
;;; ORIC "Read keyboard subroutine
;;; - retro8bitcomputers.co.uk/Content/downloads/manuals/oric-graphics-and-machine-code-techniques.pdf
;;; 
;;; A row 0-7, X $ff-columnbit $ff-1 $ff-2 -4 -8 -16...
readkey:        
        php
        sei
        pha
        lda #$0e
        jsr #f590
        pla
        ora #$b8
        sta $0300
        ldx #$04
        dex
        bne $4010
        lda $0300
        and #$08
        tax
        plp
        txa
        rts
.endif

;;; TODO: move before startaddr! (begin.asm)

;;; - https:  //github.com/Oric-Software-Development-Kit/osdk/blob/master/osdk%2Fmain%2FOsdk%2F_final_%2Flib%2Fgpchar.s

;;; input char from keyboard
;;;
;;; 10B
xgetchar:       
.proc getchar
;        lda #'A'
;        rts

;;; TODO: replace by my own...
.ifdef TTYxxxxxxLOL
        jmp halt
        lda #'A'
        rts
.endif ; TTY

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
.endproc


;.zeropage                     
;sos:    .word SCREEN
;.code

sos:    .byte 0

SCR=$bb80
SCREND=SCR+40*28


;;; platputchar used to delay print A
;;; (search usage in printd)
plaputchar:    
        pla

;;; putchar(c) print char from A
;;; (saves X, A retains value, Y not used)
;;; 
;;; 12B
.export putchar

putchar:        

.ifdef TTY
rawputc:                        ; well...
        stx savexputchar
        
        ;; minimal screen w putchar!, lol
        ldx sos
        and #127
        cmp #' '
        bcc :+
        sta $bb80,x
        inc sos
:    

        ldx savexputchar
        rts

.else

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

.ifdef HIBIT
        ;; printable with hibit?
        cmp #128+' '
        bcc :+
        ;; put directly in mem
;;; TODO: BUG: first char on line looses hibit?
        sty saveyputchar
        ldy CURCOL
        dey
        sta (ROWADDR),y
        ldy saveyputchar
:       

.endif ; HIBIT
        ldx savexputchar
        rts
.endif ; TTY

.else
;;; Generic IO names with cc65 (conio.h)
        .import _getchar
        .import _putchar

putchar=_putchar
getchar=_getchar
rawputc=_putchar

plaputchar:
        pla
        jmp putchar

.endif ; !__ATMOS__



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
