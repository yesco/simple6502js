;;; ----------------------------------------
;;;               " B I O S "
;;; 
;;;       R A W    A T M O S    T T Y
;;; 
;;; 
;;; (C) 2025 Jonas S Karlsson, jsk@yesco.org
;;; 
;;; Features:
;;; - replaces, and doesn't dpend on ORIC BASIC ROM
;;; - can be used in your own ROM!
;;; - less than 256 Bytes code
;;; - mostly equivalent functionality


;;; #xc2 = 194 Bytes at the moment
;;;   not including keyboard


;;; FREE:  @ABCDEFGHIJKLMNOPQRSTUVWXYZ 27 28 29 30 31
;;; USED:          HIJKLM O    t      (27)      30
;;; EMACS:  ab defg  jk  nop  s uvw y             (ins)
;;; 
;;; legend:       (UPPER=impl, lower/()=TODO:)






;;; TODO: make it work!


;;; WARNING: not good yet!




;;;                  UNTESTED CODE!




;;; An BIOS implementation for ORIC ATMOS
;;; with these functions:
;;; 
;;; - jsr getchar  -  waits for a keypress
;;; 
;;; - jsr putchar  -  prints a character (Unix style)
;;; - jsr rawputc  -  raw prints a character
;;;                   (not \n takes cr+lf)
;;; - jsr writec   -  writes byte to screen
;;;                   (updates pos etc)
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


;;; TODO: move to ATMOS symbols file?

SCREEN=$bb80
SCREND=SCREEN+40*28


;;; putchar(c) print char from A
;;;   10= cr/lf unix-style \n
;;;   A,X,Y retains values
;;; 
;;; 19 B

spc:    
        lda #' '

putchar:        
        ;; '\n' -> '\n\r' = CRLF
        cmp #10                 ; '\n'
        bne rawputc
newline:
nl:     
        lda #13                 ; '\r'
        jsr rawputc
        lda #10
        ;; fall-through to rawputc

rawputc:        
        stx savexputchar
        sty saveyputchar

        cmp #' '
;        bcs putcnocontrol
        bcc :+
        jmp writec
:       
        ;; special control characters

;;; TODO: 20B (5 ctrl-chars) dispatch code
;;;   at 32+9=41 41/4=10 ctrls break-even point!
;;;   i.e., when adding EMACS then it's worth it!

;;; 8 codes => (* 8 4) = 32 bytes

        ;; - cr
        cmp #CTRL('M')          ; 10
        beq cr
        ;; - lf
        cmp #CTRL('J')          ; 10
        beq lf
        ;; - up
        cmp #CTRL('K')         
        beq up
        ;; - forward/right (9) - no tab? lol
        cmp #CTRL('I')
        beq forward

        ;; - bs
        cmp #CTRL('H')
        beq bs
        ;; - clearline (^O)
        cmp #CTRL('O')
        beq clrln
        ;; - clear screen
        cmp #12
        beq clrscr
        ;; - home cursor
        cmp #30
        beq home

        ;; - not recognized CTRL - ignore!
        bne rawputret

cr:
        ;; TODO: protected columns?
        ldx #0
        stx curx
        ;; always jump
        beq rawputret

lf:     
        inc cury
        lda cury
        cmp #28
        beq scrollup
        ;; - inc line ptr
        ;; 11 B TODO: subroutine?
        clc
        lda curlineptr
        adc #40
        sta curlineptr
        bcc :+
        inc curlineptr+1
:       
        jmp rawputret


;;; put in the middel, as many exits through here

writec: 
        ;; write it
        ldy #0
        sta (curlineptr),y

        ;; inc pos
        inc curx
        lda curx
        cmp #40
        bne :+
        jmp newline

rawputret:      
        ldy saveyputchar
        ldx savexputchar
        rts




scrollup:
        ;; TODO: scrollup
        ;; (for now, wrap around!)
        jsr home
        ;; - clear line

clrln: 
        lda #' '
        ldy #39
:       
        sta (curlineptr),y
        dey
        bpl :-
        bmi rawputret

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
        ;; TODO: subroutine?
        ;; 11 B
        sec
        lda curlineptr
        sbc #40
        sta curlineptr
        bcs :+
        dec curlineptr+1
:       
        ;; always
        bne rawputret

forward:        
        inc curx
        ldx curx
        cmp #40
        ;; wrap around at end
        jsr lf
        jmp cr
       
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
        ;; TODO: protected first row?
        ;; TODO: protected two cols?
        ldx #0
        sta curx
        sta cury

        ldx #<SCREEN
        stx curlineptr
        ldx #>SCREEN
        stx curlineptr+1
        ;; always 
        bne rawputret







.macro GOTOXY xx,yy
        ;; CURROW
        ldx #xx
        stx curx
        ldy #yy
        sty cury
        ;; ROWADDR
        lda #<(SCREEN + yy*40)
        ldx #>(SCREEN + yy*40)
        sta curlineptr
        stx curlineptr+1
.endmacro

;;; Atmos style names
CURROW=cury
CURCOL=curx
ROWADDR=curlineptr

;;; TODO: move all specifics into this file(?)
