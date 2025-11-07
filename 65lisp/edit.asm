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
        ;; some may need it
        ldy #0

	;; --- CTRL DISPATCH
;;; 6 * 4 = 24
        ;; -> ^Forward
        cmp #CTRL('F')
        beq eforward
        cmp #CTRL('I')
        beq eforward
        ;; <- ^Back
        cmp #CTRL('B')
        beq eback
        cmp #CTRL('H')
        beq eback
        ;; BackSpace
        cmp #CTRL('D')
        beq edel
        cmp #127
        beq ebs
        ;; Return
        cmp #CTRL('M')
        bne :+
        lda #10
:       
        ;; CAPS LOCK
        cmp #CTRL('T')
        bne :+
        jmp putchar
:       
        ;; ^Help
        cmp #CTRL('H')
        bne :+
        jmp _help
:       
        ;; ^Verbose info
        cmp #CTRL('V')
        bne :+
        .import _info
        jsr _info
        jmp getchar
:       
        ;; ^l redisplay (tood: reload)
        cmp #CTRL('L')
        bne :+
        jmp loadfirst          
:       


        ;; --- INSERT
;;; (+ 1 10 7 14 9) = 41
        ;; To insert a character we need to push
        ;; overy thing up (unless we use gap-buffer)

        ;; - save key for later
        pha

        ;; - make spece shift up
        ;; (we need to know the end)

        ;; TDOO: seems redundant or too much work!
        ;;       we knew it when we copied...

        ;; - move back from end
;;; (10)
        lda editend
        sta tos
        lda editend+1
        sta tos+1

        ldy #0

        ;; TODO: revisit
        ;; double 0 byte makes this insert
        ;; not bleed into next input

        ;; TODO: alternatives to double 0?
        ; jsr _inct
        ; jmp @copyc
@nextc:
;;; (7)
        ;; dec tos
        lda tos
        bne :+
        dec tos+1
:       
        dec tos
@copyc:       
;;; (14)
        lda (tos),y
        pha
        iny
        and #$7f
        sta (tos),y
        dey
        pla
        ;; hibit == curpos! => exit!
;        beq @done
        bpl @nextc
        
@done:
;;; (9)
        ;; turn off old cursor
        jsr togglecursor

        pla
        sta (editpos),y
;        sta (tos),y

        ;; inc editend
        inc editend
        bne :+
        inc editend+1
:       

        ;; turn off new curosr
        jsr togglecursor
        ;; fall-through eforward
eforward:        
;;; 12
        ;; off
        jsr togglecursor

;;; TODO: at beginning of file - stop
        ;; todo: jsr _ince
        inc editpos
        bne :+
        inc editpos+1
:       
;;; TODO: make all routines "turn off cursor"
;;;    turn on before getchar, turn off after
        ;; on
        jmp togglecursor


eback:
;;; 11
        jsr togglecursor

;;; TODO: at end of file - stop
	;; todo: jsr _dece
        lda editpos
        bne :+
        dec editpos+1
:       
        dec editpos
        ;; fall-through togglecursor
togglecursor:   
;;; 9
        ldy #0
        lda (editpos),y
        eor #$80
        sta (editpos),y
ret:    
        rts


ebs:    
        jsr eback
edel:    
        jsr togglecursor
        
        ;; delete one character at cursor
        ;; - to
        lda editpos
        ldx editpos+1
        sta tos
        stx tos+1

        ;; Y=0
@loop:   
        ;; - copy back
        iny
        lda (tos),y
        dey
        sta (tos),y
        tax
        beq @done
        ;; - INC tos
        inc tos
        bne :+
        inc tos+1
:       
        bne @loop
@done:
        ;; - DEC editend
        lda editend
        bne :+
        dec editend+1
:       
        dec editend

        jmp togglecursor
        
        
        


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
;;; (+ 24 55) = 79
;;; (16)
        lda #<EDITNULL
        ldx #>EDITNULL
        sta pos
        stx pos+1

        lda #<(SC+40)
        ldx #>(SC+40)
        sta tos
        stx tos+1
;;; (8)
        lda #ROWS
        sta editrow
        
        ldx #WIDTH
        ldy #0

@nextc:
;;; 
        inc pos
        bne :+
        inc pos+1
:       
        ;; copy byte
        lda (pos),y
        beq @clreol             ; clrEOS!
        sta (tos),y

        ;; newline
        cmp #10
        beq @nl
        cmp #10+128             ; nl + cursor!
        beq @nl
@forw:
        dex
        bne :+
        ldx #WIDTH
:       
        inc tos
        bne :+
        inc tos+1
:       
        ;; always
        bne @nextc

        ;; we clear till end of line
@clreol:
        lda #' '
        sta (tos),y
@nl:
        inc tos
        bne :+
        inc tos+1
:       
        dex
        bne @clreol

        ;; no more rows
        dec editrow
        beq ret

        ldx #WIDTH

        lda (pos),y
        beq @clreol
        bne @nextc
.endif ; RED_RAW_ORIC
        



loadfirst:
;;; (+ 20 11 12 3 14 3) = 63

;;; 20+11
;;; TODO: 20 bytes param set up
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

        ;; TODO: maybe copyz does this? 
        ;; or dos+a reoutine?
        ;; update edit end
;;; 12
        tya
        clc
        adc dos
        sta editend
        lda #0
        adc dos+1
        sta editend+1
;;; 3
        jsr togglecursor

        ;; calculate end

;.if ((EDITSTART .mod 256)==0)
;EDITALIGNED=1
.scope
.ifdef EDITALIGNED
;;; 6

        .assert ((EDITNULL .mod 256)=0),error,"%% EDITALIGNED"
        sty editend
        lda dos+1
        sta editend+1
.else
;;; 14
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
;;; 3
        jmp _redraw







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
todoo
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

        

        
        
        
