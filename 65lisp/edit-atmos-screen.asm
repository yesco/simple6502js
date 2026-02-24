;;; NOTE: this is no longer used.
;;; 
;;; It was "novel" as it implemented EMACS-style
;;; editing using ORIC ATMOS full-screen.
;;; 
;;; It was abonded because of limitations:
;;; - limited to 26 lines
;;; - lines couildn't really be longer than 37 (?) chars
;;; - not "portable"

;;; edit's text on ORIC ATMOS hardware text screen
;;; 
;;; 

;;; - just use BASIC terminal!
;;; - add "save" (to tape? load from tape?)
;;; - limit walk out and intercept ctrl-L
;;; - add features
;;;   + ^O insert newline
;;;   + ^K remove line
;;;   + ^A ^E navigation ^F ^B

;;; ORIC terminal magical chars
;;; -(CTRL-A : copy char under cursor)
;;; -(CTRL-C : break)
;;; - CTRL-D : auto double height
;;; - CTRL-F : toggle keyclick
;;; - CTRL-G : BELL
;;; - CTRL-H : backspace
;;; - CTRL-I : forward
;;; - CTRL-J : line feed
;;; - CTRL-K : up
;;; - CTRL-L : clear screen
;;; - CTRL-M : carriage return
;;; - CTRL-N : clear row
;;; - CTRL-O : toggle screen (disable)
;;; - CTRL-P : toggle printer
;;; - CTRL-Q : toggle cursor
;;; - CTRL-S : toggle screen on/off
;;; - CTRL-T : toggle CAPS
;;; -(CTRL-X : cancel line)

;;; - CTRL- toggle protected column ORIC-1 only? (say ^I)


;;; Issues:
;;; - return doesn't break line into two
;;;   need to scroll down part of screen 
;;;   & move some text to next line, indented...
;;; - ctrl-O insert newline
;;; 
;;; ! can cheat: insert actual 10, "extract text",
;;;   clear screen, print text!
;;; 
;;; - kill line, similar
;;; 
;;; - need ^C to break!
;;; - or at least NMI! (simpliest)
;;; 
;;; - no way to save? LPRINT? 
;;; 
;;; - seems CSAVE and CLOAD works like "random access"
;;;   Not sure if last file wins if you down load .tap
;;;   that has been saved in oriutron.
;;; 
;;; - 



FUNC _ide
        CURSOR_OFF
        
.ifdef INTERRUPT
.ifnblank
        ;; print time
        putc 'M'-'@'
        lda seconds
        sta tos
        lda seconds+1
        sta tos+1
        jsr putu
        jsr spc

        jmp _ide
.endif
.endif ; INTERRUPT

.ifdef __ATMOS__
;;; update display of state
        ;; - dirty
        lda dirty
        beq :+
        lda #'*'
        SKIPTWO
:       
        lda #' '
        sta SCREEN+33

        ;; - showbuffer
        lda showbuffer
        beq :+
        lda #'a'
        SKIPTWO
:       
        lda #' '
        sta SCREEN+34
.endif ; __ATMOS__


        ;; "EDITLOOP"

        jsr getchar

        jsr editaction
        jmp _ide


editaction:     

;;; - ESC - toggle "editor" and "cmd"
        cmp #27
        bne :+

        lda showbuffer
        bmi load                ; firsttime
        beq load                ; no buffer shown => show!
docmd:  
        jsr _savescreen

        lda #0
        sta showbuffer
        jsr _eosnormal
        jsr nl
        jmp nl
:       
;;; - ctrl-Load/edit
        cmp #CTRL('L')
        bne  :+

load:   
        ;; first time?
        lda showbuffer
        bpl @notfirst

        lda 0
        sta showbuffer
        sta dirty

        jsr _eosnormal
        jsr _printsrc
        jmp write
@notfirst:       
        ;; not first
        jsr _eosnormal
        jmp _loadscreen
:       
;;; - CTRL-H (only on oric)
        cmp #CTRL('H')
        bne :+
        ;; CTRL-KEY?
        ldx $0209
        cpx #162
        bne :+
dohelp: 
        jsr _savescreen
        jsr _eosnormal
        jsr _help
        jmp _loadscreen
:
;;; - ctrl-V - info
        cmp #CTRL('V')
        bne :+

        jsr _savescreen
        jsr _eosnormal
        .import _info
        jmp _info
:       
;;; - ctrl-C - compile
        cmp #CTRL('C')
        bne :+

        jsr _savescreen

        lda #0
        sta showbuffer

        jsr nl
        lda #(BLACK+BG)&127
        ldx #WHITE&127
        jsr _eoscolors
        PRINTZ {10,YELLOW,"compiling...",10,10}
        ;; This basically restarts program, lol
	; TIMER
        
        ;; CTRL-KEY?
;        ldx $0209
;        cpx #162
;        beq @default

        ;; shift + ctrl ? lol
        ;; TODO: better combo


        ;; save 10 newline at last pos in every line!
        ;; lol
        ;; TODO: maybe have other way to detect this
        ;;   during compilation?

;;; TODO: make one sub? (also in FUNC _compile
;;;  TODO: maybe have one func set all defaults,
;;;   then you can override, and call "cont"?
        lda #<_output
        ldx #>_output
        sta _out
        stx _out+1
        ;; set input = screen
        lda #<(savedscreen+40)
        ldx #>(savedscreen+40)
        ;; set one byte 0 *after* screen!
        ;; (I guess we could just last pos..)
        ;; 0 -- it's also BLACK TEXT...
        ldy #0 
        sty savedscreen+SCREENSIZE
        ;; alright, all done?
        jmp _compileAX
        
@default:
        jmp _init


:       
;;; - DEL - delete backwards
        cmp #127                ; DEL-key
        bne :+
        
        inc dirty
        ;; back one, delete forward!
        jsr bs
        lda #CTRL('D')
:       
;;; - ctrl-D - delete char forward
        cmp #CTRL('D')
        bne :+
@bs:
        inc dirty
        ;; move chars back til end of line
        ldy CURCOL
@copyback:
        cpy #39
        bcs @deldone
        ;; copy one char
        iny
        lda (ROWADDR),y
        dey
        sta (ROWADDR),y
        iny
        jmp @copyback

@deldone:
        ;; erase last char
        lda #' '
        sta (ROWADDR),y

ret:
        ;; if at last pos in row
        lda CURCOL
        cmp #39
        beq @notlast
        rts
@notlast:       
        ;; - then go to end of line (last nonspace)
        lda #CTRL('E')
:       
;;; - ctrl-A - beginning of text in line
        cmp #CTRL('A')
        bne :+

        putc CTRL('M')

        ;; move to first nonspace
        
        ;; (cursor must be on for this to work!!!)
        putc CTRL('Q')

ctrla:  
        ;; end of screen - don't!
        lda CURROW
        cmp #27
        beq ret                 
        ;; stand on (white)space?
        ldy CURCOL
        lda (ROWADDR),y
        cmp #' '+1
        bmi ret
        ;; move forward
        jsr forward
        jmp ctrla

        ;; off
        putc CTRL('Q')
:       
;;; - ctrl-E - end of text in line
        cmp #CTRL('E')
        bne :+

        ;; (cursor must be on for this to work!!!)
        putc CTRL('Q')

        ;; move to end of line, lol
        putc CTRL('M')          ; beginning of line
        jsr nl

        ;; move to first nonspace
ctrle:  
        ;; beginning of screen - don't!
        lda CURROW
        cmp #1
        beq ret                 
        ;; move back
        jsr bs
        ;; stand on space?
        ldy CURCOL
        lda (ROWADDR),y
        cmp #' '+1
        bmi doneCE
        jmp ctrle
doneCE: 
        ;; forward one (after last char)
        jsr forward

        ;; off
        putc CTRL('Q')

        rts
:
;;; - ctrl-R - run/display error
        cmp #CTRL('R')
        bne :+

.scope
        jsr _savescreen
        jsr _eosnormal
        jmp _run
.endscope
        ;; just shows compilation errors again
        ;; jmp _aftercompile
:       
;;; - ctrl-Qasm - disasm => ^M machine code? lol
        cmp #CTRL('Q')
        bne :+

        jsr _savescreen
        jmp _dasm
:       
;;; - ctrl-Zource (as print source)
        cmp #CTRL('Z')
        bne :+

        jsr _savescreen
        jsr _eosnormal
        jmp _printsrc
:       
;;; - ctrl-Garnish source - pretty print
        cmp #CTRL('G')
        bne :+

        jsr _savescreen
        jsr _eosnormal
        jsr clrscr
        lda #<input
        ldx #>input
        .import _prettyprint
        jmp _prettyprint
:       
;;; - ctrl-U repeat N times ... command
        cmp #CTRL('U')
        bne :+

        rts
:       
;;; - ctrl-W - save
        cmp #CTRL('W')
        bne :+
        
write:  
        ;; over-ride, you can write, silly one!
        inc showbuffer
        inc dirty

        jsr _savescreen

        ;; yeah, it's still there
        inc showbuffer
        rts
:       
;;; - ctrl-Youit (just for sim65, can't catch ^C)
        cmp #CTRL('Y')
        bne  :+

        jsr _savescreen
        jsr nl
.ifdef __ATMOS__

        ;; NOP
        rts
.else

.import _exit
        lda #0
        tax
        jsr _exit
.endif

:       

;;; === MAPPING EMACS commands to ORIC control codes

;;; - RETURN goes next line indented as prev!
        cmp #CTRL('M')
        bne :+

        inc dirty

.ifdef DOO
        ;; remember here
        ldx CURCOL
        stx savex
        ;; save current row ptr
        lda ROWADDR
        sta sos
        lda ROWADDR+1
        sta sos+1
        ;; indent like this line
        lda #CTRL('A')
        jsr editaction
        ldy CURCOL
        sty savey
        ;; - move down
        lda #CTRL('N')
        ;; - scroll these lines down
        ;;   = from 
        lda #<SCREENEND-40
        sta tos
        lda #>SCREENEND-40
        sta tos+1
        ;;   = to
        lda #<SCREENEND
        sta dos
        lda #>SCREENEND
        sta dos+1
        ;;; copy line down
        ldy #39
:       
        lda (tos),y
        sta (dos),y
        dey
        bpl :-
        ;; dec lines
        
.endif ; DOO
        

:       
;;; - ctrl-Forward (emacs)
        cmp #CTRL('F')
        bne :+

        jmp forward
:       
;;; - ctrl-Backwards (emacs)
        cmp #CTRL('B')
        bne :+

        inc dirty
        jmp bs
:       
;;; - ctrl-Next line (emacs)
        cmp #CTRL('N')
        bne :+

        lda #CTRL('J')
:       
;;; - ctrl-Previous line (emacs)
        cmp #CTRL('P')
        bne :+

        lda #CTRL('K')
:       
;;; - ctrl-Xended commands
        cmp #CTRL('X')
        bne :+

        jmp _extend
:       
;;; - control char - just print it
        cmp #' '
        bcc editprint

;;; - INSERT CHAR (shift line + putchar)
        inc dirty
        pha
        ;; insert - push line right left of cursor
        ldy #38
:       
        lda (ROWADDR),y
        iny
        sta (ROWADDR),y
        dey
        dey
        cpy CURCOL
        bcs :-

        pla
editprint:
        ;; print it
        jmp rawputc

        cmp #CTRL('F')
        bne :+
        ; jmp fileopen
:       
        cmp #CTRL('S')
        bne :+
        ; jmp savefile
:       
        cmp #CTRL('W')
        bne :+
        ; jmp writefile
:       
        cmp #CTRL('C')
        bne :+
        ; jmp crashexit
:       
        cmp #CTRL('Z')
        bne :+
        ; jmp zleep (10s?)
        ; PING
:       
        rts

FUNC _savescreen
.ifndef __ATMOS__
        rts
.endif

        ;;; update editing state

        ;; - exit if not buffer
        lda showbuffer
        beq @ret

        ;; - exit if not dirty
        lda dirty
        beq @ret

        lda #0
        sta dirty
        sta showbuffer

        ;; TODO: alt: save as sanitized "string"
        ;;       use this for comilation/saving etc...
        ;;       can have many "buffers" a-z...

        ;; "sneakily" put 10 (newline) at last pos
        ;; of each line (otherwise one long line)
        ;; 
        ;; 10 is DOUBLE NORMAL, on oric screen
        ;; but in last column it's harmless!
        lda #<(SCREEN+40)
        ldx #>(SCREEN+40)
        sta pos
        stx pos+1

        ldx #27
        ldy #39
@nextrow:
        lda #10                 ; \n newline
        sta (pos),y
        ;; move down one line
        clc
        lda pos
        adc #40
        sta pos
        bcc :+
        inc pos+1
:       
        dex
        bne @nextrow

        ;; Now save the damn screen!

;;; 23 B
        ;; from
        lda #<SCREEN
        ldx #>SCREEN
        sta tos
        stx tos+1
        ;; to
        lda #<savedscreen
        ldx #>savedscreen
        sta dos
        stx dos+1
        ;; copy
        lda #<SCREENSIZE
        ldx #>SCREENSIZE
        
        jsr _memcpy
@ret:
        rts



FUNC _loadscreen
.ifndef __ATMOS__
        rts
.endif

        ;; update state
        ldx #0
        stx dirty
        inx
        stx showbuffer


;;; TODO: fixed param calling (copy N bytes to tos++)
;;;   20+3B params+call
        ;; from
;;; TODO: implement blockcalling convention!
        lda #<(savedscreen+40)
        ldx #>(savedscreen+40)
        sta tos
        stx tos+1
        ;; to
        lda #<(SCREEN+40)
        ldx #>(SCREEN+40)
        sta dos
        stx dos+1
        ;; copy
        lda #<(SCREENSIZE-40)
        ldx #>(SCREENSIZE-40)

        jmp memcpy


;;; CHEAT - not counted in parse.bin

;;; (+ 8 21 9) = 38 
;;; now: a generic multiplication is ... 32 .. 38 bytes...

;;; Isn't it just that AX means more code than
;;; separate tos?

.ifdef JUNK
  .code
FUNC _savedscreen

savedscreen:
        .byte "0123456789012345678901234567890123456789"
        .byte "1111111111222222222233333333334444444444"
;        .byte "2                                       "
        .byte "2 --------------------------------------"
        .byte "3 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        .byte "4 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        .byte "5 cccccccccccccccccccccccccccccccccccccc"
        .byte "6 dddddddddddddddddddddddddddddddddddddd"
        .byte "7 eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        .byte "8 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        .byte "9 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        .byte "10 ccccccccccccccccccccccccccccccccccccc"
        .byte "11 ddddddddddddddddddddddddddddddddddddd"
        .byte "12 eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        .byte "13 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        .byte "14 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        .byte "15 ccccccccccccccccccccccccccccccccccccc"
        .byte "16 ddddddddddddddddddddddddddddddddddddd"
        .byte "17 eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        .byte "18 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        .byte "19 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        .byte "20 ccccccccccccccccccccccccccccccccccccc"
        .byte "21 ddddddddddddddddddddddddddddddddddddd"
        .byte "22 eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        .byte "23 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        .byte "24 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        .byte "25 ccccccccccccccccccccccccccccccccccccc"
        .byte "26 ddddddddddddddddddddddddddddddddddddd"
        .byte "27 eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",0
        ;; not on sceen!
        .byte "28 ####################################"

.code

.else

.bss
FUNC _savedscreen

savedscreen:
        ;; ORIC SCREEN SIZE
        ;; (save program/screen before compile to "input")
        .res SCREENSIZE+1       ; +1 for \0

.code

.endif ; JUNK


FUNC _printsrc
        jsr clrscr
        lda #<input
        ldx #>input
        jmp _printz
