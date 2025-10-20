;;; ----------------------------------------
;;;               " B I O S "
;;; 
;;;       R A W    A T M O S    T T Y
;;; 
;;; 
;;; (C) 20225 Jonas S Karlsson, jsk@yesco.org
;;; 
;;; Features:
;;; - replaces, and doesn't dpend on ORIC BASIC ROM
;;; - can be used in your own ROM!
;;; - less than 256 Bytes code
;;; - mostly equivalent functionality



;;; WARNING: not good yet!




;;;                  UNTESTED CODE!




;;; An BIOS implementation for ORIC ATMOS
;;; with these functions:
;;; 
;;; - jsr getchar  -  waits for a keypress
;;; 
;;; - jsr putchar  -  prints a character
;;; 
;;; Note: putchar recognizes \n and will do cr+lf
;;; 
;;; Assumption:
;;; 
;;; Neither routine modifies X or Y register
;;; (they ar saved and restored)
;;; 
;;; A after putchar is assumed to be A before.


BIOSINCLUDED=1


;;; ----------------------------------------
;;;       C O N F I G U R A T I O N

;;; enable to invers character on hibit!
;;; This seems to have been an missed opportunito
;;; on ORIC. ('A'+128 will print an inverted 'A')

;HIBIT=1



;;; ========================================

.zeropage

;;; TODO: hmmm?
sos:    .byte 0

saveaputchar:   .res 1
savexputchar:   .res 1
saveyputchar:   .res 1

curlineptr:     .res 2
curx:           .res 1
cury:           .res 1

.code



.define CTRL(c) c-'@'


putchar:        
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


;;; TODO: to calculate static address to write raw


.macro GOTOXY xx,yy
;;; TODO: fix This is updating assuming rom

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



;;; TODO: move to ATMOS symbols file?

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


