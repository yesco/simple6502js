;;; edit.asm -
;;; (c) 2025 Jonas S Karlsson, jsk@yesco.org
;;; 
;;; A simple emacs style editor for ORIC ATMOS
;;; written in pure assembly.
;;; 

;;; TODO: optimize for code-size.
;;; TODO: and... is gap-buffer smaller? (faster!)

;;; This module is 
;;;    545 B / IDE: 2432 B
;;;    683 B - added ^A ^E (hmmm?), command stuff
;;; 
;;; Old editor ( edit-atmos-screen.asm )
;;;    529 B / IDE: 2428 B
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

;;; TODO: doesn't need to be zeropage?
editend:        .res 2

editcol:        .res 1

;;; TODO: just use a tmp in zp?
editrow:        .res 1


.code



;;; Edit the current buffer
;;; 
;;; Depending on "mode", you're either in
;;; edit mode (BPL) or command mode (BMI).
;;; 
;;; 
FUNC _edit
        ;; init if first time
        bit mode
        bvc :+
        ;; init + "load"
        jsr loadfirst
        ;; mark not need init
        lda mode
        and #255-64
        sta mode
:       
        jmp editloop


command:
        PRINTZ {10,">"}
        jsr _eosnormal
editing:
        jsr getchar
        jsr _ideaction

editloop:       
        bit mode
        bmi command

        ;; don't redraw if key waiting!
        jsr KBHIT
        bmi :+
        jsr _redraw
:       
        jmp editing



;;; putting some routines BEFORE ediaction
;;; (to reach them)

enext:
        lda #10
        jsr etill

egotocol:       
        ldx editcol
:       
        lda (editpos),y
        beq rts2
        cmp #10
        beq rts2
;;; This messes things up
;        cmp #10+128
;        beq rts2

        jsr eforward
        ;; move forward more?
        dex
        bpl :-
rts2:       
        rts

eprev:  
        jsr eback
        lda #10
        jsr ebtill
        jsr eback
        lda #10
        jsr ebtill

        ;; similar to 
        jmp egotocol


eend:   
        lda #10
        jmp etill

ebeginning:     
        jsr eback
        lda #10
        jsr ebtill
        jmp eforward
        
eindent:
        jsr ebeginning
:       
        lda (editpos),y
        ;; damn cursor lol
        and #$7f
        beq rts2
        cmp #' '+1
        bcs rts2
        
        jsr eforward
        jmp :-
        

;;; each operation ends with rts
;;; (instead of jmp edit, saving 2 bytes)
FUNC _editaction
        ;; some may need it
        ldy #0

	;; --- CTRL DISPATCH

        ;; ^ ^Prev
        cmp #CTRL('P')
        beq eprev
        cmp #UPKEY              ; CTRL-K (delline)
        bne :+
        cpx #sCTRL
        bne eprev               ; is arrowkey
        ;; ^Kill
        jmp ekill
:       
        ;; v ^Next
        cmp #CTRL('N')
        beq enext
        cmp #DOWNKEY            ; CTRL-J (indent new line)
        bne :+
        cpx #sCTRL
        bne enext               ; is arrowkey
        ;; CTRL-J - insert and indent line
        ;; A=10 already!
:       

        ;; -> ^Forward
        cmp #CTRL('F')
        beq eforward
        cmp #RIGHTKEY           ; CTRL-I (tab)
        bne :+
        cpx #sCTRL
        bne eforward            ; is arrowkey
        ;; ^Indent (move to first letter)
        beq eindent
:       
        ;; <- ^Back
        cmp #CTRL('B')
        beq eback
        cmp #LEFTKEY            ; CTRL-H (help)
        beq eback

        ;; |< ^A beginning
        cmp #CTRL('A')
        beq ebeginning
        ;; >| ^End
        cmp #CTRL('E')
        beq eend


        ;; Delete forward / DEL=BackSpace!
        cmp #CTRL('D')
        beq edel
        cmp #127                ; DEL key on ORIC!
        beq ebs
        ;; ? RETURN or CTRL-M
        cmp #13                 ; RETURN
        bne :+
        ;; (test that ctrl is pressed and not BS)
        cpx #sCTRL
        bne @nl
        jmp ctrlM
@nl:
        ;; RETURN newline
        lda #10
:       
        ;; ----------------------------------------
        ;; ELSE

        ;; --- INSERT
        jsr einsert
        ;; fall-through to eforward
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
        ;; at cursor, save COL
        bpl :+
        stx editcol
        ;; store editrow? currently used as loopvar
:
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
        beq @done

        ldx #WIDTH

        lda (pos),y
        beq @clreol
        bne @nextc

@done:
        ;; reverse editcol
        lda #40
        sec
        sbc editcol
        sta editcol

        rts

togglecommand:
;;; 7
        lda mode
        eor #128
        sta mode

        bpl @ed
        ;; reshow compilation result
        jsr _eosnormal
        jmp _aftercompile
@ed:
        jmp _redraw


;; == COMMANDS
FUNC _ideaction
        ;; ESCape (toggle COMMAND/EDIT)
        cmp #27
        beq togglecommand

        cpx #sCTRL
        bne ia_noctrl
       
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
        ;; ^L redisplay (Undo?)
        cmp #CTRL('L')
        bne :+
        jmp loadfirst          
:       
        ;; ^T CAPS LOCK (ORIC KEY)
        cmp #CTRL('T')
        bne :+
        jmp putchar
:       
        ;; ^Compile
        cmp #CTRL('C')
        bne :+

        jmp ecompile
:       
        ;; ^Run
        cmp #CTRL('R')
        bne :+

        jmp _run
:       
        ;; - ctrl-Qasm - disasm
        cmp #CTRL('Q')
        bne :+

        jmp _dasm
:       

ia_noctrl:
        ;; --- none
        bit mode
        bmi @command
@edit:
        jmp _editaction

        ;; command mode return
@command:
        rts




;;; move forwards (editpos) till A
etill:  
;;; 15
        sta savea
        jsr togglecursor
@nextc:       
        lda (editpos),y
        beq eret
        cmp savea
        beq eret

;;; TOOD: what's the difference (incinc works...)
.ifblank
        ;; WTF? why doesn't it work?
;;; because CMP fails? beq ...
;;; TODO: remove almost ALL toggle cursors!
jsr togglecursor
        jsr eforward
jsr togglecursor
.else
        inc editpos
        bne :+
        inc editpos+1
:
.endif

        jmp @nextc
eret:   
        jmp togglecursor


;;; move backward (editpos) till A
ebtill:  
;;; 12
        sta savea
        jsr togglecursor
@nextc:       
        lda (editpos),y
        beq eret
        cmp savea
        beq eret

.ifnblank
        jmp eback
.else
        lda editpos
        bne :+
        dec editpos+1
:       
        dec editpos
.endif
        jmp @nextc


;;; Insert A at current cursor position
einsert:
;;; (+ 1 10 7 14 9) = 41
        ;; - save key for later
        pha

        ;; To insert a character we need to push
        ;; overy thing up (unless we use gap-buffer)

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
        jmp @copyc
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
        jmp togglecursor



;;; TODO: crashes...
ctrlM:  
        ;; CTRL-M .... ? Sectret Mystery Action?
        jsr _eosnormal

        putc 'S'
        jsr spc
        lda #<EDITSTART
        ldx #>EDITSTART
        jsr _printh
        jsr nl

        putc 'P'
        ldy #editpos
        jsr printvar

        putc 'E'
        ldy #editend
        jsr printvar

        putc 'e'
        jsr spc
        lda #<EDITEND
        ldx #>EDITEND
        jsr _printh
        jsr nl

        putc 'Z'
        jsr spc
        lda #<EDITSIZE
        ldx #>EDITSIZE
        jsr _printu
        jsr nl

        jsr nl

        putc 'c'
        jsr spc
        lda editcol
        ldx #0
        jsr _printu

        jmp getchar

ekill:  
;;; TODO: iplement kill line
        rts


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


.ifnblank

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

.endif ; BLANK

        jmp _redraw



ecompile:
        jsr nl
        lda #(BLACK+BG)&127
        ldx #WHITE&127
        jsr _eoscolors
        PRINTZ {10,YELLOW,"compiling...",10,10}
        
        ;; set output
        lda #<_output
        ldx #>_output
        sta _out
        stx _out+1
        ;; set input = EDITSTART
        lda #<EDITSTART
        ldx #>EDITSTART
        ;; alright, all done?
        jmp _compileAX

