;;; edit.asm -
;;; (c) 2025 Jonas S Karlsson, jsk@yesco.org
;;; 
;;; A simple emacs style editor for ORIC ATMOS
;;; written in pure assembly.
;;; 

;;; TODO: move to atmos constants file?
HIRES      = $a000
HICHARSET  = $9800
SCREEN     = $bb80
CHARSET    = $b400


;;; Currently, we have a fixed buffer for editing.
;;; EDITSTART points to first char of text.
;;; EDITNULL  is one byte before containing 0!
;;; (to facilitate backward processing)

;;; For ORIC ATMOS we're going to use part of the
;;; HIRES as an editing buffer.
EDITNULL= HICHARSET


EDITSTART= EDITNULL+1
;;; non inclusive
;;; TEXTSCREEN CHARSET start
EDITEND= CHARSET
;;; 
EDITSIZE= EDITEND-EDITSTART



.bss
        
.org EDITSTART

editbuffer:         .res BUFFERSIZE

.zeropage

;;; A value of point EDITSTART <= x < EDITEND
editcursor:     .res 2
editend:        .res 2

editrow:        .res 1
editcol:        .res 1

.code

startedit:
        jsr clrscr
        
        ;; put cursor at start, len=0 bytes
        lda #<EDITSTART
        ldx #>EDITSTART
        sta editcursor
        stx editcursor+1
        sta editend
        stx editend+1

        ;; put zeroes at boundaries
        lda #0
        sta EDITNULL
        sta (editend),0
        sta editrow
        sta editcol


edit:   
        jsr getchar
        jsr editaction
        jmp edit
        

;;; Each operation ends with RTS
;;; (instead of jmp edit, saving 2 bytes)
editaction:
        
        ;; ^L redisplay (TOOD: reload)
        cmp #CTRL('L')
        bne :+

loadfirst:
        ;; TOS= from
        lda #<input
        ldx #>input
        sta tos
        stx tos+1

        ;; DOS= to
        lda #<EDITSTART
        ldx #>EDITSTART
        sta dos
        stx dos+1

        jsr copyz

        ;; calculate end
.if (EDITSTART .mod 256)==0
        sty dos
        lda dos+1
        sta editend+1
.else
        clc
        tya
        adc dos
        bcc :+
        inc dos+1
:       

        sta editend
        ldx dos+1
        stx editend+1
.endif

        jmp redraw
:       
        
        

;;; update
redraw: 
        lda #<EDITSTART
        ldx #>EDITSTART
        sta pos
        lda #0
        sta pos+1
        
        ;; keep track of column
        ldx #$ff
        ;; low byte of pos ptr
        ldy pos
@nextc:       
        lda (pos),y
        beq @done
        ;; newline
        cmp #10
        bne :+

        jsr clreol
        jmp @wrap
:       
        inx
        cpx #WIDTH
        bne :+
@wrap:
        ldx #$ff

        inc editrow
        ;; end of screen? - done
        lda editrow
        cmp #ROWS
        beq @done
:       
        jsr putchar

        ;; move forward
        iny
        bne @nextc
        inc pos+1
        ;; always
        bne @nextc

@done:
        stx editcol
        rts
        


        

        
        
        
