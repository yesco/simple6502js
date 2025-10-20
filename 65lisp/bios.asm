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

.export _biosstart
_biosstart:     

.define CTRL(c) c-'@'

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
;;; 17B
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


;;; putchar(c) print char from A
;;;   10= cr/lf unix-style \n
;;;   A,X,Y retains values
;;; 
;;; 19 B
.export putchar

.export _xputchar
_xputchar:

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

.ifdef TTY
.zeropage
curlineptr:     .res 2
curx:           .res 1
cury:           .res 1
.code
        pha

        ;; new line? => cr/lf
        cmp #10
        bne :+
        ;; cr
        jsr rawputc
        ;; lf
        lda #13
:       
.ifdef CHANGECOLORS
        ;; col==2, rewrite colors!
        lda $0269                ; CURCOL
;        cmp #2
        bne :+

changecolors:   
        sty saveyputchar

        lda $026b               ; paper
        ldy #0
        sta ($12),y             ; ROWADDR

        lda $026c               ; color
        iny
        sta ($12),y             ; ROWADDR

        ldx saveyputchar

        pla
        pha
:       
.endif ; CHANGECOLORS           

        jsr rawputc

        pla
        rts

;;; TODO: 20B (5 ctrl-chars) dispatch code
;;;   at 32+9=41 41/4=10 ctrls break-even point!
;;;   i.e., when adding EMACS then it's worth it!

;;; rawputc saves X,Y trashes A
;;; 
;;; bs lf up forward clrscr  scrollup clrln
;;;   may trash A,X,Y!
;;; 
;;;   (+2 spc)
spc:    
        lda #' '
rawputc:
        stx savexputchar
        sty saveyputchar

        cmp #' '
;        bcs putcnocontrol
        bcc control
        jmp putcwriteit

control:        
        ;; special control characters

        ;; - clearline (^O)
        cmp #CTRL('O')
        beq clrln

        ;; - cr
        cmp #CTRL('M')          ; 10
        bne :+
cr:     
;;; TODO: protected columns?
        ldx #0
        stx curx

        ;; - lf
        cmp #CTRL('J')          ; 10
        bne :+
lf:     
        inc cury
        lda cury
        cmp #28
        beq @scrollup
        ;; - inc line ptr
;;; 11 B TODO: subroutine? (so far not used elsewhere!)
        clc
        lda curlineptr
        adc #40
        sta curlineptr
        bcc @noinc
        inc curlineptr+1
@noinc:
        jmp rawputret
@scrollup:
        ;; TODO: scrollup
        ;; (for now, wrap around!)
        jsr home
        jsr cr
        ;; - clear line
clrln: 
        lda #' '
        ldy #39
@loop:       
        sta (curlineptr),y
        dey
        bpl @loop
        bmi rawputret
:       
        ;; - bs
        cmp #CTRL('H')
        bne :+
bs:     
        ldx curx
        beq @bswrap
        dec curx
        ;; always
        bpl rawputret
@bswrap:
        ldx #39
        stx curx
up:     
        ;; at top, no up
        ldx cury
        beq rawputret
        ;; up
        dec cury
;;; TODO: -CONST == add (^CONST): use one routine!
;;; 11B (15 full add routine, 6B to call x 2) - save 6B?
        sec
        lda curlineptr
        sbc #40
        sta curlineptr
        bcs @nodec
        dec curlineptr+1
@nodec:
        ;; always
        bne rawputret
:       
        ;; - right (9) - no tab? lol
        cmp #CTRL('I')
        bne :+
forward:        
        inc curx
        ldx curx
        cmp #40
        ;; wrap around at end
        jsr lf
        jmp cr
:       
        ;; - home cursor
        cmp #30
        beq home
        ;; - clear screen
        cmp #12
        bne :+
clrscr: 
        jsr home
        ldx #27
        stx savexputchar
@nextrow:
        ;; these "restore" savexputchar but don't save!
        jsr clrln
        jsr lf
        dec savexputchar
        bne @nextrow
        ;; fall-through to home
home:   
;;; TODO: protected first row?
;;; TODO: protected two cols?
        ldx #0
        sta curx
        sta cury

        ldx #<SCR
        stx curlineptr
        ldx #>SCR
        stx curlineptr+1
        ;; always 
        bne rawputret
:       

;;; FREE:  @ABCDEFGHIJKLMNOPQRSTUVWXYZ 27 28 29 30 31
;;; USED:          HIJKLM O    t      (27)      30
;;; EMACS:  ab defg  jk  nop  s uvw y             (ins)
;;; 
;;; legend:       (UPPER=impl, lower/()=TODO:)

putcwriteit:    
        ;; write it
        ldy #0
        sta (curlineptr),y

        ;; inc pos
        inc curx
        lda curx
        cmp #40
        bne :+
        jmp newline
:       

rawputret:      
        ldy saveyputchar
        ldx savexputchar
        rts

.export _dummyputc
_dummyputc:     


.else ; !TTY

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

.else

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

.zeropage

saveaputchar:   .res 1
savexputchar:   .res 1
saveyputchar:   .res 1

.code


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

.export _biosend
_biosend:

BIOSINCLUDED=1


