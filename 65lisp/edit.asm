;;; edit.asm -
;;; (c) 2025 Jonas S Karlsson, jsk@yesco.org
;;; 
;;; A simple emacs style editor for ORIC ATMOS
;;; written in pure assembly.
;;; 

;;; TODO: move to atmos constants file?
HIRES      = $a000
HICHARSET  = $9800
;SCREEN     = $bb80
SC=$bb80
CHARSET    = $b400


;;; Currently, we have a fixed buffer for editing.
;;; EDITSTART points to first char of text.
;;; EDITNULL  is one byte before containing 0!
;;; (to facilitate backward processing)

;;; For ORIC ATMOS we're going to use part of the
;;; HIRES as an editing buffer.
EDITNULL= HICHARSET

;;; lol
;EDITNULL= input-1


EDITSTART= EDITNULL+1

;;; non inclusive
;;; TEXTSCREEN CHARSET start
EDITEND= CHARSET
;;; 
EDITSIZE= EDITEND-EDITSTART


WIDTH=40
;ROWS=20
ROWS=27

.zeropage

;;; A value of point EDITSTART <= x < EDITEND
editpos:        .res 2
lineptr:        .res 2
editend:        .res 2

editrow:        .res 1
editcol:        .res 1

.code

.ifdef FISHF
FUNC _initedit
        jsr clrscr
        
        ;; put cursor at start, len=0 bytes
        lda #<EDITSTART
        ldx #>EDITSTART
        sta editpos
        stx editpos+1
        sta editend
        stx editend+1

        ;; put zeroes at boundaries
        ldy #0
        tya
        sta EDITNULL
        sta (editend),y
;        sta editrow
;        sta editcol

.endif

FUNC _edit
        jsr loadfirst

FUNC _editloop

        jsr getchar

;jsr printchar
        jsr _editaction

;;; TODO: if bbhit skip redraw!
        jsr _redraw

        jmp _editloop
        

;;; each operation ends with rts
;;; (instead of jmp edit, saving 2 bytes)
FUNC _editaction
        
        ldy #0

        ;; ^l redisplay (tood: reload)
        cmp #CTRL('L')
        beq loadfirst

        cmp #CTRL('F')
        beq eforward
        cmp #CTRL('I')
        beq eforward

        cmp #CTRL('B')
        beq eback
        ;; TODO: DEL gibes ^H?
        cmp #CTRL('H')
        beq eback
        ;; not special - insert
        ;; - save for later
        pha

        ;; - make spece shift up
        ;; (we need to know the end)

;;; seems redundant or too much work!
;;; todo: we knew it when we copied...

        ;; - move back from end
        lda editend
        sta tos
        lda editend+1
        sta tos+1

        ldy #0

;;; double 0 byte makes this insert
;;; not bleed into next input

;        jsr _inct
;        jmp @copyc
@nextc:
        ;; dec tos
        lda tos
        bne :+
        dec tos+1
:       
        dec tos
@copyc:       
        lda (tos),y
        pha
        iny
        and #$7f
        sta (tos),y
        dey
        ;; todo: beginning of file (no cursor?)
        pla
;        beq @done
        ;; hibit == curpos! => exit
        beq @nextc
        bpl @nextc
        
@done:
        jsr togglecursor
        pla
        sta (editpos),y
        
;        sta (tos),y
        ;; fall-through
        jsr togglecursor

eforward:        
        jsr togglecursor

;;; todo: jsr _ince
        inc editpos
        bne :+
        inc editpos+1
:       

        jmp togglecursor

eback:   

        jsr togglecursor

;;; todo: jsr _dece
        lda editpos
        bne :+
        dec editpos+1
:       
        dec editpos

;;; todo: fall-through?
        jmp togglecursor

togglecursor:   
        ldy #0
        lda (editpos),y
        eor #$80
        sta (editpos),y
        rts

loadfirst:
        ;; tos= from
        lda #<input
        ldx #>input
        sta tos
        stx tos+1
        ;; dos= to
        lda #<EDITSTART
        ldx #>EDITSTART
        sta dos
        stx dos+1
        ;; sta editpos too
        sta editpos
        stx editpos+1
        ;; 
        jsr copyz
        ;; zero terminate
        lda #0
        sta (dos),y
        iny
        sta (dos),y
        dey

        ;; update edit end
        tya
        clc
        adc dos
        sta editend
        lda #0
        adc dos+1
        sta editend+1

        ;; set hibit on first char
        ;; == cursor!
        lda EDITSTART
        ora #$80
        sta EDITSTART
        
        ;; calculate end

;.if ((EDITSTART .mod 256)==0)
;EDITALIGNED=1
.scope
.ifdef EDITALIGNED

        .assert ((EDITNULL .mod 256)=0),error,"%% EDITALIGNED"
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
.endscope

        jmp _redraw
;        rts




;REDRAW_NONE=1
;
RED_RAW_ORIC=1
;RECDRAW_Y=1
;REDRAW_GENERIC=1
;REDRAW_PUTCHAR=1

.ifdef REDRAW_NONE
FUNC _redraw
        rts
.endif ; REDRAW_NONE



.ifdef RED_RAW_ORIC
;;; raw raw raw - relatively fast!
FUNC _redraw 
;;; (+ 20 50) = 70
        lda #<(SC+40)
        ldx #>(SC+40)
        sta tos
        stx tos+1
        
        lda #<EDITNULL
        ldx #>EDITNULL
        sta pos
        stx pos+1

        lda #ROWS
        sta editrow
        
        ldx #WIDTH
        ldy #0

@nextc:
        inc pos
        bne :+
        inc pos+1
:       

        lda (pos),y
        beq @done2
        sta (tos),y

        ;; newline
        cmp #10
        beq @newline
        cmp #10+128             ; nl + cursor!
        beq @newline

        
@forw:
        dex
        bne :+
        ldx #WIDTH
:       

        inc tos
        bne :+
        inc tos+1
:       
        jmp @nextc

@clreol2:
        lda #' '
        sta (tos),y
@newline:
        inc tos
        bne :+
        inc tos+1
:       
        dex
        bne @clreol2

        ;; no more rows
        dec editrow
        beq @done2

        ldx #WIDTH
        jmp @nextc

@done2:
        rts
        
.endif ; RED_RAW_ORIC
        










.ifdef REDRAW_Y;
;; redraw whole edit screen directly in memory
FUNC _redraw 
;;; (+ 20 50) = 70
        lda #<(SCREEN+40)
        ldx #>(SCREEN+40)
        sta dos
        stx dos+1
lskjdflsakjdflasdkjflsdkf        
        lda #<EDITSTART
        ldx #>EDITSTART
        sta pos
        stx pos+1

        ldx #0                  ; X=rows
        ;; Y store col and offset from dos and pos!
        ldy #0                  ; Y=cols, lol
        
@nextc:
        lda (pos),y
        beq @done
        ;; newline
        cmp #10+128
        beq @newline
        cmp #10
        bne @putcraw
@newline:
        ;; update lineptr
        tya
        clc
        adc pos
        sta lineptr
        lda pos+1
        sta lineptr+1

@cleareol:
        ;; clear till end of line
        lda #'-'
:       
;;; TODO: always do one, maybe not good?
        sta (dos),y
        iny
        cpy #COLS
        bne :-
        beq @wrap

@putcraw:
        sta (dos),y

        iny
        cpy #WIDTH
        bne @nextc
@wrap:
        ;; move line down
        clc
        lda dos
        adc #WIDTH
        sta dos
        bcc :+
        inc dos+1
:       
        jmp @nextc
        

@done:
        rts

.endif ; REDRAW_Y
















.ifdef REDRAW_GENERIC
;;; GENERIC "vt100" terminal style
FUNC _redraw
;;; 42 B
        ;; "hack"
        ;; - save char at cursor, replace with \0
        ldy #0
        lda (editpos),y
        pha
        tya
        sta (editpos),y

        ;; print till cursor
        jsr clrscr

        lda #<EDITSTART
        ldx #>EDITSTART
        jsr putz
        
        ;; save cursor pos on screen
        ;; (TODO: it's compat w gap-buffer!)
        jsr hidecursor
        jsr savecursor

        ;; restore char
        pla
        ldy #0
        sta (editpos),y

        lda editpos
        ldx editpos+1
        jsr putz
        
        ;; move cursor to "editpos"
        jsr restorecursor
        jsr showcursor

        rts
.endif ; REDRAW_GENERIC


.ifdef REDRAW_PUTChAR
;;; update "no putz"
FUNC _redraw
;;; 56 B
        lda #<EDITSTART
        ldx #>EDITSTART
        sta pos
        lda #0
        sta pos+1

        sta editrow
        
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

        ;; store lineptr
        sty lineptr
        lda pos+1
        sta lineptr+1

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
;        jsr putchar

        ;; move forward
        iny
        bne @nextc
        inc pos+1
        ;; always
        bne @nextc

@done:
        stx editcol
        rts
        

.endif ; REDRAW_PUTChAR

        

        
        
        
