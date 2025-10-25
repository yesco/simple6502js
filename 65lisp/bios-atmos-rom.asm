;;; ----------------------------------------
;;;               " B I O S "

;;; An BIOS implementation for ORIC ATMOS
;;; with these functions:
;;; 
;;; - jsr getchar
;;; - jsr putchar
;;; 
;;; Assumption:
;;; 
;;; Neither routine modifies X or Y register
;;; (they ar saved and restored)
;;; 
;;; A after putchar is assumed to be A before.


;;; In most cases, if you generate a .tap-file,
;;; this is the most economical, as it saves
;;; about 256 bytes!
;;; 
;;; NOTE: ORIC uses timer-interrupts to scan keyboard
;;;       and they need to be enabled if they are off:
;;; 
;;; TIM:  If TIM is defined, interrupts are enabled
;;;       before reading, and turned off after.
;;;       This seems to work fine.


BIOSINCLUDED=1

;HIBIT=1


.if !.definedmacro(CTRL)
  .define CTRL(c) c-'@'
.endif





;;; ========================================
;;;        A T M O S    R O M   T T Y

.zeropage

saveaputchar:   .res 1
savexputchar:   .res 1
saveyputchar:   .res 1

.code

.macro CURSOR_OFF
        pha
        lda $026a
        and #255-1
        sta $026a
        pla
.endmacro

.macro CURSOR_ON
        pha
        lda $026a
        ora #1
        sta $026a
        pla
.endmacro


;; - https:  //github.com/Oric-Software-Development-Kit/osdk/blob/master/osdk%2Fmain%2FOsdk%2F_final_%2Flib%2Fgpchar.s

;;; input char from keyboard
;;;
;;; 17B
getchar:        
        ;; can't see cursor move, it's delay from turn on
        ;;  CURSOR_ON

;.ifdef TIM
        cli
;.endif ; TIM

        stx savexputchar
        sty saveyputchar

        ;; simulate fixed cursor
        ldy CURCOL
        lda (ROWADDR),y
        ora #$80
        sta (ROWADDR),y
        
        sty saveaputchar
        ldy #0
        sty CURCOL
:       
        jsr $023B               ; ORIC ATMOS only
        bpl :-                  ; hibit set when ready
        tax

        ;; simulate fixed cursor
        ldy saveaputchar
        sty CURCOL
        lda (ROWADDR),y
        and #$7f
        sta (ROWADDR),y

        ;; TODO: optional?
;        jsr $0238               ; echo char

        txa

        ldy saveyputchar
        ldx savexputchar

;.ifdef TIM
        sei
;.endif ; TIM

        ;CURSOR_OFF

        rts


plaputchar:     
        pla
putchar:        
        stx savexputchar
        sty saveyputchar
        ;; '\n' -> '\n\r' = CRLF
        cmp #$0A                ; '\n'
        bne notnl
        pha
        ldx #$0D                ; '\r'
        jsr $0238               ; oric putchar
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
        ldy CURCOL
        dey
        sta (ROWADDR),y
:       

.endif ; HIBIT
        ldx savexputchar
        ldy saveyputchar
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

putcraw:        
        pha
        ;; need to move first as ORIC ROM
        ;; removes hibit!
        lda #9
        jsr putchar
        ldy CURCOL
        ;; anum, and if col= 0, lol wraphell
        dey
        pla
        sta (ROWADDR),y
        rts


SCR=$bb80
SCREND=SCR+40*28



;;; ========================================
;;;            M I S C   I N F O

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



